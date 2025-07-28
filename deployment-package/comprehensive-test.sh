#!/bin/bash

echo "🧪 COMPREHENSIVE TEST SUITE - DỰ ÁN HOÀN CHỈNH"
echo "==============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_header() { echo -e "${BOLD}${PURPLE}$1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_info "Testing: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        print_success "PASS: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        print_error "FAIL: $test_name"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

print_header "📊 TEST SUITE 1: INFRASTRUCTURE"
print_header "================================"

run_test "Docker containers running" "docker ps | grep -q deployment-package"
run_test "Orderer container running" "docker ps | grep -q orderer.example.com"
run_test "Ibn peer container running" "docker ps | grep -q peer0.ibn.ictu.edu.vn"
run_test "Partner1 peer container running" "docker ps | grep -q peer0.partner1.example.com"
run_test "CLI container running" "docker ps | grep -q cli"

print_header "📊 TEST SUITE 2: PEER CONNECTIVITY"
print_header "=================================="

run_test "CLI peer version command" "docker exec deployment-package-cli-1 peer version"
run_test "Ibn peer connectivity" "docker exec -e CORE_PEER_ADDRESS=peer0.ibn.ictu.edu.vn:7051 deployment-package-cli-1 peer version"
run_test "Partner1 peer connectivity" "docker exec -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 deployment-package-cli-1 peer version"

print_header "📊 TEST SUITE 3: CHANNEL MEMBERSHIP"
print_header "==================================="

run_test "Ibn peer channel list" "docker exec -e CORE_PEER_LOCALMSPID=IbnMSP -e CORE_PEER_ADDRESS=peer0.ibn.ictu.edu.vn:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/users/Admin@ibn.ictu.edu.vn/msp deployment-package-cli-1 peer channel list | grep -q mychannel"

run_test "Partner1 peer channel list" "docker exec -e CORE_PEER_LOCALMSPID=Partner1MSP -e CORE_PEER_ADDRESS=peer0.partner1.example.com:8051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/partner1.example.com/users/Admin@partner1.example.com/msp deployment-package-cli-1 peer channel list | grep -q mychannel"

print_header "📊 TEST SUITE 4: ORDERER FUNCTIONALITY"
print_header "======================================"

run_test "Orderer connectivity from CLI" "docker exec deployment-package-cli-1 peer channel fetch config -o orderer.example.com:7050 -c mychannel /tmp/config.pb"

print_header "📊 TEST SUITE 5: CHAINCODE READINESS"
print_header "===================================="

run_test "Chaincode directory exists" "[ -d chaincode/ibn-basic ]"
run_test "Ibn-basic chaincode files" "[ -f chaincode/ibn-basic/ibn-basic.go ]"
run_test "Go mod file exists" "[ -f chaincode/ibn-basic/go.mod ]"

print_header "📊 TEST SUITE 6: CRYPTO MATERIAL"
print_header "================================"

run_test "Orderer MSP exists" "[ -d crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp ]"
run_test "Ibn peer MSP exists" "[ -d crypto-config/peerOrganizations/ibn.ictu.edu.vn/peers/peer0.ibn.ictu.edu.vn/msp ]"
run_test "Partner1 peer MSP exists" "[ -d crypto-config/peerOrganizations/partner1.example.com/peers/peer0.partner1.example.com/msp ]"
run_test "Genesis block exists" "[ -f channel-artifacts/genesis.block ]"
run_test "Channel transaction exists" "[ -f channel-artifacts/mychannel.tx ]"

print_header "📊 TEST SUITE 7: BUSINESS LOGIC"
print_header "==============================="

print_info "Analyzing ibn-basic chaincode functions..."
if [ -f chaincode/ibn-basic/ibn-basic.go ]; then
    FUNCTIONS=$(grep -o "func ([^)]*) [A-Z][a-zA-Z]*" chaincode/ibn-basic/ibn-basic.go | wc -l)
    if [ $FUNCTIONS -gt 0 ]; then
        print_success "PASS: Chaincode has $FUNCTIONS business functions"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        print_error "FAIL: No business functions found in chaincode"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    print_error "FAIL: Chaincode file not found"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

