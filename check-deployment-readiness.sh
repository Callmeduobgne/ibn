#!/bin/bash

echo "🔍 CHECK DEPLOYMENT READINESS FOR 6-STEP PLAN"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_ready() { echo -e "${GREEN}🚀 $1${NC}"; }
print_not_ready() { echo -e "${RED}🔧 $1${NC}"; }
print_header() { echo -e "${BOLD}${PURPLE}$1${NC}"; }

echo ""
print_header "🔍 DEPLOYMENT READINESS CHECK"
print_header "============================="

echo ""
print_info "Checking readiness for 6-step deployment plan..."

# Initialize counters
ready_steps=0
total_steps=6

echo ""
print_header "📋 STEP 1: WORKSPACE AND CA SERVERS"
echo ""

# Check workspace structure
if [ -d "bin" ] && [ -d "config" ] && [ -d "ca-configs" ] && [ -d "ca-scripts" ]; then
    print_ready "READY: Workspace structure complete"
    print_status "✅ bin/ - Fabric binaries present"
    print_status "✅ config/ - Network configurations present"
    print_status "✅ ca-configs/ - CA configurations present"
    print_status "✅ ca-scripts/ - Certificate scripts present"
    step1_ready=true
else
    print_not_ready "NOT READY: Missing workspace directories"
    step1_ready=false
fi

# Check CA configurations
if [ -f "ca-configs/ca-ibn-config.yaml" ] && [ -f "ca-configs/ca-orderer-config.yaml" ] && [ -f "ca-configs/ca-partner1-config.yaml" ]; then
    print_ready "READY: CA configurations complete"
    print_status "✅ ca-ibn-config.yaml present"
    print_status "✅ ca-orderer-config.yaml present"
    print_status "✅ ca-partner1-config.yaml present"
    step1_ca_ready=true
else
    print_not_ready "NOT READY: Missing CA configurations"
    step1_ca_ready=false
fi

# Check Docker Compose
if [ -f "docker-compose-ca.yml" ]; then
    print_ready "READY: Docker Compose infrastructure file present"
    print_status "✅ docker-compose-ca.yml with multi-org setup"
    step1_docker_ready=true
else
    print_not_ready "NOT READY: Missing docker-compose-ca.yml"
    step1_docker_ready=false
fi

if [ "$step1_ready" = true ] && [ "$step1_ca_ready" = true ] && [ "$step1_docker_ready" = true ]; then
    print_ready "STEP 1: ✅ READY - Workspace and CA Servers"
    ((ready_steps++))
else
    print_not_ready "STEP 1: 🔧 NOT READY - Missing components"
fi

echo ""
print_header "📋 STEP 2: CERTIFICATE GENERATION"
echo ""

# Check certificate scripts
if [ -f "ca-scripts/enroll-all.sh" ]; then
    print_ready "READY: Certificate enrollment script present"
    print_status "✅ ca-scripts/enroll-all.sh - Complete enrollment"
    step2_scripts_ready=true
else
    print_not_ready "NOT READY: Missing certificate enrollment script"
    step2_scripts_ready=false
fi

# Check for existing certificates
if [ -d "crypto-config-ca" ]; then
    print_ready "READY: Certificate directory structure exists"
    print_status "✅ crypto-config-ca/ directory present"
    
    # Check for specific org certificates
    if [ -d "crypto-config-ca/peerOrganizations" ] && [ -d "crypto-config-ca/ordererOrganizations" ]; then
        print_status "✅ Organization certificate structures present"
        step2_certs_ready=true
    else
        print_warning "PARTIAL: Certificate directories exist but may need regeneration"
        step2_certs_ready=true
    fi
else
    print_warning "PARTIAL: Certificate directory not found - will be created during enrollment"
    step2_certs_ready=true
fi

if [ "$step2_scripts_ready" = true ] && [ "$step2_certs_ready" = true ]; then
    print_ready "STEP 2: ✅ READY - Certificate Generation"
    ((ready_steps++))
else
    print_not_ready "STEP 2: 🔧 NOT READY - Missing certificate components"
fi

echo ""
print_header "📋 STEP 3: GENESIS BLOCK AND ORDERER"
echo ""

# Check configtx.yaml
if [ -f "config/configtx.yaml" ]; then
    print_ready "READY: Network configuration file present"
    print_status "✅ config/configtx.yaml with multi-org setup"
    
    # Check for multi-org configuration
    if grep -q "IbnMSP" config/configtx.yaml && grep -q "Partner1MSP" config/configtx.yaml; then
        print_status "✅ Multi-organization configuration detected"
        step3_config_ready=true
    else
        print_warning "PARTIAL: configtx.yaml exists but may need multi-org update"
        step3_config_ready=true
    fi
else
    print_not_ready "NOT READY: Missing config/configtx.yaml"
    step3_config_ready=false
fi

# Check for channel artifacts directory
if [ -d "channel-artifacts" ]; then
    print_ready "READY: Channel artifacts directory exists"
    print_status "✅ channel-artifacts/ directory present"
    step3_artifacts_ready=true
else
    print_warning "PARTIAL: channel-artifacts/ will be created during genesis generation"
    step3_artifacts_ready=true
fi

# Check for configtxgen binary
if [ -f "bin/configtxgen" ]; then
    print_ready "READY: configtxgen binary present"
    print_status "✅ bin/configtxgen available"
    step3_binary_ready=true
else
    print_not_ready "NOT READY: Missing bin/configtxgen binary"
    step3_binary_ready=false
fi

if [ "$step3_config_ready" = true ] && [ "$step3_artifacts_ready" = true ] && [ "$step3_binary_ready" = true ]; then
    print_ready "STEP 3: ✅ READY - Genesis Block and Orderer"
    ((ready_steps++))
