#!/bin/sh

set -eu

# $1 -- jacoco .exec file
# $2 -- package prefix (slash form), e.g. org/apache/commons/compress
# $3 -- zip filename
# $4 -- output directory (/output/xx-parser_name)
# $5 -- optional package regex in dot form for focused coverage scope

exec_file="$1"
package_prefix="$2"
dot_package_prefix=$(printf '%s' "$package_prefix" | tr '/' '.')
zip_name="$3"
out_dir="$4"
package_regex="${5:-}"
csv_file="$out_dir/$zip_name.jacoco.csv"

java_bin="${JAVA_BIN:-}"
if [ -z "$java_bin" ]; then
    for candidate in /opt/java/openjdk/bin/java /usr/bin/java java; do
        if command -v "$candidate" >/dev/null 2>&1; then
            java_bin="$candidate"
            break
        fi
    done
fi
if [ -z "$java_bin" ]; then
    printf "0\n" > "$out_dir/$zip_name.covinfo"
    exit 0
fi

"$java_bin" -jar /tools/jacococli.jar report "$exec_file" \
    --classfiles /workspace/unzip.jar \
    --csv "$csv_file" >/dev/null

percent=$(awk -F',' -v pkg="$package_prefix" -v dpkg="$dot_package_prefix" -v re="$package_regex" '
    NR > 1 && (index($2, pkg) == 1 || index($2, dpkg) == 1) {
        if (re != "" && $2 !~ re) {
            next
        }
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
if [ "${ZIPDIFF_KEEP_JACOCO_CSV:-0}" != "1" ]; then
    rm -f "$csv_file"
fi
