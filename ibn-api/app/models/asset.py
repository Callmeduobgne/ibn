from datetime import datetime, timezone
from bson import ObjectId
import json

class Asset:
    """Asset model for MongoDB and Blockchain integration"""
    
    def __init__(self, asset_id, color, size, owner, appraised_value, 
                 blockchain_tx_id=None, status='active', created_at=None):
        self.asset_id = asset_id
        self.color = color
        self.size = int(size)
        self.owner = owner
        self.appraised_value = int(appraised_value)
        self.blockchain_tx_id = blockchain_tx_id
        self.status = status  # active, transferred, deleted
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = datetime.utcnow()
    
    def to_dict(self):
        """Convert to dictionary for MongoDB storage"""
        return {
            'asset_id': self.asset_id,
            'color': self.color,
            'size': self.size,
            'owner': self.owner,
            'appraised_value': self.appraised_value,
            'blockchain_tx_id': self.blockchain_tx_id,
            'status': self.status,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }
    
    def to_json(self):
        """Convert to JSON for API responses"""
        data = self.to_dict()
        # Convert datetime to ISO format
        data['created_at'] = self.created_at.isoformat() if self.created_at else None
        data['updated_at'] = self.updated_at.isoformat() if self.updated_at else None
        return data
    
    @staticmethod
    def from_blockchain(blockchain_asset):
        """Create Asset from blockchain response"""
        return Asset(
            asset_id=blockchain_asset.get('ID'),
            color=blockchain_asset.get('color'),
            size=blockchain_asset.get('size'),
            owner=blockchain_asset.get('owner'),
            appraised_value=blockchain_asset.get('appraisedValue')
        )
    
    @staticmethod
    def from_dict(data):
        """Create Asset from dictionary"""
        return Asset(
            asset_id=data.get('asset_id'),
            color=data.get('color'),
            size=data.get('size'),
            owner=data.get('owner'),
            appraised_value=data.get('appraised_value'),
            blockchain_tx_id=data.get('blockchain_tx_id'),
            status=data.get('status', 'active'),
            created_at=data.get('created_at')
        )
    
    def validate(self):
        """Validate asset data"""
        errors = []
        
        if not self.asset_id or len(self.asset_id.strip()) == 0:
            errors.append("Asset ID is required")
        
        if not self.color or len(self.color.strip()) == 0:
            errors.append("Color is required")
        
        if not isinstance(self.size, int) or self.size <= 0:
            errors.append("Size must be a positive integer")
        
        if not self.owner or len(self.owner.strip()) == 0:
            errors.append("Owner is required")
        
        if not isinstance(self.appraised_value, int) or self.appraised_value <= 0:
            errors.append("Appraised value must be a positive integer")
        
        return errors
    
    def __str__(self):
        return f"Asset(id={self.asset_id}, owner={self.owner}, value={self.appraised_value})"
    
    def __repr__(self):
        return self.__str__()
