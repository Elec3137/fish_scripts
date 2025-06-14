#!/usr/bin/env fish
set output_dir './re-encoded'
set input_dir $argv[1]
set regexp $argv[2]

# handle incorrect inputs
if not path is -d "$input_dir"
	echo "'$input_dir' is not a directory! Exiting"
	exit 1
end

function err
	set_color brred
	echo $argv
	set_color normal
end

# returns true if $regexp is empty or if it matches with any input arg
function matches_regexp
	if [ -z "$regexp" ]
		return 0
	end
	
	for input in $argv

		if [ -n "$input" ] && string match -qr "$regexp" "$input" 
			return 0
		end
	end

	return 1
end

# find wrappers for readability
function dirs_at
	find $argv -type d
end
function files_at
	find $argv -type f
end

# create the local output directory
mkdir -pv "$output_dir" || exit

# iterate through each directory in the input
for dir in $(dirs_at "$input_dir")

	# mkdir if there are regexp matches in this directory
	if matches_regexp $(files_at "$dir")

		# this may make directories even if there are no media files in them
		# however there is not much of a choice; `file` is not so helpful either
		# see: https://stackoverflow.com/questions/8101812/using-the-linux-file-command-to-determine-type-ie-image-audio-or-video
		mkdir -pv "$output_dir/$dir" || exit 
	end
end

# iterate through each file of the source directory
for file in $(files_at "$input_dir")

	if matches_regexp "$file"
		set output_file "$output_dir/$(path change-extension 'webm' "$file")"

		if path is $output_file
			err "Output file '$output_file' already exists, SKIPPING"
			continue
		end

		# re-encode the video to the target; if this doesn't work trash the result
		if not ffmpeg -i "$file" -c:v libsvtav1 -g 600 -c:a libopus "$output_file"
			if trash "$output_file"
				err "Failed to encode to '$output_file', output is TRASHED"
			else
				err "Failed to encode to '$output_file', EXITING"
				exit 1
			end
		end
	end
end
