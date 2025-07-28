from flask import Flask, render_template
from flask_pymongo import PyMongo
from flask_cors import CORS
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize extensions
mongo = PyMongo()

def create_app():
    """Application factory pattern"""
    # Get the directory where this file is located
    template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'templates'))
    static_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'static'))

    app = Flask(__name__,
                template_folder=template_dir,
                static_folder=static_dir)
    
    # Configuration
    app.config['MONGO_URI'] = os.getenv('MONGODB_URI', 'mongodb://admin:password123@localhost:27017/ibn_blockchain?authSource=admin')
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'ibn-blockchain-secret-key-2024')
    app.config['DEBUG'] = os.getenv('FLASK_ENV') == 'development'
    
    # Initialize extensions
    mongo.init_app(app)
    CORS(app)
    
    # Register blueprints
    from app.routes.assets import assets_bp
    from app.routes.transactions import transactions_bp
    from app.routes.network import network_bp
    from app.routes.dashboard import dashboard_bp
    from app.routes.auth import auth_bp
    from app.routes.users import users_bp
    from app.routes.roles import roles_bp

    app.register_blueprint(assets_bp, url_prefix='/api/assets')
    app.register_blueprint(transactions_bp, url_prefix='/api/transactions')
    app.register_blueprint(network_bp, url_prefix='/api/network')
    app.register_blueprint(dashboard_bp, url_prefix='/')
    app.register_blueprint(auth_bp)  # Auth routes include /api/auth prefix
    app.register_blueprint(users_bp)  # User routes include /api/users prefix
    app.register_blueprint(roles_bp)  # Role routes include /api/roles prefix
    
    # Health check endpoint
    @app.route('/health')
    def health_check():
        return {
            'status': 'healthy',
            'service': 'IBN Blockchain API',
            'version': '1.0.0'
        }

    # Web interface route
    @app.route('/web')
    def web_interface():
        return render_template('index.html')

    # Favicon route to prevent 404 errors
    @app.route('/favicon.ico')
    def favicon():
        return '', 204

    return app
