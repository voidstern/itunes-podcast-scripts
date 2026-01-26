tell application "iTunes"
	-- Wrap the entire operation in a 12-hour timeout block to prevent error -1712
	with timeout of 43200 seconds
		try
			-- 1. Find all unplayed podcasts in the main library
			set tracksToProcess to (every track of library playlist 1 whose media kind is podcast and unplayed is true)
			
			set procCount to count of tracksToProcess
			set failCount to 0 -- Initialize a counter for failed tracks
			
			-- Check if we found anything before asking
			if procCount is 0 then
				return "No unplayed podcasts found."
			end if
			
			-- 2. Add Confirmation Dialog
			display dialog "Found " & procCount & " unplayed podcasts." & return & return & ¬
				"This operation will take a significant amount of time." & return & ¬
				"To prevent timeouts, a 12-hour limit has been set." & return & return & ¬
				"Do you want to continue?" with title "Refresh Unplayed Podcasts" buttons {"Cancel", "Start Refresh"} default button "Start Refresh" with icon caution
			
			-- 3. Loop through the found podcasts
			repeat with aTrack in tracksToProcess
				
				-- CRITICAL CHANGE: Inner try block catches errors per track
				try
					-- THE TRICK: Force a database write by toggling the 'start' time.
					set originalStart to start of aTrack
					
					-- Change start to 1 second (or original + 1)
					set start of aTrack to (originalStart + 1)
					
					-- revert immediately
					set start of aTrack to originalStart
					
					-- Finally, refresh to read the new file duration
					refresh aTrack
					
				on error
					-- If "End of file" or other error occurs, increment failure count but DO NOT STOP
					set failCount to failCount + 1
				end try
				
			end repeat
			
			-- 4. Report results
			set successCount to procCount - failCount
			if failCount is greater than 0 then
				return "Completed with skipped files. Updated: " & successCount & ". Failed/Skipped: " & failCount & "."
			else
				return "Success: Updated " & procCount & " unplayed podcast(s)."
			end if
			
		on error errMsg number errNum
			-- Handle "User Canceled" (error -128) gracefully
			if errNum is -128 then
				return "Operation canceled by user."
			else
				return "Critical Error: " & errMsg
			end if
		end try
	end timeout
end tell