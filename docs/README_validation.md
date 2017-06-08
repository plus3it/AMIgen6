# Verification 

*Note:* This document describes steps for manually validating AMIs produced with AMIgen. Automated procuedures - supplemented with CloudFormation templates and other AWS components - are described in the [Automated Validation](README_validation-automated.md) document.

After creating an AMI, it is recommended to launch an instance from the AMI and perform some configuration-verification tasks before publishing the AMI. The AMIgen-created AMIs are notable for supporting:
- Use of LVM for managing root (OS) filesystems (to meet STIG and related security guidelines' requirements).
- Enablement of SELinux (in "Permissive" mode) with initial labels applied prior to launch (speeds first boot).
- Dynamic resizing of root EBS: allows increasing from 20GiB default, only (e.g., to support remote graphical Linux desktop deployments)
- Supporting 10Gbps mode in m4-generation instance-types (inclusive of C3, C4, D2, I2, R3 and newer instance-types).
- Inclusion of cloud-init for boot-time automated provisioning tasks
- Inclusion of AWS utilities (the AWS CLI, the CloudFormation bootstrapper, etc.)
- Binding to RPM update repositories to support lifecycle patching/sustainment activities (RHEL AMIs link to RHUI; CentOS binds to the CentOS.Org mirros; either may be configured to use private repos as needed).
It is recommended to verify that all of these features are working as expected in instances launched from newly-generated AMIs. 

## Verification-Instance Setup
To set up a in instance with an adequate test-configuration, launch an m4.large instance (t2 instance types can be used, but it will not be possible to verify proper 10Gbps support) with the root EBS increased by 10GiB and UserData defined similar to the following:

~~~
#cloud-config
users:
  - default
  - name: testusr0
    ssh-authorized-keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAnEePMHxFDPqP+XYBu5nkwsi+eW7g4CLUs38JLfkhxv3NfPJCaskvx85ipom65nAobEQ8l00xk08cF8zSSZa1ONBVmQ6O69f4MouTrM55fTVi4lA8U7G00PDnVysQ2Q1aa9NG13rJusfo9ELDGk6EsBYnZLF3BHN7lpo0+V3RLjs= validation test key
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: wheel
    lock-passwd: True
    selinux-user: unconfined_u
  - name: testusr1
    ssh-authorized-keys:
    - ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAkOCVLhrzFrNWmS1THQoqW6hwWNVSJ7vnN/iKnW/qeEOH7szwC2IfG4Hz5d1ZoKloiKeN4iP68TuxhGswgryrkALgVf0j2Mksw7hFPFVpj0TDWvv0flfpU9SpOWBl75fO1miMQPEmt2Y+RfUANlu553TYoweYRAPv11t7Vecc4sM= validation test key
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: wheel
    lock-passwd: True
    selinux-user: unconfined_u
packages:
  - git
package_upgrade: True
runcmd:
  - yum install -y https://repo.saltstack.com/yum/redhat/salt-repo-2016.3-1.el6.noarch.rpm
  - init 6
~~~

## UserData Explanation
### `users` Section:
As prototyped, this section causes three users to be created within the instance: the default user and two custom users. The directives:
- `name`: Sets the logical name of the custom user
- `ssh-authorized-keys`: Installs the public key into the custom user's `${HOME}/.ssh/authorized_keys` file (allows passwordless, key-based SSH logins to the custom user's account using the private key associated with the installed public key.
- `groups`: Adds the custom user to the specified group
- `lock-passwd`: Locks the password of the custom user. This disables the ability to login via password - preventing brute-force attacks.
- `selinux-user`: Sets the custom user's target SELinux role.
- `sudo`: Sets the custom user's rights within the `sudo` subsystem. Because the initial users are being configured with locked passwords, it is necessary to configure sudo to allow the defined users to escallate privileges without supplying a password.

### `packages` Section:
As prototyped, this section will install the `git` RPM (and any dependencies). This section may be omitted or supplemented as needs dictate. The inclusion of the `git` RPM is provided in case the AMI-tester needs to use git to install any further tools.

### `package_upgrade` Section:
As prototyped, this will cause the instance to do a `yum upgrade -y` type of action at first boot. Including this in the initial launch should cause no configuration changes since the new AMI notionally has all patches already applied.

### `runcmd` Section:
As prototyped this section will:
- Installs the SaltStack yum repo definitions. During validation, this simply exercises the validation instance's ability to run "first-launch" scripts.
- Reboots the instance. With EL6, in order for LVM2 to be able to make use of extra disk-space allocated to the root EBS, the host needs one reboot to incorporate all of the relevant geometry changes to the root EBS.

The contents of this section will be saved to the file `/var/lib/cloud/instances/<INSTANCE_ID>/scripts/runcmd`. Because this file can contain sensitive data, cloud-init protects its contents from view by unprivileged user accounts.

## Verification

After the test instance completes its boot-sequence, login to the intance.

1. Login with either the default user account (maintuser) or one of the testing-user accounts specified in the UserData. Note that using a testing-user account to login will verify that UserData was properly handled by the AMI.
1. Escalate privileges to root
1. Use the `ethtool` command to verify that the default network interface is running at `10000Mb/s`(or `10000baseT/Full`)

    <img alt="Speed Check" src="https://cloud.githubusercontent.com/assets/7087031/21895702/a2e21de0-d8b1-11e6-863a-9035c6be6440.png" width="70%" heigt="70%">

1. Use the `lsblk` command to map out the storage configuration.
1. Use the `df` command to verify that the STIG-mandated root filesystems exist and are hosted within LVM2 volumes.

    <img alt="LVMed-root Check" src="https://cloud.githubusercontent.com/assets/7087031/21895700/a2e1bd6e-d8b1-11e6-84f4-f17cb2792814.png" width="70%" heigt="70%">

1. Issue the command `pvresize /dev/xvda2`. This will cause LVM2 to remap its view of the /dev/xvda2 partition to pick up any increases in block-allocation.
1. Use the `vgdisplay -s` command to verify that the added storage shows up in the root LVM2 volume-group.
1. Use `rpm -qa | grep -E "(aws|ec2)"` and `aws --version` to verify that the expected AWS uitilities and RPMs are installed.

    <img alt="AWS Utils" src="https://cloud.githubusercontent.com/assets/7087031/21895705/a2f396ba-d8b1-11e6-9c7b-7f55e17926e9.png" width="70%" heigt="70%">

1. Check the contents of the `/home` directory to ensure that the requested user accounts were all created
1. Use `yum repolist` - or other equivalent yum invocation - to verify that the instance is able to talk to its RPM sources.

    <img alt="Repo-Availability Check" src="https://cloud.githubusercontent.com/assets/7087031/21895703/a2e3c9f6-d8b1-11e6-9cdd-464ee0a83581.png" width="70%" heigt="70%">

1. Use the `getenforce` command to verify that the instance is running in "`Permissive`" mode.

    <img alt="SEL-mode Check" src="https://cloud.githubusercontent.com/assets/7087031/21895699/a2e1908c-d8b1-11e6-9c1e-c0b579bbff28.png" width="70%" heigt="70%">

1. Verify that the AMI was properly cleaned up: the `/var/lib/cloud/instances/` directory should have only *one* subdirectory (its name should match the id of the launched instance) and the only history in the yum database should be those actions that occured during instance launch (yum history dates should be within minutes of the current system date).

    <img alt="AMI-cleanup Check" src="https://cloud.githubusercontent.com/assets/7087031/21895701/a2e19564-d8b1-11e6-9f2a-c881923f207d.png" width="70%" heigt="70%">

1. Verify that the OS has been forced to map the root EBS to the `/dev/xvda` device-node:

    <img alt="Device-mapping Check" src="https://cloud.githubusercontent.com/assets/7087031/21895704/a2e4641a-d8b1-11e6-8b63-a1c049b9733b.png" width="70%" heigt="70%">
