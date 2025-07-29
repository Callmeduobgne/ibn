from flask import Blueprint, request, jsonify
from datetime import datetime
import logging

from app import mongo
from app.models.transaction import NetworkStatus
from app.services.blockchain_service import BlockchainService

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create blueprint
network_bp = Blueprint('network', __name__)

# Initialize blockchain service
blockchain_service = BlockchainService()

@network_bp.route('/status', methods=['GET'])
def get_network_status():
    """Get current blockchain network status"""
    try:
        # Try to get status from blockchain
        blockchain_result = blockchain_service.get_network_status()
        
        if blockchain_result['success']:
            # Store status in MongoDB
            network_status = NetworkStatus(
                timestamp=datetime.utcnow(),
                peers_status=[{
                    'name': 'peer0.ibn.ictu.edu.vn',
                    'status': 'running',
                    'port': '7051'
                }, {
                    'name': 'peer0.partner1.example.com', 
                    'status': 'running',
                    'port': '8051'
                }],
                orderer_status={
                    'name': 'orderer.example.com',
                    'status': 'running',
                    'port': '7050'
                }
            )
            
            mongo.db.network_status.insert_one(network_status.to_dict())
            
            return jsonify({
                'success': True,
                'data': {
                    'blockchain_status': blockchain_result['data'],
                    'network_status': network_status.to_json(),
                    'source': 'blockchain'
                }
            })
        else:
            # Fallback to cached status
            latest_status = mongo.db.network_status.find_one(
                {}, sort=[('timestamp', -1)]
            )
            
            if latest_status:
                latest_status['_id'] = str(latest_status['_id'])
                if 'timestamp' in latest_status:
                    latest_status['timestamp'] = latest_status['timestamp'].isoformat()
                
                return jsonify({
                    'success': True,
                    'data': latest_status,
                    'source': 'cache',
                    'warning': 'Using cached data due to blockchain connectivity issues'
                })
            else:
                return jsonify({
                    'success': False,
                    'error': 'No network status available',
                    'blockchain_error': blockchain_result['error']
                }), 503
                
    except Exception as e:
        logger.error(f"Error getting network status: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@network_bp.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        # Check MongoDB connection
        mongo.db.command('ping')
        
        # Check if we can access blockchain (optional)
        blockchain_healthy = False
        try:
            blockchain_result = blockchain_service.get_network_status()
            blockchain_healthy = blockchain_result['success']
        except:
            pass
        
        return jsonify({
            'success': True,
            'data': {
                'api_status': 'healthy',
                'database_status': 'healthy',
                'blockchain_status': 'healthy' if blockchain_healthy else 'unavailable',
                'timestamp': datetime.utcnow().isoformat()
            }
        })
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return jsonify({
            'success': False,
            'error': str(e),
            'data': {
                'api_status': 'unhealthy',
                'timestamp': datetime.utcnow().isoformat()
            }
        }), 500

@network_bp.route('/info', methods=['GET'])
def get_network_info():
    """Get network configuration information"""
    try:
        network_info = {
            'network_name': 'IBN Blockchain Network',
            'channel_name': 'mychannel',
            'chaincode_name': 'ibn-basic',
            'organizations': [
                {
                    'name': 'IbnMSP',
                    'peers': ['peer0.ibn.ictu.edu.vn:7051']
                },
                {
                    'name': 'Partner1MSP', 
                    'peers': ['peer0.partner1.example.com:8051']
                }
            ],
            'orderers': ['orderer.example.com:7050'],
            'api_version': '1.0.0',
            'supported_functions': [
                'CreateAsset',
                'ReadAsset',
                'UpdateAsset', 
                'DeleteAsset',
                'TransferAsset',
                'GetAllAssets',
                'AssetExists',
                'InitLedger'
            ]
        }
        
        return jsonify({
            'success': True,
            'data': network_info
        })
        
    except Exception as e:
        logger.error(f"Error getting network info: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
