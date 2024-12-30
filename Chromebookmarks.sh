#!/bin/bash
####################################################################
# Created: August 3, 2023
# Author: Darian Garcia 
# Created to assist with bookmark backups 
# Prerequists JAMF Helper. 
####################################################################

# Source and destination paths
chrome_profile_dir="$HOME/Library/Application Support/Google/Chrome/Default"
bookmark_file="$chrome_profile_dir/Bookmarks"
destination_dir="$HOME/Desktop/Chrome_Backups"
backup_file="$destination_dir/Bookmarks_backup.json"

# Get the username of the currently logged in user 
loggedInUser=$(/bin/ls -la /dev/console | /usr/bin/cut -d ' ' -f 4)
#echo current logged in user
echo "<result>$loggedInUser</result>"

# This pulls current user to scope the path of the brandingimage
currentUser=$(/bin/echo 'show State:/Users/ConsoleUser' | /usr/sbin/scutil | /usr/bin/awk '/Name / { print $3 }')
# This will set a variable for the jamfHelper
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# Window Type picks out how it is presented. Note: Your choices include utility, hud or fs
windowType="utility"
# Note: This can be BASE64, a Local File or a URL. If a URL the file needs to curl down prior to jamfHelper
icon="/Users/$currentUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
# "Window Title"
title="Chrome Backup Utility"
# "Window Heading"
heading="Backup Utility"
# "Window Message"
description="Utility to pull your Chrome Profile for troubleshooting."

# Second "Window Message"
descriptionno="Files have been pulled for : $loggedInUser  

please reinstall chrome before porting back"

# Second "Window Message"
descriptionno2="Bookmarks have been Restored!"

# "Button1"
button1="Backup"
# "Button1no"
button1no="Close"
# "Button2"
button2="Restore"

userChoice=$("$jamfHelper" -windowType "$windowType" -icon "$icon" -title "$title" -heading "$heading" -description "$description" -button1 "$button1" -button2 "$button2" -defaultButton 1 -cancelButton 2)
if [[ "$userChoice" == "0" ]]; then
    # Actions for Button 1 Go Here
    # Check if the bookmarks file exists
    if [ -f "$bookmark_file" ]; then
        # Create the destination directory if it doesn't exist
        mkdir -p "$destination_dir"
        # Use jq to format the bookmarks file and save it to the backup file
        jq . "$bookmark_file" > "$backup_file"
        echo "Bookmarks backed up to Desktop successfully."
    else
        echo "Bookmarks file not found in Chrome profile directory."
    fi
    "$jamfHelper" -windowType "$windowType" -icon "$icon" -title "$title" -heading "$heading" -description "$descriptionno" -button1 "$button1no" -defaultButton 1
else
    # Actions for Button 2 Go Here
    if [ -f "$backup_file" ]; then
        # Restore the bookmarks file from the backup
        cp "$backup_file" "$bookmark_file"
        echo "Bookmarks restored successfully."
    else
        echo "Backup file not found on Desktop."
    fi
    "$jamfHelper" -windowType "$windowType" -icon "$icon" -title "$title" -heading "$heading" -description "$descriptionno2" -button1 "$button1no" -defaultButton 1
fi

exit 0
