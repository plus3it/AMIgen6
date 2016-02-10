#!/bin/sh
#
# Script to rename the current root volume-group to a specified
# value.
#
#################################################################
NEWSUFX="${1}"
ROOTDEV=$(grep -w / /proc/mounts | grep -v ^rootfs | cut -d" " -f 1)

# Function to handle rename-task
RenameVG() {
   if [ "${1}" = "" ]
   then
      DEFIF=$(ip route show | awk '/^default/{print $5}')
      SUFFIX=$(printf '%02X' \
         $(ip addr show ${DEFIF} | \
           awk '/inet /{print $2}' | \
           sed -e 's#/.*$##' -e 's/\./ /g' \
           ))
   else
      SUFFIX="${1}"
   fi

   vgrename -v ${ROOTVG} ${ROOTVG}_${SUFFIX}
   sed -i 's/'${ROOTVG}'/&_'${SUFFIX}'/' /etc/fstab
   sed -i 's/'${ROOTVG}'/&_'${SUFFIX}'/g' /boot/grub/grub.conf

   for KRNL in $(awk '/initrd/{print $2}' /boot/grub/grub.conf | \
                 sed -e 's/^.*initramfs-//' -e 's/\.img$//')
   do
      mkinitrd -f -v /boot/initramfs-${KRNL}.img ${KRNL}
   done

   init 6
}

# See if root-dev is a device-mapper blockdev
if [[ $(echo ${ROOTDEV} | grep mapper) ]]
then
   DEMAPPED=$(basename $(echo ${ROOTDEV}))
else
   echo "Root device is a bare-device. Nothing to do."
   exit
fi

# Convert mapper-dev to array
TOKARRAY=($(IFS='-'; for TOK in ${DEMAPPED} ; do printf "%s\n" $TOK; done))

# Reverse-iterate array to find root volume-group
for (( idx=${#TOKARRAY[@]}-1 ; idx>=0 ; idx-- )) ; do
   if [[ ${#TOKARRAY[@]}-1 -ne idx ]]
   then
      if [[ $(vgs --noheadings -o vg_name "${TOKARRAY[idx]}"
               > /dev/null 2>&1 )$? -eq 0 ]]
      then
         ROOTVG="${TOKARRAY[idx]}"
         break
      else
         ROOTVG=""
      fi
   fi
done

if [[ "${ROOTVG}" = "" ]]
then
   echo "Could not find volume-group for '/'. Exiting..."
   exit 1
else
   echo "Renaming root volume-group ['$ROOTVG']..."
   RenameVG "${NEWSUFX}"
fi
