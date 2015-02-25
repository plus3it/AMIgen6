#!/bin/bash
#
# Dismount and deactivate the chroot EBS
#
########################################
CHROOT=${CHROOT:-/mnt/ec2-root}
RESULT=0

sync ; sync ;sync

for MOUNT in `mount | awk '/mnt\/ec2-root/{ print $3}' | sed '1!G;h;$!d'`
do
   printf "Attempting to umount ${MOUNT}... "
   umount ${MOUNT}
   if [ $? -eq 0 ]
   then
      echo "success!"
   else
      echo "FAILED!"
      RESULT=1
   fi
done

# Deactivate the chroot VG
vgchange -a n VolGroup00

if [ ${RESULT} -eq 0 ]
then
   echo "Now prepped for EBS snapshot"
else
   echo "Some prep steps failed. Manually ensur that:"
   echo "* All chroot-mounts offlined"
   echo "* All LVM objects deconfigured"
fi
