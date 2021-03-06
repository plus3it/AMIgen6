The scripts in this project are designed to ease the creation of LVM-enabled Enterprise Linux 6 AMIs for use in AWS envrionments. It has been successfully tested with CentOS 6.x, Scientific Linux 6.x and Red Hat Enterprise Linux 6.x. It should work with other EL6-derived operating systems. If you are looking for similar functionality for Enterprise Linux 7 distributions, please see [AMIgen7](../../../AMIgen7.git).

Please see the RHEL6 subdirectory for directions/scripts specifically required to leverage this solution for creating license-included RHEL6 AMIs.

If attempting to port for other EL6 derivatives that use publicly-accessible repositories create a yum-build.conf file to point to the distro-specific public repositories. Use the yum-build_CentOS.conf and yum-build_SciLin.conf files as references for creating a yum-build.conf file appropriate to your distro of choice.

Please read through all of the READMEs before using. Most of the errors you're likely to encounter can be avoided by doing so:

- [README.md](README.md): This file
- [README_dependencies.md](README_dependencies.md): Contains a list of packages that need to be present on the build-host for these scripts to run correctly. Bottom of file includes a user-data excerpt that will cause these dependencies to be satisfied.
- [README_profile](README_profile): List of environment variables that should be set.
- [README_scripts](README_scripts): Contains an list of the scripts in this archive and explanations of their functionalities and any arguments/options that may be passed to the scripts. These scripts should be executed in the order listed.

Additionally, some scripts have their own explanation files:
- [AWScliSetup.sh.md](AWScliSetup.sh.md): Details for use of the AWScliSetup.sh script's options.
- [ChrootBuild.sh.md](ChrootBuild.sh.md): Details for use of the ChrootBuild.sh script's options.
- [Packages-Core.md](Packages-Core.md): Details packages installed to chroot via "@Core" build-profile.
- [Packages-CloudInit.md](Packages-CloudInit.md): Details further packages installed to chroot due to cloud-init and its dependencies.
- [Packages-MinExtra.md](Packages-MinExtra.md): List of extra packages and dependencies required in the chroot to provide LVM2 functionality and to support HVM instance-types.
- [AMI Validation](docs/README_validation.md): tips on how to verify that resultant AMIs produce instances with expected functionality.

If there are any gaps that not covered in these documentation-files, please open an [issue](../../issues).

**Notes:**
* Please see the [spel](../../../../plus3it/spel.git) project if you wish to have pre-packaged extended functionality for this project's tool-set. The spel project adds image-creation via Packer and creation of images suitable for Vagrant, VMware and Azure. The spel project also acts as a combined driver for this project and the AMIgen7 peer-project.
* Extensions planned for the future:
    * Enhancing the EBS-carving routines
        * Accommodate other than 20GiB root EBS
        * Accommodate user-driven partition-sizing (note: no plans are in place to include partitions not prescribed by [SCAP guidance](https://fedorahosted.org/scap-security-guide/). It is assumed that non SCAP-prescribed partitioning will primarily be for hosting application-data - and that such data will be segregated from OS data via encapsulation in other than the root LVM2 volume-group)
