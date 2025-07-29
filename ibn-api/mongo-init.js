// MongoDB initialization script for IBN Blockchain Database

// Switch to ibn_blockchain database
db = db.getSiblingDB('ibn_blockchain');

// Create collections
db.createCollection('assets');
db.createCollection('transactions');
db.createCollection('network_status');
db.createCollection('users');

// Create indexes for performance
db.assets.createIndex({ "asset_id": 1 }, { unique: true });
db.assets.createIndex({ "owner": 1 });
db.assets.createIndex({ "created_at": 1 });
db.assets.createIndex({ "status": 1 });

db.transactions.createIndex({ "tx_id": 1 }, { unique: true });
db.transactions.createIndex({ "timestamp": 1 });
db.transactions.createIndex({ "function_name": 1 });
db.transactions.createIndex({ "status": 1 });

db.network_status.createIndex({ "timestamp": 1 });

// Insert sample data
db.assets.insertMany([
    {
        "asset_id": "sample1",
        "color": "blue",
        "size": 5,
        "owner": "SampleUser",
        "appraised_value": 300,
        "blockchain_tx_id": null,
        "status": "sample",
        "created_at": new Date(),
        "updated_at": new Date()
    }
]);

db.transactions.insertMany([
    {
        "tx_id": "init_tx_001",
        "function_name": "InitDatabase",
        "args": {},
        "result": "Database initialized successfully",
        "timestamp": new Date(),
        "status": "success",
        "block_number": 0
    }
]);

print("✅ IBN Blockchain database initialized successfully!");
print("📊 Collections created: assets, transactions, network_status, users");
print("🔍 Indexes created for performance optimization");
print("📝 Sample data inserted for testing");
