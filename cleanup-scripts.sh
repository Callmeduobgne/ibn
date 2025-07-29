#!/bin/bash

# Script dọn dẹp các file script thừa trong workspace
# Tạo bởi: GitHub Copilot

echo "🧹 Phân tích và dọn dẹp file script thừa..."

WORKSPACE="/Users/luongxitin/Documents/blockchain/fabric-ibn-network/deployment-package"
TOTAL_SCRIPTS=$(find "$WORKSPACE" -name "*.sh" | wc -l)
EMPTY_SCRIPTS=0
BACKUP_DIR="${WORKSPACE}/backup-scripts"

echo "📊 Tìm thấy $TOTAL_SCRIPTS file script trong deployment-package"

# Tạo thư mục backup
mkdir -p "$BACKUP_DIR"

echo ""
echo "🔍 Phân tích các file script:"
echo "=================================="

# Kiểm tra file rỗng
echo "📝 File script RỖNG (có thể xóa):"
for script in "$WORKSPACE"/*.sh; do
    if [ -f "$script" ] && [ ! -s "$script" ]; then
        basename "$script"
        ((EMPTY_SCRIPTS++))
    fi
done

echo ""
echo "📏 Kích thước các file script:"
echo "-------------------------------"
for script in "$WORKSPACE"/*.sh; do
    if [ -f "$script" ]; then
        lines=$(wc -l < "$script")
        name=$(basename "$script")
        printf "%-30s %3d dòng\n" "$name" "$lines"
    fi
done

echo ""
echo "🎯 KHUYẾN NGHỊ DỌN DẸP:"
echo "========================"

echo "1. File rỗng cần xóa ($EMPTY_SCRIPTS file):"
for script in "$WORKSPACE"/*.sh; do
    if [ -f "$script" ] && [ ! -s "$script" ]; then
        echo "   - $(basename "$script")"
    fi
done

echo ""
echo "2. File có thể hợp nhất (chức năng tương tự):"
echo "   - simple.sh + ibn-network.sh (wrapper scripts)"
echo "   - các file phase1-*.sh (có thể gộp thành 1)"
echo "   - network-status.sh + start-stable-network.sh"

echo ""
echo "3. File chính cần giữ lại:"
echo "   - ibn-network.sh (script chính)"
echo "   - deploy-chaincode.sh (deploy chaincode)"
echo "   - network-status.sh (kiểm tra trạng thái)"
echo "   - ubuntu-deploy.sh (deploy trên Ubuntu)"

echo ""
echo "🚀 Thực hiện dọn dẹp? (y/n)"
read -p "Nhập lựa chọn: " choice

if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    echo "🧹 Bắt đầu dọn dẹp..."
    
    # Backup file quan trọng trước
    echo "📦 Backup file quan trọng..."
    cp "$WORKSPACE/ibn-network.sh" "$BACKUP_DIR/" 2>/dev/null
    cp "$WORKSPACE/deploy-chaincode.sh" "$BACKUP_DIR/" 2>/dev/null
    cp "$WORKSPACE/network-status.sh" "$BACKUP_DIR/" 2>/dev/null
    
    # Xóa file rỗng
    echo "🗑️  Xóa file rỗng..."
    for script in "$WORKSPACE"/*.sh; do
        if [ -f "$script" ] && [ ! -s "$script" ]; then
            rm -f "$script"
            echo "  ✅ Đã xóa: $(basename "$script")"
        fi
    done
    
    # Xóa file thừa
    echo "🗑️  Xóa file script thừa..."
    
    # File summary không cần thiết
    rm -f "$WORKSPACE/phase1-summary.sh" 2>/dev/null
    rm -f "$WORKSPACE/final-cleanup-summary.sh" 2>/dev/null
    rm -f "$WORKSPACE/docker-consolidation-summary.sh" 2>/dev/null
    
    # File duplicate/redundant
    rm -f "$WORKSPACE/run.sh" 2>/dev/null  # trùng với ibn-network.sh
    rm -f "$WORKSPACE/quick-deploy.sh" 2>/dev/null  # trùng với deploy-chaincode.sh
    
    echo "✅ Hoàn thành dọn dẹp script!"
    
    # Báo cáo kết quả
    NEW_COUNT=$(find "$WORKSPACE" -name "*.sh" | wc -l)
    REMOVED=$((TOTAL_SCRIPTS - NEW_COUNT))
    
    echo ""
    echo "📊 KẾT QUẢ:"
    echo "  📁 Script ban đầu: $TOTAL_SCRIPTS"
    echo "  📁 Script còn lại: $NEW_COUNT"
    echo "  🗑️  Script đã xóa: $REMOVED"
    echo "  💾 Backup tại: $BACKUP_DIR"
    
    echo ""
    echo "📋 Script còn lại:"
    for script in "$WORKSPACE"/*.sh; do
        if [ -f "$script" ]; then
            echo "  - $(basename "$script")"
        fi
    done
else
    echo "❌ Hủy bỏ dọn dẹp script"
fi

echo ""
echo "✨ Hoàn thành phân tích script!"
