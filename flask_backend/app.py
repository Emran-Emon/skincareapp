from flask import Flask
from flask_cors import CORS
from flask_pymongo import PyMongo
import os
from analysis.routes import analysis_bp

# Initialize Flask app
app = Flask(__name__)
CORS(app)

# Load configuration
app.config.from_object('config.Config')

# Initialize MongoDB
mongo = PyMongo(app)

# Create upload folder if it doesn't exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Store mongo in app context for blueprint access
app.mongo = mongo

# Register blueprints
from auth.routes import auth_bp
from analysis.routes import analysis_bp

app.register_blueprint(auth_bp, url_prefix='/auth')
app.register_blueprint(analysis_bp, url_prefix='/analysis')

# Run the app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)
