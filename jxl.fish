#!/usr/bin/env fish
# This is a script to re-encode all jpegs and pngs into JXLs (losslessly)
# JXL is a more efficient format, therefore this saves space.

set trashdir "$(pwd)/original-images_$(date -I)"

function err -d 'prints the given error message and exits'
    set_color brred >&2
    printf "%s\n" "$argv" >&2
    set_color normal >&2
    exit 1
end

function info -d 'prints info as cyan into stderr, to enhance readability and avoid being hidden and used by redirection'
    set_color brcyan >&2
    printf "%s\n" "$argv" >&2
    set_color normal >&2
end

info "making trash directory at '$trashdir'"
if not mkdir "$trashdir"
    if path is -f "$trashdir"
        err "trash directory '$trashdir' is a file, cannot continue"
    end
end
info

for image in $(fd . ./ --type file -E "original-images_*" -L -e jpeg -e jpg -e png)
    info "Processing '$image'..."

    set jxl $(path change-extension 'jxl' "$image")

    if path is "$jxl"
        err "Output file '$jxl' already exists"
    else if cjxl --lossless_jpeg=1 -q 100 -e 10 "$image" "$jxl"
        info "$(du -h "$image" | cut -f 1) -> $(du -h "$jxl" | cut -f 1)"
        if not mv -vt "$trashdir" "$image"
            err "Failed to trash '$image'"
        end
    else
        info "Failed to process '$image', skipping!"
    end

    info
end

if rmdir "$trashdir"
    info "removed empty trash directory at '$trashdir'"
else
    read -P "Delete original images in '$trashdir' now? [y/N] " input

    if test "$(string lower -- $input)" = y
        rm -rv "$trashdir"
    end
end
