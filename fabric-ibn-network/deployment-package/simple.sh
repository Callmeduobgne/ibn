#!/bin/bash

# 🚀 IBN Network - Super Simple Script
# Just 3 commands: run, stop, test

case "${1:-help}" in
    "run")
        echo "🚀 Starting IBN Blockchain Network..."
        ./ibn-network.sh start
        ;;
    "stop")
        echo "🛑 Stopping IBN Blockchain Network..."
        ./ibn-network.sh stop
        ;;
    "test")
        echo "🧪 Testing IBN Blockchain Network..."
        ./network-status.sh
        ;;
    *)
        echo "🎯 IBN Blockchain Network - Super Simple Commands"
        echo ""
        echo "Usage: $0 [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  run       🚀 Start everything (network + chaincode)"
        echo "  stop      🛑 Stop network"
        echo "  test      🧪 Test chaincode"
        echo ""
        echo "Examples:"
        echo "  $0 run    # Start complete blockchain"
        echo "  $0 test   # Test the blockchain"
        echo "  $0 stop   # Stop everything"
        ;;
esac
