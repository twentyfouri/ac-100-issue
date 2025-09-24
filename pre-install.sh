#!/bin/sh

touch "/mnt/flash/ac100/pre-install"

xzcat /tmp/ac100-firmware.tar.xz | tar xf - -C /tmp nand-env
if [ -f /tmp/nand-env ]; then
        /usr/sbin/flash_erase /dev/mtd1 0 0
        /usr/sbin/nandwrite -p /dev/mtd1 /tmp/nand-env
        echo writing env done
fi
