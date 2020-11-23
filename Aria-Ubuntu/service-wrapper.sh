#!/bin/bash
/etc/init.d/haproxy start
/etc/init.d/haproxy status

status=$?

if [ $status -ne 0 ]; then
  echo "[err] Failed to start haproxy status=$status"
  exit $status
fi

/etc/init.d/nginx start
/etc/init.d/nginx status

status=$?

if [ $status -ne 0 ]; then
  echo "[err] Failed to start nginx status=$status"
  exit $status
fi

/usr/local/sbin/keepalived -f /etc/keepalived/keepalived.conf

status=$?

if [ $status -ne 0 ]; then
  echo "[warn] Failed to start keepalived status=$status"
  #do not exit, just warn
fi

/usr/local/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf

status=$?

if [ $status -ne 0 ]; then
  echo "[err] Failed to start webserver status=$status"
  exit $status
fi

while sleep 5; do
  ps aux |grep haproxy |grep -q -v grep
  haproxy=$?
  ps aux |grep nginx |grep -q -v grep
  nginx=$?
  ps aux |grep lighttpd |grep -q -v grep
  lighttpd=$?

  #if [ $haproxy -ne 0 -o $nginx -ne 0 -o $lighttpd -ne 0 ]; then
    #testing with only lighttpd as main critical service
    if [ $lighttpd -ne 0 ]; then
    echo "A critical process is not runnning - Going down!"
    exit 1
  fi
done