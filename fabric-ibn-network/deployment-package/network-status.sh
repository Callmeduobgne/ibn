#!/bin/bash

# 🎯 Ibn Blockchain Network - Complete Status Check

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_header() { echo -e "${PURPLE}═══════════════════════════════════════${NC}"; echo -e "${PURPLE}$1${NC}"; echo -e "${PURPLE}═══════════════════════════════════════${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

print_header "IBN BLOCKCHAIN NETWORK - FINAL STATUS"

echo "🕒 $(date)"
echo ""

# 1. Container Status
print_info "1. CONTAINER STATUS"
RUNNING_CONTAINERS=$(docker-compose ps -q | wc -l)
if [ "$RUNNING_CONTAINERS" -eq 5 ]; then
    print_success "All 5 containers running"
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
else
    print_error "Only $RUNNING_CONTAINERS/5 containers running"
    docker-compose ps
fi
echo ""

# 2. Peer Channel Membership
print_info "2. CHANNEL MEMBERSHIP"
echo -n "• Ibn peer: "
if docker exec cli peer channel list 2>/dev/null | grep -q "mychannel"; then
    print_success "Joined mychannel"
else
    print_error "Not joined to mychannel"
fi

echo -n "• Partner1 peer: "
if docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt cli peer channel list 2>/dev/null | grep -q "mychannel"; then
    print_success "Joined mychannel"
else
    print_error "Not joined to mychannel"
fi

echo -n "• Partner2 peer: "
if docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt cli peer channel list 2>/dev/null | grep -q "mychannel"; then
    print_success "Joined mychannel"
else
    print_error "Not joined to mychannel"
fi
echo ""

# 3. Orderer Health
print_info "3. ORDERER HEALTH"
if curl -sSf http://localhost:9443/healthz &> /dev/null; then
    print_success "Orderer health endpoint responding"
else
    print_warning "Orderer health endpoint not accessible (normal on some setups)"
fi
echo ""

# 4. Chaincode Status
print_info "4. CHAINCODE STATUS"
COMMITTED_CC=$(docker exec cli peer lifecycle chaincode querycommitted --channelID mychannel 2>/dev/null | grep -c "Name:" || echo "0")
if [ "$COMMITTED_CC" -gt 0 ]; then
    print_success "$COMMITTED_CC chaincode(s) committed"
    docker exec cli peer lifecycle chaincode querycommitted --channelID mychannel
else
    print_warning "No chaincode committed (chaincode deployment pending)"
fi
echo ""

# 5. Network Connectivity Test
print_info "5. NETWORK CONNECTIVITY TEST"
echo -n "• CLI to orderer: "
if docker exec cli peer channel list &>/dev/null; then
    print_success "Connected"
else
    print_error "Connection failed"
fi

echo -n "• Peer-to-peer gossip: "
if docker logs peer0.ibn.ictu.edu.vn 2>&1 | grep -q "Joining gossip network"; then
    print_success "Gossip active"
else
    print_warning "Gossip status unclear"
fi
echo ""

# 6. Storage and Certificates
print_info "6. CRYPTO MATERIALS"
if [ -d "crypto-config-cryptogen" ]; then
    CERT_COUNT=$(find crypto-config-cryptogen -name "*.pem" | wc -l)
    print_success "$CERT_COUNT certificates generated"
else
    print_error "Crypto materials missing"
fi

if [ -f "channel-artifacts-new/genesis.block" ]; then
    GENESIS_SIZE=$(ls -lh channel-artifacts-new/genesis.block | awk '{print $5}')
    print_success "Genesis block created ($GENESIS_SIZE)"
else
    print_error "Genesis block missing"
fi
echo ""

# Summary
print_header "SUMMARY"

HEALTH_SCORE=0
MAX_SCORE=6

# Score calculation
[ "$RUNNING_CONTAINERS" -eq 5 ] && ((HEALTH_SCORE++))
docker exec cli peer channel list 2>/dev/null | grep -q "mychannel" && ((HEALTH_SCORE++))
docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt cli peer channel list 2>/dev/null | grep -q "mychannel" && ((HEALTH_SCORE++))
docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt cli peer channel list 2>/dev/null | grep -q "mychannel" && ((HEALTH_SCORE++))
docker exec cli peer channel list &>/dev/null && ((HEALTH_SCORE++))
[ -d "crypto-config-cryptogen" ] && [ -f "channel-artifacts-new/genesis.block" ] && ((HEALTH_SCORE++))

PERCENTAGE=$((HEALTH_SCORE * 100 / MAX_SCORE))

if [ "$PERCENTAGE" -eq 100 ]; then
    print_success "🎉 NETWORK HEALTH: $PERCENTAGE% ($HEALTH_SCORE/$MAX_SCORE)"
    print_success "Ibn Blockchain Network is fully operational!"
elif [ "$PERCENTAGE" -ge 80 ]; then
    print_warning "⚡ NETWORK HEALTH: $PERCENTAGE% ($HEALTH_SCORE/$MAX_SCORE)"
    print_info "Network is mostly functional"
else
    print_error "⚠️  NETWORK HEALTH: $PERCENTAGE% ($HEALTH_SCORE/$MAX_SCORE)"
    print_info "Network needs attention"
fi

echo ""
print_info "🚀 READY TO USE COMMANDS:"
echo "  ./simple.sh run     # Restart network"
echo "  ./simple.sh stop    # Stop network"  
echo "  ./ibn-network.sh status # Detailed status"
echo "  docker-compose logs # View logs"

echo ""
if [ "$COMMITTED_CC" -eq 0 ]; then
    print_info "📋 NEXT STEPS:"
    print_info "Network infrastructure complete! For chaincode deployment:"
    print_info "• Use Linux environment with proper Docker access"
    print_info "• Or implement external chaincode service"
    print_info "• Current setup perfect for network testing & development"
fi

print_header "STATUS CHECK COMPLETED"
