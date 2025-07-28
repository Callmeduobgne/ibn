"""
Role-Based Access Control Service
Theo kiến trúc Giai đoạn 2 - Application Layer
"""

from datetime import datetime, timezone
from pymongo import MongoClient
import os
import logging

from ..models.user import User
from ..models.role import Role
from ..models.permission import Permission

logger = logging.getLogger(__name__)

class RBACService:
    """Role-Based Access Control service"""
    
    def __init__(self, mongo_uri=None, database_name=None):
        """
        Initialize RBAC Service
        
        Args:
            mongo_uri (str): MongoDB connection URI
            database_name (str): Database name
        """
        self.mongo_uri = mongo_uri or os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
        self.database_name = database_name or os.getenv('MONGO_DB', 'ibn_blockchain')
        
        # Connect to database
        try:
            self.client = MongoClient(self.mongo_uri)
            self.db = self.client[self.database_name]
        except Exception as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            raise
    
    def get_user_role(self, user_id):
        """Get user's role information"""
        try:
            # Get user
            user_data = self.db.users.find_one({'user_id': user_id})
            if not user_data:
                return None, "User not found"
            
            # Get role
            role_data = self.db.roles.find_one({'role_id': user_data['role_id']})
            if not role_data:
                return None, "Role not found"
            
            role = Role.from_dict(role_data)
            return role, None
            
        except Exception as e:
            logger.error(f"Failed to get user role: {e}")
            return None, "Service error"
    
    def get_user_permissions(self, user_id):
        """Get all permissions for a user"""
        try:
            role, error = self.get_user_role(user_id)
            if error:
                return [], error
            
            # Get permissions
            permissions_data = list(self.db.permissions.find({
                'permission_id': {'$in': role.permissions}
            }))
            
            permissions = [Permission.from_dict(perm) for perm in permissions_data]
            return permissions, None
            
        except Exception as e:
            logger.error(f"Failed to get user permissions: {e}")
            return [], "Service error"
    
    def check_permission(self, user_id, permission_name):
        """Check if user has specific permission"""
        try:
            permissions, error = self.get_user_permissions(user_id)
            if error:
                return False, error
            
            # Check if user has permission
            for permission in permissions:
                if permission.permission_name == permission_name:
                    return True, None
            
            return False, f"Permission '{permission_name}' not granted"
            
        except Exception as e:
            logger.error(f"Failed to check permission: {e}")
            return False, "Service error"
    
    def check_multiple_permissions(self, user_id, permission_names, require_all=True):
        """Check multiple permissions"""
        try:
            permissions, error = self.get_user_permissions(user_id)
            if error:
                return False, error
            
            user_permission_names = [perm.permission_name for perm in permissions]
            
            if require_all:
                # User must have ALL permissions
                for perm_name in permission_names:
                    if perm_name not in user_permission_names:
                        return False, f"Missing permission: {perm_name}"
                return True, None
            else:
                # User must have ANY permission
                for perm_name in permission_names:
                    if perm_name in user_permission_names:
                        return True, None
                return False, f"Missing any of permissions: {permission_names}"
                
        except Exception as e:
            logger.error(f"Failed to check multiple permissions: {e}")
            return False, "Service error"
    
    def assign_role_to_user(self, user_id, role_id, assigned_by):
        """Assign role to user"""
        try:
            # Verify role exists
            role_data = self.db.roles.find_one({'role_id': role_id})
            if not role_data:
                return False, "Role not found"
            
            # Verify user exists
            user_data = self.db.users.find_one({'user_id': user_id})
            if not user_data:
                return False, "User not found"
            
            # Check if assigner has permission
            can_assign, error = self.check_permission(assigned_by, 'assign_roles')
            if not can_assign:
                return False, f"Permission denied: {error}"
            
            # Update user role
            result = self.db.users.update_one(
                {'user_id': user_id},
                {
                    '$set': {
                        'role_id': role_id,
                        'updated_at': datetime.now(timezone.utc).isoformat()
                    }
                }
            )
            
            if result.modified_count > 0:
                logger.info(f"Role {role_id} assigned to user {user_id} by {assigned_by}")
                return True, "Role assigned successfully"
            else:
                return False, "Failed to assign role"
                
        except Exception as e:
            logger.error(f"Failed to assign role: {e}")
            return False, "Service error"
    
    def get_role_hierarchy(self, role_name):
        """Get role hierarchy for permission inheritance"""
        try:
            role_data = self.db.roles.find_one({'role_name': role_name})
            if not role_data:
                return None, "Role not found"
            
            role = Role.from_dict(role_data)
            
            # Define role hierarchy
            hierarchy = {
                Role.ADMIN: [Role.LEADER, Role.DEVELOPER, Role.TESTER],
                Role.LEADER: [Role.DEVELOPER, Role.TESTER],
                Role.DEVELOPER: [],
                Role.TESTER: []
            }
            
            return hierarchy.get(role.role_name, []), None
            
        except Exception as e:
            logger.error(f"Failed to get role hierarchy: {e}")
            return None, "Service error"
    
    def can_user_manage_role(self, manager_user_id, target_role_name):
        """Check if user can manage specific role"""
        try:
            # Get manager's role
            manager_role, error = self.get_user_role(manager_user_id)
            if error:
                return False, error
            
            # Get target role
            target_role_data = self.db.roles.find_one({'role_name': target_role_name})
            if not target_role_data:
                return False, "Target role not found"
            
            target_role = Role.from_dict(target_role_data)
            
            # Check if manager can manage target role
            can_manage = manager_role.can_manage_role(target_role)
            
            if can_manage:
                return True, None
            else:
                return False, f"Cannot manage role: {target_role_name}"
                
        except Exception as e:
            logger.error(f"Failed to check role management permission: {e}")
            return False, "Service error"
    
    def get_manageable_roles(self, manager_user_id):
        """Get list of roles that user can manage"""
        try:
            # Get manager's role
            manager_role, error = self.get_user_role(manager_user_id)
            if error:
                return [], error
            
            # Get all roles
            all_roles_data = list(self.db.roles.find({'is_active': True}))
            manageable_roles = []
            
            for role_data in all_roles_data:
                role = Role.from_dict(role_data)
                if manager_role.can_manage_role(role):
                    manageable_roles.append(role)
            
            return manageable_roles, None
            
        except Exception as e:
            logger.error(f"Failed to get manageable roles: {e}")
            return [], "Service error"
    
    def get_users_by_role(self, role_name):
        """Get all users with specific role"""
        try:
            # Get role
            role_data = self.db.roles.find_one({'role_name': role_name})
            if not role_data:
                return [], "Role not found"
            
            # Get users with this role
            users_data = list(self.db.users.find({'role_id': role_data['role_id']}))
            users = [User.from_dict(user_data) for user_data in users_data]
            
            return users, None
            
        except Exception as e:
            logger.error(f"Failed to get users by role: {e}")
            return [], "Service error"
    
    def validate_permission_access(self, user_id, resource_type, resource_id, action):
        """Validate permission for specific resource and action"""
        try:
            # Get user permissions
            permissions, error = self.get_user_permissions(user_id)
            if error:
                return False, error
            
            # Check for specific permission patterns
            permission_patterns = [
                f"{action}_{resource_type}",  # e.g., "create_projects"
                f"manage_{resource_type}",    # e.g., "manage_projects"
                f"manage_all_{resource_type}", # e.g., "manage_all_projects"
                f"{resource_type}_management"  # e.g., "project_management"
            ]
            
            user_permission_names = [perm.permission_name for perm in permissions]
            
            for pattern in permission_patterns:
                if pattern in user_permission_names:
                    return True, None
            
            return False, f"No permission for {action} on {resource_type}"
            
        except Exception as e:
            logger.error(f"Failed to validate permission access: {e}")
            return False, "Service error"
    
    def get_permission_summary(self, user_id):
        """Get comprehensive permission summary for user"""
        try:
            # Get user and role
            user_data = self.db.users.find_one({'user_id': user_id})
            if not user_data:
                return None, "User not found"
            
            role, error = self.get_user_role(user_id)
            if error:
                return None, error
            
            permissions, error = self.get_user_permissions(user_id)
            if error:
                return None, error
            
            # Group permissions by module
            permissions_by_module = {}
            for permission in permissions:
                module = permission.module or 'general'
                if module not in permissions_by_module:
                    permissions_by_module[module] = []
                permissions_by_module[module].append({
                    'name': permission.permission_name,
                    'display_name': permission.display_name,
                    'description': permission.description,
                    'resource': permission.resource,
                    'action': permission.action
                })
            
            return {
                'user': {
                    'user_id': user_data['user_id'],
                    'username': user_data['username'],
                    'email': user_data['email'],
                    'full_name': user_data['full_name']
                },
                'role': {
                    'role_id': role.role_id,
                    'role_name': role.role_name,
                    'display_name': role.display_name,
                    'description': role.description,
                    'priority': role.priority
                },
                'permissions_by_module': permissions_by_module,
                'total_permissions': len(permissions),
                'can_manage_users': any(p.permission_name == 'user_management' for p in permissions),
                'can_manage_roles': any(p.permission_name == 'role_management' for p in permissions),
                'is_admin': role.role_name == Role.ADMIN
            }, None
            
        except Exception as e:
            logger.error(f"Failed to get permission summary: {e}")
            return None, "Service error"
    
    def close_connection(self):
        """Close database connection"""
        if self.client:
            self.client.close()

