tell application "iTunes"
    -- We wrap the commands in a timeout block to prevent errors with large libraries
    -- 600 seconds = 10 minutes
    with timeout of 600 seconds
        set podcastTracks to (every file track of playlist "Podcasts" whose grouping is not equal to "")
        set clearedCount to count of podcastTracks
        
        repeat with t in podcastTracks
            set grouping of t to ""
        end repeat
        
        return "Cleared grouping for " & clearedCount & " podcasts."
    end timeout
end tell
