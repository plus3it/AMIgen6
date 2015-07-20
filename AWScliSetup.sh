#!/bin/sh
#
# Script to automate and standardize installation of AWScli tools
############################################################
SCRIPTROOT="$(dirname ${0})"
CHROOT="${CHROOT:-/mnt/ec2-root}"
AWSZIP=${1:-/tmp/awscli-bundle.zip}

# Bail if bogus location for ZIP
if [ -s ${AWSZIP} ]
then
   echo "Found ${AWSZIP}"
else
   echo "Did not find software at ${AWSZIP}. Aborting..." > /dev/stderr
   exit 1
fi

# Unzip the AWScli bundle into /tmp
(cd /tmp ; unzip ${AWSZIP})

# Copy the de-archived zip to ${CHROOT}
cp -r /tmp/awscli-bundle ${CHROOT}/root

# Install AWScli bundle into ${CHROOT}
chroot ${CHROOT} /root/awscli-bundle/install -i /opt/aws -b /usr/bin/aws

# Verify AWScli functionality within ${CHROOT}
chroot ${CHROOT} /usr/bin/aws --version

# Cleanup
rm -rf ${CHROOT}/root/awscli-bundle

# Install other AWS utilities to CHROOT
yum --installroot=${CHROOT} install -y ${SCRIPTROOT}/AWSpkgs/*.noarch.rpm
