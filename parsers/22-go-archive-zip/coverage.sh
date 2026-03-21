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

go tool covdata percent -i=/cov | awk '$1=="github.com/evilsocket/islazy/zip"{print $3}' > "$3"/"$2".covinfo