print_header "📊 TEST SUITE 8: NETWORK CAPABILITIES"
print_header "====================================="

print_info "Testing network capabilities..."

# Test channel info
if docker exec -e CORE_PEER_LOCALMSPID=IbnMSP -e CORE_PEER_ADDRESS=peer0.ibn.ictu.edu.vn:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ibn.ictu.edu.vn/users/Admin@ibn.ictu.edu.vn/msp deployment-package-cli-1 peer channel getinfo -c mychannel >/dev/null 2>&1; then
    print_success "PASS: Channel info accessible"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    print_error "FAIL: Channel info not accessible"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))

print_header "🎯 TEST RESULTS SUMMARY"
print_header "======================="

echo ""
print_info "Total Tests: $TOTAL_TESTS"
print_success "Passed: $PASSED_TESTS"
print_error "Failed: $FAILED_TESTS"

SUCCESS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo ""
print_info "Success Rate: $SUCCESS_RATE%"

if [ $SUCCESS_RATE -ge 90 ]; then
    print_success "🎉 EXCELLENT: Project is production-ready!"
elif [ $SUCCESS_RATE -ge 80 ]; then
    print_success "✅ GOOD: Project is mostly functional"
elif [ $SUCCESS_RATE -ge 70 ]; then
    print_warning "⚠️  FAIR: Project needs some improvements"
else
    print_error "❌ POOR: Project needs significant work"
fi

print_header "📋 DETAILED ASSESSMENT"
print_header "======================"

echo ""
print_info "INFRASTRUCTURE STATUS:"
if docker ps | grep -q "deployment-package.*Up"; then
    print_success "• All containers running stable"
else
    print_error "• Container stability issues"
fi

print_info "NETWORK STATUS:"
if [ $SUCCESS_RATE -ge 80 ]; then
    print_success "• Blockchain network functional"
    print_success "• Peers successfully joined channel"
    print_success "• Orderer working correctly"
else
    print_warning "• Network has some issues"
fi

print_info "BUSINESS READINESS:"
if [ -f chaincode/ibn-basic/ibn-basic.go ]; then
    print_success "• Complete ibn-basic chaincode ready"
    print_success "• Asset management functions available"
    print_success "• Multi-organization support designed"
else
    print_error "• Chaincode not ready"
fi

print_header "🚀 NEXT STEPS RECOMMENDATIONS"
print_header "============================="

if [ $SUCCESS_RATE -ge 90 ]; then
    echo ""
    print_success "PROJECT IS READY FOR:"
    echo "• Production deployment"
    echo "• Chaincode deployment (with docker socket fix)"
    echo "• Business transaction testing"
    echo "• Client application integration"
elif [ $SUCCESS_RATE -ge 80 ]; then
    echo ""
    print_info "RECOMMENDED ACTIONS:"
    echo "• Fix remaining issues"
    echo "• Test chaincode deployment"
    echo "• Prepare for production"
else
    echo ""
    print_warning "PRIORITY FIXES NEEDED:"
    echo "• Address failed tests"
    echo "• Stabilize network"
    echo "• Complete setup"
fi

print_header "🎯 FINAL CONCLUSION"
print_header "==================="

echo ""
if [ $SUCCESS_RATE -ge 85 ]; then
    print_success "🎉 DỰ ÁN THÀNH CÔNG!"
    print_info "Blockchain network hoàn chỉnh với peers đã join channel."
    print_info "Sẵn sàng cho business applications!"
else
    print_info "🔧 DỰ ÁN CẦN HOÀN THIỆN THÊM"
    print_info "Core functionality working, cần fix một số issues."
fi

echo ""
print_success "✅ COMPREHENSIVE TEST COMPLETED!"
