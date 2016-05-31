This script takes two optional arguments:
* **ARG1**: Path to remotely-hosted `awscli-bundle.zip` file. Pass only the base-URI - the `awscli-bundle.zip` component is assumed. If not specified, the script assumes "`https://s3.amazonaws.com/aws-cli`".
* **ARG2**: Path to localized EPEL-release RPM. This may be given as a local file-spec or a remotely-hosted file/URI. If not specified, the script assumes "`https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm`".
