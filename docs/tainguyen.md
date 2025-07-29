# 📋 TÀI NGUYÊN CẦN THIẾT - HYPERLEDGER FABRIC NETWORK

## 🖥️ YÊU CẦU HỆ THỐNG

### Hardware Requirements

- **RAM:** 8GB minimum (16GB khuyến nghị)
- **CPU:** 4 cores minimum (8 cores khuyến nghị)  
- **Storage:** 50GB free disk space
- **OS:** macOS 15+ (Sequoia), Windows 10/11, Ubuntu 20.04+

### Software Prerequisites

- **Docker Desktop:** 4.15+ với Docker Compose 2.0+
- **Terminal/Command Line:** bash, zsh
- **Network:** Stable internet connection
- **Browser:** Chrome/Firefox/Safari (để truy cập web interfaces)

---

## 🐳 DOCKER IMAGES CẦN TẢI

### Core Hyperledger Fabric Images

```bash
# Version 2.5.4 (LTS - Long Term Support)
docker pull hyperledger/fabric-ca:2.5.4          # Certificate Authority
docker pull hyperledger/fabric-orderer:2.5.4     # Ordering Service  
docker pull hyperledger/fabric-peer:2.5.4        # Peer Node
docker pull hyperledger/fabric-tools:2.5.4       # CLI Tools
docker pull hyperledger/fabric-ccenv:2.5.4       # Chaincode Environment
```

### Database Images

```bash
docker pull mongo:7.0                             # MongoDB (off-chain data)
docker pull couchdb:3.3                           # CouchDB (state database)
```

### Utility Images

```bash
docker pull alpine:latest                         # Lightweight Linux
docker pull busybox:latest                        # Debugging utilities
```

### Tổng dung lượng images: ~3.5GB

---

## 🔧 HYPERLEDGER FABRIC BINARIES

### Download Script

```bash
# Tải script cài đặt chính thức
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh
chmod +x install-fabric.sh

# Cài đặt binaries version 2.5.4
./install-fabric.sh --fabric-version 2.5.4 binary
```

### Manual Download (Alternative)

```bash
# Cho macOS (Apple Silicon)
wget https://github.com/hyperledger/fabric/releases/download/v2.5.4/hyperledger-fabric-darwin-arm64-2.5.4.tar.gz

# Cho macOS (Intel)
wget https://github.com/hyperledger/fabric/releases/download/v2.5.4/hyperledger-fabric-darwin-amd64-2.5.4.tar.gz
```

### Binaries bao gồm

- `configtxgen` - Generate configuration transactions
- `cryptogen` - Generate crypto materials
- `fabric-ca-client` - CA client
- `fabric-ca-server` - CA server
- `orderer` - Orderer node
- `peer` - Peer node

---

## 📁 CẤU TRÚC THƯ MỤC DỰ ÁN

```bash
fabric-ibn-network/
├── bin/                          # Fabric binaries
│   ├── configtxgen
│   ├── cryptogen
│   ├── fabric-ca-client
│   ├── fabric-ca-server
│   ├── orderer
│   └── peer
├── config/                       # Configuration files
│   ├── configtx.yaml            # Channel & Genesis config
│   ├── crypto-config.yaml       # Crypto generation config
│   └── fabric-ca-server-config.yaml
├── crypto-config/               # Generated certificates
│   ├── ordererOrganizations/
│   │   └── ictu.edu.vn/
│   └── peerOrganizations/
│       └── ibn.ictu.edu.vn/
├── channel-artifacts/           # Channel configuration files
│   ├── genesis.block
│   ├── mychannel.tx
│   └── ibnMSPanchors.tx
├── chaincode/                   # Smart contracts
│   └── fabcar/
│       ├── go/
│       ├── javascript/
│       └── java/
├── scripts/                     # Automation scripts
│   ├── network.sh              # Network management
│   ├── deployCC.sh             # Chaincode deployment
│   ├── envVar.sh               # Environment variables
│   └── utils.sh                # Utility functions
├── docker-compose.yml           # Docker services definition
├── .env                        # Environment variables
├── logs/                       # Application logs
└── README.md                   # Project documentation
```

---

## 🌐 NETWORK CONFIGURATION

### Port Mapping

