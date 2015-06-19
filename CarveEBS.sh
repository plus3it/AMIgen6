#!/bin/bash
#
# Configure attached EBS into target partitioning-state
#
#   Need to see if can automagically determine which disk to use via
#   Fetchable attributes @  http://169.254.169.254/latest/meta-data/
#   or via /opt/ec2/tools/bin commands. Until then, specify as argv.
#
####################################################################
TARGET=${1:-UNDEF}
ROOTVOL=${ROOTVOL:-rootVol}
SWAPVOL=${SWAPVOL:-swapVol}
VARVOL=${VARVOL:-varVol}
LOGVOL=${LOGVOL:-logVol}
AUDVOL=${AUDVOL:-auditVol}
HOMEVOL=${HOMEVOL:-homeVol}
ROOTVOLSZ=${ROOTVOLSZ:-4g}
SWAPVOLSZ=${SWAPVOLSZ:-2g}
VARVOLSZ=${VARVOLSZ:-2g}
LOGVOLSZ=${LOGVOLSZ:-2g}
AUDVOLSZ=${AUDVOLSZ:-100%FREE}
HOMEVOLSZ=${HOMEVOLSZ:-1g}

function err_out() {
   echo $2
   exit $1
}

if [ ${TARGET} = "UNDEF" ]
then
   err_out 1 "Failed to supply a target for setup. Aborting!"
elif [ ! -b ${TARGET} ]
then
   err_out 2 "Device supplied not valid. Aborting!"
else
   BASEDEV=`basename ${TARGET}`
   stat -t -c "%n" /sys/block/`basename ${TARGET}` > /dev/null 2>&1 || \
      err_out 3 "Need the *base* devnode. Aborting!"
fi

# Clear the MBR and partition table
dd if=/dev/zero of=${TARGET} bs=512 count=1

# Oh, parted, how I hate that you require me to do it all at once...
parted -s ${TARGET} -- mklabel msdos mkpart primary ext4 2048s 500m \
mkpart primary ext4 500m 100%s set 2 lvm on

# Let's make sure that actually worked...
if [ $? -ne 0 ]
then
   err_out 4 "Error during partitioning. Aborting!"
fi

# Set up LVM objects
#   Note: we'll change this to formula based, later, to accommodate
#         arbitrary EBS geometries
vgcreate VolGroup00 ${TARGET}2 || err_out 5 "VG creation failed. Aborting!"
lvcreate -L ${ROOTVOLSZ} -n ${ROOTVOL} VolGroup00 || LVCSTAT=1
lvcreate -L ${SWAPVOLSZ} -n ${SWAPVOL} VolGroup00 || LVCSTAT=1
lvcreate -L ${HOMEVOLSZ} -n ${HOMEVOL} VolGroup00 || LVCSTAT=1
lvcreate -L ${VARVOLSZ} -n ${VARVOL} VolGroup00 || LVCSTAT=1
lvcreate -L ${LOGVOLSZ} -n ${LOGVOL} VolGroup00 || LVCSTAT=1
lvcreate -l ${AUDVOLSZ} -n ${AUDVOL} VolGroup00 || LVCSTAT=1

if [ "${LVCSTAT}" = "1" ]
then
   echo "WARNING: one or more volume creations failed."
fi   

# TEMPORARILY turn off the swapVol volume
lvchange -a n VolGroup00/swapVol

# Iterate the volgroup for active volumes to format
for VOL in /dev/VolGroup00/*
do
   mkfs.ext4 -q ${VOL} && echo "Formatted ${VOL} with ext4"
done

# Format (and label) boot partition
mkfs.ext4 -q -L /boot ${TARGET}1 && echo "Formatted ${TARGET}1 with ext4"

# Retun swapVol to service
lvchange -a y VolGroup00/swapVol

# Format for use as swap
mkswap -f /dev/VolGroup00/swapVol
