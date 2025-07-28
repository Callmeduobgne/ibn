#!/bin/bash

echo "🚀 CREATE WORKING FABRIC NETWORK WITH PEERS JOIN CHANNEL"
echo "========================================================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_header() { echo -e "${BOLD}${PURPLE}$1${NC}"; }

print_header "🔧 STEP 1: CREATE SIMPLE WORKING DOCKER COMPOSE"
print_header "==============================================="

print_info "Creating minimal working docker-compose..."

cat > docker-compose-working.yml << 'EOF'
version: '2'

networks:
  test:

services:
  orderer.example.com:
    image: hyperledger/fabric-orderer:2.5.4
    environment:
      - FABRIC_LOGGING_SPEC=INFO
      - ORDERER_GENERAL_LISTENADDRESS=0.0.0.0
      - ORDERER_GENERAL_LISTENPORT=7050
      - ORDERER_GENERAL_LOCALMSPID=OrdererMSP
      - ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp
      - ORDERER_GENERAL_TLS_ENABLED=false
      - ORDERER_GENERAL_BOOTSTRAPMETHOD=file
      - ORDERER_GENERAL_BOOTSTRAPFILE=/var/hyperledger/orderer/orderer.genesis.block
      - ORDERER_CHANNELPARTICIPATION_ENABLED=true
      - ORDERER_ADMIN_LISTENADDRESS=0.0.0.0:7053
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric
    command: orderer
    volumes:
      - ./channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block
      - ./crypto-config-ca/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp
    ports:
      - 7050:7050
      - 7053:7053
    networks:
      - test

  peer0.org1.example.com:
    image: hyperledger/fabric-peer:2.5.4
    environment:
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=deployment-package_test
      - FABRIC_LOGGING_SPEC=INFO
      - CORE_PEER_TLS_ENABLED=false
      - CORE_PEER_PROFILE_ENABLED=true
      - CORE_PEER_ID=peer0.org1.example.com
      - CORE_PEER_ADDRESS=peer0.org1.example.com:7051
      - CORE_PEER_LISTENADDRESS=0.0.0.0:7051
      - CORE_PEER_CHAINCODEADDRESS=peer0.org1.example.com:7052
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:7052
      - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org1.example.com:7051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7051
      - CORE_PEER_LOCALMSPID=Org1MSP
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config-ca/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp:/etc/hyperledger/fabric/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
    ports:
      - 7051:7051
    networks:
      - test
    depends_on:
      - orderer.example.com

  peer0.org2.example.com:
    image: hyperledger/fabric-peer:2.5.4
    environment:
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=deployment-package_test
      - FABRIC_LOGGING_SPEC=INFO
      - CORE_PEER_TLS_ENABLED=false
      - CORE_PEER_PROFILE_ENABLED=true
      - CORE_PEER_ID=peer0.org2.example.com
      - CORE_PEER_ADDRESS=peer0.org2.example.com:9051
      - CORE_PEER_LISTENADDRESS=0.0.0.0:9051
      - CORE_PEER_CHAINCODEADDRESS=peer0.org2.example.com:9052
      - CORE_PEER_CHAINCODELISTENADDRESS=0.0.0.0:9052
      - CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org2.example.com:9051
      - CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org2.example.com:9051
      - CORE_PEER_LOCALMSPID=Org2MSP
    volumes:
      - /var/run/:/host/var/run/
      - ./crypto-config-ca/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp:/etc/hyperledger/fabric/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: peer node start
    ports:
      - 9051:9051
    networks:
      - test
    depends_on:
      - orderer.example.com

  cli:
    image: hyperledger/fabric-tools:2.5.4
    tty: true
    stdin_open: true
    environment:
      - GOPATH=/opt/gopath
      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - FABRIC_LOGGING_SPEC=INFO
      - CORE_PEER_ID=cli
      - CORE_PEER_ADDRESS=peer0.org1.example.com:7051
      - CORE_PEER_LOCALMSPID=Org1MSP
      - CORE_PEER_TLS_ENABLED=false
      - CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    working_dir: /opt/gopath/src/github.com/hyperledger/fabric/peer
    command: /bin/bash
    volumes:
      - /var/run/:/host/var/run/
      - ./chaincode/:/opt/gopath/src/github.com/chaincode
      - ./crypto-config-ca:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/
      - ./channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts
    depends_on:
      - orderer.example.com
      - peer0.org1.example.com
      - peer0.org2.example.com
    networks:
      - test
EOF

print_status "Simple Docker Compose created"

print_header "🔧 STEP 2: CREATE SIMPLE CONFIGTX"
print_header "================================="

print_info "Creating simple configtx.yaml..."

mkdir -p config-simple

