#!/bin/sh

set -eu

# $1 -- cover db dir
# $2 -- zip filename
# $3 -- output directory

db_dir="$1"
zip_name="$2"
out_dir="$3"

percent=$(cover -report text -db "$db_dir" 2>/dev/null | awk '
    /^Total[[:space:]]/ {
        v=$NF
    }
    END {
        if (v ~ /^[0-9]+([.][0-9]+)?$/) print v
    }
')
if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
