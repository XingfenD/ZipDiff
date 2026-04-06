#!/bin/sh

set -eu

# $1 -- NODE_V8_COVERAGE directory
# $2 -- dependency path fragment to match
# $3 -- zip filename
# $4 -- output directory (/output/xx-parser_name)

cov_dir="$1"
lib_fragment="$2"
zip_name="$3"
out_dir="$4"
report_dir="$(mktemp -d /tmp/c8report.XXXXXX)"
summary_file="$report_dir/coverage-summary.json"
prebuilt_summary="$cov_dir/coverage-summary.json"

trap 'rm -rf "$report_dir"' EXIT

if [ -f "$prebuilt_summary" ]; then
    cp "$prebuilt_summary" "$summary_file"
elif [ -z "$(ls -A "$cov_dir" 2>/dev/null || true)" ]; then
    printf "0\n" > "$out_dir/$zip_name.covinfo"
    exit 0
else
    c8 report \
        --temp-directory "$cov_dir" \
        --report-dir "$report_dir" \
        --reporter json-summary >/dev/null 2>&1 || true
fi

if [ ! -f "$summary_file" ]; then
    printf "0\n" > "$out_dir/$zip_name.covinfo"
    exit 0
fi

percent=$(node -e '
const fs = require("fs");
const p = process.argv[1];
const frag = process.argv[2];
const data = JSON.parse(fs.readFileSync(p, "utf8"));
let covered = 0;
let total = 0;
let found = false;
for (const [file, stat] of Object.entries(data)) {
  if (file === "total") continue;
  if (file.includes(frag)) {
    found = true;
    covered += (stat.lines && stat.lines.covered) || 0;
    total += (stat.lines && stat.lines.total) || 0;
  }
}
if ((!found || total === 0) && data.total && data.total.lines) {
  covered = data.total.lines.covered || 0;
  total = data.total.lines.total || 0;
}
if (total === 0) {
  process.stdout.write("0");
} else {
  process.stdout.write(((covered * 100) / total).toFixed(2));
}
' "$summary_file" "$lib_fragment")

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
