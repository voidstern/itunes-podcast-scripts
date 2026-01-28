tell application "iTunes"
    -- We wrap the commands in a timeout block to prevent errors with large libraries
    -- 600 seconds = 10 minutes
    with timeout of 600 seconds
        -- Find podcasts that have a bookmark (resume point) > 0 but play count is 0 
        -- This is the heavy operation that likely caused the timeout
        set startedTracks to (every file track of playlist "Podcasts" whose bookmark > 0 and played count is 0)
        
        -- Add them to the playlist 
        repeat with t in startedTracks
            set grouping of t to "Started"
        end repeat
        
        -- Optional: Desktop notification 
        return "Playlist updated with " & (count of startedTracks) & " podcasts."
        
    end timeout
end tell