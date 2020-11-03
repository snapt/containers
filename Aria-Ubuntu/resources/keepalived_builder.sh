#!/bin/bash -e
#====================================================================================================
# Author: tim.elston@snapt.net
# Description: Build script for keepalived 2.0.15
# Date: 2019/04/26
#====================================================================================================
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#====================================================================================================
#

wget https://www.keepalived.org/software/keepalived-2.0.15.tar.gz

tar -xvf keepalived-2.0.15.tar.gz

cd keepalived-2.0.15

apt-get update && apt-get install -y\
	build-essential\
	pkg-config

./configure --with-systemdsystemunitdir=/etc/systemd/system

make && make install

cd ..

rm -rf keepalived-2.0.15 keepalived-2.0.15.tar.gz

if [ ! -d "/etc/keepalived/" ]; then
	mkdir /etc/keepalived/
	touch /etc/keepalived/keepalived.conf
fi

exit 0
