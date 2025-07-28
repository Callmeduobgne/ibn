"""
Authentication routes cho User Management System
Theo kiến trúc Giai đoạn 2 - Application Layer
"""

from flask import Blueprint, request, jsonify
from datetime import datetime, timezone
import logging

from ..services.auth_service import AuthService, require_auth
from ..models.user import User
from ..models.user_session import UserSession

# Setup logging
logger = logging.getLogger(__name__)

# Create blueprint
auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

@auth_bp.route('/login', methods=['POST'])
def login():
    """
    User login endpoint
    
    Expected JSON:
    {
        "username": "admin",
        "password": "admin123"
    }
    
    Returns:
    {
        "success": true,
        "data": {
            "user": {...},
            "tokens": {...},
            "session": {...}
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
        
        username = data.get('username')
        password = data.get('password')
        
        if not username or not password:
            return jsonify({
                'success': False,
                'error': 'Username and password required'
            }), 400
        
        # Get client info
        ip_address = request.remote_addr
        user_agent = request.headers.get('User-Agent')
        
        # Authenticate user
        auth_service = AuthService()
        result, error = auth_service.authenticate_user(
            username=username,
            password=password,
            ip_address=ip_address,
            user_agent=user_agent
        )
        
        if error:
            logger.warning(f"Login failed for {username}: {error}")
            return jsonify({
                'success': False,
                'error': error
            }), 401
        
        logger.info(f"User logged in successfully: {username}")
        
        return jsonify({
            'success': True,
            'data': result,
            'message': 'Login successful'
        }), 200
        
    except Exception as e:
        logger.error(f"Login endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@auth_bp.route('/refresh', methods=['POST'])
def refresh_token():
    """
    Refresh access token endpoint
    
    Expected JSON:
    {
        "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
    }
    
    Returns:
    {
        "success": true,
        "data": {
            "tokens": {...},
            "session": {...}
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
        
        refresh_token = data.get('refresh_token')
        if not refresh_token:
            return jsonify({
                'success': False,
                'error': 'Refresh token required'
            }), 400
        
        # Refresh token
        auth_service = AuthService()
        result, error = auth_service.refresh_access_token(refresh_token)
        
        if error:
            logger.warning(f"Token refresh failed: {error}")
            return jsonify({
                'success': False,
                'error': error
            }), 401
        
        logger.info("Token refreshed successfully")
        
        return jsonify({
            'success': True,
            'data': result,
            'message': 'Token refreshed successfully'
        }), 200
        
    except Exception as e:
        logger.error(f"Token refresh endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@auth_bp.route('/logout', methods=['POST'])
@require_auth
def logout():
    """
    User logout endpoint
    
    Headers:
    Authorization: Bearer <access_token>
    
    Returns:
    {
        "success": true,
        "message": "Logged out successfully"
    }
    """
    try:
        # Get token from header
        auth_header = request.headers.get('Authorization')
        token = auth_header.split(' ')[1]  # Bearer <token>
        
        # Logout user
        auth_service = AuthService()
        success, message = auth_service.logout_user(token)
        
        if not success:
            return jsonify({
                'success': False,
                'error': message
            }), 400
        
        logger.info(f"User logged out: {request.current_user['username']}")
        
        return jsonify({
            'success': True,
            'message': message
        }), 200
        
    except Exception as e:
        logger.error(f"Logout endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@auth_bp.route('/me', methods=['GET'])
@require_auth
def get_current_user():
    """
    Get current user information
    
    Headers:
    Authorization: Bearer <access_token>
    
    Returns:
    {
        "success": true,
        "data": {
            "user": {...},
            "permissions": [...]
        }
    }
    """
    try:
        user_id = request.current_user['user_id']
        
        # Get user details
        auth_service = AuthService()
        user_data = auth_service.db.users.find_one({'user_id': user_id})
        
        if not user_data:
            return jsonify({
                'success': False,
                'error': 'User not found'
            }), 404
        
        user = User.from_dict(user_data)
        
        # Get user permissions
        permissions = auth_service.get_user_permissions(user_id)
        
        # Get role information
        role_data = auth_service.db.roles.find_one({'role_id': user.role_id})
        role_info = None
        if role_data:
            role_info = {
                'role_id': role_data['role_id'],
                'role_name': role_data['role_name'],
                'display_name': role_data['display_name'],
                'description': role_data['description']
            }
        
        return jsonify({
            'success': True,
            'data': {
                'user': user.to_dict(),
                'role': role_info,
                'permissions': permissions
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Get current user endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@auth_bp.route('/change-password', methods=['POST'])
@require_auth
def change_password():
    """
    Change user password
    
    Expected JSON:
    {
        "current_password": "old_password",
        "new_password": "new_password"
    }
    
    Returns:
    {
        "success": true,
        "message": "Password changed successfully"
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
        
        current_password = data.get('current_password')
        new_password = data.get('new_password')
        
        if not current_password or not new_password:
            return jsonify({
                'success': False,
                'error': 'Current password and new password required'
            }), 400
        
        # Validate new password
        if len(new_password) < 6:
            return jsonify({
                'success': False,
                'error': 'New password must be at least 6 characters'
            }), 400
        
        user_id = request.current_user['user_id']
        
        # Get user
        auth_service = AuthService()
        user_data = auth_service.db.users.find_one({'user_id': user_id})
        
        if not user_data:
            return jsonify({
                'success': False,
                'error': 'User not found'
            }), 404
        
        user = User.from_dict(user_data)
        
        # Verify current password
        if not user.check_password(current_password):
            return jsonify({
                'success': False,
                'error': 'Current password is incorrect'
            }), 400
        
        # Set new password
        user.set_password(new_password)
        
        # Update user in database
        auth_service.db.users.update_one(
            {'user_id': user_id},
            {'$set': user.to_dict(include_sensitive=True)}
        )
        
        logger.info(f"Password changed for user: {user.username}")
        
        return jsonify({
            'success': True,
            'message': 'Password changed successfully'
        }), 200
        
    except Exception as e:
        logger.error(f"Change password endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@auth_bp.route('/sessions', methods=['GET'])
@require_auth
def get_user_sessions():
    """
    Get user's active sessions
    
    Headers:
    Authorization: Bearer <access_token>
    
    Returns:
    {
        "success": true,
        "data": {
            "sessions": [...],
            "total": 3
        }
    }
    """
    try:
        user_id = request.current_user['user_id']
        
        # Get user sessions
        auth_service = AuthService()
        sessions_data = list(auth_service.db.user_sessions.find({
            'user_id': user_id,
            'is_active': True
        }).sort('created_at', -1))
        
        sessions = []
        for session_data in sessions_data:
            session = UserSession.from_dict(session_data)
            sessions.append(session.to_dict())
        
        return jsonify({
            'success': True,
            'data': {
                'sessions': sessions,
                'total': len(sessions)
            }
        }), 200
        
    except Exception as e:
        logger.error(f"Get user sessions endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500

@auth_bp.route('/sessions/<session_id>', methods=['DELETE'])
@require_auth
def revoke_session(session_id):
    """
    Revoke a specific session
    
    Headers:
    Authorization: Bearer <access_token>
    
    Returns:
    {
        "success": true,
        "message": "Session revoked successfully"
    }
    """
    try:
        user_id = request.current_user['user_id']
        
        # Revoke session
        auth_service = AuthService()
        result = auth_service.db.user_sessions.update_one(
            {
                'session_id': session_id,
                'user_id': user_id,
                'is_active': True
            },
            {
                '$set': {
                    'is_active': False,
                    'updated_at': datetime.now(timezone.utc).isoformat()
                }
            }
        )
        
        if result.modified_count == 0:
            return jsonify({
                'success': False,
                'error': 'Session not found or already revoked'
            }), 404
        
        logger.info(f"Session revoked: {session_id} for user: {user_id}")
        
        return jsonify({
            'success': True,
            'message': 'Session revoked successfully'
        }), 200
        
    except Exception as e:
        logger.error(f"Revoke session endpoint error: {e}")
        return jsonify({
            'success': False,
            'error': 'Internal server error'
        }), 500
