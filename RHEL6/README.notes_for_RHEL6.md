Creation of RHEL 6 AMIs requires slight alteration to the chroot-build process:
* First, launch a license-included RHEL 6 AMI from the Amazon Marketplace. This instance will include access to all of the base and update RPMs and the components needed to provide access to those components within your AMI
* First, within the launced, license-included instance, create a local cache of all of the RPMs required to perform the chroot-build of RHEL 6
* Instead of executing the ChrootBuild1.sh step (outlined in the README.scripts file), execute:
~~~
yum --deisablerepo=* --enablerepo=build-cache --enablerepo=epel --nogpgcheck --installroot=${CHROOT} install -y
~~~

This directory includes a utility to automate the creation of the local RPM cache repository. The `LocalRepoSetup.sh` utility will download all of the RPMs necessary to crea an RHEL 6 AMI via the chroot-build process. The utility will also create the necessary data-structures to turn the downloaded RPMs into a yum-usable repository. Finally, the utility will create a repo-definition (in /etc/yum.repos.d) to make the cached RPMs usable via yum.

The resultant cache will enable the AMI-creator to more-easily creat an AMI with an "@Core" type of package manifest. This will mean that the resultant Red Hat AMI will more-closely match the RPM manifest created by the reest of the AMI-creation tools used to create the standardized CentOS (or Scientific Linux) builds. 

This cache will contain the following RPMs:
======================================================================
   acl
   aic94xx-firmware
   atmel-firmware
   attr
   audit
   audit-libs
   audit-libs-python
   authconfig
   b43-openfwwf
   basesystem
   bash
   bc
   bfa-firmware
   binutils
   busybox
   bzip2
   bzip2-libs
   ca-certificates
   checkpolicy
   chkconfig
   cloud-init
   coreutils
   coreutils-libs
   cpio
   cracklib
   cracklib-dicts
   cronie
   cronie-anacron
   crontabs
   curl
   cyrus-sasl
   cyrus-sasl-lib
   dash
   db4
   db4-utils
   dbus-glib
   dbus-libs
   dbus-python
   device-mapper
   device-mapper-event
   device-mapper-event-libs
   device-mapper-libs
   device-mapper-persistent-data
   dhclient
   dhcp-common
   diffutils
   dmidecode
   dracut
   dracut-kernel
   e2fsprogs
   e2fsprogs-libs
   efibootmgr
   elfutils-libelf
   elfutils-libs
   ethtool
   expat
   file
   file-libs
   filesystem
   findutils
   fipscheck
   fipscheck-lib
   gamin
   gawk
   gdbm
   glib2
   glibc
   glibc-common
   gmp
   gnupg2
   gpgme
   grep
   groff
   grub
   grubby
   gzip
   hwdata
   info
   initscripts
   iproute
   iptables
   iptables-ipv6
   iputils
   ipw2100-firmware
   ipw2200-firmware
   ivtv-firmware
   iwl1000-firmware
   iwl100-firmware
   iwl3945-firmware
   iwl4965-firmware
   iwl5000-firmware
   iwl5150-firmware
   iwl6000-firmware
   iwl6000g2a-firmware
   iwl6050-firmware
   kbd
   kbd-misc
   kernel
   kernel-firmware
   kexec-tools
   keyutils-libs
   kpartx
   krb5-libs
   less
   libacl
   libattr
   libblkid
   libcap
   libcap-ng
   libcgroup
   libcom_err
   libcurl
   libdrm
   libedit
   libertas-usb8388-firmware
   libffi
   libgcc
   libgcrypt
   libgpg-error
   libgudev1
   libidn
   libnih
   libnl
   libpciaccess
   libselinux
   libselinux-python
   libselinux-utils
   libsemanage
   libsemanage-python
   libsepol
   libss
   libssh2
   libstdc++
   libtasn1
   libudev
   libusb
   libuser
   libutempter
   libuuid
   libxml2
   libxml2-python
   libxslt
   libyaml
   logrotate
   lua
   lvm2
   lvm2-libs
   lzo
   m2crypto
   m4
   make
   MAKEDEV
   man
   mdadm
   mingetty
   module-init-tools
   mysql-libs
   ncurses
   ncurses-base
   ncurses-libs
   net-tools
   newt
   newt-python
   nspr
   nss
   nss-softokn
   nss-softokn-freebl
   nss-sysinit
   nss-tools
   nss-util
   ntp
   ntpdate
   openldap
   openssh
   openssh-clients
   openssh-server
   openssl
   p11-kit
   p11-kit-trust
   pam
   passwd
   pciutils-libs
   pcre
   pinentry
   pkgconfig
   plymouth
   plymouth-core-libs
   plymouth-scripts
   policycoreutils
   policycoreutils-python
   popt
   postfix
   procps
   psmisc
   pth
   pygobject2
   pygpgme
   pyOpenSSL
   python
   python-argparse
   python-backports
   python-backports-ssl_match_hostname
   python-boto
   python-chardet
   python-cheetah
   python-configobj
   python-dateutil
   python-dmidecode
   python-ethtool
   python-gudev
   python-iniparse
   python-jsonpatch
   python-jsonpointer
   python-libs
   python-lxml
   python-markdown
   python-prettytable
   python-pycurl
   python-pygments
   python-rhsm
   python-setuptools
   python-six
   python-urlgrabber
   python-urllib3
   PyYAML
   ql2100-firmware
   ql2200-firmware
   ql23xx-firmware
   ql2400-firmware
   ql2500-firmware
   readline
   redhat-logos
   redhat-release-server
   redhat-support-lib-python
   redhat-support-tool
   rhn-check
   rhn-client-tools
   rhnlib
   rhnsd
   rhn-setup
   rootfiles
   rpm
   rpm-libs
   rpm-python
   rsyslog
   rt61pci-firmware
   rt73usb-firmware
   sed
   selinux-policy
   selinux-policy-targeted
   setools-libs
   setools-libs-python
   setup
   shadow-utils
   shared-mime-info
   slang
   snappy
   sqlite
   subscription-manager
   sudo
   sysvinit-tools
   tar
   tcp_wrappers-libs
   tzdata
   udev
   upstart
   usermode
   ustr
   util-linux-ng
   vim-minimal
   virt-what
   wget
   which
   xorg-x11-drv-ati-firmware
   xz
   xz-libs
   xz-lzma-compat
   yum
   yum-metadata-parser
   yum-rhn-plugin
   yum-utils
   zd1211-firmware
   zlib
======================================================================
The above RPM-list will support an Anaconda-type installation specification similar to:
   @Core -- \
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
