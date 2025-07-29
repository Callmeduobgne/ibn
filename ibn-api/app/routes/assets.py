from flask import Blueprint, request, jsonify
from datetime import datetime
import logging

from app import mongo
from app.models.asset import Asset
from app.models.transaction import Transaction
from app.services.blockchain_service import BlockchainService

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create blueprint
assets_bp = Blueprint('assets', __name__)

# Initialize blockchain service
blockchain_service = BlockchainService()

@assets_bp.route('/', methods=['GET'])
def get_all_assets():
    """Get all assets from blockchain and cache in MongoDB"""
    try:
        # Get from blockchain
        blockchain_result = blockchain_service.get_all_assets()
        
        if blockchain_result['success']:
            assets = []
            
            # Process blockchain data
            for asset_data in blockchain_result['data']:
                asset = Asset.from_blockchain(asset_data)
                assets.append(asset.to_json())
                
                # Update MongoDB cache
                mongo.db.assets.update_one(
                    {'asset_id': asset.asset_id},
                    {'$set': asset.to_dict()},
                    upsert=True
                )
            
            return jsonify({
                'success': True,
                'data': assets,
                'count': len(assets),
                'source': 'blockchain'
            })
        else:
            # Fallback to MongoDB cache
            logger.warning(f"Blockchain query failed: {blockchain_result['error']}")
            cached_assets = list(mongo.db.assets.find({'status': 'active'}))
            
            assets = []
            for asset_doc in cached_assets:
                asset_doc['_id'] = str(asset_doc['_id'])
                assets.append(asset_doc)
            
            return jsonify({
                'success': True,
                'data': assets,
                'count': len(assets),
                'source': 'cache',
                'warning': 'Using cached data due to blockchain connectivity issues'
            })
            
    except Exception as e:
        logger.error(f"Error getting all assets: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@assets_bp.route('/<asset_id>', methods=['GET'])
def get_asset(asset_id):
    """Get specific asset by ID"""
    try:
        # Try blockchain first
        blockchain_result = blockchain_service.read_asset(asset_id)
        
        if blockchain_result['success']:
            asset = Asset.from_blockchain(blockchain_result['data'])
            
            # Update MongoDB cache
            mongo.db.assets.update_one(
                {'asset_id': asset_id},
                {'$set': asset.to_dict()},
                upsert=True
            )
            
            return jsonify({
                'success': True,
                'data': asset.to_json(),
                'source': 'blockchain'
            })
        else:
            # Fallback to MongoDB
            asset_doc = mongo.db.assets.find_one({'asset_id': asset_id})
            if asset_doc:
                asset_doc['_id'] = str(asset_doc['_id'])
                return jsonify({
                    'success': True,
                    'data': asset_doc,
                    'source': 'cache'
                })
            else:
                return jsonify({
                    'success': False,
                    'error': 'Asset not found'
                }), 404
                
    except Exception as e:
        logger.error(f"Error getting asset {asset_id}: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@assets_bp.route('/', methods=['POST'])
def create_asset():
    """Create new asset on blockchain"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['asset_id', 'color', 'size', 'owner', 'appraised_value']
        for field in required_fields:
            if field not in data:
                return jsonify({
                    'success': False,
                    'error': f'Missing required field: {field}'
                }), 400
        
        # Create asset object for validation
        asset = Asset(
            asset_id=data['asset_id'],
            color=data['color'],
            size=data['size'],
            owner=data['owner'],
            appraised_value=data['appraised_value']
        )
        
        # Validate asset data
        validation_errors = asset.validate()
        if validation_errors:
            return jsonify({
                'success': False,
                'error': 'Validation failed',
                'details': validation_errors
            }), 400
        
        # Check if asset already exists
        exists_result = blockchain_service.asset_exists(asset.asset_id)
        if exists_result['success'] and exists_result['exists']:
            return jsonify({
                'success': False,
                'error': f'Asset {asset.asset_id} already exists'
            }), 409
        
        # Create on blockchain
        blockchain_result = blockchain_service.create_asset(
            asset.asset_id,
            asset.color,
            asset.size,
            asset.owner,
            asset.appraised_value
        )
        
        if blockchain_result['success']:
            # Handle both real blockchain and mock responses
            tx_id = blockchain_result.get('tx_id') or blockchain_result.get('data', {}).get('transaction_id', f'mock_tx_{data["asset_id"]}')
            result_msg = blockchain_result.get('result', 'Asset created successfully')

            # Update asset with blockchain transaction ID
            asset.blockchain_tx_id = tx_id

            # Store in MongoDB
            result = mongo.db.assets.insert_one(asset.to_dict())

            # Log transaction
            transaction = Transaction(
                tx_id=tx_id,
                function_name='CreateAsset',
                args=data,
                result=result_msg,
                status='success'
            )
            mongo.db.transactions.insert_one(transaction.to_dict())

            return jsonify({
                'success': True,
                'data': asset.to_json(),
                'tx_id': tx_id,
                'message': 'Asset created successfully',
                'source': blockchain_result.get('data', {}).get('source', 'blockchain')
            }), 201
        else:
            # Log failed transaction
            transaction = Transaction(
                tx_id=f"failed_{int(datetime.utcnow().timestamp())}",
                function_name='CreateAsset',
                args=data,
                status='failed',
                error_message=blockchain_result['error']
            )
            mongo.db.transactions.insert_one(transaction.to_dict())
            
            return jsonify({
                'success': False,
                'error': blockchain_result['error']
            }), 500
            
    except Exception as e:
        logger.error(f"Error creating asset: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@assets_bp.route('/<asset_id>/transfer', methods=['POST'])
def transfer_asset(asset_id):
    """Transfer asset ownership"""
    try:
        data = request.get_json()
        
        if 'new_owner' not in data:
            return jsonify({
                'success': False,
                'error': 'Missing required field: new_owner'
            }), 400
        
        new_owner = data['new_owner'].strip()
        if not new_owner:
            return jsonify({
                'success': False,
                'error': 'New owner cannot be empty'
            }), 400
        
        # Check if asset exists
        exists_result = blockchain_service.asset_exists(asset_id)
        if not exists_result['success'] or not exists_result['exists']:
            return jsonify({
                'success': False,
                'error': f'Asset {asset_id} not found'
            }), 404
        
        # Transfer on blockchain
        blockchain_result = blockchain_service.transfer_asset(asset_id, new_owner)
        
        if blockchain_result['success']:
            # Update MongoDB
            mongo.db.assets.update_one(
                {'asset_id': asset_id},
                {
                    '$set': {
                        'owner': new_owner,
                        'updated_at': datetime.utcnow(),
                        'status': 'transferred'
                    }
                }
            )
            
            # Log transaction
            transaction = Transaction(
                tx_id=blockchain_result['tx_id'],
                function_name='TransferAsset',
                args={'asset_id': asset_id, 'new_owner': new_owner},
                result=blockchain_result['result'],
                status='success'
            )
            mongo.db.transactions.insert_one(transaction.to_dict())
            
            return jsonify({
                'success': True,
                'message': f'Asset {asset_id} transferred to {new_owner}',
                'tx_id': blockchain_result['tx_id']
            })
        else:
            # Log failed transaction
            transaction = Transaction(
                tx_id=f"failed_{int(datetime.utcnow().timestamp())}",
                function_name='TransferAsset',
                args={'asset_id': asset_id, 'new_owner': new_owner},
                status='failed',
                error_message=blockchain_result['error']
            )
            mongo.db.transactions.insert_one(transaction.to_dict())
            
            return jsonify({
                'success': False,
                'error': blockchain_result['error']
            }), 500
            
    except Exception as e:
        logger.error(f"Error transferring asset {asset_id}: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@assets_bp.route('/<asset_id>/exists', methods=['GET'])
def check_asset_exists(asset_id):
    """Check if asset exists on blockchain"""
    try:
        result = blockchain_service.asset_exists(asset_id)
        
        if result['success']:
            return jsonify({
                'success': True,
                'exists': result['exists'],
                'asset_id': asset_id
            })
        else:
            return jsonify({
                'success': False,
                'error': result['error']
            }), 500
            
    except Exception as e:
        logger.error(f"Error checking asset existence {asset_id}: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@assets_bp.route('/init-ledger', methods=['POST'])
def init_ledger():
    """Initialize blockchain ledger with sample data"""
    try:
        blockchain_result = blockchain_service.init_ledger()
        
        if blockchain_result['success']:
            # Log transaction
            transaction = Transaction(
                tx_id=blockchain_result['tx_id'],
                function_name='InitLedger',
                args={},
                result=blockchain_result['result'],
                status='success'
            )
            mongo.db.transactions.insert_one(transaction.to_dict())
            
            return jsonify({
                'success': True,
                'message': 'Ledger initialized successfully',
                'tx_id': blockchain_result['tx_id']
            })
        else:
            return jsonify({
                'success': False,
                'error': blockchain_result['error']
            }), 500
            
    except Exception as e:
        logger.error(f"Error initializing ledger: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
