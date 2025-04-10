#!/bin/bash
# ============================================================
# Script Name: toggleWiFiOnEthernet.sh
# Description: This script automatically toggles the Wi-Fi 
#              (AirPort) status on macOS based on the 
#              Ethernet connection status. If Ethernet is 
#              connected, Wi-Fi is turned off. If Ethernet 
#              is disconnected, Wi-Fi is enabled.
#
# Author: Darixn (https://github.com/darixn)
# Based on the work : https://gist.github.com/albertbori/1798d88a93175b9da00b
#
# Created: Dec2024
# Last Modified: Dec2024
#
# Version: 1.0.0
# License: MIT (or any applicable license)
#
# 
#
# Usage:
# This script is intended ran from an MDM to be run by the logged-in user on macOS
# and can be loaded as a LaunchAgent to run automatically.
#
# Notes:
# - The script will create a LaunchAgent to monitor Ethernet status
#   and toggle the Wi-Fi accordingly.
# - A notification will be displayed to the user whenever the
#   network status changes.
# ============================================================


# Get the logged-in user
LOGGED_IN_USER=$(stat -f "%Su" /dev/console)

# Exit if no user is logged in
if [ "$LOGGED_IN_USER" == "root" ] || [ -z "$LOGGED_IN_USER" ]; then
    echo "No user logged in. Exiting."
    exit 1
fi

# Get the logged-in user's home directory
USER_HOME=$(eval echo ~$LOGGED_IN_USER)

# Variables
SCRIPT_PATH="$USER_HOME/Library/Scripts/toggleAirport.sh"
PLIST_PATH="$USER_HOME/Library/LaunchAgents/com.xxxx.toggleairport.plist"
PLIST_LABEL="com.xxxx.toggleairport"

# Function to write the toggleAirport script
write_toggle_airport_script() {
    mkdir -p "$USER_HOME/Library/Scripts"
    cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash

# Function to enable or disable the AirPort/Wi-Fi adapter
function set_airport {
    new_status=$1

    if [ $new_status = "On" ]; then
        # Enable AirPort/Wi-Fi
        /usr/sbin/networksetup -setairportpower $air_name on
        # Record the state by creating a temporary file
        touch /var/tmp/prev_air_on
    else
        # Disable AirPort/Wi-Fi
        /usr/sbin/networksetup -setairportpower $air_name off
        # Remove the temporary file if it exists
        if [ -f "/var/tmp/prev_air_on" ]; then
            rm /var/tmp/prev_air_on
        fi
    fi
}

# Initialize default values for network statuses
prev_eth_status="Off"   # Previous Ethernet status
prev_air_status="Off"   # Previous AirPort/Wi-Fi status
eth_status="Off"        # Current Ethernet status

# Get the names of Ethernet adapters (assumed to end with "Ethernet" or include "Dock")
eth_names=$(networksetup -listnetworkserviceorder | sed -En 's/^\(Hardware Port: .*(Ethernet|LAN).*, Device: (en.+)\)$/\2/pI')

# Get the name of the AirPort/Wi-Fi adapter
air_name=$(networksetup -listnetworkserviceorder | sed -En 's/^\(Hardware Port: (Wi-Fi|AirPort), Device: (en.+)\)$/\2/p')

# Determine the previous Ethernet status by checking if a temporary file exists
if [ -f "/var/tmp/prev_eth_on" ]; then
    prev_eth_status="On"
fi

# Determine the previous AirPort/Wi-Fi status
if [ -f "/var/tmp/prev_air_on" ]; then
    prev_air_status="On"
fi

# Check the current Ethernet status for each detected adapter
for eth_name in ${eth_names}; do
    if ([ "$eth_name" != "" ] && [ "$(ifconfig $eth_name | grep "status: active")" != "" ]); then
        eth_status="On"
        break
    fi
done

# Check the current AirPort/Wi-Fi status
air_status=$(/usr/sbin/networksetup -getairportpower $air_name | awk '{ print $4 }')

# If there is a change in the status of Ethernet or AirPort/Wi-Fi
if [ "$prev_air_status" != "$air_status" ] || [ "$prev_eth_status" != "$eth_status" ]; then
    # Handle Ethernet status change
    if [ "$prev_eth_status" != "$eth_status" ]; then
        if [ "$eth_status" = "On" ]; then
            # If Ethernet is connected, turn off AirPort/Wi-Fi
            set_airport "Off"
            osascript -e "display notification \"Wired network detected. Turning AirPort off.\" with title \"Wi-Fi Toggle\" sound name \"Hero\""
        else
            # If Ethernet is disconnected, turn on AirPort/Wi-Fi
            set_airport "On"
            osascript -e "display notification \"No wired network detected. Turning AirPort on.\" with title \"Wi-Fi Toggle\" sound name \"Hero\""
        fi
    else
        # Check for manual AirPort/Wi-Fi status changes by the user
        if [ "$prev_air_status" != "$air_status" ]; then
            set_airport $air_status
            if [ "$air_status" = "On" ]; then
                #echo "display notification \"Wi-Fi manually turned on.\" with title \"Wi-Fi Toggle\" sound name \"Hero\""
            else
                #echo "display notification \"Wi-Fi manually turned off.\" with title \"Wi-Fi Toggle\" sound name \"Hero\""
            fi
        fi
    fi

    # Update the temporary file for Ethernet status
    if [ "$eth_status" == "On" ]; then
        touch /var/tmp/prev_eth_on
    else
        # Remove the temporary file if Ethernet is disconnected
        if [ -f "/var/tmp/prev_eth_on" ]; then
            rm /var/tmp/prev_eth_on
        fi
    fi
fi

exit 0
EOF

    chmod +x "$SCRIPT_PATH"
}

# Function to write the LaunchAgent plist
write_launch_agent_plist() {
    mkdir -p "$USER_HOME/Library/LaunchAgents"
    cat << EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$PLIST_LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$SCRIPT_PATH</string>
  </array>
  <key>WatchPaths</key>
  <array>
    <string>/Library/Preferences/SystemConfiguration</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

    chmod 644 "$PLIST_PATH"
    chown "$LOGGED_IN_USER:wheel" "$PLIST_PATH"
}

# Main logic
write_toggle_airport_script
write_launch_agent_plist

# Load the LaunchAgent as the logged-in user
sudo -u "$LOGGED_IN_USER" launchctl unload "$PLIST_PATH" 2>/dev/null
sudo -u "$LOGGED_IN_USER" launchctl load "$PLIST_PATH"

echo "Wi-Fi toggle script and LaunchAgent have been installed and activated for user $LOGGED_IN_USER."

exit 0
