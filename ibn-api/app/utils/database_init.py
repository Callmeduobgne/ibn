"""
Database initialization script cho User Management System
Theo kiến trúc Giai đoạn 2 - Application Layer
"""

from datetime import datetime, timezone
from pymongo import MongoClient
import os
import logging

from ..models.user import User
from ..models.role import Role
from ..models.permission import Permission
from ..models.user_session import UserSession

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class DatabaseInitializer:
    """Initialize database với schema và default data"""
    
    def __init__(self, mongo_uri=None, database_name=None):
        """
        Initialize database connection
        
        Args:
            mongo_uri (str): MongoDB connection URI
            database_name (str): Database name
        """
        self.mongo_uri = mongo_uri or os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
        self.database_name = database_name or os.getenv('MONGO_DB', 'ibn_blockchain')
        
        try:
            self.client = MongoClient(self.mongo_uri)
            self.db = self.client[self.database_name]
            logger.info(f"Connected to MongoDB: {self.database_name}")
        except Exception as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            raise

    def _create_index_safe(self, collection, field, **kwargs):
        """Safely create index, skip if already exists"""
        try:
            collection.create_index(field, **kwargs)
        except Exception as e:
            if "already exists" in str(e) or "IndexOptionsConflict" in str(e):
                logger.debug(f"Index {field} already exists, skipping")
            else:
                logger.warning(f"Failed to create index {field}: {e}")
    
    def create_collections(self):
        """Create collections với indexes"""
        logger.info("Creating collections and indexes...")

        # Users collection
        users_collection = self.db.users
        self._create_index_safe(users_collection, "username", unique=True)
        self._create_index_safe(users_collection, "email", unique=True)
        self._create_index_safe(users_collection, "user_id", unique=True)
        self._create_index_safe(users_collection, "role_id")
        self._create_index_safe(users_collection, "status")
        self._create_index_safe(users_collection, "created_at")
        logger.info("✅ Users collection created")
        
        # Roles collection
        roles_collection = self.db.roles
        self._create_index_safe(roles_collection, "role_id", unique=True)
        self._create_index_safe(roles_collection, "role_name", unique=True)
        self._create_index_safe(roles_collection, "is_system_role")
        self._create_index_safe(roles_collection, "is_active")
        logger.info("✅ Roles collection created")

        # Permissions collection
        permissions_collection = self.db.permissions
        self._create_index_safe(permissions_collection, "permission_id", unique=True)
        self._create_index_safe(permissions_collection, "permission_name", unique=True)
        self._create_index_safe(permissions_collection, "module")
        self._create_index_safe(permissions_collection, "resource")
        self._create_index_safe(permissions_collection, "action")
        logger.info("✅ Permissions collection created")

        # User Sessions collection
        sessions_collection = self.db.user_sessions
        self._create_index_safe(sessions_collection, "session_id", unique=True)
        self._create_index_safe(sessions_collection, "user_id")
        self._create_index_safe(sessions_collection, "session_token")
        self._create_index_safe(sessions_collection, "refresh_token")
        self._create_index_safe(sessions_collection, "expires_at")
        self._create_index_safe(sessions_collection, "is_active")
        self._create_index_safe(sessions_collection, "created_at")
        # TTL index for automatic cleanup of expired sessions
        self._create_index_safe(sessions_collection, "expires_at", expireAfterSeconds=0)
        logger.info("✅ User Sessions collection created")
        
        # Projects collection (for future use)
        projects_collection = self.db.projects
        self._create_index_safe(projects_collection, "project_id", unique=True)
        self._create_index_safe(projects_collection, "project_name")
        self._create_index_safe(projects_collection, "created_by")
        self._create_index_safe(projects_collection, "status")
        logger.info("✅ Projects collection created")

        # Project Groups collection (for future use)
        project_groups_collection = self.db.project_groups
        self._create_index_safe(project_groups_collection, "group_id", unique=True)
        self._create_index_safe(project_groups_collection, "group_name")
        self._create_index_safe(project_groups_collection, "created_by")
        logger.info("✅ Project Groups collection created")

        # Channels collection (for future use)
        channels_collection = self.db.channels
        self._create_index_safe(channels_collection, "channel_id", unique=True)
        self._create_index_safe(channels_collection, "channel_name")
        self._create_index_safe(channels_collection, "project_id")
        self._create_index_safe(channels_collection, "status")
        logger.info("✅ Channels collection created")

        # Chaincodes collection (for future use)
        chaincodes_collection = self.db.chaincodes
        self._create_index_safe(chaincodes_collection, "chaincode_id", unique=True)
        self._create_index_safe(chaincodes_collection, "chaincode_name")
        self._create_index_safe(chaincodes_collection, "version")
        self._create_index_safe(chaincodes_collection, "channel_id")
        self._create_index_safe(chaincodes_collection, "status")
        self._create_index_safe(chaincodes_collection, "created_by")
        logger.info("✅ Chaincodes collection created")

        # Activity Logs collection (enhanced)
        activity_logs_collection = self.db.activity_logs
        self._create_index_safe(activity_logs_collection, "log_id", unique=True)
        self._create_index_safe(activity_logs_collection, "user_id")
        self._create_index_safe(activity_logs_collection, "action")
        self._create_index_safe(activity_logs_collection, "resource_type")
        self._create_index_safe(activity_logs_collection, "resource_id")
        self._create_index_safe(activity_logs_collection, "timestamp")
        self._create_index_safe(activity_logs_collection, "project_id")
        self._create_index_safe(activity_logs_collection, "channel_id")
        logger.info("✅ Activity Logs collection created")
        
        logger.info("🎉 All collections created successfully!")
    
    def create_system_permissions(self):
        """Create system permissions"""
        logger.info("Creating system permissions...")
        
        permissions_collection = self.db.permissions
        
        # Check if permissions already exist
        if permissions_collection.count_documents({}) > 0:
            logger.info("Permissions already exist, skipping creation")
            return
        
        # Create system permissions
        system_permissions = Permission.create_system_permissions()
        
        # Insert permissions
        permission_docs = [perm.to_dict() for perm in system_permissions]
        result = permissions_collection.insert_many(permission_docs)
        
        logger.info(f"✅ Created {len(result.inserted_ids)} system permissions")
        return system_permissions
    
    def create_system_roles(self):
        """Create system roles với permissions"""
        logger.info("Creating system roles...")
        
        roles_collection = self.db.roles
        permissions_collection = self.db.permissions
        
        # Check if roles already exist
        if roles_collection.count_documents({}) > 0:
            logger.info("Roles already exist, skipping creation")
            return
        
        # Get all permissions for mapping
        all_permissions = list(permissions_collection.find({}))
        permission_map = {perm['permission_name']: perm['permission_id'] for perm in all_permissions}
        
        # Create system roles
        system_roles = Role.create_system_roles()
        
        # Map permission names to IDs
        for role in system_roles:
            permission_ids = []
            for perm_name in role.permissions:
                if perm_name in permission_map:
                    permission_ids.append(permission_map[perm_name])
            role.permissions = permission_ids
        
        # Insert roles
        role_docs = [role.to_dict() for role in system_roles]
        result = roles_collection.insert_many(role_docs)
        
        logger.info(f"✅ Created {len(result.inserted_ids)} system roles")
        return system_roles
    
    def create_default_admin(self, username='admin', email='admin@ibn.ictu.edu.vn', 
                           password='admin123', full_name='System Administrator'):
        """Create default admin user"""
        logger.info("Creating default admin user...")
        
        users_collection = self.db.users
        roles_collection = self.db.roles
        
        # Check if admin already exists
        if users_collection.find_one({'username': username}):
            logger.info("Admin user already exists, skipping creation")
            return
        
        # Get admin role
        admin_role = roles_collection.find_one({'role_name': 'admin'})
        if not admin_role:
            logger.error("Admin role not found! Create roles first.")
            return
        
        # Create admin user
        admin_user = User(
            username=username,
            email=email,
            password=password,
            full_name=full_name,
            role_id=admin_role['role_id'],
            department='IT',
            status='active'
        )
        
        # Insert admin user
        result = users_collection.insert_one(admin_user.to_dict(include_sensitive=True))
        
        logger.info(f"✅ Created default admin user: {username}")
        logger.info(f"   Email: {email}")
        logger.info(f"   Password: {password}")
        logger.info(f"   User ID: {admin_user.user_id}")
        
        return admin_user
    
    def initialize_database(self, create_admin=True):
        """Initialize complete database"""
        logger.info("🚀 Starting database initialization...")
        
        try:
            # Step 1: Create collections and indexes
            self.create_collections()
            
            # Step 2: Create system permissions
            self.create_system_permissions()
            
            # Step 3: Create system roles
            self.create_system_roles()
            
            # Step 4: Create default admin user
            if create_admin:
                self.create_default_admin()
            
            logger.info("🎉 Database initialization completed successfully!")
            
            # Print summary
            self.print_summary()
            
        except Exception as e:
            logger.error(f"❌ Database initialization failed: {e}")
            raise
    
    def print_summary(self):
        """Print database summary"""
        logger.info("\n📊 DATABASE SUMMARY:")
        logger.info("=" * 50)
        
        collections = [
            ('users', 'Users'),
            ('roles', 'Roles'),
            ('permissions', 'Permissions'),
            ('user_sessions', 'User Sessions'),
            ('projects', 'Projects'),
            ('project_groups', 'Project Groups'),
            ('channels', 'Channels'),
            ('chaincodes', 'Chaincodes'),
            ('activity_logs', 'Activity Logs'),
            ('assets', 'Assets'),
            ('transactions', 'Transactions')
        ]
        
        for collection_name, display_name in collections:
            count = self.db[collection_name].count_documents({})
            logger.info(f"📋 {display_name}: {count} documents")
        
        logger.info("=" * 50)
    
    def close_connection(self):
        """Close database connection"""
        if self.client:
            self.client.close()
            logger.info("Database connection closed")

def main():
    """Main function for standalone execution"""
    initializer = DatabaseInitializer()
    try:
        initializer.initialize_database()
    finally:
        initializer.close_connection()

if __name__ == "__main__":
    main()
