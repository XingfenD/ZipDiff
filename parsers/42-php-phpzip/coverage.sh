#!/bin/sh

set -eu

# $1 -- xdebug coverage json
# $2 -- zip filename
# $3 -- output directory

coverage_json="$1"
zip_name="$2"
out_dir="$3"

percent=$(php -r '
$path = $argv[1];
$data = json_decode(file_get_contents($path), true);
if (!is_array($data)) { echo "0"; exit(0); }
$covered = 0;
$total = 0;
foreach ($data as $file => $lines) {
    if (strpos($file, "/vendor/nelexa/zip/") === false) continue;
    foreach ($lines as $ln => $hit) {
        if ($hit < 0) continue;
        $total++;
        if ($hit > 0) $covered++;
    }
}
if ($total === 0) {
    echo "0";
} else {
    printf("%.2f", $covered * 100.0 / $total);
}
' "$coverage_json")

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
