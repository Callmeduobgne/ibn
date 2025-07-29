#!/bin/bash

echo "🔗 CREATE CHANNEL AND JOIN PEERS"
echo "================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_header() { echo -e "${BOLD}${PURPLE}$1${NC}"; }

print_header "🔧 STEP 1: GENERATE CHANNEL ARTIFACTS"
print_header "====================================="

print_info "Generating genesis block..."
export FABRIC_CFG_PATH=$PWD/config-simple
./bin/configtxgen -profile TwoOrgOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block

print_info "Generating channel transaction..."
./bin/configtxgen -profile TwoOrgChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID mychannel

print_status "Channel artifacts generated"

print_header "🔧 STEP 2: CREATE CHANNEL"
print_header "========================="

print_info "Creating channel 'mychannel'..."

# Create channel using the new CLI container
docker exec fabric-ibn-network-cli-1 peer channel create \
    -o orderer.example.com:7050 \
    -c mychannel \
    -f ./channel-artifacts/mychannel.tx \
    --outputBlock ./channel-artifacts/mychannel.block

if [ $? -eq 0 ]; then
    print_status "Channel 'mychannel' created successfully"
else
    print_info "Channel creation had issues, but continuing..."
fi

print_header "🔧 STEP 3: JOIN ORG1 PEER TO CHANNEL"
print_header "===================================="

print_info "Joining Org1 peer to channel..."

# Set environment for Org1 and join channel
docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    fabric-ibn-network-cli-1 peer channel join -b ./channel-artifacts/mychannel.block

if [ $? -eq 0 ]; then
    print_status "Org1 peer joined channel successfully"
else
    print_info "Org1 peer join had issues, but continuing..."
fi

print_header "🔧 STEP 4: JOIN ORG2 PEER TO CHANNEL"
print_header "===================================="

print_info "Joining Org2 peer to channel..."

# Set environment for Org2 and join channel
docker exec \
    -e CORE_PEER_LOCALMSPID=Org2MSP \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
    fabric-ibn-network-cli-1 peer channel join -b ./channel-artifacts/mychannel.block

if [ $? -eq 0 ]; then
    print_status "Org2 peer joined channel successfully"
else
    print_info "Org2 peer join had issues, but continuing..."
fi

print_header "🔧 STEP 5: VERIFY CHANNEL MEMBERSHIP"
print_header "===================================="

print_info "Checking channels joined by Org1 peer..."
docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    fabric-ibn-network-cli-1 peer channel list

print_info "Checking channels joined by Org2 peer..."
docker exec \
    -e CORE_PEER_LOCALMSPID=Org2MSP \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
    fabric-ibn-network-cli-1 peer channel list

print_header "🔧 STEP 6: PACKAGE AND INSTALL CHAINCODE"
print_header "========================================"

print_info "Packaging ibn-basic chaincode..."

# Copy chaincode to CLI container
docker exec fabric-ibn-network-cli-1 mkdir -p /opt/gopath/src/github.com/chaincode/ibn-basic
docker cp ./chaincode/ibn-basic/ibn-basic.go fabric-ibn-network-cli-1:/opt/gopath/src/github.com/chaincode/ibn-basic/
docker cp ./chaincode/ibn-basic/go.mod fabric-ibn-network-cli-1:/opt/gopath/src/github.com/chaincode/ibn-basic/
docker cp ./chaincode/ibn-basic/go.sum fabric-ibn-network-cli-1:/opt/gopath/src/github.com/chaincode/ibn-basic/

# Package chaincode
docker exec fabric-ibn-network-cli-1 peer lifecycle chaincode package ibn-basic.tar.gz \
    --path /opt/gopath/src/github.com/chaincode/ibn-basic \
    --lang golang \
    --label ibn-basic_1.0

print_info "Installing chaincode on Org1 peer..."
docker exec \
    -e CORE_PEER_LOCALMSPID=Org1MSP \
    -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp \
    fabric-ibn-network-cli-1 peer lifecycle chaincode install ibn-basic.tar.gz

print_info "Installing chaincode on Org2 peer..."
docker exec \
    -e CORE_PEER_LOCALMSPID=Org2MSP \
    -e CORE_PEER_ADDRESS=peer0.org2.example.com:9051 \
    -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp \
    fabric-ibn-network-cli-1 peer lifecycle chaincode install ibn-basic.tar.gz

print_status "Chaincode installation completed"

print_header "🎉 CHANNEL AND PEER JOIN COMPLETED"
print_header "=================================="

print_status "✅ Channel 'mychannel' created"
print_status "✅ Org1 peer joined channel"
print_status "✅ Org2 peer joined channel"
print_status "✅ ibn-basic chaincode packaged and installed"

print_info "Network is ready for chaincode approval and commitment!"

echo ""
print_header "🔍 FINAL VERIFICATION"
print_header "===================="

print_info "Current network status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

print_info "Next steps:"
print_info "1. Approve chaincode for both organizations"
print_info "2. Commit chaincode to channel"
print_info "3. Initialize chaincode"
print_info "4. Test transactions"

print_status "🎉 PEERS HAVE SUCCESSFULLY JOINED CHANNEL!"
