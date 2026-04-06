#!/bin/sh

# Copyright (c) [Fendy/WHU] [2025-2026]
# Licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

set -u

# $1 -- go binary coverage directory (GOCOVERDIR)
# $2 -- zip filename
# $3 -- output directory (/output/xx-parser_name)

cov_dir="$1"
zip_name="$2"
out_dir="$3"

go_cmd="go"
if ! command -v "$go_cmd" >/dev/null 2>&1; then
    if [ -x /usr/local/go/bin/go ]; then
        go_cmd=/usr/local/go/bin/go
    fi
fi

percent=$("$go_cmd" tool covdata func -i "$cov_dir" 2>/dev/null | awk '
    $1 == "total" {
        gsub(/%/, "", $NF)
        print $NF
        exit
    }
')

if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
