tell application "iTunes"
	-- Step 1: 5-star tracks that aren't Loved -> Mark as Loved
	set starTracks to (every track of library playlist 1 whose rating is 100 and loved is false)
	repeat with aTrack in starTracks
		set loved of aTrack to true
	end repeat
	
	-- Step 2: Loved tracks that aren't 5-star -> Rate 5 stars
	-- Note: iTunes ratings are 0-100 (100 = 5 stars)
	set lovedTracks to (every track of library playlist 1 whose loved is true and rating is not 100)
	repeat with bTrack in lovedTracks
		set rating of bTrack to 100
	end repeat
	
	return "Sync complete! Library ratings and love status are now aligned."
end tell