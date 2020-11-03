#!/bin/bash
#====================================================================================================
# Author: tim.elston@snapt.net
# Description: Script to be run on first boot
# Date: 2018/11/14
#====================================================================================================
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#====================================================================================================
#Check if snapt_firstboot file exists and if so execute all code in if block
if [ -f /etc/snapt_firstboot ]
then

echo "First boot"

openssl req -new -newkey rsa:4096 -days 825 -nodes -x509 -subj "/C=NA/ST=NA/L=Unknown/O=NA/CN=snapt.internal" -keyout /etc/lighttpd/lighttpd.pem -out /etc/lighttpd/lighttpd.pem

chown -R root:lighttpd /srv/www/htdocs/
chmod -R 777 /srv/www/htdocs/
chown root:www-data /srv/www/htdocs/bin/wrapper
chmod 4755 /srv/www/htdocs/bin/wrapper

#tar -xf /etc/snapt/boot/fileOverlay.tar.gz -C /
cp /etc/snapt/boot/intercept.ini /usr/local/snapt/program/config/
cp /etc/snapt/boot/snapt-tproxy.sh /etc/
cp /etc/snapt/boot/getty@.service /etc/systemd/system/
chmod 644 /etc/systemd/system/getty@.service /etc/systemd/system/nginx.service /etc/systemd/system/snapt-boot.service

rm -rf /srv/www/htdocs/config/default.ini

chmod 755 /usr/local/bin/createmotd
createmotd

chmod 777 /etc/motd /etc/resolv.conf
chmod 775 /usr/sbin/haproxy

mkdir -p /var/lib/nginx
chmod -R 777 /var/lib/nginx
chmod -R 777 /etc/nginx

cp /etc/snapt/boot/nginx.service /etc/systemd/system/
cp /etc/snapt/boot/lighttpd.service /etc/systemd/system/
cp /etc/snapt/boot/keepalived.service /etc/systemd/system/

systemctl enable lighttpd
systemctl disable haproxy
systemctl disable squid
killall -9 squid
systemctl disable nginx
systemctl disable keepalived

#Disable automatic updates
#chmod -R -x /etc/cron.daily/ /etc/cron.monthly/ /etc/cron.weekly/ /etc/cron.hourly/
#systemctl disable apt-daily-upgrade.timer
#systemctl disable apt-daily.timer
echo 'APT::Periodic::Update-Package-Lists "0";' > /etc/apt/apt.conf.d/20auto-upgrades
echo 'APT::Periodic::Unattended-Upgrade "0";' >> /etc/apt/apt.conf.d/20auto-upgrades

#custom logrotate files
cp -r /etc/snapt/boot/logrotate/* /etc/logrotate.d/

#symlink for chmod (UI uses /usr/bin/chmod someitmes)
ln -s /bin/chmod /usr/bin/chmod

rm -rf /etc/netplan/*.yaml

/usr/bin/php /etc/snapt/network/getInterfaces.php

ln -s /etc/snapt/network/networkConfig.php /bin/networkConfig

echo "Welcome to Snapt. Default login user is snapt with password snapt." > /etc/issue

if [ -f /etc/systemd/system/getty.target.wants/getty@tty1.service ]
then
	rm /etc/systemd/system/getty.target.wants/getty@tty1.service
	ln -s /etc/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
else
	ln -s /etc/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
fi

#generate new machine-id

if [ -f /etc/machine-id ]
then
	rm /etc/machine-id
	/bin/systemd-machine-id-setup
else
	/bin/systemd-machine-id-setup
fi

#echo "ifconfig | grep "inet" | grep -v "127.0.0.1" | grep -v "inet6" | awk '{ print \$2 }'" > /usr/local/bin/getipaddress
echo "ip address show | grep inet | grep brd | grep -v 127.0.0.1 | grep -v inet6 | awk '{ print \$2 }'" > /usr/local/bin/getipaddress
chmod 777 /usr/local/bin/getipaddress

fi

# after running the above, check if the file still exists, then remove it and reboot
if [ -f /etc/snapt_firstboot ]
then

rm /etc/snapt_firstboot
rm -rf /etc/snapt/boot

echo 'Rebooting!'
reboot

fi

exit 0
