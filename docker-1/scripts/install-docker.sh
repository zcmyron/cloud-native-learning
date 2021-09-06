#! /bin/bash
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -i  's/$releasever/7/g' /etc/yum.repos.d/CentOS-Base.repo
yum clean all
yum list

#stop firewall
systemctl stop firewalld && systemctl disable firewalld
yum install iptables-services -y
service iptables stop && systemctl disable iptables

#clear firewall rules
iptables -F

#shutdown selinux
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

getenforce
sleep 3


#ntp server
yum install -y ntp ntpdate
ntpdate cn.pool.ntp.org

#add crontab job
crontab_job="* */1 * * * /usr/sbin/ntpdate   cn.pool.ntp.org"
( crontab -l | grep -v "$cron_job"; echo "$cron_job" ) | crontab -
systemctl restart crond

#install basic packages
yum install -y  wget net-tools nfs-utils lrzsz gcc gcc-c++ make cmake libxml2-devel openssl-devel curl curl-devel unzip sudo ntp libaio-devel wget vim ncurses-devel autoconf automake zlib-devel  python-devel epel-release openssh-server socat  ipvsadm conntrack

#install docker
#configure aliyun docker yum source
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

#install dependencies
yum install -y yum-utils device-mapper-persistent-data lvm2

#install docker-ce
yum install docker-ce -y

#start docker
systemctl start docker && systemctl enable docker
systemctl status docker

#enable br_netfilter
modprobe br_netfilter

cat > /etc/sysctl.d/docker.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl -p /etc/sysctl.d/docker.conf

cat > /etc/rc.sysinit <<EOF
#!/bin/bash
for file in /etc/sysconfig/modules/*.modules ; do
[ -x $file ] && $file
done

EOF

sleep 2

cat > /etc/sysconfig/modules/br_netfilter.modules <<EOF
modprobe br_netfilter

EOF

sleep 2

chmod 755 /etc/sysconfig/modules/br_netfilter.modules

sleep 2

lsmod|grep br_netfilter

systemctl restart docker

sleep 2
echo "finish installing docker-ce."
