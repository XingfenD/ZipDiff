#!/bin/sh

set -u

# $1 -- instrumented binary path
# $2 -- profdata output path
# $3 -- profraw glob
# $4 -- zip filename
# $5 -- output directory

bin_path="$1"
profdata_path="$2"
profraw_glob="$3"
zip_name="$4"
out_dir="$5"

# shellcheck disable=SC2086
profraw_files=$(ls $profraw_glob 2>/dev/null || true)
if [ -z "$profraw_files" ]; then
  printf "0\n" > "$out_dir/$zip_name.covinfo"
  exit 0
fi

if ! command -v llvm-profdata >/dev/null 2>&1 || ! command -v llvm-cov >/dev/null 2>&1; then
  printf "0\n" > "$out_dir/$zip_name.covinfo"
  exit 0
fi

# Ensure rust-bundled LLVM shared libs are discoverable.
if command -v rustc >/dev/null 2>&1; then
  sysroot=$(rustc --print sysroot 2>/dev/null || true)
  if [ -n "$sysroot" ]; then
    export LD_LIBRARY_PATH="$sysroot/lib/rustlib/x86_64-unknown-linux-gnu/lib:${LD_LIBRARY_PATH:-}"
  fi
fi

# shellcheck disable=SC2086
if ! llvm-profdata merge -sparse $profraw_glob -o "$profdata_path" >/dev/null 2>&1; then
  printf "0\n" > "$out_dir/$zip_name.covinfo"
  exit 0
fi

percent=$(llvm-cov report "$bin_path" -instr-profile="$profdata_path" 2>/dev/null | awk '
  /zip-0\.6\.6\// {
    v = ""
    for (i = 1; i <= NF; i++) {
      if ($i ~ /%$/) {
        v = $i
      }
    }
    if (v != "") {
      gsub("%", "", v)
      sum += v
      n += 1
    }
  }
  END {
    if (n > 0) {
      printf "%.2f", sum / n
    }
  }
')

if [ -z "$percent" ]; then
  percent=$(llvm-cov report "$bin_path" -instr-profile="$profdata_path" 2>/dev/null | awk '
    /^TOTAL/ {
      v = ""
      for (i = 1; i <= NF; i++) {
        if ($i ~ /%$/) {
          v = $i
        }
      }
      if (v != "") {
        gsub("%", "", v)
        print v
        exit
      }
    }
  ')
fi

if [ -z "$percent" ]; then
  percent="0"
fi

printf "%s\n" "$percent" > "$out_dir/$zip_name.covinfo"
