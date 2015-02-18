#!/bin/sh
#
######################################################################
PROGNAME=`basename ${0}`
SPECCT=0

OPTIONBUFR=`getopt -o v: --long volspec: -n ${PROGNAME} -- "$@"`
# Note the quotes around '$OPTIONBUFR': they are essential!
eval set -- "$OPTIONBUFR"

LoadArray() {
   VOLSPECARRAY[${1}]="${2}"
}

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
               LoadArray ${SPECCT} ${2}
               SPECCT=`expr ${SPECCT} + 1`
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
for VOLSPEC in ${VOLSPECARRAY[*]}
do
  VOLNAME=`echo ${VOLSPEC} | cut -d":" -f 1`
  VOLSIZE=`echo ${VOLSPEC} | cut -d":" -f 2`
  MONTPNT=`echo ${VOLSPEC} | cut -d":" -f 3`
  echo "lvcreate -l ${VOLSIZE} -n ${VOLNAME} VolGroup00"
done
