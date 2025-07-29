#!/bin/bash

# 🚀 Deploy Chaincode - Simple Approach (No Docker-in-Docker needed)

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

print_info "Starting chaincode deployment..."

# Clean old files
rm -f *.tar.gz *.tgz connection.json metadata.json code.tar.gz

# Method 1: Try simple Go chaincode package
print_info "Creating simple chaincode package..."

# Create a simple chaincode package manually
mkdir -p chaincode-pkg/src
cp -r chaincode/ibn-basic/* chaincode-pkg/src/

# Create package
cd chaincode-pkg
tar czf ../ibn-basic-simple.tar.gz src/
cd ..
rm -rf chaincode-pkg

# Copy to CLI container
docker cp ibn-basic-simple.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/

print_info "Installing chaincode on Ibn peer..."
if docker exec cli peer lifecycle chaincode install ibn-basic-simple.tar.gz 2>/dev/null; then
    print_success "Chaincode installed successfully"
    PACKAGE_APPROACH="simple"
else
    print_warning "Simple approach failed, trying external approach..."
    
    # Method 2: External chaincode approach
    print_info "Creating external chaincode package..."
    
    # Create external chaincode files
    cat > connection.json << 'EOF'
{
  "address": "127.0.0.1:7052",
  "dial_timeout": "10s",
  "tls_required": false
}
EOF

    cat > metadata.json << 'EOF'
{
    "type": "external",
    "label": "ibn-basic_1.0"
}
EOF

    # Package external chaincode
    tar czf code.tar.gz connection.json
    tar czf ibn-basic-external.tar.gz metadata.json code.tar.gz
    
    # Copy to CLI
    docker cp ibn-basic-external.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/
    
    if docker exec cli peer lifecycle chaincode install ibn-basic-external.tar.gz 2>/dev/null; then
        print_success "External chaincode installed successfully"
        PACKAGE_APPROACH="external"
    else
        # Method 3: Pre-built binary approach
        print_warning "External approach failed, trying pre-built binary..."
        
        # Create a package with the pre-built binary
        mkdir -p chaincode-binary
        cp chaincode/ibn-basic/ibn-basic chaincode-binary/
        
        # Create a simple package structure
        cat > chaincode-binary/metadata.json << 'EOF'
{
    "type": "golang",
    "label": "ibn-basic_1.0"
}
EOF
        
        cd chaincode-binary
        tar czf ../ibn-basic-binary.tar.gz .
        cd ..
        rm -rf chaincode-binary
        
        docker cp ibn-basic-binary.tar.gz cli:/opt/gopath/src/github.com/hyperledger/fabric/peer/
        
        if docker exec cli peer lifecycle chaincode install ibn-basic-binary.tar.gz 2>/dev/null; then
            print_success "Binary chaincode installed successfully"
            PACKAGE_APPROACH="binary"
        else
            print_error "All chaincode installation methods failed"
            print_info "Network is running but chaincode deployment requires Docker-in-Docker"
            print_info "You can still test network connectivity and peer functionality"
            exit 1
        fi
    fi
fi

# Get package ID
print_info "Getting package ID..."
PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep "ibn-basic_1.0" | head -1 | cut -d: -f3 | cut -d, -f1)

if [ -z "$PACKAGE_ID" ]; then
    print_error "Could not get package ID"
    exit 1
fi

print_success "Package ID: $PACKAGE_ID"

# Install on Partner1 peer
print_info "Installing chaincode on Partner1 peer..."
docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP \
    -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install ibn-basic-${PACKAGE_APPROACH}.tar.gz

# Install on Partner2 peer
print_info "Installing chaincode on Partner2 peer..."
docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP \
    -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt \
    cli peer lifecycle chaincode install ibn-basic-${PACKAGE_APPROACH}.tar.gz

# Approve chaincode for Ibn org
print_info "Approving chaincode for Ibn organization..."
docker exec cli peer lifecycle chaincode approveformyorg \
    -o orderer.ictu.edu.vn:7050 \
    --channelID mychannel \
    --name ibn-basic \
    --version 1.0 \
    --package-id $PACKAGE_ID \
    --sequence 1 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem

# Approve chaincode for Partner1 org
print_info "Approving chaincode for Partner1 organization..."
docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP \
    -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt \
    cli peer lifecycle chaincode approveformyorg \
    -o orderer.ictu.edu.vn:7050 \
    --channelID mychannel \
    --name ibn-basic \
    --version 1.0 \
    --package-id $PACKAGE_ID \
    --sequence 1 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem

# Approve chaincode for Partner2 org
print_info "Approving chaincode for Partner2 organization..."
docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP \
    -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt \
    cli peer lifecycle chaincode approveformyorg \
    -o orderer.ictu.edu.vn:7050 \
    --channelID mychannel \
    --name ibn-basic \
    --version 1.0 \
    --package-id $PACKAGE_ID \
    --sequence 1 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem

# Check commit readiness
print_info "Checking commit readiness..."
docker exec cli peer lifecycle chaincode checkcommitreadiness \
    --channelID mychannel \
    --name ibn-basic \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem \
    --output json

# Commit chaincode
print_info "Committing chaincode definition..."
docker exec cli peer lifecycle chaincode commit \
    -o orderer.ictu.edu.vn:7050 \
    --channelID mychannel \
    --name ibn-basic \
    --version 1.0 \
    --sequence 1 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem \
    --peerAddresses peer0.ibn.ictu.edu.vn:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt \
    --peerAddresses peer0.partner1.example.com:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt \
    --peerAddresses peer0.partner2.example.com:9051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt

# Wait a bit for chaincode to be ready
print_info "Waiting for chaincode to be ready..."
sleep 5

# Test if chaincode works (without InitLedger first)
print_info "Testing chaincode query..."
if docker exec cli peer chaincode query -C mychannel -n ibn-basic -c '{"function":"GetAllAssets","Args":[]}' 2>/dev/null; then
    print_success "Chaincode is working! But ledger is empty."
    print_info "Initializing ledger with sample data..."
    
    # Initialize ledger
    docker exec cli peer chaincode invoke \
        -o orderer.ictu.edu.vn:7050 \
        --tls \
        --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem \
        -C mychannel \
        -n ibn-basic \
        --peerAddresses peer0.ibn.ictu.edu.vn:7051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt \
        --peerAddresses peer0.partner1.example.com:8051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt \
        --peerAddresses peer0.partner2.example.com:9051 \
        --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt \
        -c '{"function":"InitLedger","Args":[]}'
    
    sleep 3
    
    # Test again
    print_info "Testing chaincode after initialization..."
    docker exec cli peer chaincode query -C mychannel -n ibn-basic -c '{"function":"GetAllAssets","Args":[]}'
    
    print_success "🎉 Chaincode deployment completed successfully!"
    print_info "You can now test all chaincode functions"
    
else
    print_warning "Chaincode committed but may need external service for $PACKAGE_APPROACH approach"
    print_info "Network is functional, chaincode definition is committed"
fi

# Cleanup temp files
rm -f *.tar.gz *.tgz connection.json code.tar.gz

print_success "Deployment script completed!"
