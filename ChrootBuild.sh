#!/bin/bash
#
# Install minimal RPM-set into chroot
#
#####################################
PROGNAME=$(basename "$0")
CHROOT="${CHROOT:-/mnt/ec2-root}"
CONFROOT=$(dirname $0)
REPORFILEPMS=($(rpm --qf '%{name}\n' -qf /etc/yum.repos.d/* 2>&1 | \
               grep -v "not owned" | sort -u))

function PrepChroot() {
   local DISABLEREPOS="*media*,*epel*,C*-*"

   if [[ ! -e ${CHROOT}/etc/init.d ]]
   then
      ln -t ${CHROOT}/etc -s rc.d/init.d
   fi

   yumdownloader --destdir=/tmp $(rpm --qf '%{name}\n' -qf /etc/redhat-release)
   yumdownloader --destdir=/tmp "${REPORFILEPMS[@]}"
   rpm --root ${CHROOT} --initdb
   rpm --root ${CHROOT} -ivh --nodeps /tmp/*.rpm
   yum --enablerepo=* --disablerepo=${DISABLEREPOS} --installroot=${CHROOT} \
      -y reinstall "${REPORFILEPMS[@]}"

   # if alt-repo defined, disable everything, then install alt-repo
   if [[ ! -z ${REPORPM+xxx} ]]
   then
      for FILE in ${CHROOT}/etc/yum.repos.d/*.repo
      do
         sed -i '{
	    /^\[/{N
	       s/\n/&enabled=0\n/
            }
	    /^enabled=1/d
         }' "${FILE}"
      done
      rpm --root ${CHROOT} -ivh --nodeps "${REPORPM}"
   fi
}


######################
## Main program flow
######################

# See if we'e passed any valid flags
OPTIONBUFR=$(getopt -o r:b:e: --long repouri:bonusrepos:extras: -n ${PROGNAME} -- "$@")
eval set -- "${OPTIONBUFR}"

while [[ true ]]
do
   case "$1" in
      -r|--repouri)
         case "$2" in
	    "")
	       echo "Error: option required but not specified" > /dev/stderr
	       shift 2;
	       exit 1
	       ;;
	    *)
	       REPORPM=${2}
	       shift 2;
	       ;;
	 esac
	 ;;
      -b|--bonusrepos)
         case "$2" in
	    "")
	       echo "Error: option required but not specified" > /dev/stderr
	       shift 2;
	       exit 1
	       ;;
	    *)
	       BONUSREPO=${2}
	       shift 2;
	       ;;
	 esac
	 ;;
      -e|--extras)
         case "$2" in
            "")
               echo "Error: option required but not specified" > /dev/stderr
               shift 2;
               exit 1
               ;;
            *)
               EXTRARPMS=($(echo ${2} | sed 's/,/ /g'))
               shift 2;
               ;;
         esac
         ;;
      --)
         shift
	 break
	 ;;
      *)
         echo "Internal error!" > /dev/stderr
	 exit 1
	 ;;
   esac
done

# Stage useable repo-defs into $CHROOT/etc/yum.repos.d
PrepChroot

if [[ ! -z ${BONUSREPO+xxx} ]]
then
   ENABREPO="--enablerepo=${BONUSREPO}"
   YUMCMD="yum --nogpgcheck --installroot=${CHROOT} ${ENABREPO} install -y" 
else
   YUMCMD="yum --nogpgcheck --installroot=${CHROOT} install -y" 
fi

# Install main RPM-groups
${YUMCMD} @Core -- \
"${REPORFILEPMS[@]}" \
authconfig \
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

# Install additionally-requested RPMs
if [[ ! -z ${EXTRARPMS+xxx} ]]
then
   printf "##########\n## Installing requested RPMs/groups\n##########\n"
   ${YUMCMD} "${EXTRARPMS[@]}"
else
   echo "No 'extra' RPMs requested"
fi
