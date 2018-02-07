# Use ubuntu 16.04 base image
FROM ubuntu:xenial

# update and install dependencies
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		wget \
		net-tools \
		lshw \
		dmidecode \
		psmisc \
		openssl \
		haproxy \
		keepalived \
		vim \
		cron \
		ca-certificates \
		sudo \
		squid \
		nginx 

# Download SNAPT
RUN wget https://downloads.snapt.net/fetch/linux \
	&& tar -C / -xvf ./linux \
	&& rm linux

COPY snapt_nginx_builder.sh /tmp/
RUN chmod 777 /tmp/snapt_nginx_builder.sh
RUN ./tmp/snapt_nginx_builder.sh
RUN rm /tmp/snapt_nginx_builder.sh \
	&& rm -rf /var/lib/apt/lists/*

#Create persistent volumes
VOLUME ["/usr/local/snapt", "/etc/haproxy", "/etc/nginx", "/var"]

EXPOSE 8080
EXPOSE 29987

ENTRYPOINT ./usr/local/snapt/start.sh \
	&& cron \
	&& /bin/bash \
	&& /etc/init.d/haproxy start \
	&& /etc/init.d/nginx start \
	&& service keepalived start
