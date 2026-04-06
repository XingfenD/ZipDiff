#!/bin/sh

set -u

# $1 -- coverage xml file
# $2 -- package/assembly prefix
# $3 -- zip filename
# $4 -- output directory (/output/xx-parser_name)

coverage_xml="$1"
package_prefix="$2"
zip_name="$3"
out_dir="$4"

line_rate=$(grep -F "name=\"${package_prefix}" "$coverage_xml" 2>/dev/null | sed -n 's/.*line-rate="\([0-9.]*\)".*/\1/p' | head -n 1)

if [ -z "$line_rate" ]; then
    # Fallback to wrapper package when third-party package symbols are unavailable.
    line_rate=$(grep -F 'name="unzip"' "$coverage_xml" 2>/dev/null | sed -n 's/.*line-rate="\([0-9.]*\)".*/\1/p' | head -n 1)
fi

if [ -z "$line_rate" ]; then
    line_rate="0"
fi

percent=$(awk -v rate="$line_rate" 'BEGIN { printf "%.2f", rate * 100 }')
printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
