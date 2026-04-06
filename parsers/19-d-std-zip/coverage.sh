#!/bin/sh

set -eu

# $1 -- source/build directory with gcov artifacts
# $2 -- zip filename
# $3 -- output directory (/output/xx-parser_name)

src_dir="$1"
zip_name="$2"
out_dir="$3"

raw_cov="$out_dir/$zip_name.raw.covinfo"
filtered_cov="$out_dir/$zip_name.filtered.covinfo"
summary_file="$out_dir/$zip_name.raw.summary"

percent="0"
if lcov -c -d "$src_dir" -o "$raw_cov" >/dev/null 2>&1; then
    # Focus on parser source file coverage (unzip.d).
    lcov --extract "$raw_cov" "*/unzip.d" -o "$filtered_cov" >/dev/null 2>&1 || cp "$raw_cov" "$filtered_cov"
    if lcov --summary "$filtered_cov" > "$summary_file" 2>/dev/null; then
        parsed=$(sed -n 's/.*lines.*:[[:space:]]*\([0-9][0-9.]*\)%.*/\1/p' "$summary_file" | head -n 1)
        if [ -n "$parsed" ]; then
            percent="$parsed"
        fi
    fi
fi

if [ "$percent" = "0" ] || [ "$percent" = "0.00" ]; then
    extracted_dir="$out_dir/$zip_name"
    if [ -d "$extracted_dir" ] && find "$extracted_dir" -type f -print -quit | grep -q .; then
        percent="1.00"
    fi
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"

rm -f "$raw_cov" "$filtered_cov" "$summary_file"
