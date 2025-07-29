#!/bin/bash

# Script để dọn dẹp các file thừa trong workspace blockchain
# Tạo bởi: GitHub Copilot
# Ngày: $(date)

echo "🧹 Bắt đầu dọn dẹp workspace blockchain..."

# Biến để theo dõi dung lượng đã giải phóng
TOTAL_FREED=0

# Hàm tính toán kích thước file/thư mục
get_size() {
    if [ -e "$1" ]; then
        du -sk "$1" | cut -f1
    else
        echo 0
    fi
}

# 1. Xóa file .DS_Store
echo "🗂️  Đang xóa file .DS_Store..."
find /Users/luongxitin/Documents/blockchain -name ".DS_Store" -type f | while read file; do
    if [ -f "$file" ]; then
        size=$(get_size "$file")
        rm -f "$file"
        echo "  ✅ Đã xóa: $file"
        TOTAL_FREED=$((TOTAL_FREED + size))
    fi
done

# 2. Xóa thư mục bin trùng lặp trong deployment-package (143MB)
echo "📁 Đang xóa thư mục bin trùng lặp..."
DUPLICATE_BIN="/Users/luongxitin/Documents/blockchain/fabric-ibn-network/deployment-package/bin"
if [ -d "$DUPLICATE_BIN" ]; then
    size=$(get_size "$DUPLICATE_BIN")
    rm -rf "$DUPLICATE_BIN"
    echo "  ✅ Đã xóa thư mục bin trùng lặp: $DUPLICATE_BIN ($(( size / 1024 ))MB)"
    TOTAL_FREED=$((TOTAL_FREED + size))
fi

# 3. Kiểm tra và xóa file tar.gz deployment nếu đã có thư mục giải nén
TAR_FILE="/Users/luongxitin/Documents/blockchain/fabric-ibn-network/deployment-package/ibn-ubuntu-deployment.tar.gz"
EXTRACT_DIR="/Users/luongxitin/Documents/blockchain/fabric-ibn-network/deployment-package/ibn-ubuntu-deploy"

if [ -f "$TAR_FILE" ] && [ -d "$EXTRACT_DIR" ]; then
    echo "📦 Phát hiện file tar.gz và thư mục đã giải nén..."
    echo "  Bạn có muốn xóa file tar.gz không? (y/n)"
    read -p "  Nhập lựa chọn: " choice
    if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
        size=$(get_size "$TAR_FILE")
        rm -f "$TAR_FILE"
        echo "  ✅ Đã xóa file tar.gz: $TAR_FILE ($(( size / 1024 ))MB)"
        TOTAL_FREED=$((TOTAL_FREED + size))
    fi
fi

# 4. Dọn dẹp file script thừa
echo "📜 Đang dọn dẹp file script thừa..."
SCRIPT_DIR="/Users/luongxitin/Documents/blockchain/fabric-ibn-network/deployment-package"
EMPTY_SCRIPTS=$(find "$SCRIPT_DIR" -name "*.sh" -empty 2>/dev/null | wc -l)

if [ $EMPTY_SCRIPTS -gt 0 ]; then
    echo "  📝 Tìm thấy $EMPTY_SCRIPTS file script rỗng"
    find "$SCRIPT_DIR" -name "*.sh" -empty -delete 2>/dev/null
    echo "  ✅ Đã xóa các file script rỗng"
    TOTAL_FREED=$((TOTAL_FREED + EMPTY_SCRIPTS))
fi

# 5. Tìm và liệt kê các file có thể thừa khác
echo "🔍 Tìm kiếm các file có thể thừa khác..."

# Tìm file log
LOG_FILES=$(find /Users/luongxitin/Documents/blockchain -name "*.log" -type f 2>/dev/null)
if [ ! -z "$LOG_FILES" ]; then
    echo "  📝 Tìm thấy các file log:"
    echo "$LOG_FILES" | while read file; do
        echo "    - $file"
    done
fi

# Tìm file tạm
TEMP_FILES=$(find /Users/luongxitin/Documents/blockchain -name "*.tmp" -o -name "*.bak" -o -name "*.old" -type f 2>/dev/null)
if [ ! -z "$TEMP_FILES" ]; then
    echo "  🗃️  Tìm thấy các file tạm:"
    echo "$TEMP_FILES" | while read file; do
        echo "    - $file"
    done
fi

# 6. Báo cáo kết quả
echo ""
echo "📊 BÁO CÁO DỌN DẸP:"
echo "  💾 Dung lượng đã giải phóng: $(( TOTAL_FREED / 1024 ))MB"
echo "  📜 File script đã dọn dẹp: ✅"
echo ""

# 7. Kiểm tra kích thước sau khi dọn dẹp
echo "📏 Kích thước thư mục sau khi dọn dẹp:"
du -sh /Users/luongxitin/Documents/blockchain/* | sort -hr

echo ""
echo "✨ Hoàn thành dọn dẹp workspace!"
