tell application "iTunes"
    -- Get the list of currently highlighted tracks [cite: 3]
    set selectedTracks to selection
    
    -- Error handling if nothing is selected
    if selectedTracks is {} then
        display dialog "No tracks selected. Please select the tracks you want to clear." buttons {"OK"} default button "OK"
        return
    end if
    
    -- Iterate through the selection and reset the Grouping property
    repeat with t in selectedTracks
        set grouping of t to ""
    end repeat
    
    return (count of selectedTracks) & " tracks have had their Grouping cleared."
end tell