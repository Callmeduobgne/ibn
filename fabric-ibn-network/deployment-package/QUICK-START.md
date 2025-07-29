# 🚀 IBN Blockchain Network - Quick Start

## Siêu đơn giản - chỉ 3 lệnh!

### 1️⃣ Chạy toàn bộ blockchain (1 lệnh)
```bash
./simple.sh run
```
✅ Tự động: Generate crypto → Start network → Deploy chaincode → Test

### 2️⃣ Test blockchain 
```bash
./simple.sh test
```
✅ Kiểm tra toàn bộ network status và connectivity

### 3️⃣ Dừng blockchain
```bash
./simple.sh stop
```
✅ Dừng toàn bộ network

---

## Thậm chí còn đơn giản hơn!

### 🔥 One-Click Start (siêu nhanh)
```bash
./run.sh
```
Chỉ 1 lệnh → có blockchain hoàn chỉnh!

---

## Advanced (nếu muốn chi tiết hơn)

```bash
./ibn-network.sh start    # Start everything
./ibn-network.sh status   # Check status  
./ibn-network.sh test     # Test chaincode
./ibn-network.sh logs     # View logs
./ibn-network.sh clean    # Full cleanup
```

---

## Cấu trúc project sau khi dọn dẹp

```
deployment-package/
├── run.sh              # 🔥 ONE-CLICK START
├── simple.sh           # 🎯 3 lệnh đơn giản  
├── ibn-network.sh      # 🛠️ Advanced script
├── docker-compose.yml  # Docker config
├── configtx.yaml       # Network config
├── crypto-config.yaml  # Crypto config
└── chaincode/          # Smart contracts
```

## Blockchain Info
- **3 Organizations**: Ibn, Partner1, Partner2
- **4 Containers**: 1 Orderer + 3 Peers + 1 CLI
- **Chaincode**: Asset management (ibn-basic)
- **Channel**: mychannel

---

**🎉 Từ giờ bạn chỉ cần nhớ:** `./simple.sh run` để có blockchain hoàn chỉnh!
