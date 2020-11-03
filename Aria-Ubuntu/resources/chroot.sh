#!/bin/bash -e
#====================================================================================================
# Author: tim.elston@snapt.net
# Description: This script builds the target filesystem and runs inside chroot /edit
# Date: 2018/11/14
#====================================================================================================
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#====================================================================================================
install_temp="etc/snapt/tmp"
install_firstboot="etc/snapt/boot"

#Mount required dir's from host system
mount -t proc isobuilder_chroot1 /proc
mount -t sysfs isobuilder_chroot2 /sys
mount -t devpts isobuilder_chroot3 /dev/pts

#Set some environment variables
export HOME=/root
export LC_ALL=C

#Add custom repo for php5 and install tasksel
apt-get update && apt-get install -y -q gnupg\
		software-properties-common\
		tasksel

echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list.d/snapt.list
echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list.d/snapt.list
gpg --keyserver keyserver.ubuntu.com --recv E5267A6C
gpg --export --armor E5267A6C | apt-key add -

echo "deb http://ppa.launchpad.net/vbernat/haproxy-1.9/ubuntu bionic main" >> /etc/apt/sources.list.d/snapt.list
echo "deb-src http://ppa.launchpad.net/vbernat/haproxy-1.9/ubuntu bionic main" >> /etc/apt/sources.list.d/snapt.list
gpg --keyserver keyserver.ubuntu.com --recv CFFB779AADC995E4F350A060505D97A41C61B9CD
gpg --export --armor CFFB779AADC995E4F350A060505D97A41C61B9CD | apt-key add -

add-apt-repository universe -y

#Install standard ubuntu server packages
apt-get update && apt-get install ubuntu-server -y

#set before installing postfix
debconf-set-selections <<< "postfix postfix/mailname string snapt.local"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

#Install additional required applications
apt-get install -y -q\
		squid\
		squidclient\
		sqlite3\
		wget\
		unzip\
		openssh-server\
		php5.6\
		php5.6-cgi\
		php5.6-sqlite3\
		php5.6-xml\
		php5.6-gd\
		php5.6-fpm\
		php5.6-ldap\
		php5.6-curl\
		php5.6-bz2\
		php5.6-mbstring\
		php5.6-mcrypt\
		man\
		ntpdate\
		telnet\
		ldap-utils\
		postfix\
		haproxy\
		nmap

#Create file system 
mkdir -p /srv/www/htdocs/
mkdir -p /usr/local/snapt/program/config/

#Extract Snapt Framework
tar -C /srv/www/htdocs/ -xvf /$install_temp/snapt_fw.tar.gz

cp /$install_temp/default.ini /srv/www/htdocs/config/
cp /$install_temp/haproxy.ini /srv/www/htdocs/config/
cp /$install_temp/hassl.ini /srv/www/htdocs/config/
cp /$install_temp/nginx.ini /srv/www/htdocs/config/
cp /$install_temp/redundancy.ini /srv/www/htdocs/config/
cp /$install_temp/snaptHaAcls.ini /srv/www/htdocs/config/

mkdir -p /$install_firstboot
cp /$install_temp/snapt-tproxy.sh /$install_firstboot/
cp /$install_temp/intercept.ini /$install_firstboot/
cp /$install_temp/getty@.service /$install_firstboot/
#Fetch snaptPowered2 plugin
curl -X POST -F 'task=getPlugin' -F 'pluginSlug=snaptPowered2' -F 'serial=10107580' https://shop.snapt.net/pluginAPI.php --output /$install_temp/snaptPowered2.tar.gz
mkdir /srv/www/htdocs/includes/plugins/snaptPowered2
tar -C /srv/www/htdocs/includes/plugins/snaptPowered2 -xvf /$install_temp/snaptPowered2.tar.gz

#custom logrotate files
cp -r /$install_temp/logrotate/ /$install_firstboot/

mkdir -p /etc/snapt/network/
cp -r /$install_temp/snaptNetwork/* /etc/snapt/network/	

cp /$install_temp/php/cli/php.ini /etc/php/5.6/cli/
cp /$install_temp/php/cgi/php.ini /etc/php/5.6/cgi/
cp /$install_temp/php/fpm/php.ini /etc/php/5.6/fpm/

#Download/Extract ioncube loader files and enable
wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /$install_temp/ioncube_loaders_lin_x86-64.tar.gz
tar -C / -xvf /$install_temp/ioncube_loaders_lin_x86-64.tar.gz
echo "zend_extension=\"/ioncube/ioncube_loader_lin_5.6.so\"" > /etc/php/5.6/mods-available/ioncube.ini
echo "; priority=01" >> /etc/php/5.6/mods-available/ioncube.ini
phpenmod ioncube

cp /$install_temp/wrapper /srv/www/htdocs/bin/

#Create cache folder
mkdir -p /data/accel/cache
chmod -R 777 /data/accel/cache

#Add lighttpd user and group
addgroup lighttpd
adduser --system --no-create-home --disabled-login --ingroup lighttpd lighttpd
#Add www user and group
addgroup www
adduser --system --no-create-home --disabled-login --ingroup www www

#Create some required directories/files and set permissions
mkdir -p /var/snapt/certs
chmod -R 777 /var/snapt

mkdir -p /var/log/lighttpd
chmod 755 /var/log/lighttpd

touch /etc/snapt-release-v2
touch /etc/snapt_firstboot

#Add Snapt cronjobs to crontab
echo "" >> /etc/crontab
echo "* * * * * root /usr/bin/php /srv/www/htdocs/bin/cronjob.php all -r" >> /etc/crontab

#Copy motd script
cp /$install_temp/createmotd /usr/local/bin
chmod 755 /usr/local/bin/createmotd

#Copy bashrc and create snapt user
cp /$install_temp/bashrc /root/.bashrc
adduser --disabled-password --gecos "" snapt
echo -e "snapt\nsnapt\n" | passwd snapt
cp /$install_temp/bashrc /home/snapt/.bashrc
usermod -aG sudo snapt

#set password for root user and permit ssh login
echo -e "snapt\nsnapt\n" | passwd root
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

echo "Please wait while we make some final changes. The system will reboot shortly..." > /etc/issue

#Run build scripts
cd /$install_temp
#/$install_temp/haproxy_builder.sh
/$install_temp/snapt_nginx_builder.sh
/$install_temp/lighttpd_builder.sh
/$install_temp/keepalived_builder.sh

#create pagespeed.conf or nginx fails to start
touch /etc/nginx/pagespeed.conf

#Lock packages that we have custom compiled to prevent APT overwriting them
cp /$install_temp/apt/preferences /etc/apt/

#Copy snapt webserver files
mkdir -p /etc/lighttpd/
cp -r /$install_temp/webserver/etc/lighttpd/* /etc/lighttpd/

#Copy default nginx and HAproxy conf files
cp /$install_temp/nginx.conf /etc/nginx/nginx.conf
cp /$install_temp/haproxy.cfg /etc/haproxy/haproxy.cfg

#Copy service files to temp boot dir
cp /$install_temp/*.service /$install_firstboot/

#enable Snapt Firstboot service
systemctl enable snapt-boot.service

mkdir -p /etc/snapt/grub/default
cp /$install_temp/grub /etc/snapt/grub/default/grub

#clean up
apt-get clean
rm -rf /tmp/* /$install_temp/ ~/.bash_history

#Unmount host dir's
umount -lf isobuilder_chroot3
umount -lf isobuilder_chroot2
umount -lf isobuilder_chroot1

exit 0
