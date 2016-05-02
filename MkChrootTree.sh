#!/bin/bash
#
# Setup/mount chroot'ed volumes/partitions
# * Takes the dev-path hosting the /boot and LVM partitions as argument
#
#######################################################################
CHROOTDEV=${1:-UNDEF}
BOOTDEV=${CHROOTDEV}1
LVMDEV=${CHROOTDEV}2
ALTROOT="${CHROOT:-/mnt/ec2-root}"

# Generic logging outputter - extend to increase output destinations
function err_out() {
   echo $2
   exit $1
}

# Can't do anything if we don't have an EBS to operate on
if [ ${CHROOTDEV} = "UNDEF" ]
then
   err_out 1 "Must supply name of device to use (e.g., /dev/xvdg)"
fi

if [ -d "${ALTROOT}" ]
then
   echo "Found ${ALTROOT}: proceeding..."
elif [ -e "${ALTROOT}" ] && [ ! -d "${ALTROOT}" ]
then
   err_out 1 "Found ${ALTROOT} but it's not usable as mount-point"
else
   printf "Requested chroot [${ALTROOT}] not found. Attempting to create... "
   install -d -m 0755 "${ALTROOT}" || err_out 1 "Failed to create ${ALTROOT}."
   echo "Success!"
fi

# Ensure all LVM volumes are active
vgchange -a y VolGroup00 || err_out 2 "Failed to activate LVM"

# Mount chroot base device
echo "Mounting /dev/VolGroup00/rootVol to ${ALTROOT}"
mount /dev/VolGroup00/rootVol ${ALTROOT}/ || err_out 2 "Mount Failed"

# Prep for next-level mounts
mkdir -p ${ALTROOT}/{var,opt,home,boot,etc} || err_out 3 "Mountpoint Create Failed"

# Mount the boot-root
echo "Mounting ${BOOTDEV} to ${ALTROOT}/boot"
mount ${BOOTDEV} ${ALTROOT}/boot/ || err_out 2 "Mount Failed"

# Mount first of /var hierarchy
echo "Mounting /dev/VolGroup00/varVol to ${ALTROOT}/var"
mount /dev/VolGroup00/varVol ${ALTROOT}/var/ || err_out 2 "Mount Failed"

# Prep next-level mountpoints
mkdir -p ${ALTROOT}/var/{cache,log,lock,lib/{,rpm},tmp}

# Mount log volume
echo "Mounting /dev/VolGroup00/logVol to ${ALTROOT}/var/log"
mount /dev/VolGroup00/logVol ${ALTROOT}/var/log

# Mount audit volume
mkdir ${ALTROOT}/var/log/audit
echo "Mounting /dev/VolGroup00/auditVol to ${ALTROOT}/var/log/audit"
mount /dev/VolGroup00/auditVol ${ALTROOT}/var/log/audit

# Mount the rest
echo "Mounting /dev/VolGroup00/homeVol to ${ALTROOT}/home"
mount /dev/VolGroup00/homeVol ${ALTROOT}/home/

# Prep for loopback mounts
mkdir -p ${ALTROOT}/{proc,sys,dev/{pts,shm},selinux}

# Create base dev-nodes
mknod -m 600 ${ALTROOT}/dev/console c 5 1
mknod -m 666 ${ALTROOT}/dev/null c 1 3
mknod -m 666 ${ALTROOT}/dev/zero c 1 5
mknod -m 666 ${ALTROOT}/dev/random c 1 8
mknod -m 666 ${ALTROOT}/dev/urandom c 1 9
mknod -m 666 ${ALTROOT}/dev/tty c 5 0
mknod -m 666 ${ALTROOT}/dev/ptmx c 5 2
chown root:tty ${ALTROOT}/dev/ptmx 

# Do loopback mounts
mount -o bind /proc ${ALTROOT}/proc/
mount -o bind /sys ${ALTROOT}/sys/

# This shouldn't be necessary...
if [[ ! -d ${ALTROOT}/selinux ]]
then
   mkdir ${ALTROOT}/selinux || (\
      printf "Unable to create missing ${ALTROOT}/selinux "
      printf "Bind-mount of selinux pseudo-filesystem will "
      printf "likely fail"
   ) > /dev/stderr
fi
mount -o bind /selinux ${ALTROOT}/selinux

mount -o bind /dev/pts ${ALTROOT}/dev/pts
mount -o bind /dev/shm ${ALTROOT}/dev/shm
