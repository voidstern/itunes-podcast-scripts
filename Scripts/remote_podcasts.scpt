tell application "iTunes"
    -- 1. Set a generous timeout (20 minutes) for processing 20k+ items
    with timeout of 1200 seconds
        
        set myPlaylistName to "Not Downloaded"
        
        -- Create/Reset Playlist
        if not (exists user playlist myPlaylistName) then
            make new user playlist with properties {name:myPlaylistName}
        end if
        delete every track of user playlist myPlaylistName
        
        -- 2. STEP ONE: Get all unplayed tracks first.
        -- We removed the "location" check from here to prevent the -1728 error.
        -- This is much faster and safer than a double-condition filter.
        set unplayedTracks to (every track of playlist "Podcasts" whose played count is 0)
        
        set addedCount to 0
        
        -- 3. STEP TWO: Loop through unplayed tracks and check location manually.
        repeat with t in unplayedTracks
            -- We wrap this in a 'try' block in case a specific track is corrupt
            try
                if location of t is missing value then
                    duplicate t to user playlist myPlaylistName
                    set addedCount to addedCount + 1
                end if
            end try
        end repeat
        
        -- 4. OUTPUT: Return the final string to be printed in the terminal
        return "Script finished. Added " & addedCount & " unplayed cloud episodes to playlist."
        
    end timeout
end tell