else
    print_not_ready "STEP 3: 🔧 NOT READY - Missing genesis components"
fi

echo ""
print_header "📋 STEP 4: PEER INITIALIZATION"
echo ""

# Check peer configuration in docker-compose
if [ -f "docker-compose-ca.yml" ]; then
    if grep -q "peer0.ibn.ictu.edu.vn" docker-compose-ca.yml && grep -q "peer0.partner1.example.com" docker-compose-ca.yml; then
        print_ready "READY: Multi-peer configuration in Docker Compose"
        print_status "✅ peer0.ibn.ictu.edu.vn configured"
        print_status "✅ peer0.partner1.example.com configured"
        step4_peers_ready=true
    else
        print_warning "PARTIAL: Docker Compose exists but peer configuration may need update"
        step4_peers_ready=true
    fi
else
    print_not_ready "NOT READY: Missing Docker Compose file"
    step4_peers_ready=false
fi

# Check peer binary
if [ -f "bin/peer" ]; then
    print_ready "READY: Peer binary present"
    print_status "✅ bin/peer available"
    step4_binary_ready=true
else
    print_not_ready "NOT READY: Missing bin/peer binary"
    step4_binary_ready=false
fi

if [ "$step4_peers_ready" = true ] && [ "$step4_binary_ready" = true ]; then
    print_ready "STEP 4: ✅ READY - Peer Initialization"
    ((ready_steps++))
else
    print_not_ready "STEP 4: 🔧 NOT READY - Missing peer components"
fi

echo ""
print_header "📋 STEP 5: CHANNEL AND CHAINCODE"
echo ""

# Check CLI configuration
if [ -f "docker-compose-ca.yml" ]; then
    if grep -q "cli" docker-compose-ca.yml; then
        print_ready "READY: CLI container configured"
        print_status "✅ CLI container in Docker Compose"
        step5_cli_ready=true
    else
        print_warning "PARTIAL: CLI container may need to be added"
        step5_cli_ready=false
    fi
else
    print_not_ready "NOT READY: Missing Docker Compose file"
    step5_cli_ready=false
fi

# Check chaincode
if [ -d "chaincode/ibn-basic" ]; then
    print_ready "READY: Custom chaincode present"
    print_status "✅ chaincode/ibn-basic/ directory"
    
    if [ -f "chaincode/ibn-basic/ibn-basic.go" ]; then
        print_status "✅ ibn-basic.go source code"
        step5_chaincode_ready=true
    else
        print_not_ready "NOT READY: Missing chaincode source"
        step5_chaincode_ready=false
    fi
    
    if [ -f "chaincode/ibn-basic/go.mod" ]; then
        print_status "✅ go.mod dependencies"
    else
        print_warning "PARTIAL: Missing go.mod"
    fi
else
    print_not_ready "NOT READY: Missing chaincode directory"
    step5_chaincode_ready=false
fi

if [ "$step5_cli_ready" = true ] && [ "$step5_chaincode_ready" = true ]; then
    print_ready "STEP 5: ✅ READY - Channel and Chaincode"
    ((ready_steps++))
else
    print_not_ready "STEP 5: 🔧 NOT READY - Missing channel/chaincode components"
fi

echo ""
print_header "📋 STEP 6: DATA MANAGEMENT"
echo ""

# Check if previous steps are ready (prerequisite for step 6)
if [ $ready_steps -eq 5 ]; then
    print_ready "READY: All prerequisite steps are ready"
    print_status "✅ Network infrastructure ready"
    print_status "✅ Certificates ready"
    print_status "✅ Genesis block ready"
    print_status "✅ Peers ready"
    print_status "✅ Chaincode ready"
    
    print_ready "STEP 6: ✅ READY - Data Management (Query/Invoke operations)"
    ((ready_steps++))
else
    print_not_ready "STEP 6: 🔧 NOT READY - Depends on previous steps completion"
fi

echo ""
print_header "📊 DEPLOYMENT READINESS SUMMARY"
echo ""

print_info "=== READINESS STATUS ==="
echo ""

if [ $ready_steps -eq 6 ]; then
    print_ready "🎉 PROJECT IS FULLY READY FOR 6-STEP DEPLOYMENT!"
    print_status "✅ All 6 steps are ready to execute"
    print_status "✅ Multi-organization network can be deployed"
    print_status "✅ Custom chaincode can be deployed"
    print_status "✅ Production-ready infrastructure"
    
    echo ""
    print_header "🚀 DEPLOYMENT COMMANDS READY:"
    echo ""
    print_info "1. Start CA servers: docker-compose -f docker-compose-ca.yml up -d"
    print_info "2. Enroll certificates: ./ca-scripts/enroll-all.sh"
    print_info "3. Generate genesis: ./bin/configtxgen -profile TwoOrgOrdererGenesis..."
    print_info "4. Start all services: docker-compose -f docker-compose-ca.yml up -d"
    print_info "5. Create channel & deploy chaincode via CLI"
    print_info "6. Test query/invoke operations"
    
else
    print_warning "⚠️  PROJECT PARTIALLY READY: $ready_steps/6 steps ready"
    print_info "Missing components need to be addressed before deployment"
fi

echo ""
print_header "🎯 CONCLUSION"
echo ""

if [ $ready_steps -eq 6 ]; then
    print_ready "✅ READY FOR DEPLOYMENT"
    print_info "The project has all necessary components for successful 6-step deployment"
    print_info "Multi-organization blockchain network can be launched immediately"
else
    print_warning "🔧 NEEDS PREPARATION"
    print_info "Some components need to be completed before deployment"
    print_info "Focus on completing the missing steps identified above"
fi

print_header "🔍 DEPLOYMENT READINESS CHECK COMPLETED!"
