#!/bin/bash

#######
#Jamf Blacklist Enforcer
#Author: darixn
#######


# JSON file path
json_file="/Library/Application Support/JAMF/.jmf_settings.json"

# Debug flag (set to 1 to enable debugging, 0 to disable)
debug=0

# Extract the number of objects in the blacklist array
num_objects=$(plutil -extract blacklist raw -o - "$json_file")
echo "Number of blacklist entries: $num_objects"

# Logic to Iterate over each index in the blacklist array handles /desktop /applications /downloads 
for ((i=0; i<num_objects; i++)); do
    # Extract the 'process' field for the current index
    process=$(plutil -extract "blacklist.$i.process" raw -o - "$json_file")
    if [ "$debug" -eq 1 ]; then
        echo "Read entry $i process: $process"
    fi

    # Extract the 'shouldDelete' field for the current index
    should_delete=$(plutil -extract "blacklist.$i.shouldDelete" raw -o - "$json_file")

    # If 'shouldDelete' is true
    if [ "$should_delete" = "true" ]; then
        # Check if the process name ends with .app
        if [[ ! "$process" =~ \.app$ ]]; then
            process="$process.app"
        fi

#Set Function check file path for file type  
check_and_delete() {
    local file_path="$1"
    local file_type="$2"

    if [ -e "$file_path" ]; then
        echo "Deleting $file_path..."
        # Uncomment the next line to actually delete the file
        rm -rf "$file_path"
    else
        if [ "$debug" -eq 1 ]; then
            echo "$file_type file $file_path not found in Downloads."
        fi
    fi
    }

        # Define paths
        downloads_path="$HOME/Downloads"
        base_name="${process%.app}" # Remove .app if it was appended

        user_app_path="$HOME/Applications/$process"
        app_path="/Applications/$process"
        desktop_path="$HOME/Desktop/$process"
        downloads_path="$HOME/Downloads/$process"
        dmg_path="$HOME/Downloads/$base_name.dmg"
        pkg_path="$HOME/Downloads/$base_name.pkg"
        installer_dmg_path="$HOME/Downloads/${base_name}_Installer.dmg"
        installer_pkg_path="$HOME/Downloads/${base_name}_Installer.pkg"
        install_dmg_path="$HOME/Downloads/Install ${base_name}.dmg"
        install_pkg_path="$HOME/Downloads/Install ${base_name}.pkg"

        # Check and delete files
        check_and_delete "$app_path" ".app"
        check_and_delete "$user_app_path" ".app"
        check_and_delete "$desktop_path" ".app"
        check_and_delete "$downloads_path" ".app"
        check_and_delete "$dmg_path" ".dmg"
        check_and_delete "$pkg_path" ".pkg"
        check_and_delete "$installer_dmg_path" ".dmg (installer)"
        check_and_delete "$installer_pkg_path" ".pkg (installer)"
        check_and_delete "$install_dmg_path" ".dmg (install)"
        check_and_delete "$install_pkg_path" ".pkg (install)"
            fi
        done
