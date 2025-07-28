#!/usr/bin/env python3
"""
IBN Blockchain API Server
Flask application for interacting with Hyperledger Fabric blockchain
"""

import os
import sys
import logging
from datetime import datetime, timezone

# Add app directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def main():
    """Main application entry point"""
    try:
        # Create Flask application
        app = create_app()
        
        # Get configuration
        host = os.getenv('FLASK_HOST', '0.0.0.0')
        port = int(os.getenv('FLASK_PORT', 5000))
        debug = os.getenv('FLASK_ENV') == 'development'
        
        logger.info("=" * 50)
        logger.info("🚀 IBN BLOCKCHAIN API SERVER")
        logger.info("=" * 50)
        logger.info(f"📅 Started at: {datetime.now(timezone.utc).isoformat()}")
        logger.info(f"🌐 Host: {host}")
        logger.info(f"🔌 Port: {port}")
        logger.info(f"🐛 Debug: {debug}")
        logger.info(f"🗄️  MongoDB: {os.getenv('MONGODB_URI', 'localhost:27017')}")
        logger.info("=" * 50)
        
        # Add startup routes
        @app.route('/')
        def index():
            return {
                'service': 'IBN Blockchain API',
                'version': '1.0.0',
                'status': 'running',
                'timestamp': datetime.now(timezone.utc).isoformat(),
                'endpoints': {
                    'health': '/health',
                    'assets': '/api/assets',
                    'transactions': '/api/transactions',
                    'network': '/api/network',
                    'dashboard': '/dashboard'
                }
            }
        
        @app.route('/api')
        def api_info():
            return {
                'api_version': '1.0.0',
                'blockchain_network': 'IBN Hyperledger Fabric',
                'supported_operations': [
                    'CreateAsset',
                    'ReadAsset', 
                    'UpdateAsset',
                    'DeleteAsset',
                    'TransferAsset',
                    'GetAllAssets',
                    'AssetExists',
                    'InitLedger'
                ],
                'documentation': '/api/docs'
            }
        
        # Run application
        app.run(
            host=host,
            port=port,
            debug=debug,
            threaded=True
        )
        
    except Exception as e:
        logger.error(f"Failed to start application: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
