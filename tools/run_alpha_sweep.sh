#!/bin/bash
# 运行 alpha-sweep 实验，各跑 3600 秒（1小时）
# 结果存到 evaluation/stats/alpha-sweep/alpha<X>.json

set -e
REPO="$(dirname "$0")/.."
REPO="$(cd "$REPO" && pwd)"

ALPHAS="0.1 0.3 0.5 1.0 1.5"
OUT_DIR="$REPO/evaluation/stats/alpha-sweep"
mkdir -p "$OUT_DIR"

for ALPHA in $ALPHAS; do
    OUTFILE="$OUT_DIR/alpha${ALPHA}.json"
    if [ -f "$OUTFILE" ]; then
        echo "[SKIP] $OUTFILE already exists"
        continue
    fi
    echo "========================================"
    echo "[START] alpha=$ALPHA  $(date '+%Y-%m-%d %H:%M:%S')"
    echo "========================================"
    cd "$REPO/zip-diff"
    ./target/release/fuzz \
        -b 50 \
        --batch-timeout-secs 300 \
        -s 3600 \
        --parsers-dir "$REPO/parsers" \
        --input-dir "$REPO/evaluation/input" \
        --output-dir "$REPO/evaluation/output" \
        --samples-dir "$REPO/evaluation/samples" \
        --results-dir "$REPO/evaluation/results" \
        --coverage-ucb-alpha "$ALPHA" \
        --stats-file "$OUTFILE"
    echo "[DONE]  alpha=$ALPHA  $(date '+%Y-%m-%d %H:%M:%S')"
done

echo "All alpha-sweep runs complete."
