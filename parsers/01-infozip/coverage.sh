#!/bin/sh

# Copyright (c) [Fendy/WHU] [2025-2026]
# Licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

set -eu

source /workspace/app.env

# $1 -- source code directory
# $2 -- zip filename
# $3 -- output directory (/output/xx-parser_name)

# generate coverage info with local path
lcov -c -d "$1" -o "$3"/"$2".raw.covinfo

# replace local path with host machine path
perl -pe "s#\Q$1\E#$ROOT_DIR/parsers/$PARSER_RELATIVE_PATH/src#g" "$3"/"$2".raw.covinfo > "$3"/"$2".covinfo

# remove raw covinfo
rm "$3"/"$2".raw.covinfo
