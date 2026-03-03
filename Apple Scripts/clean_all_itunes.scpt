-- clean_all_itunes.scpt
-- Clears lyrics, comments, description, and long description from ALL tracks
-- in the iTunes library. Run this once to reduce the iTunesDB size so the
-- iPod Classic can load more than ~30k items.

tell application "iTunes"
	with timeout of 86400 seconds -- Up to 24 hrs for a huge library
		try
			-- 1. Gather ALL tracks (songs, podcasts, audiobooks)
			set allTracks to every file track of library playlist 1

			set totalCount to count of allTracks
			if totalCount is 0 then
				display dialog "No tracks found in the library." with title "Clean All Metadata" buttons {"OK"} default button "OK"
				return
			end if

			-- 2. Confirmation dialog
			display dialog "Found " & totalCount & " tracks." & return & return & ¬
				"This will clear Lyrics, Comments, Description, and Long Description" & return & ¬
				"from every track. This helps the iPod Classic load larger libraries." & return & return & ¬
				"This may take a long time for large libraries." & return & ¬
				"A 24-hour timeout is set to prevent errors." with title "Clean All iTunes Metadata" ¬
				buttons {"Cancel", "Clean All"} default button "Clean All" with icon caution

			-- 3. Process every track
			set cleanCount to 0
			set skipCount to 0
			set failCount to 0

			repeat with aTrack in allTracks
				try
					set didChange to false

					-- Clear lyrics (songs, audiobooks)
					try
						if lyrics of aTrack is not "" then
							set lyrics of aTrack to ""
							set didChange to true
						end if
					end try

					-- Clear comment
					try
						if comment of aTrack is not "" then
							set comment of aTrack to ""
							set didChange to true
						end if
					end try

					-- Clear description (podcasts)
					try
						if description of aTrack is not "" then
							set description of aTrack to ""
							set didChange to true
						end if
					end try

					-- Clear long description (podcasts, some iTunes versions)
					try
						if long description of aTrack is not "" then
							set long description of aTrack to ""
							set didChange to true
						end if
					end try

					if didChange then
						set cleanCount to cleanCount + 1
					else
						set skipCount to skipCount + 1
					end if

				on error
					set failCount to failCount + 1
				end try
			end repeat

			-- 4. Summary dialog
			display dialog "Done!" & return & return & ¬
				"Cleaned:  " & cleanCount & return & ¬
				"Already empty: " & skipCount & return & ¬
				"Errors:   " & failCount with title "Clean All iTunes Metadata" buttons {"OK"} default button "OK"

		on error errMsg number errNum
			if errNum is -128 then
				-- User cancelled the confirmation dialog
				return
			else
				display dialog "Error: " & errMsg with title "Clean All iTunes Metadata" buttons {"OK"} default button "OK" with icon stop
			end if
		end try
	end timeout
end tell
