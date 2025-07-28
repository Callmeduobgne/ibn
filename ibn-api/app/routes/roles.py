"""
Role Management routes với RBAC
Theo kiến trúc Giai đoạn 2 - Application Layer
"""

from flask import Blueprint, request, jsonify
from datetime import datetime, timezone
import logging

from ..services.auth_service import require_auth
from ..services.rbac_service import RBACService, require_any_permission
from ..models.role import Role
from ..models.permission import Permission

# Setup logging
logger = logging.getLogger(__name__)

# Create blueprint
roles_bp = Blueprint('roles', __name__, url_prefix='/api/roles')

@roles_bp.route('/', methods=['GET'])
@require_auth
@require_any_permission('view_roles', 'role_management')
def get_roles():
    """
    Get list of roles với user counts
    
    Returns:
    {
        "success": true,
        "data": {
            "roles": [...],
            "total": 4
        }
    }
    """
    try:
        rbac_service = RBACService()
        
        # Get all roles
        roles_data = list(rbac_service.db.roles.find({'is_active': True}).sort('priority', 1))
        
        roles = []
        for role_data in roles_data:
            role = Role.from_dict(role_data)
            role_dict = role.to_dict()
            
            # Count users with this role
            user_count = rbac_service.db.users.count_documents({'role_id': role.role_id})
            role_dict['user_count'] = user_count
            
            # Get permissions details
            permissions_data = list(rbac_service.db.permissions.find({
                'permission_id': {'$in': role.permissions}
            }))
            
            role_dict['permissions_details'] = []
            for perm_data in permissions_data:
                permission = Permission.from_dict(perm_data)
                role_dict['permissions_details'].append({
                    'permission_name': permission.permission_name,
                    'display_name': permission.display_name,
                    'module': permission.module,
                    'resource': permission.resource,
                    'action': permission.action
                })
            
            roles.append(role_dict)
        
        rbac_service.close_connection()
        
        return jsonify({
            'success': True,
            'data': {
                'roles': roles,
                'total': len(roles)
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Get roles endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@roles_bp.route('/<role_id>', methods=['GET'])
@require_auth
@require_any_permission('view_roles', 'role_management')
def get_role(role_id):
    """
    Get specific role với detailed information
    
    Returns:
    {
        "success": true,
        "data": {
            "role": {...},
            "permissions": [...],
            "users": [...]
        }
    }
    """
    try:
        rbac_service = RBACService()
        
        # Get role
        role_data = rbac_service.db.roles.find_one({'role_id': role_id})
        if not role_data:
            return jsonify({
                'success': False,
                'error': 'Role not found'
            }), 404
        
        role = Role.from_dict(role_data)
        
        # Get permissions
        permissions_data = list(rbac_service.db.permissions.find({
            'permission_id': {'$in': role.permissions}
        }))
        
        permissions = []
        for perm_data in permissions_data:
            permission = Permission.from_dict(perm_data)
            permissions.append(permission.to_dict())
        
        # Get users with this role
        users_data = list(rbac_service.db.users.find({'role_id': role_id}))
        users = []
        for user_data in users_data:
            from ..models.user import User
            user = User.from_dict(user_data)
            users.append({
                'user_id': user.user_id,
                'username': user.username,
                'email': user.email,
                'full_name': user.full_name,
                'status': user.status,
                'created_at': user.created_at.isoformat() if user.created_at else None
            })
        
        rbac_service.close_connection()
        
        return jsonify({
            'success': True,
            'data': {
                'role': role.to_dict(),
                'permissions': permissions,
                'users': users,
                'user_count': len(users)
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Get role endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@roles_bp.route('/manageable', methods=['GET'])
@require_auth
def get_manageable_roles():
    """
    Get roles that current user can manage
    
    Returns:
    {
        "success": true,
        "data": {
            "roles": [...],
            "total": 2
        }
    }
    """
    try:
        rbac_service = RBACService()
        
        # Get manageable roles
        manageable_roles, error = rbac_service.get_manageable_roles(request.current_user['user_id'])
        
        if error:
            return jsonify({
                'success': False,
                'error': error
            }), 500
        
        roles = []
        for role in manageable_roles:
            role_dict = role.to_dict()
            
            # Count users with this role
            user_count = rbac_service.db.users.count_documents({'role_id': role.role_id})
            role_dict['user_count'] = user_count
            
            roles.append(role_dict)
        
        rbac_service.close_connection()
        
        return jsonify({
            'success': True,
            'data': {
                'roles': roles,
                'total': len(roles)
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Get manageable roles endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@roles_bp.route('/<role_id>/permissions', methods=['PUT'])
@require_auth
@require_any_permission('role_management', 'update_roles')
def update_role_permissions(role_id):
    """
    Update role permissions
    
    Expected JSON:
    {
        "permission_names": ["view_users", "create_users", ...]
    }
    
    Returns:
    {
        "success": true,
        "message": "Role permissions updated"
    }
    """
    try:
        # Get request data
        data = request.get_json()
        if not data or 'permission_names' not in data:
            return jsonify({
                'success': False,
                'error': 'permission_names array is required'
            }), 400
        
        rbac_service = RBACService()
        
        # Get role
        role_data = rbac_service.db.roles.find_one({'role_id': role_id})
        if not role_data:
            return jsonify({
                'success': False,
                'error': 'Role not found'
            }), 404
        
        role = Role.from_dict(role_data)
        
        # Check if user can manage this role
        can_manage, error = rbac_service.can_user_manage_role(
            request.current_user['user_id'], 
            role.role_name
        )
        
        if not can_manage:
            return jsonify({
                'success': False,
                'error': f'Cannot manage role: {error}'
            }), 403
        
        # Get permission IDs from names
        permission_names = data['permission_names']
        permissions_data = list(rbac_service.db.permissions.find({
            'permission_name': {'$in': permission_names}
        }))
        
        permission_ids = [perm['permission_id'] for perm in permissions_data]
        
        # Update role permissions
        result = rbac_service.db.roles.update_one(
            {'role_id': role_id},
            {
                '$set': {
                    'permissions': permission_ids,
                    'updated_at': datetime.now(timezone.utc).isoformat()
                }
            }
        )
        
        rbac_service.close_connection()
        
        if result.modified_count > 0:
            logger.info(f"Role permissions updated: {role.role_name} by {request.current_user['username']}")
            return jsonify({
                'success': True,
                'message': 'Role permissions updated successfully'
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to update role permissions'
            }), 500
        
    except Exception as e:
        logger.error(f"Update role permissions endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@roles_bp.route('/permissions', methods=['GET'])
@require_auth
@require_any_permission('view_roles', 'role_management')
def get_all_permissions():
    """
    Get all available permissions grouped by module
    
    Returns:
    {
        "success": true,
        "data": {
            "permissions_by_module": {...},
            "total": 42
        }
    }
    """
    try:
        rbac_service = RBACService()
        
        # Get all permissions
        permissions_data = list(rbac_service.db.permissions.find({}).sort('module', 1))
        
        # Group by module
        permissions_by_module = {}
        for perm_data in permissions_data:
            permission = Permission.from_dict(perm_data)
            module = permission.module or 'general'
            
            if module not in permissions_by_module:
                permissions_by_module[module] = []
            
            permissions_by_module[module].append({
                'permission_id': permission.permission_id,
                'permission_name': permission.permission_name,
                'display_name': permission.display_name,
                'description': permission.description,
                'resource': permission.resource,
                'action': permission.action
            })
        
        rbac_service.close_connection()
        
        return jsonify({
            'success': True,
            'data': {
                'permissions_by_module': permissions_by_module,
                'total': len(permissions_data)
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Get all permissions endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@roles_bp.route('/check-permission', methods=['POST'])
@require_auth
def check_permission():
    """
    Check if current user has specific permission
    
    Expected JSON:
    {
        "permission_name": "create_users"
    }
    
    Returns:
    {
        "success": true,
        "data": {
            "has_permission": true,
            "permission_name": "create_users"
        }
    }
    """
    try:
        # Get request data
        data = request.get_json()
        if not data or not data.get('permission_name'):
            return jsonify({
                'success': False,
                'error': 'permission_name is required'
            }), 400
        
        rbac_service = RBACService()
        
        # Check permission
        has_permission, error = rbac_service.check_permission(
            request.current_user['user_id'], 
            data['permission_name']
        )
        
        rbac_service.close_connection()
        
        return jsonify({
            'success': True,
            'data': {
                'has_permission': has_permission,
                'permission_name': data['permission_name'],
                'error': error if not has_permission else None
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Check permission endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500