# Permission checking decorators
def require_any_permission(*permission_names):
    """Decorator to require any of the specified permissions"""
    def decorator(f):
        from functools import wraps
        from flask import request, jsonify
        
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not hasattr(request, 'current_user'):
                return jsonify({'error': 'Authentication required'}), 401
            
            rbac_service = RBACService()
            try:
                has_permission, error = rbac_service.check_multiple_permissions(
                    request.current_user['user_id'], 
                    list(permission_names), 
                    require_all=False
                )
                
                if not has_permission:
                    return jsonify({'error': f'Permission denied: {error}'}), 403
                
                return f(*args, **kwargs)
            finally:
                rbac_service.close_connection()
        
        return decorated_function
    return decorator

def require_all_permissions(*permission_names):
    """Decorator to require all of the specified permissions"""
    def decorator(f):
        from functools import wraps
        from flask import request, jsonify
        
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not hasattr(request, 'current_user'):
                return jsonify({'error': 'Authentication required'}), 401
            
            rbac_service = RBACService()
            try:
                has_permission, error = rbac_service.check_multiple_permissions(
                    request.current_user['user_id'], 
                    list(permission_names), 
                    require_all=True
                )
                
                if not has_permission:
                    return jsonify({'error': f'Permission denied: {error}'}), 403
                
                return f(*args, **kwargs)
            finally:
                rbac_service.close_connection()
        
        return decorated_function
    return decorator
