FROM alpine:3.20

RUN apk add --no-cache g++ make cmake lcov zlib-dev

ADD https://github.com/pocoproject/poco/archive/refs/tags/poco-1.13.3-release.tar.gz /tmp/src.tar.gz
RUN tar xf /tmp/src.tar.gz -C / && mv /poco-* /poco && rm -f /tmp/src.tar.gz

WORKDIR /poco
RUN cmake -S . -B build \
    -D CMAKE_BUILD_TYPE=Debug \
    -D CMAKE_CXX_FLAGS="-O0 -g --coverage" \
    -D CMAKE_C_FLAGS="-O0 -g --coverage" \
    -D CMAKE_EXE_LINKER_FLAGS="--coverage" \
    -D BUILD_SHARED_LIBS=OFF \
    -D ENABLE_ZIP=ON \
    -D ENABLE_FOUNDATION=ON \
    -D ENABLE_XML=ON \
    -D ENABLE_ENCODINGS=OFF \
    -D ENABLE_ENCODINGS_COMPILER=OFF \
    -D ENABLE_JSON=OFF \
    -D ENABLE_MONGODB=OFF \
    -D ENABLE_DATA_SQLITE=OFF \
    -D ENABLE_REDIS=OFF \
    -D ENABLE_PROMETHEUS=OFF \
    -D ENABLE_UTIL=OFF \
    -D ENABLE_NET=OFF \
    -D ENABLE_SEVENZIP=OFF \
    -D ENABLE_CPPPARSER=OFF \
    -D ENABLE_POCODOC=OFF \
    -D ENABLE_PAGECOMPILER=OFF \
    -D ENABLE_PAGECOMPILER_FILE2PAGE=OFF \
    -D ENABLE_ACTIVERECORD=OFF \
    -D ENABLE_ACTIVERECORD_COMPILER=OFF
RUN cmake --build build --config Debug -j$(nproc)

WORKDIR /workspace
COPY unzip.cpp /workspace/
RUN g++ /workspace/unzip.cpp \
    -O0 -g --coverage \
    -I/poco/Foundation/include \
    -I/poco/Zip/include \
    -o /workspace/unzip-bin \
    /poco/build/lib/libPocoZip.a \
    /poco/build/lib/libPocoFoundation.a \
    -lz -lpthread --coverage

COPY unzip unzip-all.sh coverage.sh app.env /workspace/

ENTRYPOINT ["/workspace/unzip-all.sh"]
