#!/bin/sh

set -eu

# $1 -- coverage data file
# $2 -- zip filename
# $3 -- output directory (/output/xx-parser_name)

cov_file="$1"
zip_name="$2"
out_dir="$3"

percent=$(python -m coverage report --data-file="$cov_file" -m zipfile.py 2>/dev/null | awk 'END {print $(NF-1)}' | tr -d '%')

if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
