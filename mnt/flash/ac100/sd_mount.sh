#!/bin/bash

CHECK_INTERVAL=1
VREC_CMD="./vrec -c vrec_conf.ini"
VREC_PATH="/mnt/flash/ac100"
LIB_PATH="/mnt/flash/vienna/lib:/mnt/flash/vienna/lib/vienna"
SD_DEV="/dev/mmcblk0p1"
SD_MOUNT="/tmp/vrecord/videoclips"

#cd /mnt/flash/ac100
#insmod motor_control.ko
#./urcmd 0210
#insmod /mnt/flash/vienna/drivers/8723du-250701.ko rtw_drv_log_level=2

export LD_LIBRARY_PATH="$LIB_PATH:$LD_LIBRARY_PATH"

sleep 30;
#cd "$VREC_PATH"
#$VREC_CMD &
#vrec_pid=$!
echo "$(date) - ****************************************************************************************************"

while true; do
    if [ -e "$SD_DEV" ]; then
        echo "$(date) - SD card detected."

        # Mount SD card
        mount "$SD_DEV" "$SD_MOUNT"
        mount "$SD_DEV" /mnt/sd
        echo "$(date) - SD card mounted at $SD_MOUNT"

        # Check if vrec is already running
        if ! pgrep -f "$VREC_CMD" > /dev/null; then
            echo "$(date) - vrec not running. Starting..."
	    mkdir -p /tmp/vrecord/videoclips/
            echo "$(date) - Created /tmp/vrecord/videoclips/"
            cd "$VREC_PATH"
            $VREC_CMD &
            vrec_pid=$!
            echo "$(date) - vrec started with PID $vrec_pid"
        else
            echo "$(date) - vrec already running. Skipping launch."
        fi

        # Monitor SD presence
        while [ -e "$SD_DEV" ] && mountpoint -q "$SD_MOUNT"; do
            sleep $CHECK_INTERVAL
        done

        # SD removed
        echo "$(date) - SD card removed. Unmounting and stopping vrec..."
        umount "$SD_MOUNT"
        umount /mnt/sd

        # Kill vrec if running
	pids=$(ps | grep "vrec" | grep -v "grep" | awk '{print $1}')

	if [ -n "$pids" ]; then
	  echo "Killing vrec process(es): $pids"
	  kill -9 $pids
	else
	  echo "No vrec process found."
	fi
    fi

    sleep $CHECK_INTERVAL
done
