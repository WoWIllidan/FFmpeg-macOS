# 假设你有两个版本的 FFmpeg
ARM64_LIB="/Users/admin/ffmpeg-build/install_arm64/lib"
X86_64_LIB="/Users/admin/ffmpeg-build/install_x86_64/lib"  # 需要先编译 x86_64 版本
OUTPUT_LIB="$HOME/ffmpeg/lib"

# 为每个库创建通用二进制
for lib in libavcodec libavformat libavutil libswscale libswresample libavfilter libavdevice libpostproc; do
    # 找到具体的版本号文件
    arm64_file=$(ls ${ARM64_LIB}/${lib}.*.dylib 2>/dev/null | head -1)
    x86_64_file=$(ls ${X86_64_LIB}/${lib}.*.dylib 2>/dev/null | head -1)
    
    if [ -f "$arm64_file" ] && [ -f "$x86_64_file" ]; then
        output_file="$OUTPUT_LIB/$(basename $arm64_file)"
        echo "合并 $lib..."
        lipo -create "$arm64_file" "$x86_64_file" -output "$output_file"
        
        # 验证
        lipo -info "$output_file"
    fi
done

# 同样处理软链接
cd $OUTPUT_LIB
for lib in libavcodec libavformat libavutil libswscale libswresample libavfilter libavdevice libpostproc; do
    # 创建主版本号软链接和无版本号软链接
    # 例如: libavcodec.62.dylib -> libavcodec.62.3.100.dylib
    #      libavcodec.dylib -> libavcodec.62.dylib
done
