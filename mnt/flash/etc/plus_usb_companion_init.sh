#!/bin/sh
flash_folder="/mnt/flash/"

echo "flash boot"
#The default setting of ie, npu are kernel built-in
#Insert modules for debug purpose if you need and you have built the driver modules
if [ -f "$flash_folder/plus/drivers/vtx-ie.ko" ]; then
  echo "init ie"
  insmod $flash_folder/plus/drivers/vtx-ie.ko
fi
if [ -f "$flash_folder/plus/drivers/vtx-npu.ko" ]; then
  echo "init npu"
  insmod $flash_folder/plus/drivers/vtx-npu.ko
fi
echo "init usb"
cd $flash_folder/plus/usb_init_data;
. ./init_usb_device_kl630.sh
echo "kp_daemon start"
$flash_folder/plus/kp_daemon/bin/kp_daemon&