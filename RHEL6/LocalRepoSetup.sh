#!/bin/sh
#
# Script to set up local cache-repo to support chrooted build of
# RHEL 6 AMI
#
############################################################

REPOROOT=${1:-/opt/RHrepo}
REPOPKGS=${REPOROOT}/Packages
REPODATA=${REPOROOT}/repodata
LAUNCHFROM=$(dirname $(readlink -f ${0}))
EPELREPO="epel"
EPELURL="https://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
REPONAME=${2:-build-cache}
YUMDIR="/etc/yum.repos.d"

# Create ${REPOPKGS} if needed
if [ ! -d ${REPOPKGS} ]
then
   # More reliable than relying on umask setting
   install -d -m 0755 -o root -g root ${REPOPKGS}
   if [ $? -ne 0 ]
   then
      echo "Failed to create ${REPOPKGS}. Aborting..." > /dev/stderr
      exit 1
   fi
fi

# Make sure createrepo and yum-utils RPMs are installed
for RPMCHK in createrepo yum-utils
do
   rpm -q --quiet ${RPMCHK}
   if [[ $? -gt 0 ]]
   then
      echo "Attempting to install ${RPMCHK} RPM"
      yum install -q -y ${RPMCHK}
      if [[ $? -gt 0 ]]
      then
         printf "Install of ${RPMCHK} failed. " > /dev/stderr
         printf "Cache-repo creation not possible!\n" > /dev/stderr
         exit 1
      else
         echo "${RPMCHK} now installed"
      fi
   fi
done

# Make sure EPEL is defined
if [[ $(yum repolist all | grep -qE "^${EPELREPO} ")$? -ne 0 ]]
then
   printf "No ${EPELREPO} repository defined: try to configure? [y/n] "
   read ANSWER
   case ${ANSWER} in
      y|Y|yes|YES|Yes)
         yum install -q -y ${EPELURL}
         if [[ $? -eq 0 ]]
         then
            echo "Installed. Continuing"
         else
            echo "Failed. Aborting..." > /dev/stderr
            exit 1
         fi
         ;;
      n|N|no|NO|No)
         echo "Skipping EPEL setup"
         ;;
      *)
         echo "Aborting..." > /dev/stderr
         exit 1
         ;;
   esac
fi

# Check if Red Hat package list exists - create as necessary
if [ ! -s ${LAUNCHFROM}/pkglst.rh ]
then
   for PKGFILE in Packages-Core.md Packages-MinExtra.md
   do
      cat ${LAUNCHFROM}/../${PKGFILE}
   done | sed -n '{
             /[CD])$/p
             /[CD]):/p
          }' | awk '{print $2}' > ${LAUNCHFROM}/pkglst.rh
fi

# Check if EPEL package list exists - create as necessary
if [ ! -s ${LAUNCHFROM}/pkglst.epel ]
then
   sed -n '{
      /[CD])$/p
      /[CD]):/p
   }' ${LAUNCHFROM}/../Packages-CloudInit.md | \
   awk '{print $2}' > ${LAUNCHFROM}/pkglst.epel
   echo "No EPEL package-list defined"
fi

# Cache RPMs listed in pkglist files ...plus AWS RH RPM
yumdownloader --resolve --destdir=${REPOPKGS} \
  $(rpm -qa *rhui* --qf '%{name}\n') \
  $(rpm -qf /etc/redhat-release --qf '%{name}\n') \
  $(rpm -qf /etc/yum.repos.d/* --qf '%{name}\n' | grep -v cache | sort -u) \
  $(< ${LAUNCHFROM}/pkglst.rh) $(< ${LAUNCHFROM}/pkglst.epel) \
  yum-rhn-plugin rhn-setup rhn-client-tools rhnlib python-simplejson \
  libxml2-python dbus-python rhnsd python-dmidecode python-gudev \
  python-ethtool usermode m2crypto pyOpenSSL rhn-check libgudev1 pygobject2 \
  libnl


echo "Creating repo data-structures in ${REPODATA}"
createrepo -vvv ${REPOROOT}

if [ -s ${REPODATA}/repomd.xml ]
then
   echo "Repo-creation in ${REPOROOT} succeeded."
else
   echo "Repo-creation in ${REPOROOT} failed!" > /dev/stderr
   exit 1
fi

# Create repo definition in ${YUMDIR}
cat > ${YUMDIR}/${REPONAME}.repo <<EOF
[${REPONAME}]
name=Local Build-cache for AMI Chroot Install
baseurl=file://${REPOROOT}
enabled=0
gpgcheck=0
skip_if_unavailable=1
EOF
