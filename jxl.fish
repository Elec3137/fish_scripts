#!/usr/bin/env fish
# This is a script to re-encode all jpegs and pngs into JXLs (losslessly)
# JXL is a more efficient format, therefore this saves space.

function err -d 'prints the given error message and exits'
    set_color brred >&2
    printf "%s\n" "$argv" >&2
    set_color normal >&2
end

function info -d 'prints info as cyan into stderr, to enhance readability and avoid being hidden and used by redirection'
    set_color brcyan >&2
    printf "%s\n" "$argv" >&2
    set_color normal >&2
end

for file in $(fd . ./ --type file)
    if string match -qr "jpeg|jpg|png" "$(string lower $(path extension "$file"))"
        info "Processing '$file'..."

        set newfile $(path change-extension 'jxl' "$file")

        if path is "$newfile"
            err "Output file '$newfile' already exists, skipping"
        else if cjxl --lossless_jpeg=1 -q 100 -e 10 "$file" "$newfile"
            info "$(du -h "$file") -> $(du -h "$newfile")"
            if trash "$file"
                info "Trashed '$file', wrote '$newfile'"
            else
                err "Failed to trash '$file'"
                exit 1
            end
        else
            err "Failed to process '$file'"
        end

    else
        info "Skipped '$file'"
    end

    info
end
