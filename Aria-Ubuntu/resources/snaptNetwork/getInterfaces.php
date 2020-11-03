#!/usr/bin/php
<?php

require_once('yaml/Yaml.php');
$yaml = new Yaml();

$path = '/etc/netplan/config.yaml';
if (!is_file($path)) {
    file_put_contents($path, '');
}

$config = $yaml->load($path);

function getInterfaces()
{
    $interfaces = array();
    exec('/bin/ip -o link show', $tempInterfaces);

    foreach ($tempInterfaces as $interface) {
        $parts = explode(':', $interface);
        $part = $parts[1];
        if (strstr($part, '@')) {
            $part = explode('@', $part);
            $part = $part[0];
        }
        $interfaces[] = $part;
    }

    return $interfaces;
}

$config['network'] = array();
$config['network']['version'] = '2';
$config['network']['ethernets'] = array();

$interfaces = getInterfaces();
$interfaces = array_map('trim', $interfaces);

if (in_array("lo", $interfaces) && ($key = array_search('lo', $interfaces)) !== false) {
    unset($interfaces[$key]);
}

if (empty($interfaces)) {
    return false;
}

foreach ($interfaces as $interface) {
    $config['network']['ethernets'][$interface] = array();
    $config['network']['ethernets'][$interface]['dhcp4'] = true;
    $config['network']['ethernets'][$interface]['optional'] = true;
}

file_put_contents($path, $yaml->dump($config));
