#!/bin/bash
#
# Install minimal RPM-set into chroot
#
#####################################
CHROOT=${CHROOT:-/mnt/ec2-root}"
CONFROOT=`dirname $0`

# Install main RPM-groups
yum -c ${CONFROOT}/yum-build.conf --installroot=${CHROOT} -y groupinstall Base \
Core Core

# Install additional individual RPMs (dependencies pulled in automagically
yum -c ${CONFROOT}/yum-build.conf --installroot=${CHROOT} -y install kernel \
acpid \
aide \
audit \
dhclient \
e2fsprogs \
grub \
lsb \
lvm2 \
man \
ntp \
ntpdate \
openssh-clients \
openssh-server \
perl \
rng-tools \
rsync \
rsyslog \
selinux-policy \
selinux-policy-targeted \
sudo \
telnet \
unzip \
vim-enhanced \
wget \
which \
yum-cron \
yum-utils 


# Remove unwanted RPMs installed by the RPM groups
yum -c ${CONFROOT}/yum-build.conf --installroot=${CHROOT} -y erase \
abrt \
abrt-addon-ccpp \
abrt-addon-kerneloops \
abrt-addon-python \
abrt-cli \
abrt-libs \
gcc-gfortran \
libvirt-client \
libvirt-devel \
libvirt-java \
libvirt-java-devel \
nc \
sendmail
