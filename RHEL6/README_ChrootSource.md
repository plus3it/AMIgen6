To identify a good starting-point for your chroot-build process, use the AWS cli to list out AMIs of appropriate type and "freshness".

~~~
aws --region ${REGION} ec2 describe-images --owner ${AWS_ACCOUNT} --filters \
  "Name=name,Values=${OS_NAME}*" "Name=architecture,Values=x86_64" \
  "Name=virtualization-type,Values=${VIRT_TYPE}"  \
  "Name=creation-date,Values=${YEAR}*" \
  --query 'Images[].{AMI:ImageId,CDATE:CreationDate}' --out text
~~~

For example, if looking to create an AMI within the Northern CA Region using an RHEL 6 HVM source AMI, issuing:

~~~
aws --region us-west-1 ec2 describe-images --owner 309956199498 --filters "Name=name,Values=RHEL-6*" "Name=architecture,Values=x86_64" "Name=virtualization-type,Values=hvm"  "Name=creation-date,Values=2015*" --query 'Images[].{AMI:ImageId,CDATE:CreationDate}' --out text
~~~

Will get you a list of all Amazon-owned (account ID '309956199498') Red Hat 6 HVM-compatible AMIs created in 2015. Pick the one with the most recent creation-date.
