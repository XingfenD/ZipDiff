#!/bin/bash

# Original work Copyright (c) [Yufan You and so on] 2025
# Original work licensed under the Apache License, Version 2.0 (the "Apache-2.0 License");
# You may obtain a copy of the Apache-2.0 License at:
#   http://www.apache.org/licenses/LICENSE-2.0

# Modified work Copyright (c) [Fendy/WHU] [2025-2026]
# Modified work licensed under the MIT License (the "MIT License");
# You may obtain a copy of the MIT License at:
#   https://opensource.org/licenses/MIT

# This file contains modifications to the original ZipDiff codebase (https://github.com/ouuan/ZipDiff).
# Modifications include:
#   1. Change the script path to the scripts_for_parsers directory.
#   2. Add the app.env file to each parser directory.
#   3. Untar the src.tar.gz file to each parser directory.

# Unless required by applicable law or agreed to in writing, software
# distributed under the Apache-2.0 License and MIT License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the respective licenses for the specific language governing permissions and limitations.


set -euo pipefail

base="$(dirname "$(dirname "$(realpath "$0")")")"
scripts_base="$base"/tools/scripts_for_parsers
input_dir="${INPUT_DIR:-$base/evaluation/input}"
output_dir="${OUTPUT_DIR:-$base/evaluation/output}"

cd "$base"/parsers
echo "services:" > docker-compose.yml
echo "ROOT_DIR=$base" > "$scripts_base"/app.env

for i in */; do
    cp "$scripts_base"/unzip-all.sh "$scripts_base"/parallel-unzip-all.sh "$scripts_base"/testcase.sh "$scripts_base"/app.env "$i"
    parser=${i%/}
    if [ -f "$i"/src.tar.gz ]; then
        tar -zxf "$i"/src.tar.gz -C "$i"
    fi
    echo "PARSER_RELATIVE_PATH=$parser" >> "$i"/app.env
    echo "  $parser:
    build: $parser
    volumes:
      - $input_dir:/input:ro
      - $output_dir/$parser:/output" >> docker-compose.yml
done
