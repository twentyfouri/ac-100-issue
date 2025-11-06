#!/bin/sh

export LD_LIBRARY_PATH=/mnt/flash/vienna/lib:/mnt/flash/vienna/lib/vienna:$LD_LIBRARY_PATH

VREC_PATH="/mnt/flash/ac100"
SD_MOUNT_PATH="/mnt/sd"
SD_MOUNT_PATH_TMP="/tmp/vrecord/videoclips"
VREC_CONF="vrec_conf.ini"
APP_NAME="kp_firmware_host_stream_app_babycam_audio"
LOG_FILE="/tmp/sd_event.log"

printf "\n\n\n===== auto_sd.sh =====\n\n"

APP_PID=$(pidof "$APP_NAME")

if [ "$ACTION" = "add" ] || [ -b /dev/mmcblk0p1 ]; then
    echo "[auto_sd.sh] SD card inserted" >> "$LOG_FILE"

    mkdir -p "$SD_MOUNT_PATH_TMP"
    mount /dev/mmcblk0p1 "$SD_MOUNT_PATH_TMP"
    mount /dev/mmcblk0p1 "$SD_MOUNT_PATH"

    cd "$VREC_PATH"

    if ps | grep "[v]rec" > /dev/null; then
        printf "\n\n\nvrec is already running. Skipping launch.\n"
    else
        printf "\n\n\nLaunching vrec...\n"
        ./vrec -c "$VREC_CONF" &
    fi

    if [ -n "$APP_PID" ]; then
       kill -44 "$APP_PID"
        echo "[auto_sd.sh] Sent SIGRTMIN (insert) to $APP_NAME (PID=$APP_PID)" >> "$LOG_FILE"
    else
        echo "[auto_sd.sh] $APP_NAME not running. Signal not sent." >> "$LOG_FILE"
    fi

#elif [ "$ACTION" = "remove" ]; then
else
    echo "[auto_sd.sh] SD card removed" >> "$LOG_FILE"

    killall vrec
    umount "$SD_MOUNT_PATH"
    umount "$SD_MOUNT_PATH_TMP"

    if [ -n "$APP_PID" ]; then
        kill -45 "$APP_PID"
        echo "[auto_sd.sh] Sent SIGRTMIN+1 (remove) to $APP_NAME (PID=$APP_PID)" >> "$LOG_FILE"
    else
        echo "[auto_sd.sh] $APP_NAME not running. Signal not sent." >> "$LOG_FILE"
    fi
fi
