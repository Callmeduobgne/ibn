from datetime import datetime, timezone
import uuid

class Permission:
    """
    Permission model cho fine-grained access control
    Theo kiến trúc Giai đoạn 2 - Application Layer
    
    Permissions được nhóm theo modules:
    - User Management
    - Project Management  
    - Channel Management
    - Chaincode Management
    - System Management
    """
    
    def __init__(self, permission_name, display_name=None, description=None,
                 module=None, resource=None, action=None, is_system_permission=True,
                 permission_id=None, created_at=None, updated_at=None):
        """
        Initialize Permission object
        
        Args:
            permission_name (str): Unique permission name (e.g., 'user_management')
            display_name (str): Human-readable permission name
            description (str): Permission description
            module (str): Module this permission belongs to
            resource (str): Resource type (users, projects, channels, chaincodes)
            action (str): Action type (create, read, update, delete, manage)
            is_system_permission (bool): Whether this is a system-defined permission
            permission_id (str): Unique permission ID
            created_at (datetime): Creation timestamp
            updated_at (datetime): Last update timestamp
        """
        self.permission_id = permission_id or str(uuid.uuid4())
        self.permission_name = permission_name
        self.display_name = display_name or permission_name.replace('_', ' ').title()
        self.description = description
        self.module = module
        self.resource = resource
        self.action = action
        self.is_system_permission = is_system_permission
        self.created_at = created_at or datetime.now(timezone.utc)
        self.updated_at = updated_at or datetime.now(timezone.utc)
    
    def to_dict(self):
        """Convert permission to dictionary"""
        return {
            'permission_id': self.permission_id,
            'permission_name': self.permission_name,
            'display_name': self.display_name,
            'description': self.description,
            'module': self.module,
            'resource': self.resource,
            'action': self.action,
            'is_system_permission': self.is_system_permission,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }
    
    @classmethod
    def from_dict(cls, data):
        """Create Permission object from dictionary"""
        return cls(
            permission_name=data.get('permission_name'),
            display_name=data.get('display_name'),
            description=data.get('description'),
            module=data.get('module'),
            resource=data.get('resource'),
            action=data.get('action'),
            is_system_permission=data.get('is_system_permission', True),
            permission_id=data.get('permission_id'),
            created_at=datetime.fromisoformat(data['created_at'].replace('Z', '+00:00')) if data.get('created_at') else None,
            updated_at=datetime.fromisoformat(data['updated_at'].replace('Z', '+00:00')) if data.get('updated_at') else None
        )
    
    @classmethod
    def create_system_permissions(cls):
        """Create default system permissions"""
        permissions = []
        
        # User Management Permissions
        user_permissions = [
            ('user_management', 'User Management', 'Full user management access', 'users', 'users', 'manage'),
            ('view_users', 'View Users', 'View user information', 'users', 'users', 'read'),
            ('create_users', 'Create Users', 'Create new users', 'users', 'users', 'create'),
            ('update_users', 'Update Users', 'Update user information', 'users', 'users', 'update'),
            ('delete_users', 'Delete Users', 'Delete users', 'users', 'users', 'delete'),
            ('assign_roles', 'Assign Roles', 'Assign roles to users', 'users', 'users', 'manage'),
        ]
        
        # Role Management Permissions
        role_permissions = [
            ('role_management', 'Role Management', 'Full role management access', 'users', 'roles', 'manage'),
            ('view_roles', 'View Roles', 'View role information', 'users', 'roles', 'read'),
            ('create_roles', 'Create Roles', 'Create new roles', 'users', 'roles', 'create'),
            ('update_roles', 'Update Roles', 'Update role information', 'users', 'roles', 'update'),
            ('delete_roles', 'Delete Roles', 'Delete roles', 'users', 'roles', 'delete'),
        ]
        
        # Project Management Permissions
        project_permissions = [
            ('view_all_projects', 'View All Projects', 'View all projects in system', 'projects', 'projects', 'read'),
            ('manage_all_projects', 'Manage All Projects', 'Full access to all projects', 'projects', 'projects', 'manage'),
            ('view_projects', 'View Projects', 'View assigned projects', 'projects', 'projects', 'read'),
            ('create_projects', 'Create Projects', 'Create new projects', 'projects', 'projects', 'create'),
            ('manage_projects', 'Manage Projects', 'Manage assigned projects', 'projects', 'projects', 'manage'),
            ('delete_projects', 'Delete Projects', 'Delete projects', 'projects', 'projects', 'delete'),
            ('view_team_members', 'View Team Members', 'View project team members', 'projects', 'teams', 'read'),
            ('manage_team_members', 'Manage Team Members', 'Manage project team members', 'projects', 'teams', 'manage'),
        ]
        
        # Channel Management Permissions
        channel_permissions = [
            ('view_all_channels', 'View All Channels', 'View all channels in system', 'channels', 'channels', 'read'),
            ('manage_all_channels', 'Manage All Channels', 'Full access to all channels', 'channels', 'channels', 'manage'),
            ('view_channels', 'View Channels', 'View assigned channels', 'channels', 'channels', 'read'),
            ('create_channels', 'Create Channels', 'Create new channels', 'channels', 'channels', 'create'),
            ('manage_channels', 'Manage Channels', 'Manage assigned channels', 'channels', 'channels', 'manage'),
            ('delete_channels', 'Delete Channels', 'Delete channels', 'channels', 'channels', 'delete'),
        ]
        
        # Chaincode Management Permissions
        chaincode_permissions = [
            ('view_all_chaincodes', 'View All Chaincodes', 'View all chaincodes in system', 'chaincodes', 'chaincodes', 'read'),
            ('manage_all_chaincodes', 'Manage All Chaincodes', 'Full access to all chaincodes', 'chaincodes', 'chaincodes', 'manage'),
            ('view_chaincodes', 'View Chaincodes', 'View assigned chaincodes', 'chaincodes', 'chaincodes', 'read'),
            ('create_chaincodes', 'Create Chaincodes', 'Create new chaincodes', 'chaincodes', 'chaincodes', 'create'),
            ('deploy_chaincodes', 'Deploy Chaincodes', 'Deploy chaincodes to channels', 'chaincodes', 'chaincodes', 'deploy'),
            ('approve_chaincodes', 'Approve Chaincodes', 'Approve chaincode deployments', 'chaincodes', 'chaincodes', 'approve'),
            ('invoke_chaincodes', 'Invoke Chaincodes', 'Invoke chaincode functions', 'chaincodes', 'chaincodes', 'invoke'),
            ('query_chaincodes', 'Query Chaincodes', 'Query chaincode data', 'chaincodes', 'chaincodes', 'query'),
            ('upgrade_chaincodes', 'Upgrade Chaincodes', 'Upgrade chaincode versions', 'chaincodes', 'chaincodes', 'upgrade'),
        ]
        
        # System Management Permissions
        system_permissions = [
            ('system_configuration', 'System Configuration', 'Configure system settings', 'system', 'system', 'manage'),
            ('view_system_logs', 'View System Logs', 'View system logs', 'system', 'logs', 'read'),
            ('manage_system_logs', 'Manage System Logs', 'Manage system logs', 'system', 'logs', 'manage'),
            ('view_all_logs', 'View All Logs', 'View all activity logs', 'system', 'logs', 'read'),
            ('view_project_logs', 'View Project Logs', 'View project-specific logs', 'projects', 'logs', 'read'),
            ('view_development_logs', 'View Development Logs', 'View development logs', 'chaincodes', 'logs', 'read'),
            ('view_test_logs', 'View Test Logs', 'View test logs', 'testing', 'logs', 'read'),
            ('create_test_data', 'Create Test Data', 'Create test data and scenarios', 'testing', 'data', 'create'),
        ]
        
        # Combine all permissions
        all_permissions = (user_permissions + role_permissions + project_permissions + 
                          channel_permissions + chaincode_permissions + system_permissions)
        
        # Create Permission objects
        for perm_name, display_name, description, module, resource, action in all_permissions:
            permission = cls(
                permission_name=perm_name,
                display_name=display_name,
                description=description,
                module=module,
                resource=resource,
                action=action,
                is_system_permission=True
            )
            permissions.append(permission)
        
        return permissions
    
    def __repr__(self):
        return f"<Permission {self.permission_name} ({self.module}.{self.resource}.{self.action})>"
