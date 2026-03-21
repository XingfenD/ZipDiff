#!/bin/bash

# Copyright (c) [Fendy/WHU] [2025-2026]
# Licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

set -euo pipefail

base="$(dirname "$(dirname "$(realpath "$0")")")"
scripts_base="$base"/tools/scripts_for_parsers
input_dir="${INPUT_DIR:-$base/evaluation/input}"
output_dir="${OUTPUT_DIR:-$base/evaluation/output}"

cd "$base"/parsers
rm -f docker-compose.yml "$scripts_base"/app.env

for i in */; do
    rm -f "$i"/unzip-all.sh "$i"/parallel-unzip-all.sh "$i"/testcase.sh "$i"/app.env
    rm -rf "$i"/src
done