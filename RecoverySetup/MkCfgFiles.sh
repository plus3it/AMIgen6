#!/bin/bash
#
# Create storage config files within chroot
#
###########################################
AMIMTAB="/etc/mtab"
CHROOT="${CHROOT:-/mnt/ec2-root}"
ALTROOT="${CHROOT}"
ALTMTAB="${ALTROOT}/etc/mtab"
ALTBOOT="${ALTROOT}/boot"

RELCHK="/usr/bin/lsb_release"

# Check if host AMI mounts /tmp as a (pseudo)filesystem
mountpoint /tmp > /dev/null 2>&1
if [ $? -eq 0 ]
then
   TMPSUB=""
else
   TMPSUB="tmpfs /tmp tmpfs rw 0 0"
fi

if [ -x ${CHROOT}/${RELCHK} ]
then
   OSTYPE=$((chroot ${CHROOT} ${RELCHK} -i) | cut -d ":" -f 2 | \
      sed 's/^[ 	]*//')
   OSTYPE=$((chroot ${CHROOT} ${RELCHK} -r) | cut -d ":" -f 2 | \
      sed 's/^[ 	]*//')
else
   GETOSINFO=$(chroot ${CHROOT} rpm -qf /etc/redhat-release --queryformat \
      '%{vendor}:%{version}:%{release}\n' | sed 's/\.el.*$//')
   OSTYPE=$(echo ${GETOSINFO} | cut -d ":" -f 1)
   OSMVER=$(echo ${GETOSINFO} | cut -d ":" -f 2)
   OSSVER=$(echo ${GETOSINFO} | cut -d ":" -f 3)
   OSVERS="${OSMVER}.${OSSVER}"
fi

##################################
## Create chroot'ed /etc/mtab file
##################################
# Start with parent AMI's mount-tab...
(
(ALTROOT="/mnt/ec2-root" grep ${ALTROOT} /etc/mtab | \
sed -e '{
   /,bind /d
   s#'${ALTROOT}'#/#
   s#//#/#
}' | sed '{
   /boot ext4/{N
      s/$/\n<TEMPDIR>/
   }
}') | sed 's/<TEMPDIR>/'${TMPSUB}'/' 

sed -n '/^[a-z]/p' /etc/mtab | \
sed '{
   /^none/d
   s/,rootcontext.*" / /
}' ) > ${ALTMTAB}


# Create chroot fstab from chroot mtab
awk '{printf("%s\t%s\t%s\t%s\t%s %s\n",$1,$2,$3,$4,$5,$6)}' ${ALTMTAB} | \
sed '{ 
   /^	/d
   /\/boot/s/^\/dev\/[a-z0-9]*/LABEL=\/boot/
}' > ${ALTROOT}/etc/fstab
########################################
## <CREATE grub.conf AND menu.lst FILES>
########################################

# Get the chroot's kernel and initrd
VMLINUZ=`find ${ALTBOOT} -name "vmlinuz*" | awk -F "/" '{ print $NF }'`
RAMDISK=`find ${ALTBOOT} -name "initramfs*img" | awk -F "/" '{ print $NF }'`

# Generate a grub.conf
## cat << EOF > ${ALTBOOT}/grub/grub.conf 
## default=0
## timeout=0
## title ${OSTYPE} ${OSVERS} (LVM-enabled Thin AMI)
## 	root (hd0,0)
## 	kernel /${VMLINUZ} ro root=/dev/mapper/VolGroup00-rootVol xen_blkfront.sda_is_xvda=1 crashkernel=auto LANG=en_US.UTF-8 KEYTABLE=us console=ttyS0 rd_NO_DM rd_NO_MD rd_LVM_LV=VolGroup00/rootVol rd_LVM_LV=VolGroup00/swapVol
## 	initrd /${RAMDISK}
## EOF
cat << EOF > ${ALTBOOT}/grub/grub.conf 
default=0
timeout=0
title ${OSTYPE} ${OSVERS} (Recovery AMI)
	root (hd0,0)
	kernel /${VMLINUZ} ro root=LABEL=root_disk xen_blkfront.sda_is_xvda=1 crashkernel=auto LANG=en_US.UTF-8 KEYTABLE=us console=ttyS0
	initrd /${RAMDISK}
EOF

# Kill older versions of grub files
for FILE in ${ALTROOT}/etc/grub.conf ${ALTBOOT}/menu.lst ${ALTBOOT}/grub/menu.lst
do
   if [ -f ${FILE} ] || [ -L ${FILE} ]
   then
      rm ${FILE} && echo deleted ${FILE}
   fi
done

#############################################
## THIS SECTION BROKEN. NEED BETTER METHOD ##
#############################################
# Refresh grub files
(cd ${ALTBOOT}/grub ; ln -s grub.conf menu.lst )
ln -s /boot/grub/grub.conf ${ALTROOT}/etc/grub.conf
#############################################


# Create stub network config scripts
( echo "NETWORKING=yes"
  echo "NETWORKING_IPV6=no" 
  echo "HOSTNAME=localhost.localdomain" ) > ${ALTROOT}/etc/sysconfig/network

( echo "DEVICE=eth0"
  echo "BOOTPROTO=dhcp"
  echo "ONBOOT=on"
  echo "IPV6INIT=no" ) > ${ALTROOT}/etc/sysconfig/network-scripts/ifcfg-eth0 

# Make ssh relax about root logins
( echo "UseDNS no"
  echo "PermitRootLogin without-password" ) >> ${ALTROOT}/etc/ssh/sshd_config

# Ensure that SELinux contexts are up to date and mode dialed-back
touch ${ALTROOT}/.autorelabel
sed -i '/^SELINUX=/s/=.*/=permissive/' ${ALTROOT}/etc/selinux/config
