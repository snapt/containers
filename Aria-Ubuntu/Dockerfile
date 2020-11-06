# Use ubuntu 18.04 base image
FROM ubuntu:bionic
ENV DEBIAN_FRONTEND=noninteractive

# add PPA repos for PHP and HAProxy
RUN apt update && apt install -y -q gnupg software-properties-common
RUN echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list.d/snapt.list \
	&& echo "deb-src http://ppa.launchpad.net/ondrej/php/ubuntu bionic main" >> /etc/apt/sources.list.d/snapt.list \
	&& gpg --keyserver keyserver.ubuntu.com --recv E5267A6C \
	&& gpg --export --armor E5267A6C | apt-key add -
RUN echo "deb http://ppa.launchpad.net/vbernat/haproxy-1.9/ubuntu bionic main" >> /etc/apt/sources.list.d/snapt.list \
	&& echo "deb-src http://ppa.launchpad.net/vbernat/haproxy-1.9/ubuntu bionic main" >> /etc/apt/sources.list.d/snapt.list \
	&& gpg --keyserver keyserver.ubuntu.com --recv CFFB779AADC995E4F350A060505D97A41C61B9CD \
	&& gpg --export --armor CFFB779AADC995E4F350A060505D97A41C61B9CD | apt-key add -
RUN apt update && apt -y upgrade && apt -y install wget sudo net-tools lshw dmidecode psmisc iproute2 openssl haproxy keepalived \
	cron ca-certificates nginx ldap-utils nmap php5.6 php5.6-cgi php5.6-sqlite3	php5.6-xml php5.6-gd php5.6-fpm php5.6-ldap \
	php5.6-curl	php5.6-bz2 php5.6-mbstring php5.6-mcrypt

# update and install dependencies
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
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
		nmap\
		curl

#Create file system 
RUN mkdir -p /srv/www/htdocs/ \
	&& mkdir -p /usr/local/snapt/program/config/

# Download and extract latest snapt framework
RUN curl \
    --connect-timeout 30 \
    --retry 100 \
    --output /snapt_fw.tar.gz \
   https://shop.snapt.net/pluginAPI.php?task=getFramework
RUN tar -C /srv/www/htdocs/ -xvf /snapt_fw.tar.gz \
   && rm /snapt_fw.tar.gz

#Download/Extract ioncube loader files and enable
RUN wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -O /ioncube_loaders_lin_x86-64.tar.gz
RUN tar -C / -xvf /ioncube_loaders_lin_x86-64.tar.gz \
	&& echo "zend_extension=\"/ioncube/ioncube_loader_lin_5.6.so\"" > /etc/php/5.6/mods-available/ioncube.ini \
	&& echo "; priority=01" >> /etc/php/5.6/mods-available/ioncube.ini \
	&& phpenmod ioncube

COPY resources/snapt_nginx_builder.sh /tmp/
RUN chmod 777 /tmp/snapt_nginx_builder.sh
RUN /bin/bash /tmp/snapt_nginx_builder.sh
RUN rm /tmp/snapt_nginx_builder.sh

COPY resources/keepalived_builder.sh /tmp/
RUN chmod 777 /tmp/keepalived_builder.sh
RUN /bin/bash /tmp/keepalived_builder.sh

COPY resources/lighttpd_builder.sh /tmp/
RUN chmod 777 /tmp/lighttpd_builder.sh
RUN /bin/bash /tmp/lighttpd_builder.sh \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/lighttpd
RUN openssl req -new -newkey rsa:4096 -days 825 -nodes -x509 -subj "/C=NA/ST=NA/L=Unknown/O=NA/CN=snapt.internal" -keyout /etc/lighttpd/lighttpd.pem -out /etc/lighttpd/lighttpd.pem

#Add lighttpd user and group
RUN addgroup lighttpd \
	&& adduser --system --no-create-home --disabled-login --ingroup lighttpd lighttpd
#Add www user and group
RUN addgroup www \
&& adduser --system --no-create-home --disabled-login --ingroup www www

COPY resources/apt/ /etc/apt/
COPY resources/logrotate/ /etc/logrotate.d/
COPY resources/php/ /etc/php/5.6/
COPY resources/webserver/etc/lighttpd/ /etc/lighttpd/
#COPY resources/nginx.service /etc/
COPY resources/haproxy.cfg /etc/haproxy/haproxy.cfg
COPY resources/nginx.conf /etc/nginx/nginx.conf
COPY resources/*.ini /srv/www/htdocs/config/
COPY resources/wrapper /srv/www/htdocs/bin/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /data/accel/cache \
	&& chmod -R 777 /data/accel/cache
RUN chown -R root:lighttpd /srv/www/htdocs/ \
	&& chmod -R 777 /srv/www/htdocs/ \
	&& chown root:www-data /srv/www/htdocs/bin/wrapper \
	&& chmod 4755 /srv/www/htdocs/bin/wrapper

#Create persistent volumes
VOLUME ["/usr/local/snapt", "/etc/haproxy", "/etc/nginx", "/var/snapt"]

EXPOSE 8080
EXPOSE 29987

ENTRYPOINT /entrypoint.sh

#CMD /bin/bash