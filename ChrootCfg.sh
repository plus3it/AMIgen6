#!/bin/bash
#
# Configure components within the chroot
#
#####################################
CHROOT="${CHROOT:-/mnt/ec2-root}"
TARGDEV="${1:-UNDEF}"

# Dismount current /dev/* mountss
umount ${CHROOT}/dev/pts
umount ${CHROOT}/dev/shm
   
# Reconstruct chroot()'s dev-tree to be GRUB compatible
mount -o bind /dev ${CHROOT}/dev
mount -o bind /dev/pts ${CHROOT}/dev/pts
mount -o bind /dev/shm ${CHROOT}/dev/shm
mount -o bind /tmp ${CHROOT}/dev/shm
   
# Ensure `ntpd` service is enabled 
chroot ${CHROOT} /bin/sh -c "/sbin/chkconfig ntpd on ; \
   /sbin/chkconfig --list ntpd"

# Ensure that SELinux policy files are installed
chroot ${CHROOT} /bin/sh -c "(rpm -q --scripts selinux-policy-targeted | \
   sed -e '1,/^postinstall scriptlet/d' | \
   sed -e '1i #!/bin/sh') > /tmp/selinuxconfig.sh ; \
   sh /tmp/selinuxconfig.sh 1"
   
# Return chroot()'s dev-tree to PVM state
umount ${CHROOT}/tmp
umount ${CHROOT}/dev/pts
umount ${CHROOT}/dev/shm
umount ${CHROOT}/dev
   
mount -o bind /dev/pts ${CHROOT}/dev/pts
mount -o bind /dev/shm ${CHROOT}/dev/shm
