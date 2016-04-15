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

########################################
## <CREATE grub.conf AND menu.lst FILES>
########################################

# Get the chroot's kernel and initrd
VMLINUZ=`find ${ALTBOOT} -name "vmlinuz*" | awk -F "/" '{ print $NF }'`
RAMDISK=`find ${ALTBOOT} -name "initramfs*img" | awk -F "/" '{ print $NF }'`

# Generate a grub.conf
cat << EOF > ${ALTBOOT}/grub/grub.conf 
default=0
timeout=0
title ${OSTYPE} ${OSVERS} (LVM-enabled Thin AMI)
	root (hd0,0)
	kernel /${VMLINUZ} ro root=/dev/mapper/VolGroup00-rootVol xen_blkfront.sda_is_xvda=1 crashkernel=auto LANG=en_US.UTF-8 KEYTABLE=us console=ttyS0 rd_NO_DM rd_NO_MD rd_LVM_LV=VolGroup00/rootVol rd_LVM_LV=VolGroup00/swapVol
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

# Refresh grub files
chroot $CHROOT /bin/bash -c "cd /boot/grub ; ln -s grub.conf menu.lst"
chroot $CHROOT /bin/bash -c "ln -s /boot/grub/grub.conf /etc/grub.conf"


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
