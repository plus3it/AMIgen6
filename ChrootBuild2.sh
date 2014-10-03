#!/bin/bash
#
# Strip out unwanted RPMs that were installed in prior installation-phase
#
###########################################################################
CHROOT="${CHROOT:-/mnt/ec2-root}"
CONFROOT=`dirname $0`
DATE=`/bin/date "+%Y%m%d-%H%M%S"`
RMVLST="${CONFROOT}/remove.lst"
YUMINVOKE="yum -c ${CONFROOT}/yum-build.conf --disablerepo=* --nogpgcheck --installroot=${CHROOT}"
YUMLOG="/var/tmp/install2_log.${DATE}"

logit() {
   if [ $1 -ne 0 ]
   then
      printf -- "----------\nNote:%s\n----------\n" "$2" | tee -a ${YUMLOG}
   else
      echo "$2" | tee -a ${YUMLOG}
   fi
}

# Grab our current RPM-manifest
(chroot ${CHROOT} rpm -qa) > ${YUMLOG}.start
RPMCNT=`wc -l ${YUMLOG}.start | cut -d " " -f 1`

logit 0 "Started with ${RPMCNT} RPMs"

# Iterate removal list and remove one at a time 
for RPMCHK in `cat ${RMVLST}`
do
   ${YUMINVOKE} list -q -y installed ${RPMCHK} > /dev/null 2>&1
   if [ $? -ne 0 ]
   then
      logit "1" "Package ${RPMCHK} not installed. Skipping removal attempt."
   else
      logit "0" "Attempting to remove ${RPMCHK}"
      ${YUMINVOKE} -q -y erase ${RPMCHK} 2>&1 | \
         sed '{
            /listed more than once/d
            /transaction-done/d
         }' | tee -a ${YUMLOG}
   fi
done

# Grab our final RPM-manifest
(chroot ${CHROOT} rpm -qa) > ${YUMLOG}.end
RPMCNT=`wc -l ${YUMLOG}.end | cut -d " " -f 1`

logit 0 "Finished with ${RPMCNT} RPMs"
