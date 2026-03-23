#!/bin/sh

set -eu

# $1 -- tix file path
# $2 -- module prefix (e.g. Codec.Archive.Zip)
# $3 -- zip filename
# $4 -- output directory (/output/xx-parser_name)

tix_file="$1"
module_prefix="$2"
zip_name="$3"
out_dir="$4"
module_path=$(printf "%s" "$module_prefix" | tr '.' '/')

set --
while IFS= read -r mix_file; do
    mix_dir=$(dirname "$mix_file")
    set -- "$@" --hpcdir "$mix_dir"
done <<EOF
$(find /root/.cabal -type f -path "*/$module_path.mix" 2>/dev/null | sort -u)
EOF

report=$(hpc report "$tix_file" --per-module "$@" 2>/dev/null || true)

percent=$(printf "%s\n" "$report" | awk -v mod="$module_prefix" '
    index($0, mod) {
        if (match($0, /[0-9]+(\.[0-9]+)?%/)) {
            p = substr($0, RSTART, RLENGTH - 1)
            print p
            exit
        }
    }
')

if [ -z "$percent" ]; then
    percent=$(printf "%s\n" "$report" | awk '
        {
            if (match($0, /[0-9]+(\.[0-9]+)?%/)) {
                p = substr($0, RSTART, RLENGTH - 1)
                print p
                exit
            }
        }
    ')
fi

if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
