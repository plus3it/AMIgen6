#!/bin/bash
#
# Add back RPMs that were removed by dependency-tracking in prior step
#
###########################################################################
CHROOT="${CHROOT:-/mnt/ec2-root}"
CONFROOT=`dirname $0`
DATE=`/bin/date "+%Y%m%d-%H%M%S"`
ADDLST="${CONFROOT}/install.lst"
YUMINVOKE="yum -c ${CONFROOT}/yum-build.conf --nogpgcheck --installroot=${CHROOT}"
YUMLOG="/var/tmp/install3_log.${DATE}"

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

# Iterate install list and add one at a time 
for RPMCHK in `cat ${ADDLST}`
do
   (chroot $CHROOT rpm -q ${RPMCHK}) > /dev/null 2>&1
   if [ $? -eq 0 ]
   then
      logit "0" "Package ${RPMCHK} already installed. Skipping"
   else
      logit "0" "Attempting to install package ${RPMCHK}."
      ${YUMINVOKE} -q -y install ${RPMCHK} 2>&1 | \
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
