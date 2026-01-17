tell application "iTunes"
    if exists playlist "Deletable" then
        -- Get the total count first
        set totalTracks to count of tracks of playlist "Deletable"
        set successCount to 0
        
        -- Loop BACKWARDS from the last track to the first
        -- This prevents the 'shifting index' problem when tracks disappear
        repeat with i from totalTracks to 1 by -1
            try
                -- Reference the track by its current index
                set thisTrack to track i of playlist "Deletable"
                
	                -- Check if it needs updating
	            set unplayed of thisTrack to false
				set played count of thisTrack to 1
	            set successCount to successCount + 1
            on error errMsg
                -- If a track fails, log it but keep going
                log "Error on track " & i & ": " & errMsg
            end try
        end repeat
        
        -- Notification
        display notification "Updated " & successCount & " of " & totalTracks & " episodes." with title "iTunes Script"
        
    else
        -- Notification
        display notification "Playlist 'Deletable' could not be found."
    end if
end tell