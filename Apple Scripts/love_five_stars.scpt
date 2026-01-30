tell application "iTunes"
	-- Rule 1: Not loved tracks, with a 5 star rating -> Mark as Loved
	-- (Matches user rule: Not loved tracks, with a 5 star rating -> Love)
	set starTracks to (every track of library playlist 1 whose rating is 100 and loved is false)
	repeat with aTrack in starTracks
		set loved of aTrack to true
	end repeat

	-- Rule 2: Loved Tracks, with 0 rating -> Rate with 5 stars
	set zeroRatedLovedTracks to (every track of library playlist 1 whose loved is true and rating is 0)
	repeat with bTrack in zeroRatedLovedTracks
		set rating of bTrack to 100
	end repeat

	-- Rule 3: Loved tracks, with a rating < 5, but at least one star -> Remove Love
	-- (Matches rating > 0 and rating < 100)
	set conflictTracks to (every track of library playlist 1 whose loved is true and rating > 0 and rating < 100)
	repeat with cTrack in conflictTracks
		set loved of cTrack to false
	end repeat

	return "Sync complete! Library ratings and love status are now aligned."
end tell