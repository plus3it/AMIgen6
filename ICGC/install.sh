#!/bin/sh

##########################################
CURRENT_DIR=`/usr/bin/dirname $0`
RPM=/bin/rpm
CURDATE=`date +%Y%m%d-%H%M%S`
INSTLOG=$CURRENT_DIR/install_log.$CURDATE
OSVERSION=`/bin/awk '{print $3}' /etc/centos-release`
VERSION=1.0
##########################################
log_msg() {
   echo $1 2>&1 | tee -a $INSTLOG
}

log_msg  " "
log_msg "Installing post core packages on `/bin/date`"
log_msg " "

$RPM -qa | sort > $CURRENT_DIR/pre.txt

# $RPM -ivh $CURRENT_DIR/*.rpm 2>&1 | tee -a $INSTLOG
yum install -y `cat to_be_installed.lst`

$RPM -qa | sort > $CURRENT_DIR/post.txt

log_msg " "
log_msg "Post install routine complete on `/bin/date`"
log_msg " "

echo "$CURDATE | $OSVERSION | $VERSION | Completed install of primary RPMs for core stage 2 of 2" >> /etc/.icgc-cm.log
