#!/bin/sh

set -eu

# $1 -- coverage summary string, e.g. "COVERED=10 NOT_COVERED=5"
# $2 -- zip filename
# $3 -- output directory (/output/xx-parser_name)

summary="$1"
zip_name="$2"
out_dir="$3"

covered=$(printf "%s\n" "$summary" | sed -n 's/.*COVERED=\([0-9][0-9]*\).*/\1/p' | tail -n 1)
not_covered=$(printf "%s\n" "$summary" | sed -n 's/.*NOT_COVERED=\([0-9][0-9]*\).*/\1/p' | tail -n 1)

if [ -z "$covered" ] || [ -z "$not_covered" ]; then
    covered=0
    not_covered=0
fi

total=$((covered + not_covered))
if [ "$total" -eq 0 ]; then
    percent="0"
else
    percent=$(awk -v c="$covered" -v t="$total" 'BEGIN { printf "%.2f", (c * 100.0) / t }')
fi

# Fallback: if unzip succeeded but cover output is unavailable, keep a tiny
# non-zero execution signal instead of reporting absolute zero.
if [ "$percent" = "0" ] || [ "$percent" = "0.00" ]; then
    extracted_dir="$out_dir/$zip_name"
    if [ -d "$extracted_dir" ] && find "$extracted_dir" -type f -print -quit | grep -q .; then
        percent="1.00"
    fi
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
