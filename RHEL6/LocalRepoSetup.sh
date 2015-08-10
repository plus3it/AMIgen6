#!/bin/sh
#
# Script to set up local cache-repo to support chrooted build of
# RHEL 6 AMI
#
############################################################

REPOROOT=${1:-/opt/RHrepo}
REPOPKGS=${REPOROOT}/Packages
REPODATA=${REPOROOT}/repodata
EPELREPO="epel"
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

echo "==========================================================="
echo "Attempting to download mainline Red Hat RPMs to ${REPOPKGS}"
echo "==========================================================="
yumdownloader --destdir=${REPOPKGS} `cat pkglst.rh`

if [ -s pkglst.epel ]
then
   echo "=============================================================="
   echo "Attempting to download EPEL (supplemental) RPMs to ${REPOPKGS}"
   echo "=============================================================="
   yumdownloader --destdir=${REPOPKGS} --disablerepo=* \
      --enablerepo=${EPELREPO} `cat pkglst.epel`
fi

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
