#!/bin/bash
/etc/init.d/haproxy start \
	&& nginx -c /etc/nginx/nginx.conf \
	&& service keepalived start \
	&& /usr/local/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf