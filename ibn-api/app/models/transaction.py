from datetime import datetime
from bson import ObjectId
import json

class Transaction:
    """Transaction model for blockchain transaction logging"""
    
    def __init__(self, tx_id, function_name, args, result=None, 
                 timestamp=None, status='pending', block_number=None, 
                 gas_used=None, error_message=None):
        self.tx_id = tx_id
        self.function_name = function_name
        self.args = args if isinstance(args, dict) else {}
        self.result = result
        self.timestamp = timestamp or datetime.utcnow()
        self.status = status  # pending, success, failed
        self.block_number = block_number
        self.gas_used = gas_used
        self.error_message = error_message
    
    def to_dict(self):
        """Convert to dictionary for MongoDB storage"""
        return {
            'tx_id': self.tx_id,
            'function_name': self.function_name,
            'args': self.args,
            'result': self.result,
            'timestamp': self.timestamp,
            'status': self.status,
            'block_number': self.block_number,
            'gas_used': self.gas_used,
            'error_message': self.error_message
        }
    
    def to_json(self):
        """Convert to JSON for API responses"""
        data = self.to_dict()
        # Convert datetime to ISO format
        data['timestamp'] = self.timestamp.isoformat() if self.timestamp else None
        return data
    
    @staticmethod
    def from_dict(data):
        """Create Transaction from dictionary"""
        return Transaction(
            tx_id=data.get('tx_id'),
            function_name=data.get('function_name'),
            args=data.get('args', {}),
            result=data.get('result'),
            timestamp=data.get('timestamp'),
            status=data.get('status', 'pending'),
            block_number=data.get('block_number'),
            gas_used=data.get('gas_used'),
            error_message=data.get('error_message')
        )
    
    def mark_success(self, result, block_number=None):
        """Mark transaction as successful"""
        self.status = 'success'
        self.result = result
        self.block_number = block_number
        self.error_message = None
    
    def mark_failed(self, error_message):
        """Mark transaction as failed"""
        self.status = 'failed'
        self.error_message = error_message
        self.result = None
    
    def validate(self):
        """Validate transaction data"""
        errors = []
        
        if not self.tx_id or len(self.tx_id.strip()) == 0:
            errors.append("Transaction ID is required")
        
        if not self.function_name or len(self.function_name.strip()) == 0:
            errors.append("Function name is required")
        
        if self.status not in ['pending', 'success', 'failed']:
            errors.append("Status must be one of: pending, success, failed")
        
        return errors
    
    def __str__(self):
        return f"Transaction(id={self.tx_id}, function={self.function_name}, status={self.status})"
    
    def __repr__(self):
        return self.__str__()


class NetworkStatus:
    """Network status model for monitoring blockchain health"""
    
    def __init__(self, timestamp=None, peers_status=None, orderer_status=None,
                 channel_height=None, last_block_hash=None, total_transactions=None):
        self.timestamp = timestamp or datetime.utcnow()
        self.peers_status = peers_status or []
        self.orderer_status = orderer_status or {}
        self.channel_height = channel_height
        self.last_block_hash = last_block_hash
        self.total_transactions = total_transactions
    
    def to_dict(self):
        """Convert to dictionary for MongoDB storage"""
        return {
            'timestamp': self.timestamp,
            'peers_status': self.peers_status,
            'orderer_status': self.orderer_status,
            'channel_height': self.channel_height,
            'last_block_hash': self.last_block_hash,
            'total_transactions': self.total_transactions
        }
    
    def to_json(self):
        """Convert to JSON for API responses"""
        data = self.to_dict()
        data['timestamp'] = self.timestamp.isoformat() if self.timestamp else None
        return data
    
    @staticmethod
    def from_dict(data):
        """Create NetworkStatus from dictionary"""
        return NetworkStatus(
            timestamp=data.get('timestamp'),
            peers_status=data.get('peers_status', []),
            orderer_status=data.get('orderer_status', {}),
            channel_height=data.get('channel_height'),
            last_block_hash=data.get('last_block_hash'),
            total_transactions=data.get('total_transactions')
        )
