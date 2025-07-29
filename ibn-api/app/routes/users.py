"""
User Management routes với RBAC
Theo kiến trúc Giai đoạn 2 - Application Layer
"""

from flask import Blueprint, request, jsonify
from datetime import datetime, timezone
import logging

from ..services.auth_service import require_auth
from ..services.rbac_service import RBACService, require_any_permission, require_all_permissions
from ..models.user import User
from ..models.role import Role

# Setup logging
logger = logging.getLogger(__name__)

# Create blueprint
users_bp = Blueprint('users', __name__, url_prefix='/api/users')

@users_bp.route('/', methods=['GET'])
@require_auth
@require_any_permission('view_users', 'user_management')
def get_users():
    """
    Get list of users với pagination và filtering
    
    Query parameters:
    - page: Page number (default: 1)
    - limit: Items per page (default: 20)
    - role: Filter by role name
    - status: Filter by status
    - search: Search in username, email, full_name
    
    Returns:
    {
        "success": true,
        "data": {
            "users": [...],
            "pagination": {...}
        }
    }
    """
    try:
        # Get query parameters
        page = int(request.args.get('page', 1))
        limit = int(request.args.get('limit', 20))
        role_filter = request.args.get('role')
        status_filter = request.args.get('status')
        search = request.args.get('search')
        
        # Build query
        query = {}
        
        if role_filter:
            # Get role ID
            rbac_service = RBACService()
            role_data = rbac_service.db.roles.find_one({'role_name': role_filter})
            if role_data:
                query['role_id'] = role_data['role_id']
        
        if status_filter:
            query['status'] = status_filter
        
        if search:
            query['$or'] = [
                {'username': {'$regex': search, '$options': 'i'}},
                {'email': {'$regex': search, '$options': 'i'}},
                {'full_name': {'$regex': search, '$options': 'i'}}
            ]
        
        # Get total count
        rbac_service = RBACService()
        total = rbac_service.db.users.count_documents(query)
        
        # Get users with pagination
        skip = (page - 1) * limit
        users_data = list(rbac_service.db.users.find(query)
                         .skip(skip)
                         .limit(limit)
                         .sort('created_at', -1))
        
        # Convert to User objects and add role info
        users = []
        for user_data in users_data:
            user = User.from_dict(user_data)
            user_dict = user.to_dict()
            
            # Add role information
            role_data = rbac_service.db.roles.find_one({'role_id': user.role_id})
            if role_data:
                user_dict['role'] = {
                    'role_name': role_data['role_name'],
                    'display_name': role_data['display_name'],
                    'description': role_data['description']
                }
            
            users.append(user_dict)
        
        # Calculate pagination
        total_pages = (total + limit - 1) // limit
        
        pagination = {
            'page': page,
            'limit': limit,
            'total': total,
            'total_pages': total_pages,
            'has_next': page < total_pages,
            'has_prev': page > 1
        }
        
        rbac_service.close_connection()
        
        return jsonify({
            'success': True,
            'data': {
                'users': users,
                'pagination': pagination
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Get users endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@users_bp.route('/<user_id>', methods=['GET'])
@require_auth
@require_any_permission('view_users', 'user_management')
def get_user(user_id):
    """
    Get specific user với detailed information
    
    Returns:
    {
        "success": true,
        "data": {
            "user": {...},
            "role": {...},
            "permissions": [...],
            "sessions": [...]
        }
    }
    """
    try:
        rbac_service = RBACService()
        
        # Get user
        user_data = rbac_service.db.users.find_one({'user_id': user_id})
        if not user_data:
            return jsonify({
                'success': False,
                'error': 'User not found'
            }), 404
        
        user = User.from_dict(user_data)
        
        # Get permission summary
        permission_summary, error = rbac_service.get_permission_summary(user_id)
        if error:
            return jsonify({
                'success': False,
                'error': error
            }), 500
        
        # Get active sessions
        sessions_data = list(rbac_service.db.user_sessions.find({
            'user_id': user_id,
            'is_active': True
        }).sort('created_at', -1))
        
        sessions = []
        for session_data in sessions_data:
            from ..models.user_session import UserSession
            session = UserSession.from_dict(session_data)
            sessions.append(session.to_dict())
        
        rbac_service.close_connection()
        
        return jsonify({
            'success': True,
            'data': {
                'user': permission_summary['user'],
                'role': permission_summary['role'],
                'permissions_by_module': permission_summary['permissions_by_module'],
                'total_permissions': permission_summary['total_permissions'],
                'capabilities': {
                    'can_manage_users': permission_summary['can_manage_users'],
                    'can_manage_roles': permission_summary['can_manage_roles'],
                    'is_admin': permission_summary['is_admin']
                },
                'sessions': sessions
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Get user endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@users_bp.route('/', methods=['POST'])
@require_auth
@require_any_permission('create_users', 'user_management')
def create_user():
    """
    Create new user
    
    Expected JSON:
    {
        "username": "newuser",
        "email": "user@example.com",
        "password": "password123",
        "full_name": "New User",
        "role_name": "developer",
        "department": "IT",
        "phone": "+1234567890"
    }
    
    Returns:
    {
        "success": true,
        "data": {
            "user": {...}
        }
    }
    """
    try:
        # Get request data
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'error': 'JSON data required'
            }), 400
        
        # Validate required fields
        required_fields = ['username', 'email', 'password', 'role_name']
        for field in required_fields:
            if not data.get(field):
                return jsonify({
                    'success': False,
                    'error': f'{field} is required'
                }), 400
        
        rbac_service = RBACService()
        
        # Check if username/email already exists
        existing_user = rbac_service.db.users.find_one({
            '$or': [
                {'username': data['username']},
                {'email': data['email']}
            ]
        })
        
        if existing_user:
            return jsonify({
                'success': False,
                'error': 'Username or email already exists'
            }), 400
        
        # Get role
        role_data = rbac_service.db.roles.find_one({'role_name': data['role_name']})
        if not role_data:
            return jsonify({
                'success': False,
                'error': f'Role not found: {data["role_name"]}'
            }), 400
        
        # Check if current user can assign this role
        can_manage, error = rbac_service.can_user_manage_role(
            request.current_user['user_id'], 
            data['role_name']
        )
        
        if not can_manage:
            return jsonify({
                'success': False,
                'error': f'Cannot assign role: {error}'
            }), 403
        
        # Create user
        user = User(
            username=data['username'],
            email=data['email'],
            password=data['password'],
            full_name=data.get('full_name'),
            role_id=role_data['role_id'],
            department=data.get('department'),
            phone=data.get('phone'),
            created_by=request.current_user['user_id']
        )
        
        # Insert user
        result = rbac_service.db.users.insert_one(user.to_dict(include_sensitive=True))
        
        if result.inserted_id:
            logger.info(f"User created: {user.username} by {request.current_user['username']}")
            
            rbac_service.close_connection()
            
            return jsonify({
                'success': True,
                'data': {
                    'user': user.to_dict(),
                    'message': 'User created successfully'
                }
            }), 201
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to create user'
            }), 500
        
    except Exception as e:
        logger.error(f"Create user endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@users_bp.route('/<user_id>/role', methods=['PUT'])
@require_auth
@require_any_permission('assign_roles', 'user_management')
def assign_role(user_id):
    """
    Assign role to user
    
    Expected JSON:
    {
        "role_name": "developer"
    }
    
    Returns:
    {
        "success": true,
        "message": "Role assigned successfully"
    }
    """
    try:
        # Get request data
        data = request.get_json()
        if not data or not data.get('role_name'):
            return jsonify({
                'success': False,
                'error': 'role_name is required'
            }), 400
        
        rbac_service = RBACService()
        
        # Get role
        role_data = rbac_service.db.roles.find_one({'role_name': data['role_name']})
        if not role_data:
            return jsonify({
                'success': False,
                'error': f'Role not found: {data["role_name"]}'
            }), 400
        
        # Assign role
        success, message = rbac_service.assign_role_to_user(
            user_id=user_id,
            role_id=role_data['role_id'],
            assigned_by=request.current_user['user_id']
        )
        
        rbac_service.close_connection()
        
        if success:
            return jsonify({
                'success': True,
                'message': message
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': message
            }), 400
        
    except Exception as e:
        logger.error(f"Assign role endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@users_bp.route('/<user_id>/status', methods=['PUT'])
@require_auth
@require_any_permission('update_users', 'user_management')
def update_user_status(user_id):
    """
    Update user status (active, inactive, suspended)
    
    Expected JSON:
    {
        "status": "inactive"
    }
    
    Returns:
    {
        "success": true,
        "message": "User status updated"
    }
    """
    try:
        # Get request data
        data = request.get_json()
        if not data or not data.get('status'):
            return jsonify({
                'success': False,
                'error': 'status is required'
            }), 400
        
        valid_statuses = ['active', 'inactive', 'suspended']
        if data['status'] not in valid_statuses:
            return jsonify({
                'success': False,
                'error': f'Invalid status. Must be one of: {valid_statuses}'
            }), 400
        
        rbac_service = RBACService()
        
        # Update user status
        result = rbac_service.db.users.update_one(
            {'user_id': user_id},
            {
                '$set': {
                    'status': data['status'],
                    'updated_at': datetime.now(timezone.utc).isoformat()
                }
            }
        )
        
        rbac_service.close_connection()
        
        if result.modified_count > 0:
            logger.info(f"User status updated: {user_id} -> {data['status']} by {request.current_user['username']}")
            return jsonify({
                'success': True,
                'message': 'User status updated successfully'
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'User not found or status unchanged'
            }), 404
        
    except Exception as e:
        logger.error(f"Update user status endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500
