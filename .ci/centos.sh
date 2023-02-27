#!/bin/sh

[ $(id -u) -ne 0 ] && \
echo "! must be root" && \
exit 1

sed -e 's|^mirrorlist=|#mirrorlist=|g' \
-e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.ustc.edu.cn/centos|g' \
-i.bak \
/etc/yum.repos.d/CentOS-Base.repo

yum install -y epel-release
yum install -y p7zip
