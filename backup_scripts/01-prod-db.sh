#!/bin/bash
# vim: ai:ts=8:sw=8:noet
# This script automates the creation of VM on Azure to test production DB backup
set -eufo pipefail

# Debugging options... uncomment below
AZDEBUG=--verbose
#AZDEBUG="--debug --verbose"
#set -x -v

IFS=$'\t\n'

# Command requirements
command -v az >/dev/null 2>/dev/null || { echo 'Please install az utility'; exit 1; }

# Variables to change always
RG_NAME="BAD-$(date --iso-8601)-${USER}-proddb" # Name of the resource group

# Variables to change only if you know what you are doing
RG_LOC='eastus2'	# Location to create restoration resource group in
VM_NAME='restoreproddb'	# How the VM should be named
VM_USERNAME='restore'	# How the first user should be named

# Main flow
# Generate rsa keypair in current dir if not existent
test -f "./${RG_NAME}_rsa4096" || \
	ssh-keygen -f "./${RG_NAME}_rsa4096" \
		-t rsa \
		-C "ephemeral ${USER}'s key for ${RG_NAME}" \
		-N '' \
		-b 4096

echo "Creating separate resource group $RG_NAME for restoration:"
az group create $AZDEBUG \
	--location "${RG_LOC}" \
	--name "${RG_NAME}"

echo "Creating VM ${VM_NAME}"
CUSTOM_DATA=$(cat <<EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

# Format and mount gitlab storage (assuming one extra disk attached, hence sdc)
mkfs.ext4 -q /dev/sdc
mkdir -p /var/opt/gitlab && mount /dev/sdc /var/opt/gitlab

# Set apt config, update repos and disable postfix prompt
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'No configuration'"

# install everything in one go
apt-get -y install daemontools lzop gcc make python3 virtualenv python3-dev libssl-dev gitlab-ee ca-certificates postfix
gitlab-ctl reconfigure

# stop postgres just after reconfig
gitlab-ctl stop postgresql

# to save some wtf figuring out
sed -i 's/^max_replication_slots = 0/max_replication_slots = 100/' /var/opt/gitlab/postgresql/data/postgresql.conf

# Configure wal-e
mkdir -p /opt/wal-e /etc/wal-e.d/env
virtualenv --python=python3 /opt/wal-e
/opt/wal-e/bin/pip3 install boto azure wal-e

# prepare for vault
touch /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
touch /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
touch /etc/wal-e.d/env/WALE_S3_PREFIX
# this is not secret
echo 'us-east-1' > /etc/wal-e.d/env/AWS_REGION

# precreate recovery.conf
cat > /var/opt/gitlab/postgresql/data/recovery.conf <<RECOVERY
restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch "%f" "%p"'
recovery_target_time = '2017-XX-YY 06:00:00'
recovery_target_action = 'promote'
RECOVERY
chown gitlab-psql:gitlab-psql /var/opt/gitlab/postgresql/data/recovery.conf

EOF
)

az vm create $AZDEBUG \
	--resource-group "${RG_NAME}" \
	--location "${RG_LOC}" \
	--name "${VM_NAME}" \
	--image "UbuntuLTS" \
	--admin-username "${VM_USERNAME}" \
	--authentication-type "ssh" \
	--ssh-key-value "./${RG_NAME}_rsa4096.pub" \
	--size "Standard_DS3_v2" \
	--data-disk-sizes-gb 1024 \
	--custom-data "${CUSTOM_DATA}"

# We can't use the ip address from the vm create because, at least in
# one version of az cli, it produces bogus json with single quotes
VM_IP=$(az vm list-ip-addresses $AZDEBUG --resource-group "${RG_NAME}" -o json | \
			jq -r '.[0].virtualMachine.network.publicIpAddresses[0].ipAddress')

echo "All done, please proceed (see tail -f /var/log/cloud-init-output.log):"
echo ssh "${VM_USERNAME}@${VM_IP}" -i "./${RG_NAME}_rsa4096" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

echo "After you are done, don't forget to remove resource group ${RG_NAME}"
