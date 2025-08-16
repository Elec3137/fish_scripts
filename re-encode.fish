#!/usr/bin/env fish

function print_usage
    printf 'usage: <input_dir> [<regexp>]

re-encodes (videos) from given $input_dir to its parent directory
'
end

function err -d 'prints the given error message and exits'
    set_color brred >&2
    printf "%s\n" "$argv" >&2
    set_color normal >&2
    exit 1
end

if test (count $argv) -eq 0
    print_usage
    exit
end

# handle params

set input_dir $argv[1]
if not path is -d "$input_dir"
    err "'$input_dir' is not a valid path"
end

set output_dir $(path dirname "$input_dir")
if test "$(path normalize "$input_dir")" -eq "$(path normalize "$output_dir")"
    err "output dir '$output_dir' should not be equal to input dir '$input_dir' for risk of self-recursion"
end

if test -n "$argv[2]"
    set -g regexp "$argv[2]"
else
    set -g regexp "."
end

# begin logic

if not mkdir -pv "$output_dir"
    err "unable to create output directory"
end

# iterate through each file of the source directory
for file in $(fd "$regexp" -t file "$input_dir")
    if not mkdir -pv "$output_dir/$(path dirname "$file")"
        err "unable to create output subdirectory"
    end

    set output_file "$output_dir/$(path change-extension 'mkv' "$file")"

    if path is "$output_file"
        err "output file '$output_file' already exists!"
    end

    # re-encode the video to the output; if this doesn't work trash the result and exit
    if not ffmpeg -i "$file" -pix_fmt yuv420p10le -c:v libsvtav1 -crf 35 -svtav1-params tune=0:keyint=10s -preset 0 -c:a libopus -b:a 128k -c:s copy "$output_file"
        trash "$output_file"
        err "failed to encode to '$output_file'!"
    end
end
