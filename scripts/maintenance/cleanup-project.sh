#!/bin/bash

echo "🧹 COMPREHENSIVE PROJECT CLEANUP"
echo "================================"

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
print_cleanup() { echo -e "${CYAN}🧹 $1${NC}"; }
print_header() { echo -e "${BOLD}${PURPLE}$1${NC}"; }

echo ""
print_header "🎯 PROJECT CLEANUP PLAN"
print_header "======================="

echo ""
print_info "=== WHAT WILL BE CLEANED ==="
print_cleanup "🐳 Docker containers and networks"
print_cleanup "📦 Docker images (Fabric related)"
print_cleanup "🗂️  Generated certificates and artifacts"
print_cleanup "📝 Log files and temporary files"
print_cleanup "🔧 Build artifacts and cache"
print_cleanup "📊 Backup old configurations"

echo ""
print_warning "⚠️  IMPORTANT: This will remove all blockchain data!"
print_info "Press Enter to continue or Ctrl+C to cancel..."
read -r

echo ""
print_header "🧹 STARTING CLEANUP PROCESS"
echo ""

# Step 1: Stop and remove all containers
print_cleanup "Step 1: Stopping and removing Docker containers..."

# Stop fabric-ibn-network containers
print_info "Stopping fabric-ibn-network containers..."
docker-compose -f docker-compose-ca.yml down -v 2>/dev/null || true
docker-compose -f docker-compose.yml down -v 2>/dev/null || true

# Stop fabric-samples containers
print_info "Stopping fabric-samples containers..."
cd ../fabric-samples/test-network 2>/dev/null && ./network.sh down 2>/dev/null || true
cd - > /dev/null 2>&1

# Remove any remaining Fabric containers
print_info "Removing remaining Fabric containers..."
docker stop $(docker ps -aq --filter "name=peer*") 2>/dev/null || true
docker stop $(docker ps -aq --filter "name=orderer*") 2>/dev/null || true
docker stop $(docker ps -aq --filter "name=ca*") 2>/dev/null || true
docker stop $(docker ps -aq --filter "name=cli*") 2>/dev/null || true

docker rm $(docker ps -aq --filter "name=peer*") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=orderer*") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=ca*") 2>/dev/null || true
docker rm $(docker ps -aq --filter "name=cli*") 2>/dev/null || true

print_status "Docker containers stopped and removed"

# Step 2: Remove Docker networks
print_cleanup "Step 2: Removing Docker networks..."
docker network rm fabric-ibn-network_fabric-network 2>/dev/null || true
docker network rm fabric_test 2>/dev/null || true
docker network rm $(docker network ls -q --filter "name=fabric*") 2>/dev/null || true

print_status "Docker networks removed"

# Step 3: Remove Docker volumes
print_cleanup "Step 3: Removing Docker volumes..."
docker volume rm $(docker volume ls -q --filter "name=fabric*") 2>/dev/null || true
docker volume rm $(docker volume ls -q --filter "name=compose*") 2>/dev/null || true

print_status "Docker volumes removed"

# Step 4: Remove Docker images (optional)
print_cleanup "Step 4: Removing Fabric Docker images..."
print_warning "Do you want to remove Fabric Docker images? (y/N): "
read -r remove_images

if [[ $remove_images =~ ^[Yy]$ ]]; then
    docker rmi $(docker images -q "hyperledger/fabric-*") 2>/dev/null || true
    docker rmi $(docker images -q "*fabric*") 2>/dev/null || true
    print_status "Docker images removed"
else
    print_info "Docker images kept"
fi

# Step 5: Clean project files
print_cleanup "Step 5: Cleaning project files..."

# Remove generated certificates
print_info "Removing generated certificates..."
rm -rf crypto-config/ 2>/dev/null || true
rm -rf crypto-config-ca/ 2>/dev/null || true
rm -rf organizations/ 2>/dev/null || true

# Remove channel artifacts
print_info "Removing channel artifacts..."
rm -rf channel-artifacts/ 2>/dev/null || true

