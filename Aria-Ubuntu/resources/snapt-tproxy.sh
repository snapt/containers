#!/bin/sh
/usr/sbin/iptables -t mangle -N DIVERT
/usr/sbin/iptables -t mangle -A DIVERT -j MARK --set-mark 1
/usr/sbin/iptables -t mangle -A DIVERT -j ACCEPT

/bin/ip rule add fwmark 1 lookup 100
/bin/ip -f inet route add local 0.0.0.0/0 dev lo table 100

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 2 > /proc/sys/net/ipv4/conf/default/rp_filter
echo 2 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/eth0/rp_filter
