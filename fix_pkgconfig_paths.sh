#!/bin/bash
# 修复 pkg-config 文件中的 FFmpeg 路径
# 将 ffmpeg-build/install_* 路径替换为当前目录（$HOME/ffmpeg）
# 从 ffmpeg-build/install_universal 复制文件后，在 $HOME/ffmpeg 目录下执行此脚本

set -e

# 默认使用当前目录下的 lib/pkgconfig
if [ -n "$1" ]; then
    PKGCONFIG_DIR="$1"
else
    PKGCONFIG_DIR="lib/pkgconfig"
fi

if [ ! -d "$PKGCONFIG_DIR" ]; then
    echo "Error: Directory '$PKGCONFIG_DIR' not found"
    exit 1
fi

echo "Fixing pkg-config paths in: $PKGCONFIG_DIR"
echo ""

# 统计信息
total_files=0
fixed_files=0

# 查找所有 .pc 文件
while IFS= read -r -d '' pcfile; do
    total_files=$((total_files + 1))
    filename=$(basename "$pcfile")
    
    # 检查文件是否包含需要替换的路径
    if grep -q "ffmpeg-build/install_\(arm64\|universal\|x86_64\)" "$pcfile"; then
        echo "Processing: $filename"
        
        # 备份原文件
        cp "$pcfile" "$pcfile.bak"
        
        # 执行替换
        # 获取当前工作目录的绝对路径（应该是 $HOME/ffmpeg）
        TARGET_DIR="$(pwd)"
        
        # 替换所有 ffmpeg-build/install_* 路径为当前目录
        # 1. 替换 /Users/xxx/ffmpeg-build/install_arm64 -> $TARGET_DIR
        # 2. 替换 /Users/xxx/ffmpeg-build/install_universal -> $TARGET_DIR
        # 3. 替换 /Users/xxx/ffmpeg-build/install_x86_64 -> $TARGET_DIR
        sed -i '' \
            -e "s|/Users/[^/]*/ffmpeg-build/install_arm64|$TARGET_DIR|g" \
            -e "s|/Users/[^/]*/ffmpeg-build/install_universal|$TARGET_DIR|g" \
            -e "s|/Users/[^/]*/ffmpeg-build/install_x86_64|$TARGET_DIR|g" \
            "$pcfile"
        
        # 显示变化
        echo "  Changes:"
        diff "$pcfile.bak" "$pcfile" | grep "^[<>]" | head -5 || echo "  (Complex changes, see $pcfile.bak for original)"
        echo ""
        
        fixed_files=$((fixed_files + 1))
    fi
done < <(find "$PKGCONFIG_DIR" -name "*.pc" -type f -print0)

echo "----------------------------------------"
echo "Summary:"
echo "  Total .pc files: $total_files"
echo "  Files modified:  $fixed_files"
echo ""

if [ $fixed_files -gt 0 ]; then
    echo "✅ Paths fixed successfully!"
    echo ""
    echo "Backups saved with .bak extension"
    echo "To remove backups: rm $PKGCONFIG_DIR/*.pc.bak"
    echo ""
    echo "Verify changes:"
    echo "  grep -r 'ffmpeg-build' $PKGCONFIG_DIR"
    echo "  (Should show no results if all paths fixed)"
else
    echo "ℹ️  No paths needed fixing"
fi

echo ""
echo "Example usage:"
echo "  pkg-config --cflags libavcodec"
echo "  pkg-config --libs libavformat"
