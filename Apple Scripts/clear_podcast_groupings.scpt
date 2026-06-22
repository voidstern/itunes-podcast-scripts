tell application "iTunes"
    -- We wrap the commands in a timeout block to prevent errors with large libraries
    -- 600 seconds = 10 minutes
    with timeout of 600 seconds
        set podcastTracks to (every file track of playlist "Podcasts")
        set clearedCount to 0
        
        repeat with t in podcastTracks
            if grouping of t is not "" then
                set grouping of t to ""
                set clearedCount to clearedCount + 1
            end if
        end repeat
        
        return "Cleared grouping for " & clearedCount & " podcasts."
    end timeout
end tell
