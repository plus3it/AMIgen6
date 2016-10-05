# Creating `ixgbevf` RPM

1. Login to instance as a non-privileged user
2. Ensure that `developer` package-group has been installed (`sudo yum install -y @development`)
3. Create an RPM build-hierarchy:
    
    `$ mkdir -p ${HOME}/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}`
    
    (see [RPM Build How-to](https://wiki.centos.org/HowTos/SetupRpmBuildEnvironment))
    
4. Ensure that the @rpmbuild@ tool looks in the right location for build-items:
    
    `$ echo '%_topdir %(echo $HOME)/rpmbuild' > ~/.rpmmacros`
    
    (see "RPM Build How-to":https://wiki.centos.org/HowTos/SetupRpmBuildEnvironment)
    
5. Download updated `ixgbevf` driver from [SourceForge](http://downloads.sourceforge.net/project/e1000/ixgbevf%20stable/3.2.2/ixgbevf-3.2.2.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fe1000%2Ffiles%2Fixgbevf%2520stable%2F3.2.2%2F&ts=1475695310&use_mirror=pilotfiber) - placing it in `${HOME}/rpmbuild/SOURCES`
6. Extract the `.spec` file from the archive and place it into the `${HOME}/rpmbuild/SPECS` directory:
    
    ~~~~
    cd ${HOME}/rpmbuild/SPECS 
    tar zxf ${HOME}/rpmbuild/SOURCES/ixbevf-<VERSION>.tar.gz \
       ixbevf-<VERSION>/ixbevf.spec
    ~~~~
    
7. Build the RPM:
    
    `rpmbuild -bb ixbevf-<VERSION>/ixbevf.spec`

Assuming all of the above are successful, an RPM will be found at `${HOME}/rpmbuild/RPMS/x86_64/ixgbevf-<VERSION>-<RELEASE>.x86_64.rpm`
