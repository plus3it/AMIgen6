# Using DKMS to maintain driver modules
As noted elsewhere in this project, maintaining custom network drivers for the the kernel in RHEL and CentOS AMIs/instances can be a bit painful (and prone to leaving an instance unreachable or even unbootable after a kernel update). One way to take some of the pain out managing instances with custom drivers is to leverage [DKMS](http://linux.dell.com/dkms/manpage.html). In general, DKMS is the recommended way to ensure that, as kernels are updated via `rpm` or `yum`, required kernel modules are also (automatically) updated.

Unfortunately, use of the DKMS method will require that developer tools (i.e., the GNU C-compiler) be present on the instance whenever the kernel is updated. The most practical way to do this is to keep these componets installed for the lifetime of the instance. It is very likely that relevant security teams will object to - or even prohibit - this. If the objection/prohibition cannot be overridden, use of the DKMS method will not be possible.

## Steps
1. Set an appropriate version string into the shell-environment:

  ```
  export VERSION=3.2.2
  ```

2. Make sure that appropriate header files for the running-kernel are installed

  ```
  yum install -y kernel-devel-$(uname -r)
  ```

3. Ensure that the dkms utilities are installed:

  ```
  yum --enablerepo=epel install dkms
  ```

4. Download the driver sources and unarchive into the /usr/src directory:

  ```
  wget https://sourceforge.net/projects/e1000/files/ixgbevf%20stable/${VERSION}/ixgbevf-${VERSION}.tar.gz/download \
     -O /tmp/ixgbevf-${VERSION}.tar.gz && ( cd /usr/src && \
       tar zxf /tmp/ixgbevf-${VERSION}.tar.gz )
  ```

5. Create an appropriate DKMS configuration file for the driver:

  ```
  cat > /usr/src/ixgbevf-${VERSION}/dkms.conf << EOF
  PACKAGE_NAME="ixgbevf"
  PACKAGE_VERSION="${VERSION}"
  CLEAN="cd src/; make clean"
  MAKE="cd src/; make BUILD_KERNEL=\${kernelver}"
  BUILT_MODULE_LOCATION[0]="src/"
  BUILT_MODULE_NAME[0]="ixgbevf"
  DEST_MODULE_LOCATION[0]="/updates"
  DEST_MODULE_NAME[0]="ixgbevf"
  AUTOINSTALL="yes"
  EOF
  ```

6. Register the module to the DKMS-managed kernel tree:

  ```
  dkms add -m ixgbevf -v ${VERSION}
  ```

7. Build the module against the currently-running kernel:

  ```
  dkms build ixgbevf/${VERSION}
  ```

## Verification
The easiest way to verify the correct functioning of DKMS is to:

1. Perform a `yum update -y`
2. Check that the new drivers were created by executing `find /lib/modules -name ixgbevf.ko`. Output should be similar to the following:

  ```
  find /lib/modules -name ixgbevf.ko | grep extra
  /lib/modules/2.6.32-642.1.1.el6.x86_64/extra/ixgbevf.ko
  /lib/modules/2.6.32-642.6.1.el6.x86_64/extra/ixgbevf.ko
  ```

  There should be at least two output-lines: one for the currently-running kernel and one for the kernel update. If more kernels are installed, there may be more than just two output-lines
 
3. Reboot the system, then check what version is active:

  ```
  modinfo ixgbevf | grep extra
  filename:       /lib/modules/2.6.32-642.1.1.el6.x86_64/extra/ixgbevf.ko
  ```

  If the output is null, DKMS didn't build the new module.