cat > config-simple/configtx.yaml << 'EOF'
Organizations:
  - &OrdererOrg
      Name: OrdererOrg
      ID: OrdererMSP
      MSPDir: ../crypto-config-ca/ordererOrganizations/example.com/msp
      Policies:
          Readers:
              Type: Signature
              Rule: "OR('OrdererMSP.member')"
          Writers:
              Type: Signature
              Rule: "OR('OrdererMSP.member')"
          Admins:
              Type: Signature
              Rule: "OR('OrdererMSP.admin')"

  - &Org1
      Name: Org1MSP
      ID: Org1MSP
      MSPDir: ../crypto-config-ca/peerOrganizations/org1.example.com/msp
      Policies:
          Readers:
              Type: Signature
              Rule: "OR('Org1MSP.admin', 'Org1MSP.peer', 'Org1MSP.client')"
          Writers:
              Type: Signature
              Rule: "OR('Org1MSP.admin', 'Org1MSP.client')"
          Admins:
              Type: Signature
              Rule: "OR('Org1MSP.admin')"
          Endorsement:
              Type: Signature
              Rule: "OR('Org1MSP.peer')"
      AnchorPeers:
          - Host: peer0.org1.example.com
            Port: 7051

  - &Org2
      Name: Org2MSP
      ID: Org2MSP
      MSPDir: ../crypto-config-ca/peerOrganizations/org2.example.com/msp
      Policies:
          Readers:
              Type: Signature
              Rule: "OR('Org2MSP.admin', 'Org2MSP.peer', 'Org2MSP.client')"
          Writers:
              Type: Signature
              Rule: "OR('Org2MSP.admin', 'Org2MSP.client')"
          Admins:
              Type: Signature
              Rule: "OR('Org2MSP.admin')"
          Endorsement:
              Type: Signature
              Rule: "OR('Org2MSP.peer')"
      AnchorPeers:
          - Host: peer0.org2.example.com
            Port: 9051

Capabilities:
    Channel: &ChannelCapabilities
        V2_0: true
    Orderer: &OrdererCapabilities
        V2_0: true
    Application: &ApplicationCapabilities
        V2_5: true

Application: &ApplicationDefaults
    Organizations:
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        LifecycleEndorsement:
            Type: ImplicitMeta
            Rule: "MAJORITY Endorsement"
        Endorsement:
            Type: ImplicitMeta
            Rule: "MAJORITY Endorsement"
    Capabilities:
        <<: *ApplicationCapabilities

Orderer: &OrdererDefaults
    OrdererType: solo
    Addresses:
        - orderer.example.com:7050
    BatchTimeout: 2s
    BatchSize:
        MaxMessageCount: 10
        AbsoluteMaxBytes: 99 MB
        PreferredMaxBytes: 512 KB
    Organizations:
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
        BlockValidation:
            Type: ImplicitMeta
            Rule: "ANY Writers"

Channel: &ChannelDefaults
    Policies:
        Readers:
            Type: ImplicitMeta
            Rule: "ANY Readers"
        Writers:
            Type: ImplicitMeta
            Rule: "ANY Writers"
        Admins:
            Type: ImplicitMeta
            Rule: "MAJORITY Admins"
    Capabilities:
        <<: *ChannelCapabilities

Profiles:
    TwoOrgOrdererGenesis:
        <<: *ChannelDefaults
        Orderer:
            <<: *OrdererDefaults
            Organizations:
                - *OrdererOrg
            Capabilities:
                <<: *OrdererCapabilities
        Consortiums:
            SampleConsortium:
                Organizations:
                    - *Org1
                    - *Org2
    
    TwoOrgChannel:
        Consortium: SampleConsortium
        <<: *ChannelDefaults
        Application:
            <<: *ApplicationDefaults
            Organizations:
                - *Org1
                - *Org2
            Capabilities:
                <<: *ApplicationCapabilities
EOF

print_status "Simple configtx.yaml created"

print_header "🔧 STEP 3: GENERATE ARTIFACTS"
print_header "============================="

export FABRIC_CFG_PATH=$PWD/config-simple

print_info "Generating genesis block..."
../bin/configtxgen -profile TwoOrgOrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block

print_info "Generating channel transaction..."
../bin/configtxgen -profile TwoOrgChannel -outputCreateChannelTx ./channel-artifacts/mychannel.tx -channelID mychannel

print_status "Artifacts generated"

print_header "🔧 STEP 4: START NETWORK"
print_header "========================"

print_info "Starting simple working network..."
docker-compose -f docker-compose-working.yml up -d

print_info "Waiting for network to stabilize..."
sleep 20

print_status "Network started!"

echo ""
print_header "🎉 NETWORK STATUS"
print_header "================="

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

print_status "✅ Simple working network is ready for channel creation!"
print_info "Next: Run channel creation and peer join commands"
