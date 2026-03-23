#!/bin/sh

set -eu

# $1 -- simplecov resultset json
# $2 -- zip filename
# $3 -- output directory

resultset="$1"
zip_name="$2"
out_dir="$3"

percent=$(ruby -rjson -e '
path = "/usr/local/bundle/gems/rubyzip-2.3.2/"
file = ARGV[0]
data = JSON.parse(File.read(file))
entry = data.values.first || {}
cov = entry["coverage"] || {}
covered = 0
total = 0
cov.each do |k, arr|
  next unless k.include?(path)
  arr.each do |v|
    next if v.nil?
    total += 1
    covered += 1 if v > 0
  end
end
if total == 0
  puts "0"
else
  printf("%.2f\n", covered * 100.0 / total)
end
' "$resultset")

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
