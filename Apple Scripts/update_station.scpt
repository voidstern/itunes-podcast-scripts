use AppleScript version "2.4"
use scripting additions

on run {targetPlaylistName, simpleData}
    
    -- 1. Setup Target Playlist
    tell application "iTunes"
        if not (exists playlist targetPlaylistName) then
            make new user playlist with properties {name:targetPlaylistName}
        else
            delete every track of playlist targetPlaylistName
        end if
    end tell
    
    -- 2. Process Lines
    set podcastLines to paragraphs of simpleData
    
    repeat with aLine in podcastLines
        set currentLine to contents of aLine
        -- Ignore empty lines
        if length of currentLine > 0 then
            my processPodcastLine(currentLine, targetPlaylistName)
        end if
    end repeat
    
end run

on processPodcastLine(aLine, playlistName)
    -- Supported Formats: 
    -- "Name|Count" -> Specific count
    -- "Name|"      -> All episodes (0)
    -- "Name"       -> All episodes (0)
    
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to "|"
    
    set pName to ""
    set pCount to 0
    
    set lineParts to text items of aLine
    
    -- PARSING LOGIC
    if (count of lineParts) > 1 then
        -- We have a pipe
        set pName to item 1 of lineParts
        set rawCount to item 2 of lineParts
        
        if length of rawCount > 0 then
            try
                set pCount to rawCount as integer
            on error
                set pCount to 0 -- Default to All if parsing fails
            end try
        else
            set pCount to 0 -- Pipe existed but was empty "Name|"
        end if
    else
        -- No pipe found "Name"
        set pName to aLine
        set pCount to 0
    end if
    
    set AppleScript's text item delimiters to oldDelims
    
    -- Validation: prevent processing if name is somehow empty
    if length of pName is 0 then return
    
    -- 3. Get Unplayed Tracks
    set unplayedTracks to {}
    tell application "iTunes"
        try
            set unplayedTracks to (every track of library playlist 1 whose genre is "Podcast" and album is pName and unplayed is true)
        on error errMsg
            log "Error searching '" & pName & "': " & errMsg
        end try
    end tell
    
    if unplayedTracks is {} then return
    
    -- 4. Sort safely
    set sortedTracks to my sortTracksByDateSafe(unplayedTracks)
    
    -- 5. Slice List
    set tracksToAdd to {}
    set totalFound to count of sortedTracks
    
    if pCount is 0 then
        set tracksToAdd to sortedTracks
    else
        if totalFound < pCount then
            set tracksToAdd to sortedTracks
        else
            set tracksToAdd to items 1 through pCount of sortedTracks
        end if
    end if
    
    -- 6. Add to Playlist
    tell application "iTunes"
        try
            repeat with tr in tracksToAdd
                duplicate tr to playlist playlistName
            end repeat
        on error errMsg
            log "Error adding tracks: " & errMsg
        end try
    end tell
    
end processPodcastLine

on sortTracksByDateSafe(trackList)
    set listCount to count of trackList
    if listCount < 2 then return trackList
    
    set sortableList to {}
    
    -- Extract Dates
    tell application "iTunes"
        repeat with tr in trackList
            try
                set rDate to release date of tr
                if rDate is missing value then set rDate to (current date)
            on error
                set rDate to (current date)
            end try
            set end of sortableList to {trackObj:tr, rDate:rDate}
        end repeat
    end tell
    
    -- Bubble Sort (Oldest First)
    repeat with i from 1 to listCount - 1
        repeat with j from 1 to listCount - i
            
            set nextIndex to j + 1
            
            set itemA to item j of sortableList
            set itemB to item nextIndex of sortableList
            
            if (rDate of itemA) > (rDate of itemB) then
                set item j of sortableList to itemB
                set item nextIndex of sortableList to itemA
            end if
            
        end repeat
    end repeat
    
    -- Reconstruct List
    set finalTracks to {}
    repeat with anItem in sortableList
        set end of finalTracks to (trackObj of anItem)
    end repeat
    
    return finalTracks
end sortTracksByDateSafe