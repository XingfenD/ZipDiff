#!/bin/sh

set -eu

# $1 -- runtime coverage log emitted by dmd -cov
# $2 -- zip filename
# $3 -- output directory (/output/xx-parser_name)

cov_log="$1"
zip_name="$2"
out_dir="$3"

percent=$(printf "%s\n" "$cov_log" | sed -n 's|.*std/zip\.d[^0-9]*\([0-9][0-9.]*\)%.*|\1|p' | tail -n 1)

if [ -z "$percent" ]; then
    # Fallback to the last reported module if std/zip.d is not present.
    percent=$(printf "%s\n" "$cov_log" | sed -n 's|.*is \([0-9][0-9.]*\)% covered.*|\1|p' | tail -n 1)
fi

if [ -z "$percent" ]; then
    percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
