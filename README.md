# 🚀 Hyperledger Fabric Multi-Organization Network

## 📋 Overview

Production-ready multi-organization Hyperledger Fabric network với 3 organizations, 3 peers, 1 orderer và chaincode asset management.

**Network Architecture:**
- **3 Organizations**: IbnMSP, Partner1MSP, Partner2MSP
- **3 Peers**: peer0.ibn.ictu.edu.vn, peer0.partner1.example.com, peer0.partner2.example.com
- **1 Orderer**: orderer.ictu.edu.vn
- **3 Certificate Authorities**: ca.ibn.ictu.edu.vn, ca.partner1.example.com, ca.partner2.example.com
- **Chaincode**: ibn-basic (Asset management)

## 📂 Project Structure

```
fabric-ibn-network/
├── 📁 production-network/        # 🎯 MAIN PRODUCTION DEPLOYMENT
│   ├── config/                   # Production configurations
│   ├── crypto-config/            # Production certificates
│   ├── channel-artifacts/        # Genesis blocks & channels
│   ├── docker-compose-simple.yml # Solo consensus deployment
│   ├── docker-compose-production.yml # Multi-orderer deployment
│   ├── deploy-simple-working-network.sh # Working deployment
│   └── scripts/                  # Deployment automation
│
├── 📁 deployment-package/        # 🎯 ALTERNATIVE WORKING SOLUTION
│   ├── crypto-config-ca/         # CA-based certificates
│   ├── chaincode/                # Chaincode copy
│   ├── docker-compose-ca.yml     # CA-based deployment
│   ├── test-all-functions.sh     # Comprehensive testing
│   └── DEPLOYMENT-INSTRUCTIONS.md # Deployment guide
│
├── 📁 chaincode/                 # 💼 BUSINESS LOGIC
│   └── ibn-basic/                # Asset management chaincode
│       ├── ibn-basic.go          # Smart contract code
│       ├── go.mod                # Go module
│       └── go.sum                # Dependencies
│
├── 📁 bin/                       # 🔧 FABRIC TOOLS
│   ├── configtxgen               # Generate network artifacts
│   ├── cryptogen                 # Generate certificates
│   ├── peer                      # Peer operations
│   ├── fabric-ca-client          # CA client
│   └── fabric-ca-server          # CA server
│
├── 📁 config/                    # ⚙️ CORE CONFIGURATIONS
│   ├── configtx.yaml             # Channel & Genesis config
│   ├── core.yaml                 # Peer configuration
│   ├── crypto-config.yaml        # Certificate config
│   └── orderer.yaml              # Orderer configuration
│
├── � ca-configs/                # 🔐 CA CONFIGURATIONS
├── 📁 scripts/                   # 🛠️ UTILITY SCRIPTS
├── 🧪 test-chaincode-functions.sh # Chaincode testing
├── 🔍 check-deployment-readiness.sh # Deployment verification
└── 📖 README.md                  # This documentation
```

## 🎯 Quick Start

### 🚀 Option 1: Production Network (Recommended)

```bash
# Navigate to production network
cd production-network/

# Deploy simple working network
./deploy-simple-working-network.sh

# Check status
docker ps

# Test chaincode functionality
cd ..
./test-chaincode-functions.sh
```

### 🔄 Option 2: Alternative Deployment Package

```bash
# Navigate to deployment package
cd deployment-package/

# Start CA-based network
docker-compose -f docker-compose-ca.yml up -d

# Run comprehensive tests
./test-all-functions.sh

# Check deployment status
docker ps
```

### 🧪 Testing Chaincode Functions

```bash
# Test all chaincode functions
./test-chaincode-functions.sh

# Check deployment readiness
./check-deployment-readiness.sh
```

## 🔧 System Requirements

- **OS**: Ubuntu 20.04+, Debian 11+, macOS 10.15+
- **RAM**: Minimum 4GB, Recommended 8GB+
- **CPU**: Minimum 2 cores, Recommended 4+ cores
- **Storage**: Minimum 10GB free space
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+

## 🌐 Network Components

| Service | Port | Description |
|---------|------|-------------|
| Ibn Peer | 7051 | Ibn organization peer |
| Partner1 Peer | 8051 | Partner1 organization peer |
| Partner2 Peer | 9051 | Partner2 organization peer |
| Orderer | 7050 | Transaction ordering service |
| Ibn CA | 7054 | Ibn certificate authority |
| Partner1 CA | 8054 | Partner1 certificate authority |
| Partner2 CA | 9054 | Partner2 certificate authority |

## 🧪 Testing

### Chaincode Operations

```bash
# Query all assets
docker exec cli peer chaincode query -C multichannel -n ibn-basic -c '{"function":"GetAllAssets","Args":[]}'

# Create asset
docker exec cli peer chaincode invoke -o orderer.ictu.edu.vn:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/tlsca/tlsca.ictu.edu.vn-cert.pem -C multichannel -n ibn-basic --peerAddresses peer0.ibn.ictu.edu.vn:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt --peerAddresses peer0.partner1.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt -c '{"function":"CreateAsset","Args":["asset8","orange","25","Server","1500"]}'

# Transfer asset
docker exec cli peer chaincode invoke -o orderer.ictu.edu.vn:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/tlsca/tlsca.ictu.edu.vn-cert.pem -C multichannel -n ibn-basic --peerAddresses peer0.ibn.ictu.edu.vn:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt --peerAddresses peer0.partner2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt -c '{"function":"TransferAsset","Args":["asset8","NewOwner"]}'
```

## 🛠️ Management Commands

```bash
# Check container status
docker ps

# View logs
docker logs <container_name>

# Access CLI
docker exec -it cli bash

# Restart network
docker-compose restart

# Clean restart
docker-compose down && docker-compose up -d
```

## 🚨 Troubleshooting

### Common Issues

**Container fails to start:**
```bash
docker logs <container_name>
df -h  # Check disk space
free -h  # Check memory
```

**Chaincode operations fail:**
```bash
# Verify all containers running
docker ps

# Check peer connectivity
docker exec cli peer channel list

# Retry chaincode deployment
./test-multi-org-chaincode.sh
```

**Network connectivity:**
```bash
# Test port connectivity
telnet server-ip 7051

# Check firewall
sudo ufw status
```

## 📈 Development Roadmap

- **Phase 1**: ✅ Multi-org Network (Complete)
- **Phase 2**: 🔄 Application Layer Development
- **Phase 3**: 🔄 REST API Integration
- **Phase 4**: 🔄 Web Portal Development

## 📞 Support

**Status**: ✅ Production Ready  
**Version**: 1.0  
**Last Updated**: July 2025

**Network Features:**
- Multi-organization consensus
- Cross-org data consistency
- Production-grade security
- Scalable architecture
- Complete chaincode operations

---
**Ready for Phase 2: Application Development** 🚀