| Service | Container Name | Ports | Description |
|---------|---------------|-------|-------------|
| CA | ca.ibn.ictu.edu.vn | 7054:7054 | Certificate Authority |
| Orderer | orderer.ictu.edu.vn | 7050:7050 | Ordering Service |
| Peer0 | peer0.ibn.ictu.edu.vn | 7051:7051, 7053:7053 | Peer Node |
| CouchDB | couchdb.ibn.ictu.edu.vn | 5984:5984 | State Database |
| MongoDB | mongodb.ibn.ictu.edu.vn | 27017:27017 | Off-chain Database |
| CLI | cli.ibn.ictu.edu.vn | - | Command Line Interface |

### Docker Networks

```yaml
networks:
  fabric-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

---

## 🔐 CERTIFICATES VÀ KEYS

### Crypto Materials Structure

```bash
crypto-config/
├── ordererOrganizations/
│   └── ictu.edu.vn/
│       ├── ca/                  # CA certificates
│       ├── msp/                 # MSP configuration
│       ├── orderers/
│       │   └── orderer.ictu.edu.vn/
│       └── users/
│           └── Admin@ictu.edu.vn/
└── peerOrganizations/
    └── ibn.ictu.edu.vn/
        ├── ca/
        ├── msp/
        ├── peers/
        │   └── peer0.ibn.ictu.edu.vn/
        └── users/
            ├── Admin@ibn.ictu.edu.vn/
            └── User1@ibn.ictu.edu.vn/
```

---

## 🔧 ENVIRONMENT VARIABLES

### Core Configuration

```bash
# Fabric Configuration Path
export FABRIC_CFG_PATH=$PWD/config

# TLS Settings
export CORE_PEER_TLS_ENABLED=true

# Organization Settings
export CORE_PEER_LOCALMSPID="ibnMSP"
export CORE_PEER_ADDRESS=localhost:7051

# Certificate Paths
export CORE_PEER_TLS_ROOTCERT_FILE=$PWD/crypto-config/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=$PWD/crypto-config/peerOrganizations/ibn.ictu.edu.vn/users/Admin@ibn.ictu.edu.vn/msp

# Orderer Settings
export ORDERER_CA=$PWD/crypto-config/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem
```

### Project Specific

```bash
# Network Configuration
export ORG_NAME="ibn"
export DOMAIN_NAME="ictu.edu.vn"
export CHANNEL_NAME="mychannel"
export CHAINCODE_NAME="fabcar"
export CHAINCODE_VERSION="1.0"

# Docker Configuration
export COMPOSE_PROJECT_NAME="fabric-ibn"
export FABRIC_LOGGING_SPEC="INFO"
```

---

## 📦 CHAINCODE DEPENDENCIES

### Go Chaincode

```bash
# Go version 1.19+
go version

# Dependencies
go mod init
go mod tidy
```

### Node.js Chaincode

```bash
# Node.js 16+
node --version
npm --version

# Dependencies
npm install
```

---

## 🛠️ DEVELOPMENT TOOLS (Optional)

### Code Editors

- **VS Code** với Hyperledger Fabric extension
- **GoLand** cho Go chaincode development
- **WebStorm** cho Node.js chaincode

### Monitoring Tools

- **Docker Desktop Dashboard**
- **Portainer** (container management)
- **MongoDB Compass** (MongoDB GUI)

### Testing Tools

- **Postman** cho API testing
- **curl** cho command line testing
- **jq** cho JSON processing

---

## 📊 RESOURCE MONITORING

### Docker Resource Usage

```bash
# Kiểm tra resource usage
docker stats

# Kiểm tra disk usage
docker system df

# Clean up unused resources
docker system prune -a
```

### Expected Resource Usage

- **RAM Usage:** 4-6GB khi chạy full network
- **CPU Usage:** 20-40% trên 4-core system
- **Disk Usage:** 10-15GB cho full setup
- **Network:** Minimal (local communication)

---

## 🧪 HƯỚNG DẪN TEST CÁC BƯỚC TRIỂN KHAI

### Test Bước 1: CA Server

```bash
# Kiểm tra CA container status
docker ps --filter name=ca.ibn.ictu.edu.vn

# Test CA API endpoint
curl -k https://localhost:7054/cainfo | jq .

# Kiểm tra CA logs
docker logs ca.ibn.ictu.edu.vn --tail 5
```

### Test Bước 2: Certificates

```bash
# Verify certificate format
openssl x509 -in crypto-config/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/msp/signcerts/peer0.ibn.ictu.edu.vn-cert.pem -text -noout | head -10

# Verify Orderer certificate
openssl x509 -in crypto-config/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/signcerts/orderer.ictu.edu.vn-cert.pem -text -noout | head -10

# Verify TLS certificates
openssl x509 -in crypto-config/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/server.crt -text -noout | grep -A 5 "Subject:"

