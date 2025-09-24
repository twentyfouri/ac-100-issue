#!/bin/sh

export LD_LIBRARY_PATH=/mnt/flash/vienna/lib:/mnt/flash/vienna/lib/vienna:$LD_LIBRARY_PATH

VREC_PATH="/mnt/flash/ac100"
SD_MOUNT_PATH="/mnt/sd"
VREC_CONF="vrec_conf.ini"

printf "\n\n\n===== auto_sd.sh =====\n\n"

if [ "$ACTION" = "add" ] || [ -b /dev/mmcblk0p1 ]; then
    mkdir -p /tmp/vrecord/videoclips/
    mount /dev/mmcblk0p1 /tmp/vrecord/videoclips
    mount /dev/mmcblk0p1 "$SD_MOUNT_PATH"
    cd "$VREC_PATH"

    if ps | grep "[v]rec" > /dev/null; then
        printf "\n\n\nvrec is already running. Skipping launch.\n"
    else
        printf "\n\n\nLaunching vrec...\n"
        ./vrec -c "$VREC_CONF" &
    fi

elif [ "$ACTION" = "remove" ]; then
    killall vrec
    umount "$SD_MOUNT_PATH"
fi
