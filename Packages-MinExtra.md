In addition to the "Core" package group, the following packages will be needed to create an LVM2-enabled instance that is initially manageable from a remote host. RPMs denoted with "C" are directly-selected for install while RPMs denoted with "D" are installed to satisfy dependency-tracing for the "C" packages:

* kernel (C): provides components necessary to boot a hardware virtual machine instance
* lvm2 (C): provides the components necessary to boot a VM with root operating-system components hosted on LVM2 data-structures
* man (C): provides instance-local reference documentation
* ntp (C): provides automated time-syncing functionality.
* ntpdate (C): provides manual time-syncing functionality
* openssh-clients (C): provides remote CLI-based access to the virtual machine instance
* wget (C): more fully-functioning utility for fetching network-based resources
* yum-cron (C): toolset for automating yum updates of the virtual machine instance
* yum-utils (C): toolset to make managing and extracting information from yum easier.
* device-mapper-event		(D)
* device-mapper-event-libs	(D)
* device-mapper-persistent-data	(D)
* dracut-kernel			(D)
* grubby			(D)
* libedit			(D)
* lvm2-libs			(D)
* xz				(D)
* xz-lzma-compat		(D)
* 


The two RPM-sets, as listed in this document, do not describe dependency relationships. If absolute dependency relationships are required, it is recommended to construct such by issuing a command similar to:

~~~
  for DEPSRC in $(awk '/\(C)$/{ print $2}' Core.pkgs)
  do
     echo ${DEPSRC}
     rpm -Rq "${DEPSRC}" | sed 's/^/- /'
  done
~~~

from within the completed OS image.

