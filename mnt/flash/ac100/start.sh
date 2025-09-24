#!/bin/sh
mkdir -p /tmp/venc/c0/;
mkdir -p /tmp/aenc/c0/;
mkdir -p /tmp/playback/c0/;
mkdir -p /tmp/twoway/c0/;
mkdir -p /tmp/sr/c0/;
mkdir -p /tmp/vrecord/videoclips/;
#export LD_LIBRARY_PATH=$(pwd)/../lib;

export LD_LIBRARY_PATH=/mnt/flash/vienna/lib:/mnt/flash/vienna/lib/vienna:$LD_LIBRARY_PATH

sleep 1
./rtsps -c stream_server_config.ini &

sleep 1
./kp_firmware_host_stream_app_babycam_audio &

# sleep 10;
# mount /dev/mmcblk0p1 /tmp/vrecord/videoclips/
# ./vrec -c vrec_conf.ini &

