#!/bin/sh
#
# Add contents necessary to make AMI grow to up-sized root-EBS
#
#################################################################
SCRIPTROOT="$(dirname ${0})"
CHROOT="${CHROOT:-/mnt/ec2-root}"
GROWDIR="usr/share/dracut/modules.d/50growroot"

# Install the grow modules from EPEL
yum --installroot=$CHROOT --enablerepo=epel install -y dracut-modules-growroot

if [[ $? -ne 0 ]]
then
   echo "Failed to install grow dracut-modules" > /dev/null
   exit 1
fi

# Use a patched version of the EPEL-hosted grow-script
# - this should be unnecessary if/when BZ #1343571 is resolved
if [[ -d ${CHROOT}/${GROWDIR} ]]
then
   cp ${SCRIPTROOT}/growroot.sh ${CHROOT}/${GROWDIR}
   if [[ $? -ne 0 ]]
   then
      printf "Failed to copy patched growroot.sh to " > /dev/stderr
      echo "${CHROOT}/${GROWDIR}." > /dev/stderr
      exit 1
   fi

   # Ensure LVM-related binaries are in initramfs
   rpm -qlf /sbin/pvs | grep "/sbin/" | sed 's/^\/sbin\//dracut_install /' >> ${CHROOT}/${GROWDIR}/install
   if [[ $? -ne 0 ]]
   then
      echo "Failed to patch dracut 'install' file. Aborting..." > /dev/stderr
      exit 1
   fi
fi

# Recompile the new AMI's kernel to use the modules
chroot $CHROOT su - root -c \
   "rpm -q kernel | sed 's/^kernel-//' | \
    xargs -I {} dracut -f -v /boot/initramfs-{}.img {}"

# Clean out the dracut log-file
cat /dev/null > $CHROOT/var/log/dracut.log
