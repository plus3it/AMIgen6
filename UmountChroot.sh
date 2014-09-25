#!/bin/bash
#
# Dismount and deactivate the chroot EBS
#
########################################
CHROOT=/mnt/ec2-root

sync ; sync ;sync

# Kill loopbacks
umount ${CHROOT}/sys
umount ${CHROOT}/dev/shm
umount ${CHROOT}/dev/pts
umount ${CHROOT}/proc

# Kill the rest of the chroot
umount ${CHROOT}/home/
umount ${CHROOT}/opt/
umount ${CHROOT}/var/log/audit/
umount ${CHROOT}/var
umount ${CHROOT}/boot
umount ${CHROOT}/

# Deactivate the chroot VG
vgchange -a n VolGroup00

echo "Now prepped for EBS snapshot"
