tell application "iTunes"
    if it is running then
        updateAllPodcasts
        return "Podcast refresh command sent to iTunes."
    else
        return "iTunes is not currently running. Please open it and try again."
	end
end tell