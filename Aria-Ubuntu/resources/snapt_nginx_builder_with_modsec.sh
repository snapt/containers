#!/bin/bash
# SNAPT NGINX BUILD SCRIPT
# help@snapt.net

# note: on Snapt images you need to "zypper in libuuid-devel"

DIRECTORY=/root/snp_ngx_builder
PAGESPEED=1.13.35.2-stable
NPS_RELEASE_NUMBER=1.13.35.2
NGINX=1.15.8
NAXSI=0.56
OPENSSL=1.0.2o

COMPILE="--add-module=${DIRECTORY}/naxsi-${NAXSI}/naxsi_src \
--add-module=${DIRECTORY}/incubator-pagespeed-ngx-${PAGESPEED} \
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
--with-openssl=${DIRECTORY}/openssl-${OPENSSL} \
--add-dynamic-module=${DIRECTORY}/ModSecurity-nginx"

function folder_check_create ()
{
    if [ ! -d "${DIRECTORY}" ]; then
        mkdir -p "${DIRECTORY}"
    fi

    cd ${DIRECTORY}
}

function get_package_manager ()
{
    id=$(cat /etc/*release | grep ID=)
    idLike=$(cat /etc/*release | grep ID_LIKE=)
    if [[ $id == "ID=centos" ]] || [[ $idLike =~ "rhel" ]]; then
        packageMan="yum"
    elif [[ $id == "ID=opensuse" ]] || [[ $idLike =~ "suse" ]]; then
        packageMan="zypper"
    else
        packageMan="apt"
    fi
}

function dependencies_ubuntu ()
{
    if [ $packageMan == "apt" ]; then
        sudo apt-get update
        sudo apt-get -y install sudo make wget build-essential zlib1g-dev libpcre3 libpcre3-dev unzip libssl-dev libgeoip-dev uuid-dev
    fi
}

function dependencies_centos_rhel ()
{
    if [ $packageMan == "yum" ]; then
        sudo yum install -y gcc-c++ pcre-devel zlib-devel make unzip geoip-devel libuuid-devel
    fi
}

function dependencies_suse ()
{
    if [ $packageMan == "zypper" ]; then
    sudo zypper in -y libuuid-devel
    fi
}


function prepare_pagespeed ()
{
    if [ ! -d ngx_pagespeed-release-${PAGESPEED} ];
        then
            rm -rf incubator-pagespeed-*
            wget https://github.com/apache/incubator-pagespeed-ngx/archive/v${PAGESPEED}.zip
            unzip v${PAGESPEED}.zip
            rm v${PAGESPEED}.zip

            cd incubator-pagespeed-ngx-${PAGESPEED}/
            wget https://dl.google.com/dl/page-speed/psol/${NPS_RELEASE_NUMBER}-x64.tar.gz
            tar -xzvf ${NPS_RELEASE_NUMBER}-x64.tar.gz
            rm ${NPS_RELEASE_NUMBER}-x64.tar.gz
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
        wget https://www.openssl.org/source/old/1.0.2/openssl-${OPENSSL}.tar.gz;
        tar -xvzf openssl-${OPENSSL}.tar.gz;
        rm openssl-${OPENSSL}.tar.gz;
    fi;
}

function prepare_modsecurity ()
{
    git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
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
    if [ ! -d /usr/share/nginx/modules ]; 
    then
        mkdir -p /usr/share/nginx/modules
    fi
    cp objs/ngx_http_modsecurity_module.so /usr/share/nginx/modules/ngx_http_modsecurity_module.so
}

function cleanup ()
{
    if [ -d ${DIRECTORY} ]; then
        rm -rf ${DIRECTORY}   
    fi
}


folder_check_create
get_package_manager
dependencies_ubuntu
dependencies_centos_rhel
dependencies_suse
prepare_openssl
prepare_pagespeed
prepare_naxsi
prepare_modsecurity
prepare_nginx
compile
cleanup
