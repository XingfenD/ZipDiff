#!/bin/sh

set -eu

# $1 -- coverage xml file
# $2 -- package/assembly prefix
# $3 -- zip filename
# $4 -- output directory (/output/xx-parser_name)

coverage_xml="$1"
package_prefix="$2"
zip_name="$3"
out_dir="$4"

line_rate=$(awk -v key="$package_prefix" '
    match($0, /<package name="([^"]+)"[^>]*line-rate="([0-9.]+)"/, m) {
        if (index(m[1], key) == 1) {
            print m[2]
            exit
        }
    }
' "$coverage_xml")

if [ -z "$line_rate" ]; then
    line_rate=$(sed -n 's/.*<coverage[^>]*line-rate="\([0-9.]*\)".*/\1/p' "$coverage_xml" | head -n 1)
fi

if [ -z "$line_rate" ]; then
    line_rate="0"
fi

percent=$(awk -v rate="$line_rate" 'BEGIN { printf "%.2f", rate * 100 }')
printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
