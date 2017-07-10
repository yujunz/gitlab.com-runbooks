#!/bin/bash
# vim: ai:ts=8:sw=8:noet
# This script automates the creation of VM on DO to test secondary DB backup
set -eufo pipefail
IFS=$'\t\n'

# Command requirements
command -v doctl >/dev/null 2>/dev/null || { echo 'Please install doctl utility'; exit 1; }

# Variables to change always
RESTORE='customers'

# Variables to change only if you know what you are doing
DO_REGION='nyc3'	# Location to create restoration resource group in
VM_NAME="bkp${RESTORE}"	# How the VM should be named

# Main flow
# Check what we're restoring
if [[ ! "${RESTORE}" =~ ^(license|version|customers)$ ]]; then
	echo "Box to test restore should be one of: license, version, customers"
	exit 1
else
	RESTORE_IMAGE='ubuntu-14-05-x64'
	RESTORE_PG_VER='9.3'
	if [[ "${RESTORE}" == 'customers' ]]; then
		RESTORE_IMAGE='ubuntu-16-04-x64'
		RESTORE_PG_VER='9.5'
	fi
fi

# Generate rsa keypair in current dir if not existent
test -f "./${RESTORE}_rsa4096" || \
	ssh-keygen -f "./${RESTORE}_rsa4096" \
		-t rsa \
		-C "ephemeral ${USER}'s key for ${RESTORE}" \
		-N '' \
		-b 4096

echo "Creating VM ${VM_NAME}"
USER_DATA=$(cat <<EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
mkdir -p /root/.ssh
echo "$(cat "./${RESTORE}_rsa4096.pub")" >> /root/.ssh/authorized_keys
chmod 0700 /root/.ssh && chmod 0400 /root/.ssh/authorized_keys
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
echo -e '\nPermitRootLogin without-password\n' >> /etc/ssh/sshd_config
service ssh reload
chpasswd <<< "root:plzdontbugmedigitalocean$(pwgen -s -1 32)"

# install postgres
apt-get update && apt-get -y install daemontools lzop gcc make python3 virtualenvwrapper python3-dev libssl-dev postgresql gnupg-agent pinentry-curses
service postgresql stop

# Configure wal-e
mkdir -p /opt/wal-e /etc/wal-e.d/env
virtualenv --python=python3 /opt/wal-e
/opt/wal-e/bin/pip3 install --upgrade pip
/opt/wal-e/bin/pip3 install boto azure wal-e

# prepare for vault
touch /etc/wal-e.d/env/AWS_ACCESS_KEY_ID
touch /etc/wal-e.d/env/AWS_SECRET_ACCESS_KEY
touch /etc/wal-e.d/env/WALE_S3_PREFIX
touch /etc/wal-e.d/env/WALE_GPG_KEY_ID
touch /etc/wal-e.d/env/GPG_AGENT_INFO
# this is not secret
echo 'us-east-1' > /etc/wal-e.d/env/AWS_REGION

# precreate recovery.conf
cat > /var/lib/postgresql/${RESTORE_PG_VER}/main/recovery.conf <<RECOVERY
restore_command = '/usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e wal-fetch "%f" "%p"'
recovery_target_time = '2017-XX-YY 06:00:00'
# disabled on secondary
# recovery_target_action = 'promote'
RECOVERY
chown postgres:postgres /var/lib/postgresql/${RESTORE_PG_VER}/main/recovery.conf


# Manual steps cheat-sheet (if encrypted):
# Restore latest backup cmd
# /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-list 2>/dev/null | tail -1 | cut -d ' ' -f1 | xargs -n1 /usr/bin/envdir /etc/wal-e.d/env /opt/wal-e/bin/wal-e backup-fetch /var/lib/postgresql/${RESTORE_PG_VER}/main
# Then, to restore wal-e chunks, under user postgres:
# gpg --allow-secret-key-import --import /etc/wal-e.d/ops-contact+dbcrypt.key
# gpg --import-ownertrust /etc/wal-e.d/gpg_owner_trust
# (force gpg agent remember passphrase -- see official docs)
# put GPG_AGENT_INFO value to /etc/wal-e.d/env/GPG_AGENT_INFO
# Note: in 16.04 you should manually construct this value as sockpath:pid:1.
# put key id to /etc/wal-e.d/env/WALE_GPG_KEY_ID
# echo 'use-agent' > ~/.gnupg/gpg.conf
# start postgres

EOF
)

VM_IP="$(doctl compute droplet create \
	"${VM_NAME}" \
	--no-header \
	--format PublicIPv4 \
	--image "${RESTORE_IMAGE}" \
	--region "${DO_REGION}" \
	--size '512mb' \
	--user-data "${USER_DATA}" \
	--verbose \
	--wait)"

echo "All done, please proceed (see tail -f /var/log/cloud-init-output.log):"
echo ssh "root@${VM_IP}" -i "./${RESTORE}_rsa4096" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

echo "After you are done, don't forget to remove droplet ${RESTORE}"
