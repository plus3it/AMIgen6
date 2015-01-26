#!/bin/bash
#
# Install minimal RPM-set into chroot
#
#####################################
CHROOT="${CHROOT:-/mnt/ec2-root}"
TARGDEV="${1:-UNDEF}"

err_out() {
   echo "${2}" >&2
   exit ${1}
}

if [ "${TARGET}" = "UNDEF" ]
then
   err_out 1 "Failed to supply a target for setup. Aborting!"
elif [ ! -b "${TARGET}" ]
then
   err_out 2 "Device supplied not valid. Aborting!"
else

   # Dismount current /dev/* mountss
   umount ${CHROOT}/dev/pts
   umount ${CHROOT}/dev/shm
   
   # Reconstruct chroot()'s dev-tree to be GRUB compatible
   mount -o bind /dev ${CHROOT}/dev
   mount -o bind /dev/pts ${CHROOT}/dev/pts
   mount -o bind /dev/shm ${CHROOT}/dev/shm
   
   # Copy GRUB support files
   (cd ${CHROOT}/usr/share/grub/x86_64-redhat/ ; tar cvf - . ) | (cd ${CHROOT}/boot/grub ; tar xf -)
   
   # Install GRUB to EBS's MBR
cat <<EOF | chroot ${CHROOT} grub --batch
device (hd0) ${TARGDEV}
root (hd0,0)
setup (hd0)
quit
EOF
   
   # Return chroot()'s dev-tree to PVM state
   umount ${CHROOT}/dev/pts
   umount ${CHROOT}/dev/shm
   umount ${CHROOT}/dev
   
   mount -o bind /dev/pts ${CHROOT}/dev/pts
   mount -o bind /dev/shm ${CHROOT}/dev/shm
fi
