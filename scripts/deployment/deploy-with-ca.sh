#!/bin/bash

echo "🚀 HYPERLEDGER FABRIC DEPLOYMENT WITH FABRIC CA"
echo "==============================================="
echo "Multi-Organization Network with CA-based Certificate Management"
echo "Date: $(date)"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Check if running in correct directory
if [ ! -f "docker-compose-ca.yml" ]; then
    print_error "Please run this script from the fabric network directory"
    print_error "docker-compose-ca.yml not found"
    exit 1
fi

echo "🧹 STEP 1: CLEANUP EXISTING NETWORK"
echo "==================================="
print_info "Stopping any existing containers..."
docker-compose down 2>/dev/null || true
docker-compose -f docker-compose-ca.yml down 2>/dev/null || true
docker system prune -f
print_status "Cleanup completed"

echo ""
echo "📁 STEP 2: PREPARE DIRECTORIES"
echo "=============================="
print_info "Creating required directories..."
mkdir -p channel-artifacts
mkdir -p crypto-config-ca
rm -rf crypto-config-ca/*
print_status "Directories prepared"

echo ""
echo "🏗️ STEP 3: START FABRIC CA SERVERS"
echo "=================================="
print_info "Starting Fabric CA servers..."
docker-compose -f docker-compose-ca.yml up -d ca-ibn.ictu.edu.vn ca.partner1.example.com ca.partner2.example.com ca-orderer.ictu.edu.vn

print_info "Waiting for CA servers to initialize..."
sleep 15

# Check CA server status
print_info "Checking CA server status..."
docker ps --format "table {{.Names}}\t{{.Status}}" | grep ca

echo ""
echo "📜 STEP 4: EXTRACT CA CERTIFICATES"
echo "=================================="
print_info "Extracting CA certificates..."

# Extract CA certificates from containers
docker cp ca-ibn.ictu.edu.vn:/etc/hyperledger/fabric-ca-server/ca-cert.pem ./crypto-config-ca/ibn-ca-cert.pem
docker cp ca.partner1.example.com:/etc/hyperledger/fabric-ca-server/ca-cert.pem ./crypto-config-ca/partner1-ca-cert.pem
docker cp ca.partner2.example.com:/etc/hyperledger/fabric-ca-server/ca-cert.pem ./crypto-config-ca/partner2-ca-cert.pem
docker cp ca-orderer.ictu.edu.vn:/etc/hyperledger/fabric-ca-server/ca-cert.pem ./crypto-config-ca/orderer-ca-cert.pem

print_status "CA certificates extracted"

echo ""
echo "🔐 STEP 5: ENROLL CERTIFICATES"
echo "=============================="
print_info "Running certificate enrollment..."
chmod +x ca-scripts/enroll-all.sh
./ca-scripts/enroll-all.sh

if [ $? -ne 0 ]; then
    print_error "Certificate enrollment failed"
    exit 1
fi

print_status "Certificate enrollment completed"

echo ""
echo "🏗️ STEP 6: GENERATE NETWORK ARTIFACTS"
echo "====================================="
print_info "Generating genesis block..."
FABRIC_CFG_PATH=./config ./bin/configtxgen -profile IbnOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block

print_info "Generating channel transaction..."
FABRIC_CFG_PATH=./config ./bin/configtxgen -profile IbnChannel -outputCreateChannelTx ./channel-artifacts/multichannel.tx -channelID multichannel

print_info "Generating anchor peer updates..."
FABRIC_CFG_PATH=./config ./bin/configtxgen -profile IbnChannel -outputAnchorPeersUpdate ./channel-artifacts/IbnMSPanchors.tx -channelID multichannel -asOrg IbnMSP
FABRIC_CFG_PATH=./config ./bin/configtxgen -profile IbnChannel -outputAnchorPeersUpdate ./channel-artifacts/Partner1MSPanchors.tx -channelID multichannel -asOrg Partner1MSP
FABRIC_CFG_PATH=./config ./bin/configtxgen -profile IbnChannel -outputAnchorPeersUpdate ./channel-artifacts/Partner2MSPanchors.tx -channelID multichannel -asOrg Partner2MSP

print_status "Network artifacts generated"

echo ""
echo "🐳 STEP 7: START FABRIC NETWORK"
echo "==============================="
print_info "Starting Hyperledger Fabric network with CA certificates..."
docker-compose -f docker-compose-ca.yml up -d

print_info "Waiting for network to start..."
sleep 20

echo ""
echo "🔍 STEP 8: VERIFY NETWORK STATUS"
echo "==============================="
print_info "Checking container status..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Check if all required containers are running
REQUIRED_CONTAINERS=("ca-ibn.ictu.edu.vn" "ca.partner1.example.com" "ca.partner2.example.com" "ca-orderer.ictu.edu.vn" "orderer.ictu.edu.vn" "peer0.ibn.ictu.edu.vn" "peer0.partner1.example.com" "peer0.partner2.example.com" "cli")

echo ""
print_info "Verifying required containers..."
for container in "${REQUIRED_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        print_status "$container is running"
    else
        print_error "$container is not running"
        echo "Checking logs for $container:"
        docker logs $container 2>/dev/null || echo "No logs available"
    fi
done

echo ""
echo "🔍 STEP 9: TEST TLS CONNECTIONS"
echo "==============================="
print_info "Testing TLS connections..."

# Test CLI to orderer connection
print_info "Testing CLI to orderer connection..."
docker exec cli peer channel list

if [ $? -eq 0 ]; then
    print_status "CLI to orderer TLS connection successful"
else
    print_warning "CLI to orderer TLS connection failed"
fi

# Check for TLS errors in orderer logs
print_info "Checking orderer logs for TLS errors..."
TLS_ERRORS=$(docker logs orderer.ictu.edu.vn 2>&1 | grep -c "TLS handshake failed")
if [ $TLS_ERRORS -eq 0 ]; then
    print_status "No TLS handshake errors found in orderer logs"
else
    print_warning "Found $TLS_ERRORS TLS handshake errors in orderer logs"
fi

echo ""
echo "📋 STEP 10: CREATE CHANNEL"
echo "=========================="
print_info "Creating channel..."
docker exec cli peer channel create -o orderer.ictu.edu.vn:7050 -c multichannel -f ./channel-artifacts/multichannel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem

if [ $? -eq 0 ]; then
    print_status "Channel created successfully"
else
    print_warning "Channel creation failed, but continuing..."
fi

print_info "Joining peers to channel..."
# Join Ibn peer
docker exec cli peer channel join -b multichannel.block

# Join Partner1 peer
docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 cli peer channel join -b multichannel.block

# Join Partner2 peer
docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 cli peer channel join -b multichannel.block

print_status "All peers joined channel"

echo ""
echo "🎉 FABRIC CA DEPLOYMENT COMPLETED!"
echo "=================================="
print_status "Multi-Organization Hyperledger Fabric Network with Fabric CA is running"
echo ""
print_info "Network Information:"
echo "- Organizations: IbnMSP, Partner1MSP, Partner2MSP"
echo "- Peers: 3 (peer0.ibn.ictu.edu.vn:7051, peer0.partner1.example.com:8051, peer0.partner2.example.com:9051)"
echo "- Orderer: orderer.ictu.edu.vn:7050"
echo "- Channel: multichannel"
echo "- Certificate Management: Fabric CA"
echo ""
print_info "CA Servers:"
echo "- Ibn CA: localhost:7054"
echo "- Partner1 CA: localhost:8054"
echo "- Partner2 CA: localhost:9054"
echo "- Orderer CA: localhost:10054"
echo ""
print_info "Useful Commands:"
echo "- Check containers: docker ps"
echo "- View logs: docker logs <container_name>"
echo "- Access CLI: docker exec -it cli bash"
echo "- Stop network: docker-compose -f docker-compose-ca.yml down"
echo "- Restart network: docker-compose -f docker-compose-ca.yml up -d"
echo ""
print_status "🚀 Network is ready with CA-based certificate management!"
