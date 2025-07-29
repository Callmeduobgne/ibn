from flask import Blueprint, render_template, jsonify
from datetime import datetime
import logging

from app import mongo

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create blueprint
dashboard_bp = Blueprint('dashboard', __name__)

@dashboard_bp.route('/dashboard')
def dashboard():
    """Main dashboard page"""
    try:
        # Get basic statistics
        total_assets = mongo.db.assets.count_documents({})
        total_transactions = mongo.db.transactions.count_documents({})
        success_transactions = mongo.db.transactions.count_documents({'status': 'success'})
        
        # Get recent transactions
        recent_transactions = list(
            mongo.db.transactions.find()
            .sort("timestamp", -1)
            .limit(10)
        )
        
        # Convert ObjectId to string for JSON serialization
        for tx in recent_transactions:
            tx['_id'] = str(tx['_id'])
            if 'timestamp' in tx and tx['timestamp']:
                tx['timestamp'] = tx['timestamp'].isoformat()
        
        # Get asset analytics
        asset_analytics = list(mongo.db.assets.aggregate([
            {
                "$group": {
                    "_id": "$owner",
                    "total_assets": {"$sum": 1},
                    "total_value": {"$sum": "$appraised_value"}
                }
            },
            {"$sort": {"total_value": -1}},
            {"$limit": 10}
        ]))
        
        dashboard_data = {
            'total_assets': total_assets,
            'total_transactions': total_transactions,
            'success_rate': round((success_transactions / total_transactions * 100) if total_transactions > 0 else 0, 2),
            'recent_transactions': recent_transactions,
            'asset_analytics': asset_analytics,
            'last_updated': datetime.utcnow().isoformat()
        }
        
        return jsonify({
            'success': True,
            'data': dashboard_data
        })
        
    except Exception as e:
        logger.error(f"Error loading dashboard: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@dashboard_bp.route('/api/dashboard/stats')
def dashboard_stats():
    """Get dashboard statistics as JSON"""
    try:
        # Asset statistics
        total_assets = mongo.db.assets.count_documents({})
        active_assets = mongo.db.assets.count_documents({'status': 'active'})
        
        # Transaction statistics
        total_transactions = mongo.db.transactions.count_documents({})
        success_transactions = mongo.db.transactions.count_documents({'status': 'success'})
        failed_transactions = mongo.db.transactions.count_documents({'status': 'failed'})
        pending_transactions = mongo.db.transactions.count_documents({'status': 'pending'})
        
        # Recent activity (last 24 hours)
        yesterday = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        recent_assets = mongo.db.assets.count_documents({
            'created_at': {'$gte': yesterday}
        })
        recent_transactions = mongo.db.transactions.count_documents({
            'timestamp': {'$gte': yesterday}
        })
        
        # Top asset owners
        top_owners = list(mongo.db.assets.aggregate([
            {
                '$group': {
                    '_id': '$owner',
                    'asset_count': {'$sum': 1},
                    'total_value': {'$sum': '$appraised_value'}
                }
            },
            {'$sort': {'total_value': -1}},
            {'$limit': 5}
        ]))
        
        stats = {
            'assets': {
                'total': total_assets,
                'active': active_assets,
                'recent_24h': recent_assets
            },
            'transactions': {
                'total': total_transactions,
                'success': success_transactions,
                'failed': failed_transactions,
                'pending': pending_transactions,
                'success_rate': round((success_transactions / total_transactions * 100) if total_transactions > 0 else 0, 2),
                'recent_24h': recent_transactions
            },
            'top_owners': top_owners,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        return jsonify({
            'success': True,
            'data': stats
        })
        
    except Exception as e:
        logger.error(f"Error getting dashboard stats: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500
