#!/bin/bash
#
# (Re)Install RPMs that failed to be installed as part of the prior
#   RPM-handling phases
#
######################################################################
CHROOT="${CHROOT:-/mnt/ec2-root}"
CONFROOT=`dirname $0`

# Install main RPM-groups
yum -c ${CONFROOT}/yum-build.conf --nogpgcheck --installroot=${CHROOT} install -y \
cups \
cups-libs \
device-mapper-persistent-data \
dracut \
dracut-kernel \
foomatic \
foomatic-db \
foomatic-db-ppds \
ghostscript \
gtk2 \
jasper-libs \
libdrm \
libjpeg-turbo \
libmng \
libpciaccess \
libtiff \
lvm2 \
m2crypto \
mesa-dri1-drivers \
mesa-dri-drivers \
mesa-dri-filesystem \
mesa-libGL \
mesa-libGLU \
phonon-backend-gstreamer \
plymouth \
poppler \
poppler-utils \
python-ldap \
qt3 \
qt-x11 \
redhat-lsb-compat \
redhat-lsb-core \
redhat-lsb-graphics \
redhat-lsb-printing 
