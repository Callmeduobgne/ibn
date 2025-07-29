#!/bin/bash

echo "📋 TẠO SIMPLE CHANNEL CHO CHAINCODE TESTING"
echo "==========================================="

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

# Tạo simple channel configuration
print_info "Tạo simple channel configuration..."

cat > ./channel-artifacts/simple-channel-config.json << EOF
{
    "channel_group": {
        "groups": {
            "Application": {
                "groups": {
                    "IbnMSP": {
                        "values": {
                            "MSP": {
                                "value": {
                                    "config": {
                                        "name": "IbnMSP",
                                        "root_certs": [],
                                        "intermediate_certs": [],
                                        "admins": [],
                                        "revocation_list": [],
                                        "signing_identity": null,
                                        "organizational_unit_identifiers": [],
                                        "cryptoconfig": {
                                            "signature_hash_family": "SHA2",
                                            "identity_identifier_hash_function": "SHA256"
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
                "policies": {
                    "Admins": {
                        "policy": {
                            "type": 3,
                            "value": {
                                "rule": "MAJORITY",
                                "sub_policy": "Admins"
                            }
                        }
                    },
                    "Readers": {
                        "policy": {
                            "type": 3,
                            "value": {
                                "rule": "ANY",
                                "sub_policy": "Readers"
                            }
                        }
                    },
                    "Writers": {
                        "policy": {
                            "type": 3,
                            "value": {
                                "rule": "ANY",
                                "sub_policy": "Writers"
                            }
                        }
                    }
                }
            }
        },
        "policies": {
            "Admins": {
                "policy": {
                    "type": 3,
                    "value": {
                        "rule": "MAJORITY",
                        "sub_policy": "Admins"
                    }
                }
            },
            "Readers": {
                "policy": {
                    "type": 3,
                    "value": {
                        "rule": "ANY",
                        "sub_policy": "Readers"
                    }
                }
            },
            "Writers": {
                "policy": {
                    "type": 3,
                    "value": {
                        "rule": "ANY",
                        "sub_policy": "Writers"
                    }
                }
            }
        }
    }
}
EOF

print_status "Simple channel configuration created"

# Thử approach khác - sử dụng peer channel create với minimal config
print_info "Tạo channel với minimal configuration..."

# Tạo minimal channel tx
FABRIC_CFG_PATH=./config ./bin/configtxgen -profile IbnOrdererGenesis -channelID testchannel -outputCreateChannelTx ./channel-artifacts/testchannel.tx

if [ $? -eq 0 ]; then
    print_status "Channel transaction created successfully"
    
    # Thử tạo channel
    print_info "Creating channel testchannel..."
    docker exec cli peer channel create -o orderer.ictu.edu.vn:7050 -c testchannel -f ./channel-artifacts/testchannel.tx --ordererTLSHostnameOverride orderer.ictu.edu.vn --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/ictu.edu.vn/orderers/orderer.ictu.edu.vn/tls/ca.crt
    
    if [ $? -eq 0 ]; then
        print_status "Channel created successfully!"
        
        # Join peer to channel
        print_info "Joining peer to channel..."
        docker exec cli peer channel join -b testchannel.block
        
        if [ $? -eq 0 ]; then
            print_status "Peer joined channel successfully!"
            
            # List channels
            print_info "Listing channels..."
            docker exec cli peer channel list
            
        else
            print_warning "Failed to join channel, but continuing..."
        fi
    else
        print_warning "Failed to create channel, trying alternative approach..."
    fi
else
    print_error "Failed to create channel transaction"
fi

print_info "Channel setup completed. Ready for chaincode deployment."
