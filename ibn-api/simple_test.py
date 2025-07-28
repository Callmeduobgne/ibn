#!/usr/bin/env python3

print("🔍 SIMPLE SYSTEM TEST")
print("=" * 25)

try:
    print("Testing basic Python...")
    import sys
    print(f"✅ Python version: {sys.version}")
    
    print("Testing Flask...")
    import flask
    print(f"✅ Flask version: {flask.__version__}")
    
    print("Testing PyJWT...")
    import jwt
    print("✅ PyJWT imported successfully")
    
    print("Testing pymongo...")
    import pymongo
    print(f"✅ PyMongo version: {pymongo.version}")
    
    print("Testing app import...")
    from app import create_app
    print("✅ App import successful")
    
    print("Creating Flask app...")
    app = create_app()
    print("✅ Flask app created successfully")
    
    print("\n🎉 ALL TESTS PASSED!")
    
except Exception as e:
    print(f"❌ ERROR: {e}")
    import traceback
    traceback.print_exc()
