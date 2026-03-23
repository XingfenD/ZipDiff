#!/bin/sh

set -eu

# $1 -- jacoco .exec file
# $2 -- package prefix (slash form), e.g. org/apache/commons/compress
# $3 -- zip filename
# $4 -- output directory (/output/xx-parser_name)

exec_file="$1"
package_prefix="$2"
zip_name="$3"
out_dir="$4"
csv_file="$out_dir/$zip_name.jacoco.csv"

java -jar /tools/jacococli.jar report "$exec_file" \
    --classfiles /workspace/unzip.jar \
    --csv "$csv_file" >/dev/null

percent=$(awk -F',' -v pkg="$package_prefix" '
    NR > 1 && index($2, pkg) == 1 {
        missed += $8
        covered += $9
        found = 1
    }
    END {
        if (found && (missed + covered) > 0) {
            printf "%.2f", (covered * 100.0) / (missed + covered)
        }
    }
' "$csv_file")

if [ -z "$percent" ]; then
    percent=$(awk -F',' '
        NR > 1 {
            missed += $8
            covered += $9
        }
        END {
            if ((missed + covered) > 0) {
                printf "%.2f", (covered * 100.0) / (missed + covered)
            }
        }
    ' "$csv_file")
fi

if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
rm -f "$csv_file"
