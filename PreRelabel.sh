#!/bin/sh
#
# This script performs the steps necessary to allow an SELinux
# autorelabel to run within the ${CHROOT} environment prior to
# snapshotting. This obviates the need for boot-time relabeling,
# reducing the launch-to-ready time by several minutes.
#
#################################################################
CHROOT="${CHROOT:-/mnt/ec2-root}"

# Emit error message and exit
function fatal() {
   echo "${1}" > /dev/stderr
   logger -p local0 -t AMIbuilder "${1}"
   exit
}

# Make sure build-host is suitable
if [[ $(getenforce) = "Disabled" ]]
then
   fatal "SELinux not enabled on build-host"
fi

# Make sure the chroot-env knows SEL is ready
if [[ ! -d ${CHROOT}/selinux ]]
then
   mount -o bind /selinux $CHROOT/selinux && \
      echo "Mounted '/selinux' to chroot env." || \
      fatal "/selinux filesystem failed to mount"
fi

# Nuke the re-lable file
if [[ -f ${CHROOT}/.autorelabel ]]
then
   rm ${CHROOT}/.autorelabel && "Nuked ${CHROOT}/.autorelabel" || \
      fatal "Failed to nuke ${CHROOT}/.autorelabel. AMI will relabel on first-boot"
fi

# Relabel the chroot-env
printf "Relabeling the chroot env... "
chroot $CHROOT /sbin/fixfiles -f relabel && echo "Success!" || \
   fatal "Operation may have failed."
