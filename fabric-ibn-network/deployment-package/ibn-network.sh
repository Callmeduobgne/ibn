#!/bin/bash

# 🚀 IBN Blockchain Network - One-Click Deployment Script
# This script handles everything: setup, network, chaincode, and testing

set -e

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_header() { echo -e "${BLUE}═══════════════════════════════════════${NC}"; echo -e "${BLUE}$1${NC}"; echo -e "${BLUE}═══════════════════════════════════════${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

# Script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

show_help() {
    echo "🚀 IBN Blockchain Network - One-Click Deployment"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  start         🟢 Start complete network + deploy chaincode + test"
    echo "  stop          🔴 Stop network and cleanup"
    echo "  restart       🔄 Restart network (stop + start)"
    echo "  status        📊 Check network status"
    echo "  test          🧪 Test chaincode functions"
    echo "  logs          📜 Show container logs"
    echo "  clean         🧹 Full cleanup (remove containers, volumes, images)"
    echo "  help          ❓ Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 start      # Deploy everything from scratch"
    echo "  $0 test       # Test existing network"
    echo "  $0 clean      # Clean everything and start fresh"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

generate_crypto() {
    print_info "Generating crypto materials..."
    
    # Clean old crypto
    rm -rf crypto-config-cryptogen
    
    # Generate new crypto
    ./bin/cryptogen generate --config=crypto-config.yaml --output="crypto-config-cryptogen"
    
    if [ ! -d "crypto-config-cryptogen" ]; then
        print_error "Failed to generate crypto materials"
        exit 1
    fi
    
    print_success "Crypto materials generated"
}

generate_genesis() {
    print_info "Generating genesis block and channel artifacts..."
    
    # Clean old artifacts
    rm -rf channel-artifacts-new
    mkdir -p channel-artifacts-new
    
    # Set fabric config path
    export FABRIC_CFG_PATH="$SCRIPT_DIR"
    
    # Generate genesis block
    ./bin/configtxgen -profile IbnOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts-new/genesis.block
    
    # Generate channel configuration
    ./bin/configtxgen -profile IbnChannel -outputCreateChannelTx ./channel-artifacts-new/channel.tx -channelID mychannel
    
    # Generate anchor peer configs
    ./bin/configtxgen -profile IbnChannel -outputAnchorPeersUpdate ./channel-artifacts-new/IbnMSPanchors.tx -channelID mychannel -asOrg IbnMSP
    ./bin/configtxgen -profile IbnChannel -outputAnchorPeersUpdate ./channel-artifacts-new/Partner1MSPanchors.tx -channelID mychannel -asOrg Partner1MSP
    ./bin/configtxgen -profile IbnChannel -outputAnchorPeersUpdate ./channel-artifacts-new/Partner2MSPanchors.tx -channelID mychannel -asOrg Partner2MSP
    
    print_success "Genesis block and channel artifacts generated"
}

start_network() {
    print_info "Starting blockchain network..."
    
    # Stop any existing network
    docker-compose down &> /dev/null || true
    
    # Start network
    docker-compose up -d
    
    # Wait for containers to be ready
    print_info "Waiting for containers to be ready..."
    sleep 10
    
    # Check if all containers are running
    if [ "$(docker-compose ps -q | wc -l)" -ne 5 ]; then
        print_error "Not all containers are running"
        docker-compose ps
        exit 1
    fi
    
    print_success "Network started successfully"
}

create_channel() {
    print_info "Creating and joining channel..."
    
    # Create channel
    docker exec cli peer channel create -o orderer.ictu.edu.vn:7050 -c mychannel -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem
    
    # Join peers to channel
    # Ibn peer
    docker exec cli peer channel join -b mychannel.block
    
    # Partner1 peer
    docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt cli peer channel join -b mychannel.block
    
    # Partner2 peer
    docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt cli peer channel join -b mychannel.block
    
    print_success "Channel created and peers joined"
}

deploy_chaincode() {
    print_info "Deploying chaincode..."
    
    # Package chaincode
    docker exec cli peer lifecycle chaincode package ibn-basic.tar.gz --path /opt/gopath/src/github.com/chaincode/ibn-basic --lang golang --label ibn-basic_1.0
    
    # Install on all peers
    docker exec cli peer lifecycle chaincode install ibn-basic.tar.gz
    
    docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt cli peer lifecycle chaincode install ibn-basic.tar.gz
    
    docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt cli peer lifecycle chaincode install ibn-basic.tar.gz
    
    # Get package ID
    PACKAGE_ID=$(docker exec cli peer lifecycle chaincode queryinstalled | grep "ibn-basic_1.0" | cut -d: -f3 | cut -d, -f1)
    
    # Approve chaincode for all orgs
    docker exec cli peer lifecycle chaincode approveformyorg -o orderer.ictu.edu.vn:7050 --channelID mychannel --name ibn-basic --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem
    
    docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.ictu.edu.vn:7050 --channelID mychannel --name ibn-basic --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem
    
    docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt cli peer lifecycle chaincode approveformyorg -o orderer.ictu.edu.vn:7050 --channelID mychannel --name ibn-basic --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem
    
    # Commit chaincode
    docker exec cli peer lifecycle chaincode commit -o orderer.ictu.edu.vn:7050 --channelID mychannel --name ibn-basic --version 1.0 --sequence 1 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem --peerAddresses peer0.ibn.ictu.edu.vn:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt --peerAddresses peer0.partner1.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt --peerAddresses peer0.partner2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt
    
    # Initialize ledger
    docker exec cli peer chaincode invoke -o orderer.ictu.edu.vn:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem -C mychannel -n ibn-basic --peerAddresses peer0.ibn.ictu.edu.vn:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt --peerAddresses peer0.partner1.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt --peerAddresses peer0.partner2.example.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt -c '{"function":"InitLedger","Args":[]}'
    
    print_success "Chaincode deployed and initialized"
}

test_chaincode() {
    print_info "Testing chaincode functions..."
    
    # Test GetAllAssets
    print_info "Testing GetAllAssets..."
    docker exec cli peer chaincode query -C mychannel -n ibn-basic -c '{"function":"GetAllAssets","Args":[]}'
    
    # Test CreateAsset
    print_info "Testing CreateAsset..."
    docker exec cli peer chaincode invoke -o orderer.ictu.edu.vn:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem -C mychannel -n ibn-basic --peerAddresses peer0.ibn.ictu.edu.vn:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt -c '{"function":"CreateAsset","Args":["asset7","purple","20","TestUser","900"]}'
    
    # Test ReadAsset
    print_info "Testing ReadAsset..."
    docker exec cli peer chaincode query -C mychannel -n ibn-basic -c '{"function":"ReadAsset","Args":["asset7"]}'
    
    print_success "Chaincode tests completed"
}

show_status() {
    print_header "IBN BLOCKCHAIN NETWORK STATUS"
    
    print_info "Container Status:"
    docker-compose ps
    
    echo ""
    print_info "Network Health Checks:"
    
    # Check orderer
    if docker exec orderer.ictu.edu.vn sh -c 'curl -sSf http://localhost:9443/healthz' &> /dev/null; then
        print_success "Orderer is healthy"
    else
        print_error "Orderer is not healthy"
    fi
    
    # Check CLI connectivity
    if docker exec cli peer channel list &> /dev/null; then
        print_success "CLI can connect to peers"
    else
        print_error "CLI cannot connect to peers"
    fi
    
    echo ""
    print_info "Quick Commands:"
    echo "  $0 test       # Test chaincode functions"
    echo "  $0 logs       # View container logs"
    echo "  $0 stop       # Stop the network"
}

show_logs() {
    echo "📜 Container Logs:"
    echo ""
    docker-compose logs --tail=50 -f
}

stop_network() {
    print_info "Stopping blockchain network..."
    docker-compose down
    print_success "Network stopped"
}

clean_all() {
    print_warning "This will remove all containers, volumes, and chaincode images!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning everything..."
        docker-compose down --volumes --remove-orphans
        docker system prune -f
        docker volume prune -f
        rm -rf crypto-config-cryptogen channel-artifacts-new *.tar.gz
        print_success "Full cleanup completed"
    else
        print_info "Cleanup cancelled"
    fi
}

# Main execution
case "${1:-help}" in
    "start")
        print_header "STARTING IBN BLOCKCHAIN NETWORK"
        check_prerequisites
        generate_crypto
        generate_genesis
        start_network
        sleep 5
        create_channel
        deploy_chaincode
        print_success "🎉 IBN Blockchain Network is ready!"
        echo ""
        print_info "Next steps:"
        echo "  $0 test       # Test the network"
        echo "  $0 status     # Check status"
        ;;
    "stop")
        print_header "STOPPING NETWORK"
        stop_network
        ;;
    "restart")
        print_header "RESTARTING NETWORK"
        stop_network
        sleep 2
        start_network
        ;;
    "status")
        show_status
        ;;
    "test")
        print_header "TESTING CHAINCODE"
        test_chaincode
        ;;
    "logs")
        show_logs
        ;;
    "clean")
        print_header "FULL CLEANUP"
        clean_all
        ;;
    "help"|*)
        show_help
        ;;
esac
