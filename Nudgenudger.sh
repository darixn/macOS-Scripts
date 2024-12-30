#!/bin/bash
# ============================================================
# Script Name: Nudgenudger.sh
# Description: Sometimes a nudge isnt enough, therefore you must supplement it to force it show update. 
#
# Author: Darixn (https://github.com/darixn)
# Inspired by: https://gist.github.com/albertbori/1798d88a93175b9da00b
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
# Made to function with https://github.com/macadmins/nudge
# Current WF manually deploy to user whom is unable to pull latest OS .
# ============================================================

# Check for software updates
echo "Checking for software updates..."
softwareupdate -l

# Open the System Preferences System Update page
echo "Opening System Preferences to System Update page..."
open "x-apple.systempreferences:com.apple.preferences.softwareupdate"
