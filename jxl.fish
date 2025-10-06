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

for file in $(fd . ./ --type file)
    if string match -qr "jpeg|jpg|png" "$(string lower $(path extension "$file"))"
        info "Processing '$file'..."

        set newfile $(path change-extension 'jxl' "$file")

        if path is "$newfile"
            err "Output file '$newfile' already exists"
        else if cjxl --lossless_jpeg=1 -q 100 -e 10 "$file" "$newfile"
            info "$(du -h "$file" | cut -f 1) -> $(du -h "$newfile" | cut -f 1)"
            if not mv -vt "$trashdir" "$file"
                err "Failed to trash '$file'"
            end
        else
            info "Failed to process '$file', skipping!"
        end

    else
        info "Skipped '$file'"
    end

    info
end

if not rmdir "$trashdir"
    read -P "Delete original images in '$trashdir' now? [y/N] " input
    set input (string lower -- $input)

    if test "$input" = y
        rm -rv "$trashdir"
    end
end
