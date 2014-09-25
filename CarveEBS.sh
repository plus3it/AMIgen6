#!/bin/bash
#
# Configure attached EBS into target partitioning-state
#
#######################################################

# INSERT LOGIC TO DYNAMICALLY DETERMINE EBS via AWS handles
# Either via curl http://169.254.169.254/latest/meta-data/
# or /opt/ec2/tools/bin commands

parted -s /dev/xvdl -- mklabel msdos mkpart primary ext4 2048s 500m mkpart primary ext4 500m 100%s set 2 lvm on
vgcreate VolGroup00 /dev/xvdl2
lvcreate -L 512M -n auditVol VolGroup00
lvcreate -L 512M -n optVol VolGroup00
lvcreate -L 2g -n rootVol VolGroup00
lvcreate -L 512M -n varVol VolGroup00
lvcreate -L 256M -n homeVol VolGroup00
lvcreate -L 2g -n swapVol VolGroup00
lvchange -a n VolGroup00/swapVol
for VOL in /dev/VolGroup00/*; do mkfs.ext4 ${VOL}; done
mkfs.ext4 -L /boot /dev/xvdl1
