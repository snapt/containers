#!/bin/bash -e

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

curl --output snapt_fw.tar.gz https://shop.snapt.net/pluginAPI.php?task=getFramework

mkdir fw_update

tar -xvf ./resources/snapt_files.tar.gz -C ./fw_update

mv snapt_fw.tar.gz ./fw_update

rm -rf ./resources/snapt_files.tar.gz

cd fw_update/ && tar -cvzf ../resources/snapt_files.tar.gz . && cd ..

rm -rf ./fw_update
