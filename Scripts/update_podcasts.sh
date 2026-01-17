#!/bin/bash

# Script to refresh all podcasts in iTunes on macOS Mojave
# This uses AppleScript to trigger the update command within iTunes.

echo "Connecting to iTunes..."

osascript <<EOD
tell application "iTunes"
    if it is running then
        updateAllPodcasts
        return "Podcast refresh command sent to iTunes."
    else
        return "iTunes is not currently running. Please open it and try again."
	end
end tell
EOD