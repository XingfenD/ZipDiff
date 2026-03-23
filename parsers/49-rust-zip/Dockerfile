FROM rust:1.85-slim-bookworm

WORKDIR /workspace/src

RUN cargo init
RUN cargo add zip@0.6.6
RUN rustup component add llvm-tools-preview

COPY unzip.rs /workspace/src/src/main.rs

RUN RUSTFLAGS="-C instrument-coverage" cargo build --release
RUN cp /workspace/src/target/release/unzip /workspace/unzip-bin
RUN SYSROOT=$(rustc --print sysroot) && \
    cp "$SYSROOT/lib/rustlib/x86_64-unknown-linux-gnu/bin/llvm-profdata" /usr/local/bin/llvm-profdata && \
    cp "$SYSROOT/lib/rustlib/x86_64-unknown-linux-gnu/bin/llvm-cov" /usr/local/bin/llvm-cov

WORKDIR /workspace
COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
