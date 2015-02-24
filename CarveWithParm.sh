#!/bin/sh
#
######################################################################
PROGNAME=`basename ${0}`

OPTIONBUFR=`getopt -o v: --long volspec: -n ${PROGNAME} -- "$@"`
# Note the quotes around '$OPTIONBUFR': they are essential!
eval set -- "$OPTIONBUFR"

# Pre-load a "default" partition table
VOLSPECARRAY[0]="rootVol:4g:/"
VOLSPECARRAY[1]="swapVol:2g:SWAP"
VOLSPECARRAY[2]="homeVol:1g:/home"
VOLSPECARRAY[3]="varVol:2g:/var"
VOLSPECARRAY[4]="logVol:2g:/var/log"
VOLSPECARRAY[5]="auditVol:4g:/var/log/audit"

# Override default values and/or extend array
LoadArray() {
   VOLSPECARRAY[${1}]="${2}"
}

# Parse our flagged args...
while true ; do
   case "$1" in
      -v|--volspec) 
         # v has an mandatory argument. As we are in quoted mode,
         # an empty parameter will be generated if its optional
         # argument is not found.
         case "$2" in
            "")
               echo "Error: option required but not specified"
               shift 2
               ;;
            *)
               echo "A volume-specification has been selected: '${2}'"
               MONTPNT=`echo ${2} | cut -d":" -f 3`
               case "${MONTPNT}" in
                  "/") IDX=0
                       ;;
                  "swap"|"SWAP") IDX=1
                       ;;
                  "/home") IDX=2
                       ;;
                  "/var") IDX=3
                       ;;
                  "/var/log") IDX=4
                       ;;
                  "/var/log/audit") IDX=5
                       ;;
                  # Catch-all: set IDX to append to array
                  *) IDX="${#VOLSPECARRAY[*]}"
                       ;;
               esac
               # Update array with explicit sets
               LoadArray ${IDX} ${2}
               # Offset to rest of opt-stack
               shift 2
               ;;
         esac
         ;;
      --)
         shift
         break
         ;;
      *)
         echo "Internal error!"
         exit 1
         ;;
   esac
done


############################################################
## INSERT LOGIC TO DYNAMICALLY CREATE AND ATTACH A NEW EBS  
############################################################

# Set this here so that getopt can have shifted through any flag-parms
TARGET=${1}

# Clear the MBR and partition table
dd if=/dev/zero of=${TARGET} bs=512 count=1

# Oh, parted, how I hate that you require me to do it all at once...
parted -s ${TARGET} -- mklabel msdos mkpart primary ext4 2048s 500m \
mkpart primary ext4 500m 100%s set 2 lvm on

# Let's make sure that actually worked...
if [ $? -ne 0 ]
then
   err_out 4 "Error during partitioning. Aborting!"
fi

# Format "/boot" target
mkfs -t ext4 -L "/boot" ${TARGET}1

# Set up LVM objects
#   Note: we'll change this to formula based, later, to accommodate
#         arbitrary EBS geometries
vgcreate VolGroup00 ${TARGET}2 || err_out 5 "VG creation failed. Aborting!"


# Parse Volume-array for disk-carving info
for VOLSPEC in ${VOLSPECARRAY[*]}
do
  VOLNAME=`echo ${VOLSPEC} | cut -d":" -f 1`
  VOLSIZE=`echo ${VOLSPEC} | cut -d":" -f 2`
  MONTPNT=`echo ${VOLSPEC} | cut -d":" -f 3`
  if [ "${VOLSIZE}" = "100%FREE" ]
  then
     lvcreate -l ${VOLSIZE} -n ${VOLNAME} VolGroup00
  else
     lvcreate -L ${VOLSIZE} -n ${VOLNAME} VolGroup00
  fi
  if [ "${VOLNAME}" = "swapVol" ]
  then
     mkswap -f "/dev/VolGroup00/${VOLNAME}"
  else
     mkfs -t ext4 "/dev/VolGroup00/${VOLNAME}"
  fi
done
