tell application "iTunes"
    with timeout of 86400 seconds
        try
            -- 1. Calculate the cutoff time (Current Time - 24 Hours)
            set currentDate to (current date)
            set cutoffDate to currentDate - (3 * 60 * 60) -- 24 hours in seconds
            
            -- 2. Find tracks: Media Kind is 'Podcast' AND Added Date is recent
            set recentPodcasts to (every file track whose media kind is podcast and date added is greater than cutoffDate)
            
            set totalCount to count of recentPodcasts
            
            if totalCount is 0 then
                return "No podcasts added in the last 24 hours."
            end if
            
            -- 3. Loop through the recent tracks
            repeat with aTrack in recentPodcasts
                
                -- THE TRICK: Force a database write by toggling the 'start' time.
                set originalStart to start of aTrack
                
                -- Bump start time by 1 second
                set start of aTrack to (originalStart + 1)
                
                -- Revert immediately
                set start of aTrack to originalStart
                
                -- 4. Refresh to read the new file duration
                refresh aTrack
                
            end repeat
            
            return "Success: Updated " & totalCount & " recent podcast(s)."
            
        on error errMsg
            return "Error: " & errMsg
        end try
	end timeout
end tell