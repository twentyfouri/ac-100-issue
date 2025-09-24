#!/bin/sh

CONF_FILE="/etc/mdev.conf"
RULE='mmcblk[0-9]* root:root 0660 * /mnt/flash/ac100/auto_sd.sh'

while ! pidof kp_firmware_host_stream_app_babycam_audio > /dev/null; do
    echo "Waiting for kp_firmware_host_stream_app_babycam_audio..."
    sleep 3
done

mount_as_tmpfs /etc

if grep -q "^mmcblk[0-9]*" "$CONF_FILE"; then
    echo "mdev rule already exists. Skipping."
else
    echo "$RULE" >> "$CONF_FILE"
    echo "mdev rule added successfully."
fi

