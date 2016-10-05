# Enabling 10Gbps Support (EL6)

AWS-hosted instances with optimized networking-support enabled see the 10Gbps interface as an Intel 10Gbps ethernet adapter (`lspci | grep Ethernet` will display a string similar to `Intel Corporation 82599 Virtual Function`). This interface makes use the `ixgbevf` network-driver. Enterprise Linux 6 bundles the version 2.12.x version of the driver into the `kernel` RPM. Per the *[Enabling Enhanced Networking with the Intel 82599 VF Interface on Linux Instances in a VPC](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/sriov-networking.html#test-enhanced-networking)* document, AWS enhanced networking requires version 2.14.2 or higher of the `ixgbevf` network-driver. To enable 10Gbps support within an EL6 instance, it will be necessary to update to at least 2.14.2.

The `ixgbevf` network-driver sourcecode can be found on [SourceForge](https://sourceforge.net/projects/e1000/files/ixgbevf%20stable). It should be noted that not every AWS-compatible version will successfully compile on EL 6. Version `3.2.2` is known to successfully compile, without intervention, on EL6.

## Notes

**>>>CRITICAL ITEM<<<**

It is necessary to recompile the `ixgbevf` driver and inject it into the kernel *_each time the kernel version changes_*. This needs to be done between changing the kernel version and rebooting into the new kernel version. Failure to update the driver each time the kernel changes will result in the instance failing to return to the network after a reboot event.

Step &#35;10 from the implementation procedure:

    rpm -qa kernel | sed 's/^kernel-//' | xargs -I {} dracut -v -f /boot/initramfs-{}.img {}

Is the easiest way to ensure any available kernels are properly linked against the `ixgbevf` driver.

**>>>CRITICAL ITEM<<<**

## Procedure

The following assumes the instance-owner has privileged access to the instance OS and can make AWS-level configuration changes to the instance-configuration:

1. Login to the instance
2. Escalate privileges to root
3. Install the up-to-date `ixgbevf` driver. This can be installed either by compiling from source or pre-compiled binaries (see [Creating ixgbevf RPM](README.create_driver_RPM.md) for steps on how to create a binary RPM from the SourceForge-hosted sourcecode)
4. Delete any `*persistent-net*.rules` files found in the `/etc/udev/rules.d` directory (one or both of `70-persistent-net.rules` and `75-persistent-net-generator.rules` may be present)
5. Ensure that an `/etc/modprobe.d` file with the following minimum contents exists:
    
    `alias eth0 ixgbevf`
    
    Recommend creating/placing in @/etc/modprobe.d/ifaliases.conf@

6. Unload any `ixgbevf` drivers that may be in the running kernel:
    
    `modprobe -rv ixgbevf`
    
7. Load the updated `ixgbevf` driver into the running kernel:
    
    `modprobe -v ixgbevf`
    
8. Ensure that the `/etc/modprobe.d/ixgbevf.conf` file exists. Its contents should resemble:
    
    `options ixgbevf InterruptThrottleRate=1`
    
9. Update the `/etc/dracut.conf`. Ensure that the `add_dracutmodules+=""` directive is uncommented and contains reference to the `ixgbevf` modules (i.e., `add_dracutmodules+="ixgbevf"`)
10. Recompile all installed kernels:
    
    `rpm -qa kernel | sed 's/^kernel-//'  | xargs -I {} dracut -v -f /boot/initramfs-{}.img {}`
    
11. Shut down the instance
12. When the instance has stopped, use the AWS CLI tool to enable optimized networking support:
    
    `aws ec2 --region <REGION> describe-instance-attribute --instance-id <INSTANCE_ID> --attribute sriovNetSupport`
    
13. Power the instance back on
14. Verify that 10Gbps capability is available:
  1. Check that the `ixgbevf` module is loaded
<pre>
$ sudo lsmod
Module                  Size  Used by
ipv6                  336282  46
ixgbevf                63414  0
i2c_piix4              11232  0
i2c_core               29132  1 i2c_piix4
ext4                  379559  6
jbd2                   93252  1 ext4
mbcache                 8193  1 ext4
xen_blkfront           21998  3
pata_acpi               3701  0
ata_generic             3837  0
ata_piix               24409  0
dm_mirror              14864  0
dm_region_hash         12085  1 dm_mirror
dm_log                  9930  2 dm_mirror,dm_region_hash
dm_mod                102467  20 dm_mirror,dm_log
</pre>
  2. Check that `ethtool` is showing that the default interface (typicall "`eth0`") is using the `ixgbevf` driver:
<pre>
$ sudo ethtool -i eth0
driver: ixgbevf
version: 3.2.2
firmware-version: N/A
bus-info: 0000:00:03.0
supports-statistics: yes
supports-test: yes
supports-eeprom-access: no
supports-register-dump: yes
supports-priv-flags: no
</pre>
  3. Verify that the interface is listed as supporting a link mode of `10000baseT/Full` and a speed of `10000Mb/s`:
<pre>
$ sudo ethtool eth0
Settings for eth0:
        Supported ports: [ ]
        **Supported link modes:   10000baseT/Full**
        Supported pause frame use: No
        Supports auto-negotiation: No
        Advertised link modes:  Not reported
        Advertised pause frame use: No
        Advertised auto-negotiation: No
        **Speed: 10000Mb/s**
        Duplex: Full
        Port: Other
        PHYAD: 0
        Transceiver: Unknown!
        Auto-negotiation: off
        Current message level: 0x00000007 (7)
                               drv probe link
        Link detected: yes
</pre>
