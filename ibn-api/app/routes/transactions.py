from flask import Blueprint, request, jsonify
from datetime import datetime
import logging

from app import mongo
from app.models.transaction import Transaction

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create blueprint
transactions_bp = Blueprint('transactions', __name__)

@transactions_bp.route('/', methods=['GET'])
def get_all_transactions():
    """Get all transactions from MongoDB"""
    try:
        # Get query parameters
        limit = request.args.get('limit', 50, type=int)
        offset = request.args.get('offset', 0, type=int)
        status = request.args.get('status')
        function_name = request.args.get('function')
        
        # Build query
        query = {}
        if status:
            query['status'] = status
        if function_name:
            query['function_name'] = function_name
        
        # Get transactions from MongoDB
        transactions_cursor = mongo.db.transactions.find(query).sort('timestamp', -1).skip(offset).limit(limit)
        transactions = []
        
        for tx_doc in transactions_cursor:
            tx_doc['_id'] = str(tx_doc['_id'])
            if 'timestamp' in tx_doc and tx_doc['timestamp']:
                tx_doc['timestamp'] = tx_doc['timestamp'].isoformat()
            transactions.append(tx_doc)
        
        # Get total count
        total_count = mongo.db.transactions.count_documents(query)
        
        return jsonify({
            'success': True,
            'data': transactions,
            'count': len(transactions),
            'total': total_count,
            'offset': offset,
            'limit': limit
        })
        
    except Exception as e:
        logger.error(f"Error getting transactions: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@transactions_bp.route('/<tx_id>', methods=['GET'])
def get_transaction(tx_id):
    """Get specific transaction by ID"""
    try:
        transaction_doc = mongo.db.transactions.find_one({'tx_id': tx_id})
        
        if transaction_doc:
            transaction_doc['_id'] = str(transaction_doc['_id'])
            if 'timestamp' in transaction_doc and transaction_doc['timestamp']:
                transaction_doc['timestamp'] = transaction_doc['timestamp'].isoformat()
            
            return jsonify({
                'success': True,
                'data': transaction_doc
            })
        else:
            return jsonify({
                'success': False,
                'error': 'Transaction not found'
            }), 404
            
    except Exception as e:
        logger.error(f"Error getting transaction {tx_id}: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@transactions_bp.route('/stats', methods=['GET'])
def get_transaction_stats():
    """Get transaction statistics"""
    try:
        # Get stats from MongoDB
        total_transactions = mongo.db.transactions.count_documents({})
        success_transactions = mongo.db.transactions.count_documents({'status': 'success'})
        failed_transactions = mongo.db.transactions.count_documents({'status': 'failed'})
        pending_transactions = mongo.db.transactions.count_documents({'status': 'pending'})
        
        # Get function stats
        function_stats = list(mongo.db.transactions.aggregate([
            {
                '$group': {
                    '_id': '$function_name',
                    'count': {'$sum': 1},
                    'success_count': {
                        '$sum': {
                            '$cond': [{'$eq': ['$status', 'success']}, 1, 0]
                        }
                    }
                }
            },
            {'$sort': {'count': -1}}
        ]))
        
        # Get recent activity (last 24 hours)
        yesterday = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        recent_transactions = mongo.db.transactions.count_documents({
            'timestamp': {'$gte': yesterday}
        })
        
        return jsonify({
            'success': True,
            'data': {
                'total_transactions': total_transactions,
                'success_transactions': success_transactions,
                'failed_transactions': failed_transactions,
                'pending_transactions': pending_transactions,
                'success_rate': round((success_transactions / total_transactions * 100) if total_transactions > 0 else 0, 2),
                'recent_transactions_24h': recent_transactions,
                'function_stats': function_stats
            }
        })
        
    except Exception as e:
        logger.error(f"Error getting transaction stats: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
