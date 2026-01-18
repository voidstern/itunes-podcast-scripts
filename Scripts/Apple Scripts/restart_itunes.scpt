tell application "iTunes"
    -- 1. GRACEFUL QUIT
    if it is running then
        quit
    end if
end tell

-- 2. WAIT LOOP (Crucial for database integrity)
-- iTunes needs time to write the .itl file to disk. 
-- We wait up to 30 seconds for the process to vanish.
repeat 30 times
    tell application "System Events"
        if not (exists process "iTunes") then exit repeat
    end tell
    delay 1
end repeat

-- 3. RELAUNCH
tell application "iTunes"
    launch -- 'launch' runs it in background, 'activate' brings to front. 
    -- Use 'activate' if you want it to pop up, 'launch' if you want it hidden.
    activate 
end tell

-- Give it a moment to load the library file
delay 10

-- 4. THE "TOUCH" TRICK
-- We iterate through playlists and ask for a property (count).
-- This forces iTunes to calculate the list contents immediately.
tell application "iTunes"
    try
        set allSmartPlaylists to (every user playlist whose smart is true)
        
        repeat with currentPlaylist in allSmartPlaylists
            -- Simply accessing the count forces the 'Live Update' logic 
            -- to run once for the session.
            set trackCount to (count of tracks of currentPlaylist)
        end repeat
        
    on error errMsg
        -- Optional: Log errors to a file if needed
    end try
end tell