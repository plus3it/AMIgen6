#!/bin/bash
#
# Create storage config files within chroot
#
###########################################
AMIMTAB="/etc/mtab"
ALTROOT="/mnt/ec2-root"
ALTMTAB="${ALTROOT}/etc/mtab"
ALTBOOT="${ALTROOT}/boot"

# Check if host AMI mounts /tmp as a (pseudo)filesystem
mountpoint /tmp > /dev/null 2>&1
if [ $? -eq 0 ]
then
   TMPSUB=""
else
   TMPSUB="tmpfs /tmp tmpfs rw 0 0"
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
sed '/^	/d' > ${ALTROOT}/etc/fstab

########################################
## <CREATE grub.conf AND menu.lst FILES>
########################################

# Get the chroot's kernel and initrd
VMLINUZ=`find ${ALTBOOT} -name "vmlinuz*" | awk -F "/" '{ print $NF }'`
RAMDISK=`find ${ALTBOOT} -name "initramfs*img" | awk -F "/" '{ print $NF }'`

# Generate a grub.conf
cat << EOF > ${ALTBOOT}/grub.conf 
default=0
timeout=0
title CentOS 6.5 (MTC AMI)
	root (hd0,0)
	kernel /${VMLINUZ} ro root=/dev/mapper/VolGroup00-rootVol crashkernel=auto LANG=en_US.UTF-8 KEYTABLE=us rd_NO_DM rd_NO_MD rd_LVM_LV=VolGroup00/rootVol rd_LVM_LV=VolGroup00/swapVol
	initrd /${RAMDISK}
EOF

# Kill older versions of grub files
for FILE in ${ALTROOT}/etc/grub.conf ${ALTBOOT}/menu.lst ${ALTBOOT}/grub/grub.conf ${ALTBOOT}/grub/menu.lst
do
   if [ -f ${FILE} ] || [ -L ${FILE} ]
   then
      rm ${FILE} && echo deleted ${FILE}
   fi
done

# Refresh grub files
ln ${ALTBOOT}/grub.conf ${ALTBOOT}/grub/grub.conf
ln -s ${ALTBOOT}/grub.conf ${ALTBOOT}/menu.lst
ln -s ${ALTBOOT}/grub/grub.conf ${ALTBOOT}/grub/menu.lst
ln -s /boot/grub/grub.donf ${ALTROOT}/etc/grub.conf


# Create stub network config scripts
( echo "NETWORKING=yes"
  echo "NETWORKING_IPV6=no" 
  echo "HOSTNAME=localhost.localdomain" ) > ${ALTROOT}/etc/sysconfig/network

( echo "DEVICE=eth0"
  echo "BOOTPROTO=dhcp"
  echo "ONBOOT=on"
  echo "IPV6INIT=no" ) > ${ALTROOT}/etc/sysconfig/network-scripts/ifcfg-eth0 
