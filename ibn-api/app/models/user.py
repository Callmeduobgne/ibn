from datetime import datetime, timezone
from werkzeug.security import generate_password_hash, check_password_hash
import uuid

class User:
    """
    User model cho enterprise user management system
    Theo kiến trúc Giai đoạn 2 - Application Layer
    """
    
    def __init__(self, username, email, password=None, full_name=None, 
                 role_id=None, department=None, phone=None, status='active',
                 created_by=None, user_id=None, created_at=None, updated_at=None):
        """
        Initialize User object
        
        Args:
            username (str): Unique username
            email (str): User email address
            password (str): Plain text password (will be hashed)
            full_name (str): User's full name
            role_id (str): Reference to role collection
            department (str): User's department
            phone (str): Phone number
            status (str): active, inactive, suspended
            created_by (str): User ID who created this user
            user_id (str): Unique user ID (auto-generated if None)
            created_at (datetime): Creation timestamp
            updated_at (datetime): Last update timestamp
        """
        self.user_id = user_id or str(uuid.uuid4())
        self.username = username
        self.email = email
        self.full_name = full_name
        self.role_id = role_id
        self.department = department
        self.phone = phone
        self.status = status
        self.created_by = created_by
        self.created_at = created_at or datetime.now(timezone.utc)
        self.updated_at = updated_at or datetime.now(timezone.utc)
        
        # Password handling
        if password:
            self.password_hash = generate_password_hash(password)
        else:
            self.password_hash = None
            
        # Additional fields for enterprise features
        self.last_login = None
        self.login_attempts = 0
        self.locked_until = None
        self.password_changed_at = datetime.now(timezone.utc)
        self.must_change_password = False
        
        # Profile information
        self.avatar_url = None
        self.timezone = 'UTC'
        self.language = 'en'
        
        # Audit fields
        self.last_activity = None
        self.ip_address = None
        self.user_agent = None
    
    def set_password(self, password):
        """Set user password with hash"""
        self.password_hash = generate_password_hash(password)
        self.password_changed_at = datetime.now(timezone.utc)
        self.must_change_password = False
        self.updated_at = datetime.now(timezone.utc)
    
    def check_password(self, password):
        """Check if provided password matches hash"""
        if not self.password_hash:
            return False
        return check_password_hash(self.password_hash, password)
    
    def is_active(self):
        """Check if user is active"""
        return self.status == 'active'
    
    def is_locked(self):
        """Check if user account is locked"""
        if self.locked_until:
            return datetime.now(timezone.utc) < self.locked_until
        return False
    
    def lock_account(self, duration_minutes=30):
        """Lock user account for specified duration"""
        self.locked_until = datetime.now(timezone.utc).replace(
            minute=datetime.now(timezone.utc).minute + duration_minutes
        )
        self.status = 'locked'
        self.updated_at = datetime.now(timezone.utc)
    
    def unlock_account(self):
        """Unlock user account"""
        self.locked_until = None
        self.login_attempts = 0
        self.status = 'active'
        self.updated_at = datetime.now(timezone.utc)
    
    def record_login_attempt(self, success=False, ip_address=None, user_agent=None):
        """Record login attempt"""
        if success:
            self.last_login = datetime.now(timezone.utc)
            self.login_attempts = 0
            self.last_activity = datetime.now(timezone.utc)
            self.ip_address = ip_address
            self.user_agent = user_agent
        else:
            self.login_attempts += 1
            # Lock account after 5 failed attempts
            if self.login_attempts >= 5:
                self.lock_account()
        
        self.updated_at = datetime.now(timezone.utc)
    
    def update_activity(self, ip_address=None, user_agent=None):
        """Update last activity timestamp"""
        self.last_activity = datetime.now(timezone.utc)
        if ip_address:
            self.ip_address = ip_address
        if user_agent:
            self.user_agent = user_agent
        self.updated_at = datetime.now(timezone.utc)
    
    def to_dict(self, include_sensitive=False):
        """Convert user to dictionary"""
        user_dict = {
            'user_id': self.user_id,
            'username': self.username,
            'email': self.email,
            'full_name': self.full_name,
            'role_id': self.role_id,
            'department': self.department,
            'phone': self.phone,
            'status': self.status,
            'created_by': self.created_by,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'last_login': self.last_login.isoformat() if self.last_login else None,
            'last_activity': self.last_activity.isoformat() if self.last_activity else None,
            'avatar_url': self.avatar_url,
            'timezone': self.timezone,
            'language': self.language,
            'must_change_password': self.must_change_password,
            'password_changed_at': self.password_changed_at.isoformat() if self.password_changed_at else None
        }
        
        if include_sensitive:
            user_dict.update({
                'password_hash': self.password_hash,
                'login_attempts': self.login_attempts,
                'locked_until': self.locked_until.isoformat() if self.locked_until else None,
                'ip_address': self.ip_address,
                'user_agent': self.user_agent
            })
        
        return user_dict
    
    @classmethod
    def from_dict(cls, data):
        """Create User object from dictionary"""
        user = cls(
            username=data.get('username'),
            email=data.get('email'),
            full_name=data.get('full_name'),
            role_id=data.get('role_id'),
            department=data.get('department'),
            phone=data.get('phone'),
            status=data.get('status', 'active'),
            created_by=data.get('created_by'),
            user_id=data.get('user_id'),
            created_at=datetime.fromisoformat(data['created_at'].replace('Z', '+00:00')) if data.get('created_at') else None,
            updated_at=datetime.fromisoformat(data['updated_at'].replace('Z', '+00:00')) if data.get('updated_at') else None
        )
        
        # Set additional fields
        if data.get('password_hash'):
            user.password_hash = data['password_hash']
        if data.get('last_login'):
            user.last_login = datetime.fromisoformat(data['last_login'].replace('Z', '+00:00'))
        if data.get('last_activity'):
            user.last_activity = datetime.fromisoformat(data['last_activity'].replace('Z', '+00:00'))
        if data.get('locked_until'):
            user.locked_until = datetime.fromisoformat(data['locked_until'].replace('Z', '+00:00'))
        if data.get('password_changed_at'):
            user.password_changed_at = datetime.fromisoformat(data['password_changed_at'].replace('Z', '+00:00'))
        
        user.login_attempts = data.get('login_attempts', 0)
        user.avatar_url = data.get('avatar_url')
        user.timezone = data.get('timezone', 'UTC')
        user.language = data.get('language', 'en')
        user.must_change_password = data.get('must_change_password', False)
        user.ip_address = data.get('ip_address')
        user.user_agent = data.get('user_agent')
        
        return user
    
    def __repr__(self):
        return f"<User {self.username} ({self.email})>"
