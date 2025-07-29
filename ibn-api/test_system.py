#!/usr/bin/env python3
"""
Simple system test để kiểm tra lỗi
"""

import sys
import traceback

def test_imports():
    """Test all imports"""
    print("🔍 TESTING IMPORTS")
    print("=" * 25)
    
    try:
        print("📦 Testing basic imports...")
        import os
        import logging
        from datetime import datetime, timezone
        print("✅ Basic imports OK")
        
        print("🗄️ Testing database imports...")
        from pymongo import MongoClient
        print("✅ MongoDB import OK")
        
        print("🌐 Testing Flask imports...")
        from flask import Flask, request, jsonify
        print("✅ Flask imports OK")
        
        print("🔐 Testing JWT imports...")
        import jwt
        from werkzeug.security import generate_password_hash, check_password_hash
        print("✅ Security imports OK")
        
        print("📊 Testing app models...")
        from app.models.user import User
        from app.models.role import Role
        from app.models.permission import Permission
        from app.models.user_session import UserSession
        print("✅ Model imports OK")
        
        print("🔧 Testing app services...")
        from app.services.auth_service import AuthService
        from app.services.rbac_service import RBACService
        print("✅ Service imports OK")
        
        print("📡 Testing app routes...")
        from app.routes.auth import auth_bp
        from app.routes.users import users_bp
        from app.routes.roles import roles_bp
        print("✅ Route imports OK")
        
        print("🚀 Testing app creation...")
        from app import create_app
        app = create_app()
        print("✅ App creation OK")
        
        return True
        
    except Exception as e:
        print(f"❌ Import error: {e}")
        traceback.print_exc()
        return False

def test_database_connection():
    """Test database connection"""
    print("\n🗄️ TESTING DATABASE CONNECTION")
    print("=" * 35)
    
    try:
        from pymongo import MongoClient
        import os
        
        mongo_uri = os.getenv('MONGO_URI', 'mongodb://localhost:27017/')
        database_name = os.getenv('MONGO_DB', 'ibn_blockchain')
        
        print(f"📍 Connecting to: {mongo_uri}")
        print(f"🗂️ Database: {database_name}")
        
        client = MongoClient(mongo_uri)
        db = client[database_name]
        
        # Test connection
        server_info = client.server_info()
        print(f"✅ MongoDB connected successfully")
        print(f"   Version: {server_info.get('version', 'Unknown')}")
        
        # Test collections
        collections = db.list_collection_names()
        print(f"   Collections: {len(collections)}")
        
        # Test user collection
        user_count = db.users.count_documents({})
        print(f"   Users: {user_count}")
        
        client.close()
        return True
        
    except Exception as e:
        print(f"❌ Database error: {e}")
        traceback.print_exc()
        return False

def test_authentication():
    """Test authentication system"""
    print("\n🔐 TESTING AUTHENTICATION")
    print("=" * 30)
    
    try:
        from app.services.auth_service import AuthService
        
        auth_service = AuthService()
        print("✅ Auth service created")
        
        # Test admin login
        result, error = auth_service.authenticate_user(
            username='admin',
            password='admin123',
            ip_address='127.0.0.1',
            user_agent='Test Client'
        )
        
        if error:
            print(f"❌ Authentication failed: {error}")
            return False
        
        print("✅ Authentication successful")
        print(f"   User: {result['user']['username']}")
        print(f"   Token type: {result['tokens']['token_type']}")
        
        # Test token verification
        token = result['tokens']['access_token']
        payload = auth_service.verify_token(token)
        
        if payload:
            print("✅ Token verification successful")
            print(f"   User ID: {payload['user_id']}")
        else:
            print("❌ Token verification failed")
            return False
        
        auth_service.close_connection()
        return True
        
    except Exception as e:
        print(f"❌ Authentication error: {e}")
        traceback.print_exc()
        return False

def test_rbac():
    """Test RBAC system"""
    print("\n🛡️ TESTING RBAC SYSTEM")
    print("=" * 25)
    
    try:
        from app.services.rbac_service import RBACService
        
        rbac_service = RBACService()
        print("✅ RBAC service created")
        
        # Get admin user
        admin_user = rbac_service.db.users.find_one({'username': 'admin'})
        if not admin_user:
            print("❌ Admin user not found")
            return False
        
        admin_user_id = admin_user['user_id']
        print(f"✅ Admin user found: {admin_user_id}")
        
        # Test get user role
        role, error = rbac_service.get_user_role(admin_user_id)
        if error:
            print(f"❌ Get role error: {error}")
            return False
        
        print(f"✅ User role: {role.role_name}")
        
        # Test permissions
        permissions, error = rbac_service.get_user_permissions(admin_user_id)
        if error:
            print(f"❌ Get permissions error: {error}")
            return False
        
        print(f"✅ User permissions: {len(permissions)}")
        
        # Test permission check
        has_perm, error = rbac_service.check_permission(admin_user_id, 'user_management')
        if not has_perm:
            print(f"❌ Permission check failed: {error}")
            return False
        
        print("✅ Permission check successful")
        
        rbac_service.close_connection()
        return True
        
    except Exception as e:
        print(f"❌ RBAC error: {e}")
        traceback.print_exc()
        return False

def main():
    """Main test function"""
    print("🧪 SYSTEM ERROR CHECK")
    print("=" * 25)
    print("Kiểm tra toàn bộ hệ thống để tìm lỗi...")
    print()
    
    tests = [
        ("Imports", test_imports),
        ("Database", test_database_connection),
        ("Authentication", test_authentication),
        ("RBAC", test_rbac)
    ]
    
    results = []
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"❌ {test_name} test crashed: {e}")
            results.append((test_name, False))
    
    # Summary
    print("\n📊 TEST SUMMARY")
    print("=" * 20)
    
    passed = 0
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} {test_name}")
        if result:
            passed += 1
    
    print(f"\nResult: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! System is working correctly.")
        return 0
    else:
        print("⚠️ Some tests failed. Check errors above.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
