#!/bin/bash
# vim: ai:ts=8:sw=8:noet
# This automates creation of packagecloud box on AWS to test backup restore procedures
set -eufo pipefail
IFS=$'\t\n'

# Command requirements
command -v aws >/dev/null 2>/dev/null || { echo 'Please install aws utility'; exit 1; }

# Variables to change only if you know what you are doing
AWS_REGION='us-east-1'	# Location to create restoration resource group in
VM_NAME='restorepkgc'	# How the VM should be named

# Main flow
# Generate rsa keypair in current dir if not existent
test -f "./${VM_NAME}_rsa4096" || \
	ssh-keygen -f "./${VM_NAME}_rsa4096" \
		-t rsa \
		-C "ephemeral ${USER}'s key for ${VM_NAME}" \
		-N '' \
		-b 4096

# Get latest Trusty AMI
echo -n "Latest Trusty AMI: "
AWS_AMI="$(aws ec2 describe-images \
	--region "${AWS_REGION}" \
	--filters "Name=name,Values=*ubuntu-trusty-14.04-amd64-server*" \
		  "Name=root-device-type,Values=ebs" \
		  "Name=virtualization-type,Values=hvm" \
	--query 'sort_by(Images, &Name)[-1].ImageId' \
	--output text)"
echo "${AWS_AMI}"

# Use playground subnet for that
echo -n "Will use 'playground' subnet, id: "
AWS_SUBNET="$(aws ec2 describe-subnets \
	--region "${AWS_REGION}" \
	--filters "Name=tag:Name,Values=playground" \
	--query "Subnets[0].SubnetId" \
	--output text)"
echo "${AWS_SUBNET}"

# Use some old security group with ssh in and tcp out for now
AWS_SG="sg-9bf638fc"

echo "Creating VM ${VM_NAME}"
CUSTOM_DATA=$(cat <<EOF
#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
echo "$(cat "./${VM_NAME}_rsa4096.pub")" > /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
chmod 0400 /home/ubuntu/.ssh/authorized_keys

mkfs.ext4 -q /dev/xvdf
mkdir -p /var/opt/packagecloud
mount /dev/xvdf /var/opt/packagecloud

apt-get update && apt-get -y install s3cmd

EOF
)

AWS_IID="$(aws ec2 run-instances \
	--count 1 \
	--enable-api-termination \
	--ebs-optimized \
	--instance-type c4.2xlarge \
	--associate-public-ip-address \
	--subnet-id "${AWS_SUBNET}" \
	--security-group-ids "${AWS_SG}" \
	--image-id "${AWS_AMI}" \
	--user-data "${CUSTOM_DATA}" \
	--block-device-mappings "DeviceName=/dev/sdf,Ebs={VolumeSize=3072,VolumeType=gp2,DeleteOnTermination=true}" \
	--tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${VM_NAME}}]" \
	--query "Instances[0].InstanceId" \
	--output text)"

echo "Created instance: ${AWS_IID}, trying to get IP"

VM_IP="$(aws ec2 describe-instances \
	--instance-ids "${AWS_IID}" \
	--query "Reservations[].Instances[].NetworkInterfaces[].Association.PublicIp" \
	--output text)"

echo "rerun this to query for ip again"
echo aws ec2 describe-instances \
	--instance-ids "${AWS_IID}" \
	--query 'Reservations[].Instances[].NetworkInterfaces[].Association.PublicIp' \
	--output text

echo ssh "ubuntu@${VM_IP}" -i "./${VM_NAME}_rsa4096" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null

echo "After you are done, don't forget to remove ec2 machine ${VM_NAME}"

# sed '/^#/d;/^$/d;/^backups/d;/ssl/d' /etc/packagecloud/packagecloud.rb
# disable redirects to https too
