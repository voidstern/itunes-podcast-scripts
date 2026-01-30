tell application "iTunes"
	-- We wrap the commands in a timeout block to prevent errors with large libraries
	-- 600 seconds = 10 minutes
	with timeout of 600 seconds
		-- Find audiobooks that have a bookmark (resume point) > 0 but play count is 0
		set startedTracks to (every file track of playlist "Audiobooks" whose bookmark > 0 and played count is 0)
		
		-- Set grouping to "Started"
		repeat with t in startedTracks
			set grouping of t to "Started"
		end repeat
		
		-- Optional: Desktop notification
		return "Updated grouping for " & (count of startedTracks) & " books."
	end timeout
end tell