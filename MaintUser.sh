#!/bin/bash
#
# Script to create and provide privileges to a local maintenance account
#
########################################################################
PATH=/sbin:/usr/sbin:/bin:/usr/bin
CHROOT=${CHROOT:-/mnt/ec2-root}
USERNAME=${1:-awsmaint}
PASSWORD=${2:-UNDEF}
SUDOERF=/etc/sudoers.d/${USERNAME}

# Informational messages
function info_out() {
   echo $2
}

# Error handler
function err_out() {
   info_out error "$2"
   exit $1
}

if [ ${PASSWORD} = "UNDEF" ]
then
   err_out 1 "No password supplied. Aborting"
fi

# MD5 hash the password
CRYPTSTR=`openssl passwd -1 ${PASSWORD}`

# Create the user (in AMI)
chroot ${CHROOT} useradd -G wheel -m -c "Maintenance User" -p "${CRYPTSTR}" "${USERNAME}" || err_out 1 "Failed to create user"

# Create sudo rule
printf "%%wheel\tALL=(root)\tALL\n" > ${CHROOT}/etc/sudoers.d/usr_${USERNAME} || err_out 1 "Failed to create sudoers entry."