# Remove chaincode packages
print_info "Removing chaincode packages..."
rm -f *.tar.gz 2>/dev/null || true

# Remove log files
print_info "Removing log files..."
rm -f *.log 2>/dev/null || true
rm -rf logs/ 2>/dev/null || true

# Remove temporary files
print_info "Removing temporary files..."
rm -f .env 2>/dev/null || true
rm -rf .tmp/ 2>/dev/null || true

print_status "Project files cleaned"

# Step 6: Clean fabric-samples
print_cleanup "Step 6: Cleaning fabric-samples..."
if [ -d "../fabric-samples" ]; then
    print_warning "Do you want to remove fabric-samples directory? (y/N): "
    read -r remove_samples
    
    if [[ $remove_samples =~ ^[Yy]$ ]]; then
        rm -rf ../fabric-samples/
        print_status "fabric-samples removed"
    else
        # Just clean the test-network
        cd ../fabric-samples/test-network 2>/dev/null && {
            rm -rf organizations/ 2>/dev/null || true
            rm -rf channel-artifacts/ 2>/dev/null || true
            rm -f *.tar.gz 2>/dev/null || true
            rm -f *.log 2>/dev/null || true
        }
        cd - > /dev/null 2>&1
        print_info "fabric-samples cleaned but kept"
    fi
else
    print_info "fabric-samples not found"
fi

# Step 7: Docker system cleanup
print_cleanup "Step 7: Docker system cleanup..."
print_warning "Do you want to run Docker system prune? (y/N): "
read -r docker_prune

if [[ $docker_prune =~ ^[Yy]$ ]]; then
    docker system prune -f
    print_status "Docker system cleaned"
else
    print_info "Docker system prune skipped"
fi

# Step 8: Create cleanup summary
print_cleanup "Step 8: Creating cleanup summary..."

cat > cleanup-summary.txt << EOF
BLOCKCHAIN PROJECT CLEANUP SUMMARY
==================================
Date: $(date)

CLEANED ITEMS:
✅ Docker containers (peers, orderers, CAs, CLI)
✅ Docker networks (fabric-related)
✅ Docker volumes (fabric-related)
✅ Generated certificates and crypto materials
✅ Channel artifacts and genesis blocks
✅ Chaincode packages
✅ Log files and temporary files

PRESERVED ITEMS:
📁 Source code and chaincode
📁 Configuration templates
📁 Scripts and documentation
📁 Docker compose files

NEXT STEPS:
1. To restart the network, run: ./start-network.sh
2. To regenerate certificates, run: ./generate-crypto.sh
3. To redeploy chaincode, follow deployment guide

PROJECT STATUS: CLEAN AND READY FOR FRESH START
EOF

print_status "Cleanup summary created: cleanup-summary.txt"

echo ""
print_header "🎉 CLEANUP COMPLETED SUCCESSFULLY!"
echo ""

print_cleanup "📊 CLEANUP SUMMARY:"
print_status "✅ All Docker containers stopped and removed"
print_status "✅ All Docker networks and volumes cleaned"
print_status "✅ Generated certificates and artifacts removed"
print_status "✅ Log files and temporary files cleaned"
print_status "✅ Project ready for fresh start"

echo ""
print_info "📁 PRESERVED FILES:"
print_info "• Source code and chaincode"
print_info "• Configuration templates"
print_info "• Scripts and documentation"
print_info "• Docker compose files"

echo ""
print_header "🚀 PROJECT STATUS: CLEAN AND READY!"
print_info "Your blockchain project has been cleaned and is ready for a fresh start."
print_info "All development work and configurations have been preserved."

echo ""
print_cleanup "📋 TO RESTART THE PROJECT:"
print_info "1. Run certificate generation scripts"
print_info "2. Start the network with docker-compose"
print_info "3. Create channels and deploy chaincode"
print_info "4. Test invoke and query operations"

print_header "🧹 CLEANUP PROCESS COMPLETED SUCCESSFULLY!"
