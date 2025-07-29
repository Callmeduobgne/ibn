# IBN Blockchain Network

🚀 **IBN (Islamic Banking Network)** - Mạng blockchain Hyperledger Fabric dành cho hệ thống ngân hàng Hồi giáo

## 📋 Tổng quan

Dự án IBN là một mạng blockchain được xây dựng trên nền tảng Hyperledger Fabric, được thiết kế đặc biệt cho hệ thống ngân hàng tuân thủ các nguyên tắc tài chính Hồi giáo (Islamic Banking).

## 🏗️ Cấu trúc dự án

```
blockchain/
├── fabric-ibn-network/          # Mạng blockchain IBN chính
│   ├── bin/                     # Binary files của Fabric
│   ├── chaincode/               # Smart contracts
│   │   └── ibn-basic/          # Chaincode cơ bản IBN
│   └── deployment-package/      # Package triển khai
│       ├── configtx.yaml       # Cấu hình transaction
│       ├── crypto-config.yaml  # Cấu hình crypto
│       ├── docker-compose.yml  # Docker compose
│       └── scripts/            # Các script triển khai
├── fabric-samples/             # Mẫu Hyperledger Fabric
├── kehoach.md                  # Kế hoạch dự án
├── tainguyen.md               # Tài nguyên tham khảo
└── giaidoan2.jpg              # Sơ đồ giai đoạn 2
```

## 🚀 Cài đặt và chạy

### Yêu cầu hệ thống

- Docker & Docker Compose
- Go 1.19+
- Node.js 16+
- Git

### Cài đặt nhanh

```bash
# Clone repository
git clone https://github.com/Callmeduobgne/ibn.git
cd ibn

# Cài đặt Hyperledger Fabric
cd fabric-ibn-network
./install-fabric.sh

# Khởi động mạng
cd deployment-package
./ibn-network.sh start

# Deploy chaincode
./deploy-chaincode.sh

# Kiểm tra trạng thái
./network-status.sh
```

## 📦 Các thành phần chính

### 1. IBN Chaincode
- **Vị trí**: `fabric-ibn-network/chaincode/ibn-basic/`
- **Ngôn ngữ**: Go
- **Chức năng**: Xử lý các giao dịch ngân hàng tuân thủ Sharia

### 2. Network Configuration
- **Configtx**: Cấu hình channel và ordering service
- **Crypto-config**: Cấu hình certificate authorities
- **Docker Compose**: Orchestration các container

### 3. Deployment Scripts
- `ibn-network.sh`: Script chính quản lý mạng
- `deploy-chaincode.sh`: Deploy smart contracts
- `network-status.sh`: Kiểm tra trạng thái mạng
- `simple.sh`: Script đơn giản cho người dùng

## 🔧 Các lệnh hữu ích

```bash
# Khởi động mạng
./simple.sh run

# Dừng mạng
./simple.sh stop

# Kiểm tra trạng thái
./simple.sh test

# Dọn dẹp workspace
./cleanup-script.sh
```

## 📚 Tài liệu

- [Kế hoạch dự án](kehoach.md)
- [Tài nguyên tham khảo](tainguyen.md)
- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)

## 🛠️ Development

### Cấu trúc Chaincode

```go
// ibn-basic.go
func (s *SmartContract) CreateAsset(ctx contractapi.TransactionContextInterface, 
    id string, owner string, amount int) error {
    // Implementation
}
```

### Testing

```bash
# Test chaincode
cd fabric-ibn-network/chaincode/ibn-basic
go test

# Test network
./network-status.sh
```

## 🚢 Deployment

### Development Environment
```bash
./ibn-network.sh start
```

### Production Environment
```bash
# Sử dụng deployment package
cd deployment-package
./prepare-ubuntu-deployment.sh
```

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Callmeduobgne** - *Initial work* - [GitHub](https://github.com/Callmeduobgne)

## 🙏 Acknowledgments

- Hyperledger Fabric community
- Islamic Banking principles and guidelines
- Blockchain development community

---

📅 **Cập nhật lần cuối**: 29/07/2025  
🚀 **Phiên bản**: 1.0.0  
⭐ **Trạng thái**: Active Development