# Kiểm tra MSP structure
ls -la crypto-config/peerOrganizations/ibn.ictu.edu.vn/msp/

# Verify admin certificates
ls -la crypto-config/peerOrganizations/ibn.ictu.edu.vn/users/Admin@ibn.ictu.edu.vn/msp/signcerts/
```

### Test Bước 3: Genesis Block và Orderer

```bash
# Kiểm tra Genesis Block
ls -la channel-artifacts/genesis.block

# Inspect Genesis Block content
./bin/configtxgen -inspectBlock ./channel-artifacts/genesis.block | head -20

# Kiểm tra containers status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test Orderer logs
docker logs orderer.ictu.edu.vn --tail 10

# Test TLS connection đến Orderer
openssl s_client -connect localhost:7050 -servername orderer.ictu.edu.vn < /dev/null 2>/dev/null | grep -E "(CONNECTED|Verify return code)"

# Kiểm tra system channel
docker exec orderer.ictu.edu.vn ls -la /var/hyperledger/production/orderer/chains/

# Kiểm tra block files
docker exec orderer.ictu.edu.vn ls -la /var/hyperledger/production/orderer/chains/system-channel/

# Test MSP configuration
docker exec orderer.ictu.edu.vn ls -la /var/hyperledger/orderer/msp/signcerts/

# Kiểm tra resource usage
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" orderer.ictu.edu.vn ca.ibn.ictu.edu.vn
```

### Test Bước 4: Peer Service

```bash
# Kiểm tra tất cả containers đang chạy
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Test Peer logs
docker logs peer0.ibn.ictu.edu.vn --tail 10

# Test CLI connection đến Peer
docker exec cli peer version

# Test Peer lifecycle commands
docker exec cli peer lifecycle chaincode queryinstalled

# Test TLS connection đến Peer
openssl s_client -connect localhost:7051 -servername peer0.ibn.ictu.edu.vn < /dev/null 2>/dev/null | grep -E "(CONNECTED|Verify return code)"

# Test Peer MSP configuration
docker exec peer0.ibn.ictu.edu.vn ls -la /etc/hyperledger/fabric/msp/signcerts/

# Test CLI MSP configuration
docker exec cli ls -la /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/users/Admin@ibn.ictu.edu.vn/msp/signcerts/

# Test Peer storage
docker exec peer0.ibn.ictu.edu.vn ls -la /var/hyperledger/production/

# Test resource usage tất cả containers
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" ca.ibn.ictu.edu.vn orderer.ictu.edu.vn peer0.ibn.ictu.edu.vn cli
```

### Test Bước 5: Channel và Chaincode (Sẽ cập nhật sau)

```bash
# Placeholder cho test Channel và Chaincode
# Sẽ được cập nhật khi hoàn thành Bước 5
```

### Test Bước 6: Thao Tác Dữ Liệu (Sẽ cập nhật sau)

```bash
# Placeholder cho test thao tác dữ liệu
# Sẽ được cập nhật khi hoàn thành Bước 6
```

### 🔍 Các Lệnh Test Tổng Quát

```bash
# Kiểm tra tất cả containers
docker ps -a

# Kiểm tra logs của tất cả containers
docker compose logs

# Kiểm tra network connectivity
docker network ls
docker network inspect fabric-ibn-network_fabric-network

# Kiểm tra disk usage
du -sh crypto-config/ channel-artifacts/ bin/

# Test cleanup (nếu cần reset)
docker compose down
docker system prune -f
```

### ⚠️ Troubleshooting Commands

```bash
# Restart containers
docker compose restart

# Rebuild containers
docker compose up -d --force-recreate

# Check container health
docker inspect <container_name> | grep -A 10 "Health"

# Debug network issues
docker exec -it <container_name> ping <target_container>

# Interactive CLI access
docker exec -it cli bash
```

---

## 📞 HỖ TRỢ KỸ THUẬT

### Liên hệ
- **Email:** support@ictu.edu.vn
- **Hotline:** 024-3791-7979
- **Documentation:** https://hyperledger-fabric.readthedocs.io/

### Troubleshooting Resources
- **Fabric Samples:** https://github.com/hyperledger/fabric-samples
- **Community Forum:** https://discord.gg/hyperledger
- **Stack Overflow:** Tag `hyperledger-fabric`

---

**📝 Ghi chú:** File này sẽ được cập nhật khi có thêm requirements mới trong quá trình triển khai.

*Cập nhật lần cuối: 2025-07-24*
*Phiên bản tài liệu: v1.0*
