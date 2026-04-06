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

if [ ! -f "$tix_file" ]; then
    printf "0\n" > "$out_dir/$zip_name.covinfo"
    exit 0
fi

percent=$(tr '\n' ' ' < "$tix_file" | sed 's/TixModule /\nTixModule /g' | awk -v mod="$module_prefix" '
    index($0, "/" mod) == 0 { next }
    {
        left = index($0, "[")
        right = index($0, "]")
        if (left == 0 || right == 0 || right <= left) {
            next
        }
        arr = substr($0, left + 1, right - left - 1)
        n = split(arr, ticks, ",")
        for (i = 1; i <= n; i++) {
            gsub(/^[ \t]+|[ \t]+$/, "", ticks[i])
            if (ticks[i] != "") {
                total++
                if ((ticks[i] + 0) > 0) {
                    covered++
                }
            }
        }
    }
    END {
        if (total > 0) {
            printf "%.2f", (covered * 100.0) / total
        }
    }
')

if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
