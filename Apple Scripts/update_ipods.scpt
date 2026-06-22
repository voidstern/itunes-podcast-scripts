tell application "iTunes"
	if it is running then
		set updatedCount to 0
		
		with timeout of 36000 seconds
			repeat with deviceSource in sources
				if kind of deviceSource is iPod then
					update deviceSource
					set updatedCount to updatedCount + 1
				end if
			end repeat
		end timeout
		
		if updatedCount is 0 then
			return "No connected iPods found."
		else if updatedCount is 1 then
			return "Sync command sent to 1 connected iPod."
		else
			return "Sync commands sent to " & updatedCount & " connected iPods."
		end if
	else
		return "iTunes is not currently running. Please open it and try again."
	end if
end tell
