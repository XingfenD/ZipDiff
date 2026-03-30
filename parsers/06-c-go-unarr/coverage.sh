#!/bin/sh

# Copyright (c) [Fendy/WHU] [2025-2026]
# Licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

set -u

# $1 -- module source directory (/workspace/src)
# $2 -- go build work directory (contains .gcno for cgo units)
# $3 -- zip filename
# $4 -- output directory (/output/xx-parser_name)

src_dir="$1"
work_dir="$2"
zip_name="$3"
out_dir="$4"

raw_cov="$out_dir/$zip_name.raw.covinfo"
filtered_cov="$out_dir/$zip_name.filtered.covinfo"
summary_file="$out_dir/$zip_name.raw.summary"

percent="0"
if lcov -c -d "$work_dir" -o "$raw_cov" >/dev/null 2>&1; then
    lcov --extract "$raw_cov" "$src_dir/*" -o "$filtered_cov" >/dev/null 2>&1 || cp "$raw_cov" "$filtered_cov"
    if lcov --summary "$filtered_cov" > "$summary_file" 2>/dev/null; then
        parsed=$(sed -n 's/.*lines.*:\s*\([0-9][0-9.]*\)%.*/\1/p' "$summary_file" | head -n 1)
        if [ -n "$parsed" ]; then
            percent="$parsed"
        fi
    fi
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"

rm -f "$raw_cov" "$filtered_cov" "$summary_file"
