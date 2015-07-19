#!/bin/sh
#
# Script to spin up an instance of the latest-available Amazon
# Linux instance from which to extract the various AWS CLI
# utilities and modules
#
#################################################################
AWSBIN="/opt/aws/bin/aws"
export AWS_DEFAULT_REGION=$(curl -s \
   http://169.254.169.254/latest/dynamic/instance-identity/document | \
   awk -F":" '/"region"/{ print $2 }' | sed -e 's/^ "//' -e 's/".*$//')
AMZNUTIL="aws-amitools-ec2
          aws-apitools-as
          aws-apitools-common
          aws-apitools-ec2
          aws-apitools-elb
          aws-apitools-mon
          aws-apitools-rds
          aws-cfn-bootstrap
          aws-cli
          ec2-utils
          get_reference_source
          python-boto"

# Connect to AMI and stage SRPM files
function PULLSRC() {
   ssh ${SRCHOST} << EOF
for PKG in ${AMZNUTIL}
do
get_reference_source $PKG
done
EOF
}


echo "Determining latest-available Amazon Linux AMI-ID..."
TARGAMI=$(${AWSBIN} ec2 describe-images --owner amazon --filters \
   "Name=image-type,Values=machine" "Name=architecture,Values=x86_64" \
   "Name=root-device-type,Values=ebs" "Name=name,Values=amzn-ami-hvm-*" \
   --query 'Images[].{ID:ImageId,NAME:Name,DATE:CreationDate}' \
   --output text | sort -n | sed -n '$p' | awk '{print $2}')

echo $TARGAMI
echo $AMZNUTIL
