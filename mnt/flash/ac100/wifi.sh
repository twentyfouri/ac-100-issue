#!/bin/bash

# Set variables
DRIVER_PATH="/mnt/flash/vienna/drivers/8723du.ko"
WPA_CONF="/mnt/flash/ac100/wpa.conf"
NFS_SERVER="192.168.3.21"
NFS_SHARE="/home/a/nfsfile"
NFS_MOUNT_POINT="/mnt/flash/tranwo"
WLAN_INTERFACE="wlan0"
DNS_SERVER="192.168.3.1"
MAX_RETRIES=2
RETRY_DELAY=5
TIMEOUT=15
TEMP_DIR="/tmp"
DEFAULT_SSID="tranwoDemo"
DEFAULT_PSK="12345678"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

# Function: Check the result of command execution
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        return 1
    fi
    return 0
}

# Function to execute with a timeout
run_with_timeout() {
    local timeout=$1
    local start_time=$(date +%s)
    local cmd_pid

    shift
    "$@" &
    cmd_pid=$!

    while kill -0 $cmd_pid 2>/dev/null; do
        if [ $(($(date +%s) - start_time)) -ge $timeout ]; then
            kill -9 $cmd_pid 2>/dev/null
            wait $cmd_pid 2>/dev/null
            return 124
        fi
        sleep 0.1
    done

    wait $cmd_pid
    return $?
}

# Configure network settings
configure_network() {
    echo "Configuring network settings..."
    
    # Delete default routes if they exist
    echo "Deleting existing default routes..."
    ip route del default 2>/dev/null
    
    # Add DNS server
    echo "Adding DNS server $DNS_SERVER..."
    echo "nameserver $DNS_SERVER" > /etc/resolv.conf
    
    # Flush the route cache
    ip route flush cache
}

# Handle WiFi configuration
handle_wifi_config() {
    if [ "$#" -eq 2 ]; then
        NEW_SSID="$1"
        NEW_PSK="$2"
        echo "Using temporary WiFi configuration with provided credentials:"
        echo "SSID: \"$NEW_SSID\""
        echo "PSK: \"$NEW_PSK\""

        TEMP_WPA_CONF="${TEMP_DIR}/wpa_temp_$$.conf"
        cat <<EOF > "$TEMP_WPA_CONF"
ctrl_interface=/var/run/wpa_supplicant
update_config=0
network={
    ssid="$NEW_SSID"
    psk="$NEW_PSK"
    key_mgmt=WPA-PSK
}
EOF
        WPA_CONF="$TEMP_WPA_CONF"
    elif [ "$1" == "def" ]; then
        echo "Using default WiFi credentials:"
        echo "SSID: \"$DEFAULT_SSID\""
        echo "PSK: \"$DEFAULT_PSK\""

        TEMP_WPA_CONF="${TEMP_DIR}/wpa_temp_$$.conf"
        cat <<EOF > "$TEMP_WPA_CONF"
ctrl_interface=/var/run/wpa_supplicant
update_config=0
network={
    ssid="$DEFAULT_SSID"
    psk="$DEFAULT_PSK"
    key_mgmt=WPA-PSK
}
EOF
        WPA_CONF="$TEMP_WPA_CONF"
    else
        echo "Using existing $WPA_CONF for WiFi connection."
    fi
}

# Main script execution
handle_wifi_config "$@"

# Load the WiFi driver
echo "Loading WiFi driver..."
insmod "$DRIVER_PATH" rtw_drv_log_level=2

cd /mnt/flash/ac100
./urcmd 0200

# Configure network settings
configure_network

# Connect to WiFi
i=1
while [ $i -le $((MAX_RETRIES + 1)) ]; do
    echo "Attempt $i of $((MAX_RETRIES + 1)): Connecting to WiFi..."
    
    killall wpa_supplicant 2>/dev/null
    killall udhcpc 2>/dev/null
    sleep 1

    if ! run_with_timeout $TIMEOUT wpa_supplicant -Dwext -i"$WLAN_INTERFACE" -c"$WPA_CONF" -B; then
        echo "wpa_supplicant timeout or failed"
        if [ $i -gt $MAX_RETRIES ]; then
            echo "Error: Max retries reached for wpa_supplicant."
            cd /mnt/flash/ac100/
            ./urcmd 0201
            [ "$#" -ne 0 ] && rm -f "$TEMP_WPA_CONF"
            exit 1
        fi
        sleep $RETRY_DELAY
        i=$((i+1))
        continue
    fi

    if ! run_with_timeout $TIMEOUT udhcpc -i "$WLAN_INTERFACE"; then
        echo "udhcpc timeout or failed"
        if [ $i -gt $MAX_RETRIES ]; then
            echo "Error: Max retries reached for udhcpc."
            [ "$#" -ne 0 ] && rm -f "$TEMP_WPA_CONF"
            exit 1
        fi
        sleep $RETRY_DELAY
        i=$((i+1))
        continue
    fi

    echo "WiFi connection established successfully"
    break
done

# Verify network connectivity
echo "Verifying network connectivity..."
if ! ping -c 3 "$DNS_SERVER" >/dev/null 2>&1; then
    echo "ERROR: Cannot reach DNS server $DNS_SERVER"
    exit 1
fi

if ! ping -c 3 "$NFS_SERVER" >/dev/null 2>&1; then
    echo "ERROR: Cannot reach NFS server $NFS_SERVER"
    exit 1
fi

# Mount NFS with retries
echo "Mounting NFS share..."
i=1
while [ $i -le $MAX_RETRIES ]; do
    mount -t nfs -o nolock "$NFS_SERVER:$NFS_SHARE" "$NFS_MOUNT_POINT"
    if [ $? -eq 0 ]; then
        break
    fi
    echo "NFS mount attempt $i failed, retrying in $RETRY_DELAY seconds..."
    sleep $RETRY_DELAY
    i=$((i+1))
done

if mountpoint -q "$NFS_MOUNT_POINT"; then
    echo "Wi-Fi connection setup complete, NFS connected."
else
    echo "ERROR: NFS mount failed after $MAX_RETRIES attempts!"
    echo "Possible solutions:"
    echo "1. Verify NFS server is running"
    echo "2. Check export permissions on server"
    echo "3. Verify network connectivity to $NFS_SERVER"
    exit 1
fi

# Clean up
[ "$#" -ne 0 ] && rm -f "$TEMP_WPA_CONF"

cd /mnt/flash/ac100/
sh time_sync.sh
./urcmd 0211

exit 0
