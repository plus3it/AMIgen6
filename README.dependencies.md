The following RPMs must be present in order for the AMI-creation scripts to function:

* coreutils
* e2fsprogs
* epel-release (Note: if installed at boot, this repo should default to a disabled state)
* gawk
* grep
* grub
* lvm2
* parted
* sed
* sysvinit-tools
* openssl
* unzip
* util-linux-ng
* yum-utils

With a `@Core` install, this should result in the following being installed:

* epel-release
* lvm2
  * lvm2-libs
  * device-mapper
    * device-mapper-event
    * device-mapper-event-libs
    * device-mapper-libs
    * device-mapper-persistent-data
  * libudev
* parted
* unzip
* yum-utils

To ensure the above are all present within a newly-spun AMI, use the following cloud-init script:

```
#cloud-config

package_upgrade: true

packages:
  - coreutils
  - device-mapper
  - device-mapper-event
  - device-mapper-event-libs
  - device-mapper-libs
  - device-mapper-persistent-data
  - e2fsprogs
  - gawk
  - git
  - grep
  - grub
  - lvm2
  - lvm2-libs
  - libudev
  - openssl
  - parted
  - sed
  - sysvinit-tools
  - unzip
  - util-linux-ng
  - yum-utils
  - zip
```
