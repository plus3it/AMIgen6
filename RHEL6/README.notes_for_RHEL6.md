Creation of RHEL 6 AMIs requires slight alteration to the chroot-build process:
* First, launch a license-included RHEL 6 AMI from the Amazon Marketplace. This instance will include access to all of the base and update RPMs and the components needed to provide access to those components within your AMI
* First, within the launced, license-included instance, create a local cache of all of the RPMs required to perform the chroot-build of RHEL 6
* Instead of executing the ChrootBuild1.sh step (outlined in the README.scripts file), execute:
~~~
yum --disablerepo=* --enablerepo=build-cache --enablerepo=epel --nogpgcheck --installroot=${CHROOT} install -y
~~~

This directory includes a utility to automate the creation of the local RPM cache repository. The `LocalRepoSetup.sh` utility will download all of the RPMs necessary to crea an RHEL 6 AMI via the chroot-build process. The utility will also create the necessary data-structures to turn the downloaded RPMs into a yum-usable repository. Finally, the utility will create a repo-definition (in /etc/yum.repos.d) to make the cached RPMs usable via yum.

The resultant cache will enable the AMI-creator to more-easily creat an AMI with an "@Core" type of package manifest. This will mean that the resultant Red Hat AMI will more-closely match the RPM manifest created by the reest of the AMI-creation tools used to create the standardized CentOS (or Scientific Linux) builds. 
The cache-creation script expects the presence of two file:
* pkglst.rh
* pkglist.epel
This Git project does not contain prepopulated versions of these files. This desing decision was made due to differences in yum repository contents and names that may be available to the AMI build-personnel. It is expected that the person running the AMI generator scripts will populate these files by extracting the package lists from the Package*.md files in the project's parent directory. The easy method for generating these files is to do something like:
~~~
awk '/\([CD])$/{ print $2}' Packages-*.md
~~~

After generating the pkglst file(s) from the Packages-*.md files, the generated cache will contain ll of the RPMs enumerated in those files.
