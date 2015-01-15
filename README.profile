To properly use the files in this file-group, it is expected that you will
have set the following shell environmentals on your build system:

CHROOT:			Location of the target chroot() build-tree
			(e.g. "/mnt/ec2-root")

YUM0:			This should be set to the target distribution's ELx
			version number (e.g., "6.5")

EC2_HOME:		This is the path to where you have installed the AWS
			CLI tools. Typically something like "/opt/ec2/tools"
EC2_URL:		The URL to your preferred AWS region. Use the
			ec2-describe-regions command to find your URL
			(typically something like
			"https://ec2.us-east-1.amazonaws.com")

AWS_ACCOUNT_NUMBER:	The numerical identifier for your AWS account.
			Typically found on your "My Account" page.
AWS_ACCESS_KEY:		Access key created for the account. Can be found at
			https://aws-portal.amazon.com/gp/aws/securityCredentials
AWS_SECRET_KEY:		The secret key associated with your access key. Can be
			found at the same URL as the access key
AWS_AMI_BUCKET:		Preferred path for anything uploaded to an S3 bucket.

PATH:			Update your normal path environmental variable to
			include the AWS CLI tools (can be set by declaring
			your path as ${PATH}:${EC2_HOME}/bin)

JAVA_HOME:		Installation-root for your Java package. Will
			typically be "/usr"
