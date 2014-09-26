#!/bin/bash
#
# Do some file cleanup...
#
#########################
CHROOT=${CHROOT:/mnt/ec2}

# Get rid of stale RPM data
yum -c /opt/ec2/yum/yum-xen.conf --installroot=${CHROOT}/ -y clean packages
rm -rf ${CHROOT}/var/cache/yum
rm -rf ${CHROOT}/var/lib/yum

# Nuke any history data
cat /dev/null > ${CHROOT}/root/.bash_history

# Create AWS instance SSH key-grabber
cp ec2-get-ssh.txt ${CHROOT}/etc/init.d/ec2-get-ssh 

# Make it executable
chmod 755 ${CHROOT}/etc/init.d/ec2-get-ssh 

# Activate the 'service'
/usr/sbin/chroot ${CHROOT} /sbin/chkconfig ec2-get-ssh on
