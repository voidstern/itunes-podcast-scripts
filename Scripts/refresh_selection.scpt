tell application "iTunes"
    try
        -- 1. Get the currently selected tracks
        set currentSelection to selection
        
        if currentSelection is {} then
            return "No tracks selected. Please select tracks in iTunes first."
        end if
        
        set selCount to count of currentSelection
        
        -- 2. Loop through selection
        repeat with aTrack in currentSelection
            
            -- THE TRICK: Force a database write by toggling the 'start' time.
            -- We save the original start time (usually 0.0), change it, and change it back.
            set originalStart to start of aTrack
            
            -- Change start to 1 second (or original + 1)
            set start of aTrack to (originalStart + 1)
            
            -- revert immediately
            set start of aTrack to originalStart
            
            -- 3. Finally, refresh to read the new file duration
            refresh aTrack
            
        end repeat
        
        return "Success: Updated " & selCount & " selected track(s)."
        
    on error errMsg
        return "Error: " & errMsg
    end try
end tell