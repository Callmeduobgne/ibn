from datetime import datetime, timezone, timedelta
import uuid
import secrets

class UserSession:
    """
    UserSession model cho session management và security tracking
    Theo kiến trúc Giai đoạn 2 - Application Layer
    """
    
    def __init__(self, user_id, session_token=None, refresh_token=None,
                 ip_address=None, user_agent=None, expires_at=None,
                 is_active=True, session_id=None, created_at=None, updated_at=None):
        """
        Initialize UserSession object
        
        Args:
            user_id (str): User ID this session belongs to
            session_token (str): JWT session token
            refresh_token (str): Refresh token for token renewal
            ip_address (str): Client IP address
            user_agent (str): Client user agent
            expires_at (datetime): Session expiration time
            is_active (bool): Whether session is active
            session_id (str): Unique session ID
            created_at (datetime): Creation timestamp
            updated_at (datetime): Last update timestamp
        """
        self.session_id = session_id or str(uuid.uuid4())
        self.user_id = user_id
        self.session_token = session_token
        self.refresh_token = refresh_token or self._generate_refresh_token()
        self.ip_address = ip_address
        self.user_agent = user_agent
        self.is_active = is_active
        self.created_at = created_at or datetime.now(timezone.utc)
        self.updated_at = updated_at or datetime.now(timezone.utc)
        
        # Set expiration time (default 8 hours)
        if expires_at:
            self.expires_at = expires_at
        else:
            self.expires_at = datetime.now(timezone.utc) + timedelta(hours=8)
        
        # Additional security fields
        self.last_activity = datetime.now(timezone.utc)
        self.login_method = 'password'  # password, sso, api_key
        self.device_fingerprint = None
        self.location = None
        self.is_suspicious = False
        
        # Session metadata
        self.refresh_count = 0
        self.max_refresh_count = 10  # Maximum number of token refreshes
    
    def _generate_refresh_token(self):
        """Generate secure refresh token"""
        return secrets.token_urlsafe(32)
    
    def is_expired(self):
        """Check if session is expired"""
        return datetime.now(timezone.utc) > self.expires_at
    
    def is_valid(self):
        """Check if session is valid (active and not expired)"""
        return self.is_active and not self.is_expired()
    
    def extend_session(self, hours=8):
        """Extend session expiration time"""
        if self.is_valid():
            self.expires_at = datetime.now(timezone.utc) + timedelta(hours=hours)
            self.last_activity = datetime.now(timezone.utc)
            self.updated_at = datetime.now(timezone.utc)
            return True
        return False
    
    def refresh_tokens(self, new_session_token):
        """Refresh session tokens"""
        if self.refresh_count >= self.max_refresh_count:
            self.invalidate_session()
            return False
        
        self.session_token = new_session_token
        self.refresh_token = self._generate_refresh_token()
        self.refresh_count += 1
        self.last_activity = datetime.now(timezone.utc)
        self.updated_at = datetime.now(timezone.utc)
        
        # Extend expiration on refresh
        self.extend_session()
        return True
    
    def update_activity(self, ip_address=None, user_agent=None):
        """Update session activity"""
        self.last_activity = datetime.now(timezone.utc)
        self.updated_at = datetime.now(timezone.utc)
        
        if ip_address and ip_address != self.ip_address:
            # IP address changed - potential security concern
            self.is_suspicious = True
            
        if ip_address:
            self.ip_address = ip_address
        if user_agent:
            self.user_agent = user_agent
    
    def invalidate_session(self):
        """Invalidate session"""
        self.is_active = False
        self.session_token = None
        self.updated_at = datetime.now(timezone.utc)
    
    def mark_suspicious(self, reason=None):
        """Mark session as suspicious"""
        self.is_suspicious = True
        self.updated_at = datetime.now(timezone.utc)
        # In production, you might want to log the reason
    
    def get_session_duration(self):
        """Get session duration in minutes"""
        if self.last_activity and self.created_at:
            duration = self.last_activity - self.created_at
            return int(duration.total_seconds() / 60)
        return 0
    
    def get_time_until_expiry(self):
        """Get time until session expires in minutes"""
        if self.expires_at:
            time_left = self.expires_at - datetime.now(timezone.utc)
            if time_left.total_seconds() > 0:
                return int(time_left.total_seconds() / 60)
        return 0
    
    def to_dict(self, include_tokens=False):
        """Convert session to dictionary"""
        session_dict = {
            'session_id': self.session_id,
            'user_id': self.user_id,
            'ip_address': self.ip_address,
            'user_agent': self.user_agent,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'last_activity': self.last_activity.isoformat() if self.last_activity else None,
            'login_method': self.login_method,
            'device_fingerprint': self.device_fingerprint,
            'location': self.location,
            'is_suspicious': self.is_suspicious,
            'refresh_count': self.refresh_count,
            'session_duration_minutes': self.get_session_duration(),
            'time_until_expiry_minutes': self.get_time_until_expiry()
        }
        
        if include_tokens:
            session_dict.update({
                'session_token': self.session_token,
                'refresh_token': self.refresh_token
            })
        
        return session_dict
    
    @classmethod
    def from_dict(cls, data):
        """Create UserSession object from dictionary"""
        session = cls(
            user_id=data.get('user_id'),
            session_token=data.get('session_token'),
            refresh_token=data.get('refresh_token'),
            ip_address=data.get('ip_address'),
            user_agent=data.get('user_agent'),
            is_active=data.get('is_active', True),
            session_id=data.get('session_id'),
            created_at=datetime.fromisoformat(data['created_at'].replace('Z', '+00:00')) if data.get('created_at') else None,
            updated_at=datetime.fromisoformat(data['updated_at'].replace('Z', '+00:00')) if data.get('updated_at') else None,
            expires_at=datetime.fromisoformat(data['expires_at'].replace('Z', '+00:00')) if data.get('expires_at') else None
        )
        
        # Set additional fields
        if data.get('last_activity'):
            session.last_activity = datetime.fromisoformat(data['last_activity'].replace('Z', '+00:00'))
        
        session.login_method = data.get('login_method', 'password')
        session.device_fingerprint = data.get('device_fingerprint')
        session.location = data.get('location')
        session.is_suspicious = data.get('is_suspicious', False)
        session.refresh_count = data.get('refresh_count', 0)
        session.max_refresh_count = data.get('max_refresh_count', 10)
        
        return session
    
    @classmethod
    def cleanup_expired_sessions(cls, sessions_collection):
        """Clean up expired sessions from database"""
        # This would be implemented in the service layer
        # Here we just define the interface
        pass
    
    def __repr__(self):
        return f"<UserSession {self.session_id} for user {self.user_id}>"
