# 编译通用二进制的 FFmpeg
./configure \
    --prefix=$HOME/ffmpeg \
    --enable-shared \
    --disable-static \
    --enable-gpl \
    --enable-version3 \
    --enable-nonfree \
    --arch=arm64 \
    --enable-cross-compile \
    --extra-cflags="-arch arm64 -arch x86_64" \
    --extra-ldflags="-arch arm64 -arch x86_64"

make -j$(sysctl -n hw.ncpu)
make install
