#!/bin/bash
#
# Install minimal RPM-set into chroot
#
#####################################

yum -c /opt/ec2/yum/yum-xen.conf --installroot=/mnt/ec2-root/ -y groupinstall core server-policy workstation-policy
yum -c /opt/ec2/yum/yum-xen.conf --installroot=/mnt/ec2-root/ -y install kernel grub e2fsprogs lvm2 wget openssh-clients openssh-server dhclient selinux-policy selinux-policy-targeted vi
