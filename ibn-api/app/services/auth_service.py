"""
Authentication Service cho User Management System
Theo kiến trúc Giai đoạn 2 - Application Layer
"""

import jwt
import secrets
from datetime import datetime, timezone, timedelta
from functools import wraps
from flask import request, jsonify, current_app
from pymongo import MongoClient
import os
import logging

from ..models.user import User
from ..models.role import Role
from ..models.permission import Permission
from ..models.user_session import UserSession

logger = logging.getLogger(__name__)

class AuthService:
    """Authentication service với JWT và session management"""
    
    def __init__(self, mongo_uri=None, database_name=None):
        """
        Initialize AuthService
        
        Args:
            mongo_uri (str): MongoDB connection URI
            database_name (str): Database name
        """
        self.mongo_uri = mongo_uri or os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
        self.database_name = database_name or os.getenv('MONGO_DB', 'ibn_blockchain')
        
        # JWT configuration
        self.jwt_secret = os.getenv('JWT_SECRET', 'ibn-blockchain-secret-key-2025')
        self.jwt_algorithm = 'HS256'
        self.access_token_expires = timedelta(hours=8)
        self.refresh_token_expires = timedelta(days=30)
        
        # Connect to database
        try:
            self.client = MongoClient(self.mongo_uri)
            self.db = self.client[self.database_name]
        except Exception as e:
            logger.error(f"Failed to connect to MongoDB: {e}")
            raise
    
    def generate_tokens(self, user):
        """Generate access and refresh tokens for user"""
        try:
            # Create access token payload
            access_payload = {
                'user_id': user.user_id,
                'username': user.username,
                'email': user.email,
                'role_id': user.role_id,
                'exp': datetime.now(timezone.utc) + self.access_token_expires,
                'iat': datetime.now(timezone.utc),
                'type': 'access'
            }
            
            # Create refresh token payload
            refresh_payload = {
                'user_id': user.user_id,
                'exp': datetime.now(timezone.utc) + self.refresh_token_expires,
                'iat': datetime.now(timezone.utc),
                'type': 'refresh'
            }
            
            # Generate tokens
            access_token = jwt.encode(access_payload, self.jwt_secret, algorithm=self.jwt_algorithm)
            refresh_token = jwt.encode(refresh_payload, self.jwt_secret, algorithm=self.jwt_algorithm)
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'expires_in': int(self.access_token_expires.total_seconds()),
                'token_type': 'Bearer'
            }
            
        except Exception as e:
            logger.error(f"Failed to generate tokens: {e}")
            return None
    
    def verify_token(self, token, token_type='access'):
        """Verify JWT token"""
        try:
            payload = jwt.decode(token, self.jwt_secret, algorithms=[self.jwt_algorithm])
            
            # Check token type
            if payload.get('type') != token_type:
                return None
            
            # Check expiration
            if datetime.now(timezone.utc) > datetime.fromtimestamp(payload['exp'], timezone.utc):
                return None
            
            return payload
            
        except jwt.ExpiredSignatureError:
            logger.warning("Token has expired")
            return None
        except jwt.InvalidTokenError as e:
            logger.warning(f"Invalid token: {e}")
            return None
        except Exception as e:
            logger.error(f"Token verification failed: {e}")
            return None
    
    def authenticate_user(self, username, password, ip_address=None, user_agent=None):
        """Authenticate user với username/password"""
        try:
            # Find user by username or email
            users_collection = self.db.users
            user_data = users_collection.find_one({
                '$or': [
                    {'username': username},
                    {'email': username}
                ]
            })
            
            if not user_data:
                logger.warning(f"User not found: {username}")
                return None, "Invalid username or password"
            
            # Create user object
            user = User.from_dict(user_data)
            
            # Check if user is active
            if not user.is_active():
                logger.warning(f"Inactive user attempted login: {username}")
                return None, "Account is inactive"
            
            # Check if account is locked
            if user.is_locked():
                logger.warning(f"Locked user attempted login: {username}")
                return None, "Account is locked. Please try again later."
            
            # Verify password
            if not user.check_password(password):
                # Record failed login attempt
                user.record_login_attempt(success=False, ip_address=ip_address, user_agent=user_agent)
                users_collection.update_one(
                    {'user_id': user.user_id},
                    {'$set': user.to_dict(include_sensitive=True)}
                )
                logger.warning(f"Invalid password for user: {username}")
                return None, "Invalid username or password"
            
            # Record successful login
            user.record_login_attempt(success=True, ip_address=ip_address, user_agent=user_agent)
            users_collection.update_one(
                {'user_id': user.user_id},
                {'$set': user.to_dict(include_sensitive=True)}
            )
            
            # Generate tokens
            tokens = self.generate_tokens(user)
            if not tokens:
                return None, "Failed to generate authentication tokens"
            
            # Create user session
            session = UserSession(
                user_id=user.user_id,
                session_token=tokens['access_token'],
                refresh_token=tokens['refresh_token'],
                ip_address=ip_address,
                user_agent=user_agent
            )
            
            # Save session to database
            sessions_collection = self.db.user_sessions
            sessions_collection.insert_one(session.to_dict(include_tokens=True))
            
            logger.info(f"User authenticated successfully: {username}")
            
            return {
                'user': user.to_dict(),
                'tokens': tokens,
                'session': session.to_dict()
            }, None
            
        except Exception as e:
            logger.error(f"Authentication failed: {e}")
            return None, "Authentication service error"
    
    def refresh_access_token(self, refresh_token):
        """Refresh access token using refresh token"""
        try:
            # Verify refresh token
            payload = self.verify_token(refresh_token, token_type='refresh')
            if not payload:
                return None, "Invalid refresh token"
            
            # Get user
            users_collection = self.db.users
            user_data = users_collection.find_one({'user_id': payload['user_id']})
            if not user_data:
                return None, "User not found"
            
            user = User.from_dict(user_data)
            
            # Check if user is still active
            if not user.is_active():
                return None, "Account is inactive"
            
            # Find session
            sessions_collection = self.db.user_sessions
            session_data = sessions_collection.find_one({
                'user_id': user.user_id,
                'refresh_token': refresh_token,
                'is_active': True
            })
            
            if not session_data:
                return None, "Session not found or expired"
            
            session = UserSession.from_dict(session_data)
            
            # Check if session is valid
            if not session.is_valid():
                return None, "Session expired"
            
            # Generate new tokens
            new_tokens = self.generate_tokens(user)
            if not new_tokens:
                return None, "Failed to generate new tokens"
            
            # Update session
            if not session.refresh_tokens(new_tokens['access_token']):
                return None, "Maximum refresh limit reached"
            
            # Update session in database
            sessions_collection.update_one(
                {'session_id': session.session_id},
                {'$set': session.to_dict(include_tokens=True)}
            )
            
            logger.info(f"Token refreshed for user: {user.username}")
            
            return {
                'tokens': new_tokens,
                'session': session.to_dict()
            }, None
            
        except Exception as e:
            logger.error(f"Token refresh failed: {e}")
            return None, "Token refresh service error"
    
    def logout_user(self, session_token):
        """Logout user và invalidate session"""
        try:
            # Verify token
            payload = self.verify_token(session_token)
            if not payload:
                return False, "Invalid session token"
            
            # Find and invalidate session
            sessions_collection = self.db.user_sessions
            result = sessions_collection.update_one(
                {
                    'user_id': payload['user_id'],
                    'session_token': session_token,
                    'is_active': True
                },
                {
                    '$set': {
                        'is_active': False,
                        'session_token': None,
                        'updated_at': datetime.now(timezone.utc).isoformat()
                    }
                }
            )
            
            if result.modified_count > 0:
                logger.info(f"User logged out: {payload['username']}")
                return True, "Logged out successfully"
            else:
                return False, "Session not found"
                
        except Exception as e:
            logger.error(f"Logout failed: {e}")
            return False, "Logout service error"
    
    def get_user_permissions(self, user_id):
        """Get user permissions based on role"""
        try:
            # Get user
            users_collection = self.db.users
            user_data = users_collection.find_one({'user_id': user_id})
            if not user_data:
                return []
            
            # Get role
            roles_collection = self.db.roles
            role_data = roles_collection.find_one({'role_id': user_data['role_id']})
            if not role_data:
                return []
            
            # Get permissions
            permissions_collection = self.db.permissions
            permission_ids = role_data.get('permissions', [])
            permissions = list(permissions_collection.find({
                'permission_id': {'$in': permission_ids}
            }))
            
            return [perm['permission_name'] for perm in permissions]
            
        except Exception as e:
            logger.error(f"Failed to get user permissions: {e}")
            return []
    
    def cleanup_expired_sessions(self):
        """Clean up expired sessions"""
        try:
            sessions_collection = self.db.user_sessions
            result = sessions_collection.delete_many({
                'expires_at': {'$lt': datetime.now(timezone.utc).isoformat()}
            })
            
            logger.info(f"Cleaned up {result.deleted_count} expired sessions")
            return result.deleted_count
            
        except Exception as e:
            logger.error(f"Session cleanup failed: {e}")
            return 0

# Decorator for protecting routes
def require_auth(f):
    """Decorator to require authentication for routes"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({'error': 'Authorization header required'}), 401
        
        try:
            token = auth_header.split(' ')[1]  # Bearer <token>
        except IndexError:
            return jsonify({'error': 'Invalid authorization header format'}), 401
        
        auth_service = AuthService()
        payload = auth_service.verify_token(token)
        
        if not payload:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        # Add user info to request context
        request.current_user = payload
        
        return f(*args, **kwargs)
    
    return decorated_function

def require_permission(permission_name):
    """Decorator to require specific permission"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not hasattr(request, 'current_user'):
                return jsonify({'error': 'Authentication required'}), 401
            
            auth_service = AuthService()
            user_permissions = auth_service.get_user_permissions(request.current_user['user_id'])
            
            if permission_name not in user_permissions:
                return jsonify({'error': f'Permission required: {permission_name}'}), 403
            
            return f(*args, **kwargs)
        
        return decorated_function
    return decorator
