#!/bin/bash -e
#====================================================================================================
# Author: tim.elston@snapt.net
# Description: Build script for lighttpd 1.4
# Date: 2018/11/14
#====================================================================================================
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#====================================================================================================
#
parentPath=$(cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

wget https://download.lighttpd.net/lighttpd/releases-1.4.x/lighttpd-1.4.51.tar.gz

tar -xvf lighttpd-1.4.51.tar.gz

cd lighttpd-1.4.51

./configure --without-bzip2 --with-openssl

make

make install

if [ ! -d "/var/log/lighttpd" ]; then
	mkdir /var/log/lighttpd
fi

if [ ! -e "/var/log/lighttpd/error.log" ]; then
	touch /var/log/lighttpd/error.log
fi

chmod -R 777 /var/log/lighttpd/error.log

#cd doc/systemd

#sed -i 's+/usr/sbin/lighttpd+/usr/local/sbin/lighttpd+g' lighttpd.service

#cp lighttpd.service /etc/systemd/system/lighttpd.service
#systemctl daemon-reload
#systemctl enable lighttpd

rm -rf  $parentPath/lighttpd-1.4.51.tar.gz $parentPath/lighttpd-1.4.51

exit 0

