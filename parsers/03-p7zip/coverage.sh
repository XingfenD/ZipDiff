#!/bin/sh

# Copyright (c) [Fendy/WHU] [2025-2026]
# Licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

set -eu

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

lcov -c -d "$1" -o "$raw_cov"
lcov --extract "$raw_cov" "$1/*" -o "$filtered_cov" >/dev/null 2>&1 || cp "$raw_cov" "$filtered_cov"

# Extract line coverage percentage from lcov summary
lcov --summary "$filtered_cov" > "$summary_file"
percent=$(sed -n 's/.*lines.*:\s*\([0-9][0-9.]*\)%.*/\1/p' "$summary_file" | head -n 1)
if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$3/$2.covinfo"

rm -f "$raw_cov" "$filtered_cov" "$summary_file"
