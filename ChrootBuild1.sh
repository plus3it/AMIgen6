#!/bin/bash
#
# Install minimal RPM-set into chroot
#
#####################################
CHROOT="${CHROOT:-/mnt/ec2-root}"
CONFROOT=`dirname $0`
REPODIS="--disablerepo=base --disablerepo=extras --disablerepo=updates"

# Install main RPM-groups
yum -c ${CONFROOT}/yum-build.conf --nogpgcheck ${REPODIS} --installroot=${CHROOT} install -y @Core -- \
cloud-init \
kernel \
lvm2 \
man \
ntp \
ntpdate \
openssh-clients \
selinux-policy \
wget \
yum-cron \
yum-utils \
-abrt \
-abrt-addon-ccpp \
-abrt-addon-kerneloops \
-abrt-addon-python \
-abrt-cli \
-abrt-libs \
-gcc-gfortran \
-libvirt-client \
-libvirt-devel \
-libvirt-java \
-libvirt-java-devel \
-nc \
-sendmail 
