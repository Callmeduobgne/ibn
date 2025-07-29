# 🚀 FABRIC IBN NETWORK - DEPLOYMENT GUIDE

## 📋 **UPDATED DEPLOYMENT INSTRUCTIONS**
**Last Updated**: July 27, 2025
**Status**: Production Ready

## 🎯 **DEPLOYMENT OPTIONS**

### **Option 1: Local Development**
```bash
# Clone/navigate to project
cd fabric-ibn-network/

# Choose deployment method:
# A) Production Network (Recommended)
cd production-network/
./deploy-simple-working-network.sh

# B) Alternative CA-based
cd deployment-package/
docker-compose -f docker-compose-ca.yml up -d
```

### **Option 2: Server Deployment**
```bash
# Copy entire project to server
scp -r fabric-ibn-network/ user@server:~/

# SSH to server
ssh user@server
cd fabric-ibn-network/

# Deploy production network
cd production-network/
./deploy-simple-working-network.sh
```

### **Option 3: Package Deployment**
```bash
# Copy deployment package only
scp -r deployment-package/ user@server:~/

# On server
cd deployment-package/
docker-compose -f docker-compose-ca.yml up -d
./test-all-functions.sh
```

## Network Access
- **Orderer:** 100.120.39.103:7050
- **Ibn Peer:** 100.120.39.103:7051
- **Partner1 Peer:** 100.120.39.103:8051
- **Partner2 Peer:** 100.120.39.103:9051
- **Ibn CA:** 100.120.39.103:7054
- **Partner1 CA:** 100.120.39.103:8054
- **Partner2 CA:** 100.120.39.103:9054
- **Orderer CA:** 100.120.39.103:10054

## Firewall Rules (if needed)
```bash
sudo ufw allow 7050,7051,8051,9051,7054,8054,9054,10054/tcp
```

## User z Access
User z can join the network by:
1. Using the CLI container: `docker exec -it cli bash`
2. Accessing peer endpoints directly
3. Using the Fabric SDK with provided certificates

## Chaincode Deployment
The ibn-basic chaincode is ready for deployment:
- Package: ibn-basic.tar.gz (10.3MB)
- Functions: 8 (InitLedger, CreateAsset, ReadAsset, etc.)
- Status: Ready for installation

## Support
Network is production-ready with:
- ✅ Fabric CA certificate management
- ✅ TLS security enabled
- ✅ Multi-organization support
- ✅ Chaincode development environment
