#!/usr/bin/env fish
# This is a script to re-encode all jpegs and pngs into JXLs (losslessly)
# JXL is a more efficient format, therefore this saves space.

for file in $(fd . ./ --type file)
	if string match -qr "jpeg|jpg|png" $(string lower $(path extension $file))
		printf "\tProcessing '%s'...\n" $file

		set newfile $(path change-extension 'jxl' $file)

		# If the target file doesn't already exist, and the command works properly
		if not path is $newfile && cjxl --lossless_jpeg=1 -q 100 -e 9 "$file" "$newfile"
			trash $file || exit
			set_color cyan; printf "\tTrashed '%s', wrote '%s'\n" $file $newfile; set_color normal
		else
			set_color red; printf "\tFailed to process '%s'\n" $file; set_color normal
		end

	else 
		printf "\tSkipped '%s'\n" $file
	end

	printf "\n"
end
