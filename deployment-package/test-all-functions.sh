#!/bin/bash

# 🧪 COMPREHENSIVE FABRIC NETWORK TESTING SCRIPT
# Tests all functionality: Network, Channel, Chaincode, Multi-org operations

set -e

echo "🧪 COMPREHENSIVE FABRIC NETWORK TESTING"
echo "========================================"
echo "Testing all functionality on server"
echo "Date: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}🔍 Testing: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Function to run test with output
run_test_with_output() {
    local test_name="$1"
    local test_command="$2"
    
    echo -e "${BLUE}🔍 Testing: $test_name${NC}"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASS: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}❌ FAIL: $test_name${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

echo "🐳 STEP 1: DOCKER INFRASTRUCTURE TESTS"
echo "======================================"

# Test Docker daemon
run_test "Docker daemon running" "docker info"

# Test Docker Compose
run_test "Docker Compose available" "docker-compose --version"

# Test network containers
echo -e "${YELLOW}ℹ️  Checking container status...${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🔗 STEP 2: NETWORK CONNECTIVITY TESTS"
echo "====================================="

# Test container connectivity
run_test "Orderer container running" "docker ps | grep orderer.ictu.edu.vn"
run_test "Ibn peer container running" "docker ps | grep peer0.ibn.ictu.edu.vn"
run_test "Partner1 peer container running" "docker ps | grep peer0.partner1.example.com"
run_test "Partner2 peer container running" "docker ps | grep peer0.partner2.example.com"
run_test "CLI container running" "docker ps | grep cli"

# Test network connectivity between containers
run_test "CLI can reach orderer" "docker exec cli ping -c 1 orderer.ictu.edu.vn"
run_test "CLI can reach ibn peer" "docker exec cli ping -c 1 peer0.ibn.ictu.edu.vn"
run_test "CLI can reach partner1 peer" "docker exec cli ping -c 1 peer0.partner1.example.com"
run_test "CLI can reach partner2 peer" "docker exec cli ping -c 1 peer0.partner2.example.com"

echo ""
echo "📋 STEP 3: CHANNEL OPERATIONS TESTS"
echo "==================================="

# Test channel operations
run_test_with_output "List channels on ibn peer" "docker exec cli peer channel list"

# Test channel info
run_test "Get channel info" "docker exec cli peer channel getinfo -c multichannel"

echo ""
echo "📦 STEP 4: CHAINCODE TESTS"
echo "=========================="

# Test chaincode query
echo -e "${YELLOW}ℹ️  Testing chaincode query operations...${NC}"
run_test_with_output "Query all assets" "docker exec cli peer chaincode query -C multichannel -n ibn-basic -c '{\"Args\":[\"GetAllAssets\"]}'"

# Test chaincode invoke
echo -e "${YELLOW}ℹ️  Testing chaincode invoke operations...${NC}"
run_test_with_output "Create new asset" "docker exec cli peer chaincode invoke -o orderer.ictu.edu.vn:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem -C multichannel -n ibn-basic --peerAddresses peer0.ibn.ictu.edu.vn:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt -c '{\"Args\":[\"CreateAsset\",\"test-asset-$(date +%s)\",\"blue\",\"50\",\"TestOwner\",\"1000\"]}'"

# Test asset existence
run_test_with_output "Query created asset" "docker exec cli peer chaincode query -C multichannel -n ibn-basic -c '{\"Args\":[\"GetAllAssets\"]}' | grep test-asset"

echo ""
echo "🏢 STEP 5: MULTI-ORGANIZATION TESTS"
echo "==================================="

# Test as Partner1 organization
echo -e "${YELLOW}ℹ️  Testing Partner1 organization operations...${NC}"
run_test_with_output "Partner1 query assets" "docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 cli peer chaincode query -C multichannel -n ibn-basic -c '{\"Args\":[\"GetAllAssets\"]}'"

# Test as Partner2 organization
echo -e "${YELLOW}ℹ️  Testing Partner2 organization operations...${NC}"
run_test_with_output "Partner2 query assets" "docker exec -e CORE_PEER_LOCALMSPID=Partner2MSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/peers/peer0.partner2.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner2.example.com/users/Admin@partner2.example.com/msp -e CORE_PEER_ADDRESS=peer0.partner2.example.com:9051 cli peer chaincode query -C multichannel -n ibn-basic -c '{\"Args\":[\"GetAllAssets\"]}'"

echo ""
echo "🔐 STEP 6: SECURITY & PERMISSIONS TESTS"
echo "======================================="

# Test TLS connectivity
run_test "TLS enabled on orderer" "docker exec cli openssl s_client -connect orderer.ictu.edu.vn:7050 -servername orderer.ictu.edu.vn < /dev/null"
run_test "TLS enabled on ibn peer" "docker exec cli openssl s_client -connect peer0.ibn.ictu.edu.vn:7051 -servername peer0.ibn.ictu.edu.vn < /dev/null"

echo ""
echo "📊 STEP 7: PERFORMANCE & MONITORING TESTS"
echo "========================================="

# Test metrics endpoints
run_test "Ibn peer metrics endpoint" "docker exec cli curl -s http://peer0.ibn.ictu.edu.vn:9444/metrics | head -1"
run_test "Partner1 peer metrics endpoint" "docker exec cli curl -s http://peer0.partner1.example.com:9445/metrics | head -1"
run_test "Partner2 peer metrics endpoint" "docker exec cli curl -s http://peer0.partner2.example.com:9446/metrics | head -1"

echo ""
echo "🔄 STEP 8: TRANSACTION FLOW TESTS"
echo "================================="

# Test complete transaction flow
echo -e "${YELLOW}ℹ️  Testing complete transaction flow...${NC}"

# Create asset with multi-org endorsement
ASSET_ID="flow-test-$(date +%s)"
run_test_with_output "Multi-org asset creation" "docker exec cli peer chaincode invoke -o orderer.ictu.edu.vn:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/msp/tlscacerts/tlsca.ictu.edu.vn-cert.pem -C multichannel -n ibn-basic --peerAddresses peer0.ibn.ictu.edu.vn:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/tls/ca.crt --peerAddresses peer0.partner1.example.com:8051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt -c '{\"Args\":[\"CreateAsset\",\"$ASSET_ID\",\"green\",\"75\",\"FlowTestOwner\",\"2000\"]}'"

# Verify asset on all peers
sleep 2
run_test "Asset visible on ibn peer" "docker exec cli peer chaincode query -C multichannel -n ibn-basic -c '{\"Args\":[\"ReadAsset\",\"$ASSET_ID\"]}'"

echo ""
echo "📈 STEP 9: LEDGER CONSISTENCY TESTS"
echo "==================================="

# Test ledger height consistency
echo -e "${YELLOW}ℹ️  Checking ledger consistency across peers...${NC}"
IBN_HEIGHT=$(docker exec cli peer channel getinfo -c multichannel | grep -o '"height":[0-9]*' | cut -d':' -f2)
PARTNER1_HEIGHT=$(docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/tls/ca.crt -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 cli peer channel getinfo -c multichannel | grep -o '"height":[0-9]*' | cut -d':' -f2)

echo "Ibn peer height: $IBN_HEIGHT"
echo "Partner1 peer height: $PARTNER1_HEIGHT"

if [ "$IBN_HEIGHT" = "$PARTNER1_HEIGHT" ]; then
    echo -e "${GREEN}✅ PASS: Ledger heights consistent${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}❌ FAIL: Ledger heights inconsistent${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

echo ""
echo "🎯 FINAL RESULTS"
echo "==============="
echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Network is fully functional.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Check the output above.${NC}"
    exit 1
fi
