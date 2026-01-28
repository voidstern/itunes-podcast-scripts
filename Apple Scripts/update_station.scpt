use AppleScript version "2.4"
use scripting additions

on run {groupingLabel, simpleData}
    
    -- 1. Parse Lines to get Valid Podcast Names
    -- Coerce to text to avoid class errors
    set podcastLines to paragraphs of (simpleData as text)
    set validPodcastNames to {}
    
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to "|"
    
    repeat with aLine in podcastLines
        set currentLine to contents of aLine
        if length of currentLine > 0 then
            -- Extract just the name (item 1) for validation
            set end of validPodcastNames to item 1 of text items of currentLine
        end if
    end repeat
    
    set AppleScript's text item delimiters to oldDelims
    
    -- 2. Clean up old groupings
    my clearStaleGroupings(groupingLabel, validPodcastNames)
    
    -- 3. Process Lines (Add/Update Groupings)
    repeat with aLine in podcastLines
        set currentLine to contents of aLine
        if length of currentLine > 0 then
            my processPodcastLine(currentLine, groupingLabel)
        end if
    end repeat
    
end run

-- HANDLER: Removes grouping from tracks not in the current input list
on clearStaleGroupings(targetGrouping, validNamesList)
    tell application "iTunes"
        try
            -- Fetch all tracks that currently have the specific grouping
            set currentlyGroupedTracks to (every track of library playlist 1 whose grouping is targetGrouping)
            
            repeat with t in currentlyGroupedTracks
                set tName to album of t
                
                -- If the track's podcast name is not in our current input list, clear the grouping
                if tName is not in validNamesList then
                    set grouping of t to ""
                end if
            end repeat
        on error errMsg
            log "Error clearing stale groupings: " & errMsg
        end try
    end tell
end clearStaleGroupings

on processPodcastLine(aLine, targetGrouping)
    -- Formats: "Name|Count", "Name|", or "Name"
    
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to "|"
    set pName to ""
    set pCount to 0
    set lineParts to text items of aLine
    
    -- Parse Name and Count
    if (count of lineParts) > 1 then
        set pName to item 1 of lineParts
        set rawCount to item 2 of lineParts
        if length of rawCount > 0 then
            try
                set pCount to rawCount as integer
            on error
                set pCount to 0
            end try
        else
            set pCount to 0
        end if
    else
        set pName to aLine
        set pCount to 0
    end if
    
    set AppleScript's text item delimiters to oldDelims
    
    if length of pName is 0 then return
    
    -- 3. Get Unplayed Tracks
    tell application "iTunes"
        set unplayedTracks to {}
        try
            -- Fetch tracks (Order depends on iTunes internal logic)
            set unplayedTracks to (every track of library playlist 1 whose genre is "Podcast" and album is pName and unplayed is true)
        on error errMsg
            log "Error searching '" & pName & "': " & errMsg
        end try
    end tell
    
    if unplayedTracks is {} then return
    
    -- 4. REMOVED SORTING LOGIC
    -- We simply use the list exactly as iTunes returned it.
    
    -- 5. Slice List (Apply Count limit)
    set tracksToUpdate to {}
    set totalFound to count of unplayedTracks
    
    if pCount is 0 then
        set tracksToUpdate to unplayedTracks
    else
        if totalFound < pCount then
            set tracksToUpdate to unplayedTracks
        else
            set tracksToUpdate to items 1 through pCount of unplayedTracks
        end if
    end if
    
    -- 6. Update Grouping Only
    tell application "iTunes"
        try
            repeat with tr in tracksToUpdate
                try
                    set grouping of tr to targetGrouping
                on error
                    log "Could not set grouping for track."
                end try
            end repeat
        on error errMsg
            log "Error processing tracks: " & errMsg
        end try
    end tell
    
end processPodcastLine

-- REMOVED: on sortTracksByDateSafe handler is no longer needed.