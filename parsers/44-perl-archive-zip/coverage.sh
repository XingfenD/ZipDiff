#!/bin/sh

set -eu

# $1 -- cover db dir
# $2 -- zip filename
# $3 -- output directory

db_dir="$1"
zip_name="$2"
out_dir="$3"

percent=$(cover -report summary -db "$db_dir" | sed -n 's/.*\([0-9][0-9.]*\)%.*/\1/p' | head -n 1)
if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
