#!/bin/bash
#
# Install minimal RPM-set into chroot
#
#####################################
CONFROOT=`dirname $0`

yum -c ${CONFROOT}/yum-build.conf --installroot=${CHROOT} -y groupinstall core \
server-policy workstation-policy
yum -c ${CONFROOT}/yum-build.conf --installroot=${CHROOT} -y install kernel \
grub e2fsprogs lvm2 wget openssh-clients openssh-server dhclient \
selinux-policy selinux-policy-targeted vim-enhanced
