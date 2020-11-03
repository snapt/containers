#!/usr/bin/php
<?php

class NetConfig {

public function __construct() {
require_once('yaml/Yaml.php');
$this->yaml = new Yaml();

$this->path = '/etc/netplan/config.yaml';

//Create config file if it does not exist
if (!is_file($this->path)) {
    file_put_contents($this->path, '');
}

$this->config = $this->yaml->load($this->path);
}

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

function maskConvert($mask)
{
    // List of all the possible CIDR/netmask combinations
    $mappings = array(
        0 => '0.0.0.0',
        1 => '128.0.0.0',
        2 => '192.0.0.0',
        3 => '224.0.0.0',
        4 => '240.0.0.0',
        5 => '248.0.0.0',
        6 => '252.0.0.0',
        7 => '254.0.0.0',
        8 => '255.0.0.0',
        9 => '255.128.0.0',
        10 => '255.192.0.0',
        11 => '255.224.0.0',
        12 => '255.240.0.0',
        13 => '255.248.0.0',
        14 => '255.252.0.0',
        15 => '255.254.0.0',
        16 => '255.255.0.0',
        17 => '255.255.128.0',
        18 => '255.255.192.0',
        19 => '255.255.224.0',
        20 => '255.255.240.0',
        21 => '255.255.248.0',
        22 => '255.255.252.0',
        23 => '255.255.254.0',
        24 => '255.255.255.0',
        25 => '255.255.255.128',
        26 => '255.255.255.192',
        27 => '255.255.255.224',
        28 => '255.255.255.240',
        29 => '255.255.255.248',
        30 => '255.255.255.252',
        31 => '255.255.255.254',
        32 => '255.255.255.255',
    );

    if (preg_match("/.*\..*/", $mask)) {
        // Netmask given, find the CIDR
        foreach ($mappings as $cidr => $value) {
            if ($value == $mask) {
                return $cidr;
            }
        }
    } else {
        // CIDR given, return netmask
        return $mappings[$mask];
    }
}

function isYes($input) {
    if (preg_match("/^y$|^yes$/i", $input)) {
        return true;
    }
}

public function configure() {

//Clear the screen
echo exec('/usr/bin/clear');

$line = '';

$this->interfaces = $this->getInterfaces();
$this->interfaces = array_map('trim', $this->interfaces);

//exclude "lo" interface
if (in_array("lo", $this->interfaces) && ($key = array_search('lo', $this->interfaces)) !== false) {
    if ($key == 0) {
    	array_shift($this->interfaces);
    }
}

if (empty($this->interfaces)) {
    return false;
}

//Prompt 1 | select interface?

echo "-------------------------SNAPT NETWORK CONFIG--------------------------\n\n" ;
echo "Please select the number of the interface you would like to configure:\n\n";

$count = 1;

foreach ($this->interfaces as $interface) {
	echo "{$count} --> {$interface}\n";
	++$count;
}

echo "\n0 --> Quit Network Config\n\n";

echo ">> ";
$line = trim(fgets(STDIN));

while ($line > count($this->interfaces) || !preg_match("/^[0-9]+$/", $line))  {
	echo "Please enter a number from the list of availabe interfaces:\n";
	echo ">> ";
	$line = trim(fgets(STDIN));
}

if ($line === "0") {
    return;
}

$this->interfaceKey = $line - 1;

while ($line <= count($this->interfaces) && $line !== "0") {
		$this->interface = $this->interfaces[$this->interfaceKey];
		echo "------------------------------\n";
		echo "{$interface} selected!\n";
		echo "------------------------------\n";
		break;
}
// select DHCP options or static addressing
//Prompt 2 | DHCP or static?

echo "Please select an option from the list below:\n";

echo "1 --> DHCP options\n";
echo "2 --> Static Addressing\n";
echo "3 --> Default Gateway\n";
echo "4 --> DNS servers\n\n";

echo "0 --> Return to main menu\n\n";

echo ">> ";
$line = trim(fgets(STDIN));

while (!preg_match("/^[0-4]$/", $line) || $line === '') {
    echo "Invalid Selection! Please enter a number from the list of availabe options.\n";
    echo "1 --> DHCP options\n";
    echo "2 --> Static Addressing\n";
    echo "3 --> Default Gateway\n";
    echo "4 --> DNS servers\n\n";

    echo "0 --> Return to main menu\n\n";
    echo ">> ";
    $line = trim(fgets(STDIN));
}

if ($line === "0") {
    return $this->configure();
}

if ($line === "1") {
    echo "-----------------------------\n";
    echo "DHCP Options selected!\n";
    echo "-----------------------------\n\n";
    echo "Please enter a number from the list of availabe options!\n";
        
    echo "1 --> ENABLE DHCP\n";
    echo "2 --> DISABLE DHCP\n\n";

    echo "0 --> Return to main menu\n\n";

    echo ">> ";
    $line = trim(fgets(STDIN));

    while (!preg_match("/^[0-2]$/", $line) || $line === '') {
        echo "Invalid Selection! Please enter a number from the list of availabe options.\n";
        echo "1 --> ENABLE DHCP\n";
        echo "2 --> DISABLE DHCP\n\n";

        echo "0 --> Return to main menu\n\n";
        
        echo ">> ";
        $line = trim(fgets(STDIN));
    }

    if ($line === "0") {
       return $this->configure();
    }

    if ($line === "1") {
        //write config
        $this->config['network']['ethernets'][$this->interface]['dhcp4'] = true;
        $this->config['network']['ethernets'][$this->interface]['optional'] = true;
        file_put_contents($this->path, $this->yaml->dump($this->config));
        echo "------------------------------\n";
        echo "DHCP enabled on interface: {$this->interface}!\n";
        echo "------------------------------\n";

        //apply config
        exec('netplan apply');
        sleep(1);
        return $this->configure();
    } elseif ($line === "2") {
        //write config
        $this->config['network']['ethernets'][$this->interface]['dhcp4'] = false;
        if (array_key_exists('optional', $this->config['network']['ethernets'][$this->interface])) {
            unset($this->config['network']['ethernets'][$this->interface]['optional']);
        }
        file_put_contents($this->path, $this->yaml->dump($this->config));
        echo "------------------------------\n";
        echo "DHCP disabled on interface: {$this->interface}!\n";
        echo "------------------------------\n";

        //apply config
        exec('netplan apply');
        sleep(1);
        return $this->configure();
    }
}

if ($line === "2") {
    echo "-----------------------------\n";
    echo "Static Addressing selected!\n";
    echo "-----------------------------\n\n";

    //list and choose IP to edit/add
    echo "Please select an existing IP address to edit or add a new one: \n\n";

    //print existing addersses
    if (array_key_exists($this->interface, $this->config['network']['ethernets'])) {
        if (!empty($this->config['network']['ethernets'][$this->interface]['addresses'])) {
        
            $this->currentIPs = $this->config['network']['ethernets'][$this->interface]['addresses'];
            $count = 1;
            foreach ($this->currentIPs as $cIP) {
                echo "\n{$count} --> {$cIP}";
                $count++;
            }
        }
    }

    echo "\n\n0 --> Add new IP to this interface \n\n";
    echo ">> ";
    $line = trim(fgets(STDIN));

    if (empty($this->currentIPs)) {
        $this->currentIPs = array();
    }

    while ($line > count($this->currentIPs) || !preg_match("/^[0-9]+$/", $line)) {
        echo "Invalid Selection! Please enter a number from the list of availabe options.\n";
        $count = 1;
        foreach ($this->currentIPs as $cIP) {
            echo "\n{$count} --> {$cIP}";
            $count++;
        }
        echo "\n\n0 --> Add new IP to this interface \n\n";
        echo ">> ";
        $line = trim(fgets(STDIN));
    }
    if ($line === "0") {
        echo "Creating new IP address:\n";

        $ip = "";
        $mask = "";

        while ($ip == "") {
            echo "Please enter a valid IP address to use (eg: 10.10.0.100): ";
            $line = trim(fgets(STDIN));
            $duplicate = false;
            if (filter_var($line, FILTER_VALIDATE_IP)) {
                foreach ($this->currentIPs as $cIP) {
                    $tempIP = explode('/', $cIP)[0];
                    if ($tempIP == $line) {
                        echo "IP address already exists!\n";
                        $duplicate = true;
                    }
                }
                if (!$duplicate) {
                    $ip = $line;
                }
            } else {continue;}
        }

        while ($mask == "") {
            echo "Please enter a valid netmask to use (eg: 255.255.255.0): ";
            $line = trim(fgets(STDIN));
            if (filter_var($line, FILTER_VALIDATE_IP)) {
                $mask = $line;
            } else {continue;}
        }
    
        echo "Would you like to apply these settings?:\n\n";
        echo "Interface:{$this->interface}\n";
        echo "IP: {$ip}\n";
        echo "Mask: {$mask}\n\n";

        echo "\nConfirm [Yes/No](default=no): ";
        $line = trim(fgets(STDIN));

        $mask = $this->maskConvert(trim($mask));

        if ($this->isYes($line)) {
            //write config
            $this->nextIndex = count($this->currentIPs);
            $this->config['network']['ethernets'][$this->interface]['addresses'][$this->nextIndex] = $ip . '/' . $mask;

            file_put_contents($this->path, $this->yaml->dump($this->config));
            echo "------------------------------\n";
            echo "IP address [${ip}] added successfully!\n";
            echo "------------------------------\n";

            //apply config
            exec('netplan apply');
            sleep(1);
            return $this->configure();
        }
    } elseif ($line <= count($this->currentIPs) && $line !== "0") {
        $this->IPIndex = $line - 1;
        $this->editIP = $this->config['network']['ethernets'][$this->interface]['addresses'][$this->IPIndex];
        echo "IP options: {$this->editIP}\n";
          
        echo "1 --> Delete IP address\n";
        echo "0 --> Return to main menu\n\n";

        echo ">> ";
        $line = trim(fgets(STDIN));


        while (!preg_match("/[^[0|1]$/", $line) || $line === '') {
            echo "Invalid Selection! Please enter a number from the list of availabe options.\n";
            echo "IP options: {$this->editIP}\n";
            
            echo "1 --> Delete IP address\n";
            echo "0 --> Return to main menu\n\n";

            echo ">> ";
            $line = trim(fgets(STDIN));
        }

        if ($line === "1") {
            echo "Delete IP address: {$this->editIP}\n";
            echo "\nConfirm [Yes/No]?(default=no): ";
            $line = trim(fgets(STDIN));
            if ($this->isYes($line)) {
                unset($this->config['network']['ethernets'][$this->interface]['addresses'][$this->IPIndex]);
                $this->config['network']['ethernets'][$this->interface]['addresses'] = array_values($this->config['network']['ethernets'][$this->interface]['addresses']);
                file_put_contents($this->path, $this->yaml->dump($this->config));
                echo "------------------------------\n";
                echo "IP deleted!\n";
                echo "------------------------------\n";
                //apply config
                exec('netplan apply');
                sleep(1);
                return $this->configure();
            }
        } elseif ($line === "0") {
            return $this->configure();
        }
    }
}
if ($line === "3") {
    $gateway = "";

    if (!empty($this->config['network']['ethernets'][$this->interface]['gateway4'])) {
        echo "Current Gateway for this interface is: {$this->config['network']['ethernets'][$this->interface]['gateway4']}\n";
    }

    echo "Please select an option from the list below:\n\n";
    echo "1 --> Add/Change default gateway\n";
    echo "2 --> Delete default gateway\n\n";

    echo "0 --> Return to main menu\n\n";
    echo ">> ";
    $line = trim(fgets(STDIN));

    while (!preg_match("/^[0-2]$/", $line) || $line === '') {
            echo "Invalid Selection! Please enter a number from the list of availabe options.\n";
            echo "Gateway options: \n";
            
            echo "1 --> Add/Change default gateway\n";
            echo "2 --> Delete default gateway\n\n";

            echo "0 --> Return to main menu\n\n";
            echo ">> ";
            $line = trim(fgets(STDIN));
    }
    if ($line === "0") {
        return $this->configure();
    }

    if ($line === "1") {
        while ($gateway == "") {
        echo "Please enter a valid gateway to use (eg: 10.10.0.1): ";
        $line = trim(fgets(STDIN));
            if (filter_var($line, FILTER_VALIDATE_IP)) {
                $gateway = $line;
            }
        }

    $this->config['network']['ethernets'][$this->interface]['gateway4'] = $gateway;
    file_put_contents($this->path, $this->yaml->dump($this->config));
    echo "------------------------------\n";
    echo "Default Gateway updated!\n";
    echo "------------------------------\n";
    //apply config
    exec('netplan apply');
    sleep(1);
    return $this->configure();
    }
    if ($line === "2") {
        unset($this->config['network']['ethernets'][$this->interface]['gateway4']);
        file_put_contents($this->path, $this->yaml->dump($this->config));
        echo "------------------------------\n";
        echo "Default Gateway deleted!\n";
        echo "------------------------------\n";
        //apply config
        exec('netplan apply');
        sleep(1);
        return $this->configure();
    }
}
if ($line === "4") {
    $dns = array();

    if (empty($this->config['network']['ethernets'][$this->interface]['nameservers']['addresses'])) {
        $this->currentDNS = array();
    } else {
        $this->currentDNS = $this->config['network']['ethernets'][$this->interface]['nameservers']['addresses'];
    }

    if (!empty($this->currentDNS)) {
        echo "Current DNS servers: \n";
        $count = 1;
        foreach ($this->currentDNS as $host) {
            echo "{$host}\n";
            $count++;
        }
    }

    while (empty($dns)) {
        echo "\nPlease enter between one and three DNS servers (space seperated): ";
        $line = trim(fgets(STDIN));
        $parts = explode(' ', $line);
        foreach ($parts as $part) {
            if (!filter_var($part, FILTER_VALIDATE_IP)) {
                echo "{$part} is not a valid IP address. Please try again!\n";
                continue 2;
            }
        }
        while (count($parts) > 3) {
            echo "Please enter a MAX of three DNS servers: ";
            continue 2;
        }
        $dns = $parts;
    }
    $this->config['network']['ethernets'][$this->interface]['nameservers']['addresses'] = $dns;
    file_put_contents($this->path, $this->yaml->dump($this->config));
    echo "------------------------------\n";
    echo "DNS servers Updated!\n";
    echo "------------------------------\n";

    //apply config
    exec('netplan apply');
    sleep(1);
    return $this->configure();
}
}
}
