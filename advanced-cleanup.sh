#!/bin/bash

# Script nâng cao để dọn dẹp các file thừa còn lại
# Tạo bởi: GitHub Copilot

echo "🔍 Quét sâu workspace để tìm file thừa còn lại..."

WORKSPACE="/Users/luongxitin/Documents/blockchain"
TOTAL_FREED=0

# Hàm tính kích thước
get_size() {
    if [ -e "$1" ]; then
        du -sk "$1" | cut -f1
    else
        echo 0
    fi
}

echo ""
echo "📋 PHÂN TÍCH CHI TIẾT:"
echo "===================="

# 1. File Docker Compose rỗng
echo "🐳 File Docker Compose rỗng:"
EMPTY_DOCKER=$(find "$WORKSPACE" -name "docker-compose*.yml" -empty)
if [ ! -z "$EMPTY_DOCKER" ]; then
    echo "$EMPTY_DOCKER" | while read file; do
        echo "  - $(basename "$file") (0 bytes)"
    done
    echo "  💡 Khuyến nghị: Xóa các file docker-compose rỗng"
else
    echo "  ✅ Không có file docker-compose rỗng"
fi

echo ""

# 2. File .gitkeep không cần thiết  
echo "📁 File .gitkeep:"
GITKEEP_FILES=$(find "$WORKSPACE" -name ".gitkeep")
if [ ! -z "$GITKEEP_FILES" ]; then
    echo "$GITKEEP_FILES" | wc -l | xargs echo "  Tìm thấy" | xargs echo "file .gitkeep"
    echo "  💡 File .gitkeep chỉ để giữ thư mục rỗng trong Git"
else
    echo "  ✅ Không có file .gitkeep thừa"
fi

echo ""

# 3. Gradle wrapper JAR trùng lặp
echo "☕ Gradle wrapper JAR:"
GRADLE_JARS=$(find "$WORKSPACE" -name "gradle-wrapper.jar")
if [ ! -z "$GRADLE_JARS" ]; then
    GRADLE_COUNT=$(echo "$GRADLE_JARS" | wc -l)
    GRADLE_SIZE=$(echo "$GRADLE_JARS" | xargs du -ck | tail -1 | cut -f1)
    echo "  Tìm thấy $GRADLE_COUNT file gradle-wrapper.jar (tổng $(( GRADLE_SIZE / 1024 ))MB)"
    echo "  💡 Có thể gộp chung 1 file gradle-wrapper.jar"
else
    echo "  ✅ Không có Gradle wrapper"
fi

echo ""

# 4. File bin trùng lặp giữa fabric-samples và fabric-ibn-network
echo "⚙️  Binary files trùng lặp:"
IBN_BIN="$WORKSPACE/fabric-ibn-network/bin"
SAMPLES_BIN="$WORKSPACE/fabric-samples/bin"

if [ -d "$IBN_BIN" ] && [ -d "$SAMPLES_BIN" ]; then
    echo "  📂 So sánh fabric-ibn-network/bin vs fabric-samples/bin:"
    
    # Tìm file trùng tên
    for file in "$IBN_BIN"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ -f "$SAMPLES_BIN/$filename" ]; then
                ibn_size=$(get_size "$file")
                samples_size=$(get_size "$SAMPLES_BIN/$filename")
                echo "    🔄 $filename: Ibn($(( ibn_size / 1024 ))MB) vs Samples($(( samples_size / 1024 ))MB)"
            fi
        fi
    done
    
    echo "  💡 Có thể sử dụng symlink thay vì copy file"
fi

echo ""

# 5. File Markdown văn bản dự án
echo "📝 File Markdown dự án:"
MD_FILES=$(find "$WORKSPACE" -maxdepth 1 -name "*.md")
if [ ! -z "$MD_FILES" ]; then
    echo "$MD_FILES" | while read file; do
        size=$(get_size "$file")
        echo "  - $(basename "$file"): $(( size ))KB"
    done
else
    echo "  ✅ Không có file Markdown ở root"
fi

echo ""

# 6. File ảnh/media
echo "🖼️  File media:"
MEDIA_FILES=$(find "$WORKSPACE" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" -o -name "*.pdf" \))
if [ ! -z "$MEDIA_FILES" ]; then
    echo "$MEDIA_FILES" | while read file; do
        size=$(get_size "$file")
        echo "  - $(basename "$file"): $(( size ))KB"
    done
else
    echo "  ✅ Không có file media ở root"
fi

echo ""
echo "🎯 KHUYẾN NGHỊ DỌN DẸP:"
echo "======================"

echo "1. 🗑️  Có thể xóa ngay:"
echo "   - File docker-compose rỗng (0 impact)"
echo "   - File .gitkeep (chỉ cần cho Git)"

echo ""
echo "2. 🔗 Có thể tối ưu:"
echo "   - Tạo symlink cho binary files thay vì copy"
echo "   - Gộp chung gradle-wrapper.jar"

echo ""
echo "3. 📁 Cần review:"
echo "   - File Markdown có thể move vào docs/"
echo "   - File ảnh có thể move vào assets/"

echo ""
echo "🚀 Thực hiện dọn dẹp tự động? (y/n)"
read -p "Nhập lựa chọn: " choice

if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo ""
    echo "🧹 Bắt đầu dọn dẹp tự động..."
    
    # Xóa file docker-compose rỗng
    echo "🐳 Xóa file docker-compose rỗng..."
    REMOVED_DOCKER=0
    find "$WORKSPACE" -name "docker-compose*.yml" -empty | while read file; do
        rm -f "$file"
        echo "  ✅ Đã xóa: $(basename "$file")"
        ((REMOVED_DOCKER++))
    done
    
    # Tạo thư mục docs nếu chưa có
    if [ ! -d "$WORKSPACE/docs" ]; then
        mkdir -p "$WORKSPACE/docs"
        echo "📁 Tạo thư mục docs/"
    fi
    
    # Move file Markdown vào docs (trừ README)
    for file in "$WORKSPACE"/*.md; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "README.md" ]; then
            mv "$file" "$WORKSPACE/docs/"
            echo "  📝 Đã chuyển $(basename "$file") vào docs/"
        fi
    done
    
    # Tạo thư mục assets nếu có file ảnh
    MEDIA_COUNT=$(find "$WORKSPACE" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) | wc -l)
    if [ $MEDIA_COUNT -gt 0 ]; then
        mkdir -p "$WORKSPACE/assets"
        for file in "$WORKSPACE"/*.jpg "$WORKSPACE"/*.png "$WORKSPACE"/*.gif; do
            if [ -f "$file" ]; then
                mv "$file" "$WORKSPACE/assets/"
                echo "  🖼️  Đã chuyển $(basename "$file") vào assets/"
            fi
        done
    fi
    
    echo ""
    echo "✅ Hoàn thành dọn dẹp tự động!"
    
    # Báo cáo kết quả
    echo ""
    echo "📊 KẾT QUẢ:"
    echo "  🗑️  File docker-compose rỗng: Đã xóa"
    echo "  📁 File Markdown: Đã chuyển vào docs/"
    echo "  🖼️  File ảnh: Đã chuyển vào assets/"
    
    echo ""
    echo "📏 Cấu trúc workspace sau dọn dẹp:"
    tree -L 2 "$WORKSPACE" 2>/dev/null || ls -la "$WORKSPACE"
    
else
    echo "❌ Hủy bỏ dọn dẹp tự động"
fi

echo ""
echo "✨ Hoàn thành quét sâu workspace!"
