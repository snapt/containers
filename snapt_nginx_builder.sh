#!/bin/bash
# SNAPT NGINX BUILD SCRIPT
# help@snapt.net

DIRECTORY=/root/snp_ngx_builder
PAGESPEED=1.11.33.4
NGINX=1.12.2
NAXSI=0.55.3
OPENSSL=1.0.2n

COMPILE="--add-module=${DIRECTORY}/naxsi-${NAXSI}/naxsi_src \
--add-module=${DIRECTORY}/incubator-pagespeed-ngx-release-${PAGESPEED}-beta \
--prefix=/usr/share/nginx \
--conf-path=/etc/nginx/nginx.conf \
--sbin-path=/usr/sbin/nginx \
--http-log-path=/var/log/nginx/access.log \
--error-log-path=/var/log/nginx/error.log \
--lock-path=/var/lock/nginx.lock \
--pid-path=/run/nginx.pid \
--http-client-body-temp-path=/var/lib/nginx/body \
--http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
--http-proxy-temp-path=/var/lib/nginx/proxy \
--http-scgi-temp-path=/var/lib/nginx/scgi \
--http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
--with-pcre-jit \
--without-mail_pop3_module \
--without-mail_imap_module \
--without-mail_smtp_module \
--with-http_ssl_module \
--with-http_v2_module \
--with-stream \
--with-ipv6 \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_geoip_module \
--with-http_gzip_static_module \
--with-openssl=${DIRECTORY}/openssl-${OPENSSL}"


function folder_check_create ()
{
    if [ ! -d "${DIRECTORY}" ]; then
        mkdir -p "${DIRECTORY}"
    fi

    cd ${DIRECTORY}
}


function dependencies_ubuntu ()
{
    sudo apt-get update
    sudo apt-get -y install sudo make wget build-essential zlib1g-dev libpcre3 libpcre3-dev unzip libssl-dev libgeoip-dev
    #sudo yum install gcc-c++ pcre-devel zlib-devel make unzip geoip-devel
}


function prepare_pagespeed ()
{
    if [ ! -d ngx_pagespeed-release-${PAGESPEED}-beta ];
        then
            rm -rf ngx_pagespeed-release-*-beta
            wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${PAGESPEED}-beta.zip
            unzip release-${PAGESPEED}-beta.zip
            rm release-${PAGESPEED}-beta.zip

            cd incubator-pagespeed-ngx-release-${PAGESPEED}-beta/
            wget https://dl.google.com/dl/page-speed/psol/${PAGESPEED}.tar.gz
            tar -xzvf ${PAGESPEED}.tar.gz
            rm ${PAGESPEED}.tar.gz
        fi

        cd ${DIRECTORY}
    }

function prepare_naxsi ()
{
if [ ! -d naxsi-${NAXSI} ];
    then
        rm -rf naxsi-*;
        wget https://github.com/nbs-system/naxsi/archive/${NAXSI}.tar.gz;
        tar -xvzf ${NAXSI}.tar.gz;
        rm ${NAXSI}.tar.gz;
    fi;
}

function prepare_openssl ()
{
if [ ! -d naxsi-${NAXSI} ];
    then
        rm -rf naxsi-*;
        wget https://www.openssl.org/source/openssl-${OPENSSL}.tar.gz;
        tar -xvzf openssl-${OPENSSL}.tar.gz;
        rm openssl-${OPENSSL}.tar.gz;
    fi;
}

function prepare_nginx ()
{
    if [ ! -d nginx-${NGINX} ];
        then
            rm -rf nginx-*;
            wget http://nginx.org/download/nginx-${NGINX}.tar.gz;
            tar -xvzf nginx-${NGINX}.tar.gz;
            rm nginx-${NGINX}.tar.gz;
        fi;
}

function compile ()
{
    cd ${DIRECTORY}/nginx-${NGINX}
    ./configure ${COMPILE}
    make;
    sudo make install
}


folder_check_create
dependencies_ubuntu
prepare_openssl
prepare_pagespeed
prepare_naxsi
prepare_nginx
compile