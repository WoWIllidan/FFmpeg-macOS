#!/bin/bash
# 修复 FFmpeg 库的 install_name
# 将从 ffmpeg-build/install_universal 复制到 $HOME/ffmpeg 的库文件路径修正为 @rpath
# 在 $HOME/ffmpeg 目录下执行此脚本

set -e

# 使用当前目录作为 FFmpeg 目录
FFMPEG_DIR="$(pwd)"

if [ ! -d "$FFMPEG_DIR/lib" ]; then
    echo "Error: $FFMPEG_DIR/lib not found"
    echo "Please run this script from your FFmpeg installation directory (e.g., $HOME/ffmpeg)"
    exit 1
fi

echo "Fixing FFmpeg library paths in $FFMPEG_DIR/lib"
echo ""

cd "$FFMPEG_DIR/lib" || exit 1

# 自动检测旧的前缀路径（从任意一个库文件中读取）
OLD_PREFIX=$(otool -L libavcodec.dylib 2>/dev/null | grep -o '/[^[:space:]]*/ffmpeg-build/install_[^/]*' | head -1 | sed 's|/lib/.*||')

if [ -z "$OLD_PREFIX" ]; then
    echo "✅ Libraries already use @rpath, no changes needed."
    exit 0
fi

echo "Detected old prefix: $OLD_PREFIX"
echo "Will replace with: @rpath"
echo ""

# 修复每个 .dylib 文件
for lib in *.dylib; do
    if [ -f "$lib" ]; then
        echo "Processing $lib..."
        
        # 修改自身的 install_name
        install_name_tool -id "@rpath/$lib" "$lib"
        
        # 修改依赖库的路径
        otool -L "$lib" | grep "$OLD_PREFIX" | awk '{print $1}' | while read dep; do
            libname=$(basename "$dep")
            echo "  Changing $dep -> @rpath/$libname"
            install_name_tool -change "$dep" "@rpath/$libname" "$lib"
        done
    fi
done

# 处理版本号库（例如 libavcodec.62.dylib）
for lib in *.*.dylib; do
    if [ -f "$lib" ]; then
        echo "Processing $lib..."
        
        install_name_tool -id "@rpath/$lib" "$lib"
        
        otool -L "$lib" | grep "$OLD_PREFIX" | awk '{print $1}' | while read dep; do
            libname=$(basename "$dep")
            echo "  Changing $dep -> @rpath/$libname"
            install_name_tool -change "$dep" "@rpath/$libname" "$lib"
        done
    fi
done

echo "Done! Verifying..."
echo ""
echo "Checking libavcodec.dylib:"
otool -L libavcodec.dylib | head -5

echo ""
echo "✅ FFmpeg library paths fixed!"
echo "Libraries now use @rpath, which will be resolved at runtime."
