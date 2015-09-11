Creation of RHEL 6 AMIs requires slight alteration to the chroot-build process:
* First, launch a license-included RHEL 6 AMI from the Amazon Marketplace. This instance will include access to all of the base and update RPMs and the components needed to provide access to those components within your AMI. This will be your AMI-builder instance.
* Next, from your AMI-builder instance, create a local cache of all of the RPMs required to perform the chroot-build of RHEL 6 (see note, below, about the `LocalRepoSetup.sh` utility)
* After creating the localized RPM installation-cache, follow the the steps enumerated in this project's `README.scripts` file. When you reach the step where you would execute `ChrootBuild.sh` step (for CentOS or other public/free EL6 distributions), manually-execute, instead:
~~~
yum --disablerepo=* --enablerepo=build-cache --enablerepo=epel --nogpgcheck --installroot=${CHROOT} install -y
~~~

This directory includes a utility to automate the creation of the local RPM cache repository. The `LocalRepoSetup.sh` utility will download all of the RPMs necessary to crea an RHEL 6 AMI via the chroot-build process. The utility will also create the necessary data-structures to turn the downloaded RPMs into a yum-usable repository. Finally, the utility will create a repo-definition (in /etc/yum.repos.d) to make the cached RPMs usable via yum.

The resultant cache will enable the AMI-creator to more-easily creat an AMI with an "@Core" type of package manifest. This will mean that the resultant Red Hat AMI will more-closely match the RPM manifest created by the reest of the AMI-creation tools used to create the standardized CentOS (or Scientific Linux) builds. 
The cache-creation script expects the presence of two file:
* pkglst.rh
* pkglst.epel

This Git project does not contain prepopulated versions of these files. This desing decision was made due to differences in yum repository contents and names that may be available to the AMI build-personnel. If these files are missing at invocation of the repo-creation script, the script will create them by extracting the package lists from the Package*.md files in the project's parent directory.

If a different set of RPMs is desired, it will be required that the person seeking to generate the AMI create their own pkglst.rh and pkglst.epel files.

The repo script will then create a local RPM cache from the RPMs specified in the pkglst.* files and create a repo-definition pointing to that local cache.
