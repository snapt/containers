#!/bin/bash -e
#====================================================================================================
# Author: tim.elston@snapt.net
# Description: Build script for HAProxy 1.9.13
# Date: 2018/11/14
# Last Updated: 2019/12/06
#====================================================================================================
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#====================================================================================================
#Install required packages
haproxy_version='1.9.15'
lua_version='5.3.4'

apt-get install -q -y libpcre3-dev\
		libssl-dev\
		zlib1g-dev\
		libreadline-dev\
		build-essential\
		libsystemd-dev

#Download and compile lua src
wget https://www.lua.org/ftp/lua-${lua_version}.tar.gz

tar -xvf lua-${lua_version}.tar.gz

cd lua-${lua_version}

make linux install

#Download and compile HAproxy src
cd /tmp

wget https://www.haproxy.org/download/1.9/src/haproxy-${haproxy_version}.tar.gz

tar -xvf haproxy-${haproxy_version}.tar.gz

cd /tmp/haproxy-${haproxy_version}

make TARGET=linux2628 USE_PCRE=1 USE_OPENSSL=1 USE_ZLIB=1 USE_LIBCRYPT=1 USE_SYSTEMD=1 USE_LUA=1 LUA_LIB_NAME=lua LUA_LIB=/usr/local/lib/lua/5.3 LUA_INC=/usr/local/include

make install

mv /usr/local/sbin/haproxy /usr/sbin

if [ ! -d /etc/haproxy/ ]; then
mkdir /etc/haproxy/
fi

#Make and copy systemd service file

cd contrib/systemd

sed -i '1s+PREFIX = /usr/local+PREFIX = /usr+' Makefile

make

cp haproxy.service /etc/systemd/system/

cd /

exit 0


