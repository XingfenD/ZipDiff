#!/bin/bash

set -euo pipefail

base="$(dirname "$(dirname "$(realpath "$0")")")"

"$base"/tools/prepare.sh

rm -rf "$base"/evaluation/{input,output}
mkdir -p "$base/evaluation/input"

for i in $(seq 1 $#); do
    testcase="$(realpath "${!i}")"
    cp "$testcase" "$base/evaluation/input/$i.zip"
done

pushd "$base/parsers"
docker compose up
popd

for i in $(seq 1 $#); do
    testcase="$(realpath "${!i}")"
    result="$base/evaluation/results/${testcase#"$base/"}"
    rm -rf "$result"
    mkdir -p "$result"
    for p in "$base/parsers/"*/; do
        parser="$(basename "$p")"
        mv "$base/evaluation/output/$parser/$i.zip" "$result/$parser" &
    done
done

wait
