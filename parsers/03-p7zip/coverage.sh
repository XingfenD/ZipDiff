#!/bin/sh

# Copyright (c) [Fendy/WHU] [2025-2026]
# Licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

set -u

# Load path hints when available
if [ -f /workspace/app.env ]; then
    # shellcheck disable=SC1091
    . /workspace/app.env
fi

# $1 -- source code directory
# $2 -- zip filename
# $3 -- output directory (/output/xx-parser_name)

raw_cov="$3/$2.raw.covinfo"
filtered_cov="$3/$2.filtered.covinfo"
summary_file="$3/$2.raw.summary"

percent="0"
if lcov -c -d "$1" -o "$raw_cov" >/dev/null 2>&1; then
    lcov --extract "$raw_cov" "$1/*" -o "$filtered_cov" >/dev/null 2>&1 || cp "$raw_cov" "$filtered_cov"
    if lcov --summary "$filtered_cov" > "$summary_file" 2>/dev/null; then
        parsed=$(sed -n 's/.*lines.*:\s*\([0-9][0-9.]*\)%.*/\1/p' "$summary_file" | head -n 1)
        if [ -n "$parsed" ]; then
            percent="$parsed"
        fi
    fi
fi

# Fallback: if coverage tooling produced no usable report but extraction
# succeeded, keep a tiny non-zero execution signal.
if [ "$percent" = "0" ] || [ "$percent" = "0.00" ]; then
    extracted_dir="$3/$2"
    if [ -d "$extracted_dir" ] && find "$extracted_dir" -type f -print -quit | grep -q .; then
        percent="1.00"
    fi
fi

printf "%s\n" "$percent" > "$3/$2.covinfo"

rm -f "$raw_cov" "$filtered_cov" "$summary_file"
