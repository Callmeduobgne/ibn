from datetime import datetime, timezone
import uuid

class Role:
    """
    Role model cho role-based access control system
    Theo kiến trúc Giai đoạn 2 - Application Layer
    
    Roles theo kiến trúc:
    - admin: Quản lý hệ thống và người dùng
    - developer: Phát triển và deploy chaincode
    - tester: Test chaincode và applications
    - leader: Quản lý projects và teams
    """
    
    # Predefined roles theo kiến trúc
    ADMIN = 'admin'
    DEVELOPER = 'developer'
    TESTER = 'tester'
    LEADER = 'leader'
    
    VALID_ROLES = [ADMIN, DEVELOPER, TESTER, LEADER]
    
    def __init__(self, role_name, display_name=None, description=None, 
                 permissions=None, is_system_role=False, is_active=True,
                 role_id=None, created_by=None, created_at=None, updated_at=None):
        """
        Initialize Role object
        
        Args:
            role_name (str): Unique role name (admin, developer, tester, leader)
            display_name (str): Human-readable role name
            description (str): Role description
            permissions (list): List of permission IDs
            is_system_role (bool): Whether this is a system-defined role
            is_active (bool): Whether role is active
            role_id (str): Unique role ID
            created_by (str): User ID who created this role
            created_at (datetime): Creation timestamp
            updated_at (datetime): Last update timestamp
        """
        self.role_id = role_id or str(uuid.uuid4())
        self.role_name = role_name
        self.display_name = display_name or role_name.title()
        self.description = description
        self.permissions = permissions or []
        self.is_system_role = is_system_role
        self.is_active = is_active
        self.created_by = created_by
        self.created_at = created_at or datetime.now(timezone.utc)
        self.updated_at = updated_at or datetime.now(timezone.utc)
        
        # Additional metadata
        self.user_count = 0  # Number of users with this role
        self.priority = self._get_role_priority()
    
    def _get_role_priority(self):
        """Get role priority for hierarchy"""
        priority_map = {
            self.ADMIN: 1,      # Highest priority
            self.LEADER: 2,
            self.DEVELOPER: 3,
            self.TESTER: 4      # Lowest priority
        }
        return priority_map.get(self.role_name, 99)
    
    def add_permission(self, permission_id):
        """Add permission to role"""
        if permission_id not in self.permissions:
            self.permissions.append(permission_id)
            self.updated_at = datetime.now(timezone.utc)
    
    def remove_permission(self, permission_id):
        """Remove permission from role"""
        if permission_id in self.permissions:
            self.permissions.remove(permission_id)
            self.updated_at = datetime.now(timezone.utc)
    
    def has_permission(self, permission_id):
        """Check if role has specific permission"""
        return permission_id in self.permissions
    
    def can_manage_role(self, other_role):
        """Check if this role can manage another role"""
        if not isinstance(other_role, Role):
            return False
        
        # Admin can manage all roles
        if self.role_name == self.ADMIN:
            return True
        
        # Leader can manage developer and tester
        if self.role_name == self.LEADER:
            return other_role.role_name in [self.DEVELOPER, self.TESTER]
        
        # Others cannot manage roles
        return False
    
    def get_default_permissions(self):
        """Get default permissions for role"""
        default_permissions = {
            self.ADMIN: [
                'user_management',
                'role_management',
                'system_configuration',
                'view_all_projects',
                'manage_all_projects',
                'view_all_channels',
                'manage_all_channels',
                'view_all_chaincodes',
                'manage_all_chaincodes',
                'view_system_logs',
                'manage_system_logs'
            ],
            self.LEADER: [
                'view_projects',
                'manage_projects',
                'view_team_members',
                'manage_team_members',
                'view_channels',
                'manage_channels',
                'view_chaincodes',
                'approve_chaincodes',
                'view_project_logs'
            ],
            self.DEVELOPER: [
                'view_projects',
                'create_projects',
                'view_chaincodes',
                'create_chaincodes',
                'deploy_chaincodes',
                'invoke_chaincodes',
                'query_chaincodes',
                'view_development_logs'
            ],
            self.TESTER: [
                'view_projects',
                'view_chaincodes',
                'invoke_chaincodes',
                'query_chaincodes',
                'create_test_data',
                'view_test_logs'
            ]
        }
        return default_permissions.get(self.role_name, [])
    
    def to_dict(self, include_metadata=False):
        """Convert role to dictionary"""
        role_dict = {
            'role_id': self.role_id,
            'role_name': self.role_name,
            'display_name': self.display_name,
            'description': self.description,
            'permissions': self.permissions,
            'is_system_role': self.is_system_role,
            'is_active': self.is_active,
            'created_by': self.created_by,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
            'priority': self.priority
        }
        
        if include_metadata:
            role_dict['user_count'] = self.user_count
        
        return role_dict
    
    @classmethod
    def from_dict(cls, data):
        """Create Role object from dictionary"""
        role = cls(
            role_name=data.get('role_name'),
            display_name=data.get('display_name'),
            description=data.get('description'),
            permissions=data.get('permissions', []),
            is_system_role=data.get('is_system_role', False),
            is_active=data.get('is_active', True),
            role_id=data.get('role_id'),
            created_by=data.get('created_by'),
            created_at=datetime.fromisoformat(data['created_at'].replace('Z', '+00:00')) if data.get('created_at') else None,
            updated_at=datetime.fromisoformat(data['updated_at'].replace('Z', '+00:00')) if data.get('updated_at') else None
        )
        
        role.user_count = data.get('user_count', 0)
        return role
    
    @classmethod
    def create_system_roles(cls):
        """Create default system roles"""
        system_roles = []
        
        # Admin role
        admin_role = cls(
            role_name=cls.ADMIN,
            display_name='System Administrator',
            description='Full system access and user management',
            is_system_role=True
        )
        admin_role.permissions = admin_role.get_default_permissions()
        system_roles.append(admin_role)
        
        # Leader role
        leader_role = cls(
            role_name=cls.LEADER,
            display_name='Project Leader',
            description='Manage projects, teams, and approve deployments',
            is_system_role=True
        )
        leader_role.permissions = leader_role.get_default_permissions()
        system_roles.append(leader_role)
        
        # Developer role
        developer_role = cls(
            role_name=cls.DEVELOPER,
            display_name='Developer',
            description='Develop and deploy chaincode applications',
            is_system_role=True
        )
        developer_role.permissions = developer_role.get_default_permissions()
        system_roles.append(developer_role)
        
        # Tester role
        tester_role = cls(
            role_name=cls.TESTER,
            display_name='Tester',
            description='Test chaincode and create test scenarios',
            is_system_role=True
        )
        tester_role.permissions = tester_role.get_default_permissions()
        system_roles.append(tester_role)
        
        return system_roles
    
    def __repr__(self):
        return f"<Role {self.role_name} ({self.display_name})>"
