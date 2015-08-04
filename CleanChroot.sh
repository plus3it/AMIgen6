#!/bin/bash
#
# Do some file cleanup...
#
#########################
CHROOT=${CHROOT:-/mnt/ec2-root}
CONFROOT=`dirname $0`
CLOUDCFG="$CHROOT/etc/cloud/cloud.cfg"
MAINTUSR="maintuser"

# Get rid of stale RPM data
chroot ${CHROOT} yum clean -y packages
chroot ${CHROOT} rm -rf /var/cache/yum
chroot ${CHROOT} rm -rf /var/lib/yum

# Nuke any history data
cat /dev/null > ${CHROOT}/root/.bash_history

# Set TZ to UTC
rm ${CHROOT}/etc/localtime
cp ${CHROOT}/usr/share/zoneinfo/UTC ${CHROOT}/etc/localtime

# Create maintuser
CLINITUSR=$(grep -E "name: (centos|ec2-user|cloud-user)" ${CLOUDCFG} |
   awk '{print $2}')

if [ "${CLINITUSR}" = "" ]
then
   echo "Cannot reset value of cloud-init default-user" > /dev/stderr
else
   echo "Resetting default cloud-init user to ${MAINTUSR}"
   sed -i '{
      s/name: '${CLINITUSR}'/name: '${MAINTUSR}'/
      /gecos:.*$/s/:.*/: Maintenance User/
   }' ${CLOUDCFG}
fi

HASSUDO=$(grep -qw "sudo:" ${CLOUDCFG})$?
if [[ ${HASSUDO} -eq 0 ]]
then
   echo "A sudoers line has already been defined within ${CLOUDCFG}"
else
   echo "A sudoers line has already been defined within ${CLOUDCFG}"
   sed -i "/    name: ${MAINTUSR}/a\\      sudo: \[ 'ALL=(root) NOPASSWD:ALL' \]"
fi   
