#!/bin/bash
#
# Setup/mount chroot'ed volumes/partitions
#
##########################################
CHROOTDEV=${1:-UNDEF}
BOOTDEV=${CHROOTDEV}1
LVMDEV=${CHROOTDEV}2

if [ ${CHROOTDEV} = "UNDEF" ]
then
   echo "Must supply name of device to use"
   exit 1
fi

# Ensure all LVM volumes are active
vgchange -a y VolGroup00

# Mount chroot base device
mount /dev/VolGroup00/rootVol /mnt/ec2-root/

# Prep for next-level mounts
mkdir /mnt/ec2-root/{var,opt,home,boot}

# Mount the boot-root
mount /dev/xvdl1 /mnt/ec2-root/boot/

# Mount first of /var hierarchy
mount /dev/VolGroup00/varVol /mnt/ec2-root/var/

# Prep next-level mountpoints
mkdir -p /opt/ec2-root/var/{cache,log/{,audit},lock,lib/rpm}

# Mount audit volume
mount /dev/VolGroup00/auditVol /mnt/ec2-root/var/log/audit

# Mount the rest
mount /dev/VolGroup00/optVol /mnt/ec2-root/opt/
mount /dev/VolGroup00/homeVol /mnt/ec2-root/home/

# Prep for loopback mounts
mkdir -p /mnt/ec2-root/{proc,sys,dev/{pts,shm}}

# Create base dev-nodes
mknod -m 600 /mnt/ec2-root/dev/console c 5 1
mknod -m 666 /mnt/ec2-root/dev/null c 1 3
mknod -m 666 /mnt/ec2-root/dev/zero c 1 5
mknod -m 666 /mnt/ec2-root/dev/random c 1 8
mknod -m 666 /mnt/ec2-root/dev/urandom c 1 9
mknod -m 666 /mnt/ec2-root/dev/tty c 5 0
mknod -m 666 /mnt/ec2-root/dev/ptmx c 5 2
chown root:tty /mnt/ec2-root/dev/ptmx 

# Do loopback mounts
mount -o bind /proc /mnt/ec2-root/proc/
mount -o bind /sys /mnt/ec2-root/sys/
mount -o bind /dev/pts /mnt/ec2-root/dev/pts
mount -o bind /dev/shm /mnt/ec2-root/dev/shm
