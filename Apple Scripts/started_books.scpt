tell application "iTunes"
    -- Define the playlist name
    set myPlaylistName to "Started Audiobooks"
    
    -- Create the playlist if it doesn't exist
    if not (exists user playlist myPlaylistName) then
        make new user playlist with properties {name:myPlaylistName}
    end if
    
    -- Clear the playlist so we can rebuild it fresh
    delete every track of user playlist myPlaylistName
    
    -- Find audiobooks that have a bookmark (resume point) > 0 but play count is 0
    set startedTracks to (every file track of playlist "Audiobooks" whose bookmark > 0 and played count is 0)
    
    -- Add them to the playlist
    repeat with t in startedTracks
        duplicate t to user playlist myPlaylistName
    end repeat
    
    -- Optional: Desktop notification
    return "Playlist updated with " & (count of startedTracks) & " books."
end tell