tell application "iTunes"
	if it is running then
		-- Switch to the Music view to prevent freezing
		try
			reveal playlist "Music"
		end try
		
		updateAllPodcasts
		return "Podcast refresh command sent to iTunes."
	else
		return "iTunes is not currently running. Please open it and try again."
	end if
end tell