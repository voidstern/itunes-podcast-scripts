use AppleScript version "2.4"
use scripting additions

on run {groupingLabel, simpleData}
    
    -- 1. Parse Lines to get Valid Podcast Names
    set podcastLines to paragraphs of (simpleData as text)
    set validPodcastNames to {}
    
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to "|"
    repeat with aLine in podcastLines
        set currentLine to contents of aLine
        if length of currentLine > 0 then
            set end of validPodcastNames to item 1 of text items of currentLine
        end if
    end repeat
    set AppleScript's text item delimiters to oldDelims
    
    -- 2. Clean up old groupings (Optimized)
    my clearStaleGroupings(groupingLabel, validPodcastNames)
    
    -- 3. Process Lines (Optimized Batch Update)
    repeat with aLine in podcastLines
        set currentLine to contents of aLine
        if length of currentLine > 0 then
            my processPodcastLine(currentLine, groupingLabel)
        end if
    end repeat
    
    -- 4. Process Started Episodes (Optimized Query)
    my processStartedEpisodes(groupingLabel, validPodcastNames)
    
end run

-- OPTIMIZED HANDLER: Batch fetches names to reduce "AppleEvents"
on clearStaleGroupings(targetGrouping, validNamesList)
    tell application "iTunes"
        try
            -- Fetch both the track references AND their albums in one single query
            set {candidateTracks, candidateAlbums} to {contents, album} of (every track of library playlist 1 whose grouping is targetGrouping)
            
            -- Loop strictly within AppleScript (very fast)
            repeat with i from 1 to count of candidateTracks
                if validNamesList does not contain (item i of candidateAlbums) then
                    -- Only communicate with iTunes for the specific tracks that need changing
                    set grouping of (item i of candidateTracks) to ""
                end if
            end repeat
        on error errMsg
            log "Error clearing stale groupings: " & errMsg
        end try
    end tell
end clearStaleGroupings

on processPodcastLine(aLine, targetGrouping)
    -- 1. Parse the line (Name and Count)
    set oldDelims to AppleScript's text item delimiters
    set AppleScript's text item delimiters to "|"
    set pName to ""
    set pCount to 0
    set lineParts to text items of aLine
    
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
    
    tell application "iTunes"
        try
            -- 2. Optimization: Target the "Podcasts" playlist directly
            --    Searching 'playlist "Podcasts"' is faster than 'library playlist 1 whose genre is "Podcast"'
            
            -- 3. Check for existence FIRST to avoid "Unknown object type" error
            set foundCount to count (every track of playlist "Podcasts" whose album is pName and unplayed is true)
            
            if foundCount > 0 then
                
                if pCount is 0 then
                    -- UPDATE ALL (Batch Mode)
                    -- Since we know playCount > 0, this batch command will now succeed safely.
                    set grouping of (every track of playlist "Podcasts" whose album is pName and unplayed is true) to targetGrouping
                    
                else
                    -- LIMIT MODE (Slice & Loop)
                    -- We must fetch the list to slice it.
                    set matchingTracks to (every track of playlist "Podcasts" whose album is pName and unplayed is true)
                    
                    set tracksToUpdate to {}
                    if foundCount < pCount then
                        set tracksToUpdate to matchingTracks
                    else
                        set tracksToUpdate to items 1 through pCount of matchingTracks
                    end if
                    
                    repeat with tr in tracksToUpdate
                        set grouping of tr to targetGrouping
                    end repeat
                end if
                
            end if
            
        on error errMsg
            log "Error processing '" & pName & "': " & errMsg
        end try
    end tell
end processPodcastLine

-- OPTIMIZED HANDLER: Uses "Started" grouping instead of calculating bookmarks
on processStartedEpisodes(targetGrouping, validNamesList)
    tell application "iTunes"
        with timeout of 600 seconds
            try
                -- QUERY OPTIMIZATION:
                -- Since the previous script marked these as "Started", we search for the grouping.
                -- This is instant compared to searching for "bookmark > 0".
                set {startedTracks, startedAlbums} to {contents, album} of (every track of library playlist 1 whose grouping is "Started")
                
                repeat with i from 1 to count of startedTracks
                    -- Check validity in memory (fast)
                    if validNamesList contains (item i of startedAlbums) then
                        -- Set the new station grouping
                        set grouping of (item i of startedTracks) to targetGrouping
                    end if
                end repeat
                
            on error errMsg
                log "Error processing started tracks: " & errMsg
            end try
        end timeout
    end tell
end processStartedEpisodes