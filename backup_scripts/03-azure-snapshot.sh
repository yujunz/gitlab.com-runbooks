#!/bin/bash
# vim: ai:ts=8:sw=8:noet
# This script automates the creation of VM on Azure to test shapshot backups
set -eufo pipefail
IFS=$'\t\n'

# Command requirements
command -v az >/dev/null 2>/dev/null || { echo 'Please install az utility'; exit 1; }

# Variables to change always
RDATE='2018-03-01'		# Date of snapshot to restore
RG_NAME='BADFeb2018-f08'	# Name of the resource group

# Variables to change if you want test different box
RESTORE='file-08'	# Which machine to restore (leave file-08 if you are unsure)

# Variables to change only if you know what you are doing
RG_LOC='eastus2'	# Location to create restoration resource group in
VM_NAME='restorevm'	# How the VM should be named
VM_USERNAME='restore'	# How the first user should be named
SUB="c802e1f4-573f-4049-8645-4f735e6411b3" # our subscription

# Main flow
# Generate rsa keypair in current dir if not existent
test -f "./${RG_NAME}_rsa4096" || \
	ssh-keygen -f "./${RG_NAME}_rsa4096" \
		-t rsa \
		-C "ephemeral ${USER}'s key for ${RG_NAME}" \
		-N '' \
		-b 4096

# Check if the snapshot to restore exists (and check if we can login)
echo "Will try restoring this snapshots resource group:"
az group list --verbose \
	--query "[?name=='snapshots-${RDATE}']"

echo "Creating separate resource group for restoration:"
az group create --verbose \
	--location "${RG_LOC}" \
	--name "${RG_NAME}"

echo "Creating VM ${VM_NAME}"
VM_IP=$(az vm create --verbose \
	--resource-group "${RG_NAME}" \
	--location "${RG_LOC}" \
	--name "${VM_NAME}" \
	--image "UbuntuLTS" \
	--admin-username "${VM_USERNAME}" \
	--authentication-type "ssh" \
	--ssh-key-value "./${RG_NAME}_rsa4096.pub" \
	--size "Standard_DS13_v2" | jq ".publicIpAddress")

# NOTE: the following could be done multithreaded way with -P16,
# if only az client didn't break _horribly_ in multithreaded mode
# The only option/hack I see now is duplicate $HOME/.azure/ per
# thread, cause az actively writing there, with races during it
# Try this:
# az group list # check its working
# chmod 0400 ~/.azure/clouds.config
# az group list # see error completely unrelated to readonly file
echo "Creating VM disks"
seq 0 15 | xargs -n1 -P1 -I{} sh -c \
	"az disk create --verbose \
		--resource-group '${RG_NAME}' \
		--name '${RESTORE}-restore-{}' \
		--source '/subscriptions/${SUB}/resourceGroups/snapshots-${RDATE}/providers/Microsoft.Compute/snapshots/${RESTORE}-datadisk-{}-snap-${RDATE}'"

echo "Attaching VM disks"
seq 0 15 | xargs -n1 -P1 -I{} sh -c \
	"az vm disk attach --verbose \
		--resource-group '${RG_NAME}' \
		--disk '${RESTORE}-restore-{}' \
		--vm-name '${VM_NAME}' \
		--lun '{}'"

echo "All done, please proceed:"
echo ssh "${VM_USERNAME}@${VM_IP}" -i "./${RG_NAME}_rsa4096" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
echo "And do 'mkdir /var/opt/gitlab && mount /dev/gitlab_vg/gitlab_var /var/opt/gitlab'"
echo "After you are done, don't forget to remove resource group ${RG_NAME}"
