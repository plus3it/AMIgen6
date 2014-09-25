#!/bin/bash
#
# Do some file cleanup...
#
#########################
CHROOT=/mnt/ec2-root

# Get rid of stale RPM data
yum -c /opt/ec2/yum/yum-xen.conf --installroot=${CHROOT}/ -y clean packages
rm -rf ${CHROOT}/var/cache/yum
rm -rf ${CHROOT}/var/lib/yum

# Nuke any history data
cat /dev/null > ${CHROOT}/root/.bash_history
