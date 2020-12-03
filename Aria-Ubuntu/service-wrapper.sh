#!/bin/bash

balancer_started=false
accelerator_started=false
redundancy_started=false

/usr/sbin/haproxy -c -f /etc/haproxy/haproxy.cfg
status=$?

if [ $status -eq 0 ]; then
  /etc/init.d/haproxy start
  /etc/init.d/haproxy status

  status=$?
  
  if [ $status -eq 0 ]; then
    balancer_started=true
    echo "[info] Balancer process started successfully"
  else
    echo "[err] Failed to start Balancer status=$status"
  fi
else 
  echo "[warn] Invalid Balancer config - skipping"
fi

/usr/sbin/nginx -t -c /etc/nginx/nginx.conf
status=$?

if [ $status -eq 0 ]; then
  /etc/init.d/nginx start
  /etc/init.d/nginx status

  status=$?
  
  if [ $status -eq 0 ]; then
    accelerator_started=true
    echo "[info] Accelerator process started successfully"
  else
    echo "[err] Failed to start Accelerator status=$status"
  fi
else 
  echo "[warn] Invalid Accelerator config - skipping"
fi

/usr/local/sbin/keepalived -t -f /etc/keepalived/keepalived.conf
status=$?


if [ $status -eq 0 ]; then
  /etc/init.d/keepalived start
  /etc/init.d/keepalived status

  status=$?
  
  if [ $status -eq 0 ]; then
    redundancy_started=true
    echo "[info] Redundancy process started successfully"
  else
    echo "[err] Failed to start Redundancy status=$status"
  fi
else 
  echo "[warn] Invalid Redundancy config - skipping"
fi

/usr/local/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf
status=$?

if [ $status -ne 0 ]; then
  echo "[err] Failed to start webserver status=$status"
fi

while sleep 5; do

  if $balancer_started; then
    ps aux |grep haproxy |grep -q -v grep
    haproxy=$?
  fi
  if $accelerator_started; then
    ps aux |grep nginx |grep -q -v grep
    nginx=$?
  fi
  if $redundancy_started; then
    ps aux |grep lighttpd |grep -q -v grep
    lighttpd=$?
  fi

  if $balancer_started && [ $haproxy -ne 0 ]; then
    echo "A critical process is not runnning - Going down!"
    exit 1
  fi

  if $accelerator_started && [ $nginx -ne 0 ]; then
    echo "A critical process is not runnning - Going down!"
    exit 1
  fi

  if $redundancy_started && [ $keepalived -ne 0 ]; then
    echo "A critical process is not runnning - Going down!"
    exit 1
  fi
done