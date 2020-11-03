#!/usr/bin/php
<?php

if (trim(`/usr/bin/whoami`) != 'root') {
    fwrite(STDOUT, "You must run this program as root. Try 'su -' with the password 'snapt'.\n");
    exit;
}

set_include_path('/etc/snapt/network/');
include_once('networkConfigClass.php');

$netConfg = new NetConfig();
$netConfg->configure();
