#!/bin/bash
#
# Do some file cleanup...
#
#########################
CHROOT=/mnt/ec2-root

# Get rid of stale RPM data
yum -c /opt/ec2/yum/yum-xen.conf --installroot=${CHROOT}/ -y clean packages
rm -rf ${CHROOT}/var/cache/yum
rm -rf ${CHROOT}/var/lib/yum

# Nuke any history data
cat /dev/null > ${CHROOT}/root/.bash_history

# Create AWS instance SSH key-grabber
cat << EOF > ${CHROOT}/etc/init.d/ec2-get-ssh 
#!/bin/bash
# chkconfig: 2345 95 20
# processname: ec2-get-ssh
# description: Capture AWS public key credentials for EC2 user

# Source function library
. /etc/rc.d/init.d/functions

# Source networking configuration
[ -r /etc/sysconfig/network ] && . /etc/sysconfig/network

# Replace the following environment variables for your system
export PATH=:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin
 
# Check that networking is configured
if [ "${NETWORKING}" = "no" ]; then
  echo "Networking is not configured."
  exit 1
fi
 
start() {
  if [ ! -d /root/.ssh ]; then
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh
  fi
  # Retrieve public key from metadata server using HTTP
  curl -f http://169.254.169.254/latest/meta-data/public-keys/0/openssh-key > /tmp/my-public-key
  if [ $? -eq 0 ]; then
    echo "EC2: Retrieve public key from metadata server using HTTP." 
    cat /tmp/my-public-key >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    rm /tmp/my-public-key
  fi
}
 
stop() {
  echo "Nothing to do here"
}
 
restart() {
  stop
  start
}
 
# See how we were called.
case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart}"
    exit 1
esac
 
exit $?
EOF

# Make it executable
chmod 755 ${CHROOT}/etc/init.d/ec2-get-ssh 

# Activate the 'service'
/usr/sbin/chroot ${CHROOT} /sbin/chkconfig ec2-get-ssh on
