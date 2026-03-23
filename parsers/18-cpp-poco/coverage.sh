#!/bin/sh

set -eu

# $1 -- source code directory
# $2 -- zip filename
# $3 -- output directory (/output/xx-parser_name)

raw_cov="$3/$2.raw.covinfo"
filtered_cov="$3/$2.filtered.covinfo"
summary_file="$3/$2.raw.summary"

lcov -c -d "$1/build" -o "$raw_cov"
lcov --extract "$raw_cov" "$1/*" -o "$filtered_cov" >/dev/null 2>&1 || cp "$raw_cov" "$filtered_cov"
lcov --summary "$filtered_cov" > "$summary_file"

percent=$(sed -n 's/.*lines.*:\s*\([0-9][0-9.]*\)%.*/\1/p' "$summary_file" | head -n 1)
if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$3/$2.covinfo"

rm -f "$raw_cov" "$filtered_cov" "$summary_file"
