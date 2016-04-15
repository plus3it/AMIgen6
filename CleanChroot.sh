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
CLINITUSR=$(grep -E "name: (maintuser|centos|ec2-user|cloud-user)" \
            ${CLOUDCFG} | awk '{print $2}')

if [ "${CLINITUSR}" = "" ]
then
   echo "Cannot reset value of cloud-init default-user" > /dev/stderr
else
   echo "Setting default cloud-init user to ${MAINTUSR}"
   sed -i '{
      /default_user:/,/distro:/d
   }' ${CLOUDCFG}
   sed -i '{
      /^system_info:/{N
         s/\n/&  default_user:\n    name: maintuser\n    lock_passwd: true\n    gegos: Maintenance User\n    groups: \[wheel, adm\]\n    sudo: \["ALL=(root) NOPASSWD:ALL"\]\n    shell: \/bin\/bash\n  distro: rhel\n/
      }
   }'  ${CLOUDCFG}
fi

