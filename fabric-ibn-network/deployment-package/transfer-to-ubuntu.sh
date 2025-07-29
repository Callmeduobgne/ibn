#!/bin/bash

# 🚀 Transfer deployment package to Ubuntu server
# Usage: ./transfer-to-ubuntu.sh [user@ip]

SERVER=${1:-z@192.168.1.130}
DEPLOY_DIR="ibn-ubuntu-deploy"

echo "📤 Transferring deployment package to $SERVER..."

# Create tar package
tar czf ibn-deploy.tar.gz $DEPLOY_DIR/

# Transfer to server
scp ibn-deploy.tar.gz $SERVER:~/

# Connect and extract
ssh $SERVER << 'REMOTE_COMMANDS'
echo "📦 Extracting deployment package..."
tar xzf ibn-deploy.tar.gz
cd ibn-ubuntu-deploy
chmod +x ubuntu-deploy.sh

echo ""
echo "🎯 Ready to deploy! Run:"
echo "cd ibn-ubuntu-deploy"
echo "./ubuntu-deploy.sh"
echo ""
echo "Or run everything in one command:"
echo "cd ibn-ubuntu-deploy && ./ubuntu-deploy.sh"
REMOTE_COMMANDS

echo ""
echo "✅ Transfer completed!"
echo ""
echo "🔗 Connect to server and deploy:"
echo "ssh $SERVER"
echo "cd ibn-ubuntu-deploy"
echo "./ubuntu-deploy.sh"

# Clean up
rm ibn-deploy.tar.gz
