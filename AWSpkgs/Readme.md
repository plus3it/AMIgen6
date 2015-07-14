Amazon-hosted instances benefit from the availability supplemental tools provided by Amazon. Amazon does not generally make these tools directly availabile for download and porting. Instead, it is necessary to:

1. Instantiate an Amazon Linux AMI
2. Identify the AWS tools you wish to port
3. Use the `get_reference_source` Python script to pull copies of the SRPMs from the S3 hosted software repos
4. Copy the SRPMs to your target installation environment (e.g., "CentOS 6")
5. Use the `rpmbuild` utility (found in the "Development tools" Yum package-group) to create RPMs from the SRPMs.
6. Install the resultant RPMs to your instance.

As of the creation of this RPM, the following AWS-related packages were available for pull-down using the `get_reference_source` method:

* aws-amitools-ec2-1.5.6-1.1.amzn1.src.rpm
* aws-apitools-as-1.0.61.6-1.0.amzn1.src.rpm
* aws-apitools-common-1.1.0-1.8.amzn1.src.rpm
* aws-apitools-ec2-1.7.3.0-1.0.amzn1.src.rpm
* aws-apitools-elb-1.0.35.0-1.0.amzn1.src.rpm
* aws-apitools-mon-1.0.20.0-1.0.amzn1.src.rpm
* aws-apitools-rds-1.19.002-1.0.amzn1.src.rpm
* aws-cfn-bootstrap-1.4-5.4.amzn1.src.rpm
* aws-cli-1.7.14-1.8.amzn1.src.rpm
* ec2-utils-0.4-1.22.amzn1.src.rpm
* get_reference_source-1.2-0.4.amzn1.src.rpm
* python-boto-2.36.0-1.6.amzn1.src.rpm

After sorting through compatibility issues and creating RPMs, you will have the following RPMs.

* aws-amitools-ec2-1.5.6-1.1.el6.noarch.rpm
* aws-apitools-as-1.0.61.6-1.0.el6.noarch.rpm
* aws-apitools-common-1.1.0-1.8.el6.noarch.rpm
* aws-apitools-ec2-1.7.3.0-1.0.el6.noarch.rpm
* aws-apitools-elb-1.0.35.0-1.0.el6.noarch.rpm
* aws-apitools-mon-1.0.20.0-1.0.el6.noarch.rpm
* aws-apitools-rds-1.19.002-1.0.el6.noarch.rpm
* ec2-net-utils-0.4-1.22.el6.noarch.rpm
* ec2-utils-0.4-1.22.el6.noarch.rpm
* get_reference_source-1.2-0.4.el6.noarch.rpm

Most of the AWS packages change fairly infrequently. It's recommended that the procedures noted at the head of this README be executed on approximately a quarterly-basis.

Notes:
* The `aws-cli` is not relevant to CentOS 6. It is recommended to get its functionality via the [install-bundle ZIP](http://docs.aws.amazon.com/cli/latest/userguide/installing.html).
* The `get_reference_source` is only relevant for the original AWS-hosted source-RPMs. It is provided in this bundle for completeness but is not otherwise usefully-functional
* The Amazon python-boto RPM requires Python 2.7. This version is not compatible with current Enterprise Linux 6 derivatives.
* Installation of these RPMs will pull in the following package-dependencies:
  * alsa-lib
  * compat-readline5
  * fontconfig
  * freetype
  * giflib
  * java-1.8.0-openjdk
  * java-1.8.0-openjdk-headless
  * jpackage-utils
  * libICE
  * libSM
  * libX11
  * libX11-common
  * libXau
  * libXext
  * libXfont
  * libXi
  * libXrender
  * libXtst
  * libfontenc
  * libjpeg-turbo
  * libpng
  * libxcb
  * rsync
  * ruby
  * ruby-libs
  * ttmkfdir
  * tzdata-java
  * xorg-x11-font-utils
  * xorg-x11-fonts-Type1
