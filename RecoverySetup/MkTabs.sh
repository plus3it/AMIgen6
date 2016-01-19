#!/bin/bash
#
# Create storage config files within chroot
#
###########################################
AMIMTAB="/etc/mtab"
ALTROOT="${CHROOT:-/mnt/ec2-root}"
ALTMTAB="${ALTROOT}/etc/mtab"
ALTBOOT="${ALTROOT}/boot"

# Custom error-handler
function err_out() {
   echo $2
   exit $1
}

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

# Get the real mounts from the host's mtab
(
grep ${ALTROOT} ${AMIMTAB} | \
sed -e '{
   /,bind /d
   s#'${ALTROOT}'#/#
   s#//#/#
}' | sed '{
   /boot ext4/{N
      s/$/\n<TEMPDIR>/
   }
}' | sed 's/<TEMPDIR>/'${TMPSUB}'/' 

# Get pseudo-mounts
sed -n '/^[a-z]/p' ${AMIMTAB} | \
sed '{
   /^none/d
   s/,rootcontext.*" / /
}' ) |\
sed '/^$/d' > ${ALTMTAB}


# Create chroot fstab from chroot mtab
awk '{printf("%s\t%s\t%s\t%s\t%s %s\n",$1,$2,$3,$4,$5,$6)}' ${ALTMTAB} | \
## sed '{ 
##    /^	/d
##    /\/boot/s/^\/dev\/[a-z0-9]*/LABEL=\/boot/
##    /LABEL=/{N
##       s/\n/&\/dev\/mapper\/VolGroup00-swapVol	swap	swap	defaults	0 0&/
##   }
## }' | \
## sed '/mapper.*ext4/s/rw/defaults,acl/' > ${ALTROOT}/etc/fstab
sed '{
   /UUID/{N
      s/\n/&LABEL=\/boot	\/boot	ext4	defaults	1 1\n/
   }
}' | \
sed '/^UUID/s/^.*$/LABEL=root_disk	\/	ext4	defaults	1 1/' \
> ${ALTROOT}/etc/fstab
