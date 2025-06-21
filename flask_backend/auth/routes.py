from flask import Blueprint, request, jsonify, current_app
from werkzeug.security import generate_password_hash, check_password_hash
import jwt
import datetime
import smtplib
from email.mime.text import MIMEText
from bson.objectid import ObjectId
from flask_pymongo import PyMongo

auth_bp = Blueprint('auth', __name__)
mongo = PyMongo()

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    if not username or not email or not password:
        return jsonify({'error': 'All fields are required'}), 400

    mongo = current_app.mongo
    if mongo.db.users.find_one({'email': email}):
        return jsonify({'error': 'Email already exists'}), 400

    hashed_password = generate_password_hash(password, method='pbkdf2:sha256', salt_length=16)
    mongo.db.users.insert_one({
        'username': username,
        'email': email,
        'password': hashed_password
    })
    return jsonify({'message': 'User registered successfully'}), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    email = data.get('email')
    password = data.get('password')
    mongo = current_app.mongo
    user = mongo.db.users.find_one({'email': email})

    if not user or not check_password_hash(user['password'], password):
        return jsonify({'error': 'Invalid credentials'}), 400

    token = jwt.encode({
        'id': str(user['_id']),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    }, current_app.config['SECRET_KEY'], algorithm='HS256')

    return jsonify({'message': 'Login successful', 'token': token})

@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.json
    email = data.get('email')
    mongo = current_app.mongo
    user = mongo.db.users.find_one({'email': email})

    if not user:
        return jsonify({'error': 'User not found'}), 404

    reset_token = jwt.encode({
        'id': str(user['_id']),
        'exp': datetime.datetime.utcnow() + datetime.timedelta(minutes=15)
    }, current_app.config['SECRET_KEY'], algorithm='HS256')

    smtp_server = "smtp.gmail.com"
    smtp_port = 587
    sender_email = "urpersonalizedskincareadvisor@gmail.com"
    sender_password = "flpm tkaz zmtw dbpl"

    message = MIMEText(f"Reset your password: http://localhost:3000/reset-password/{reset_token}")
    message['Subject'] = 'Password Reset Request'
    message['From'] = sender_email
    message['To'] = email

    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(message)
        return jsonify({'message': 'Password reset email sent'}), 200
    except Exception as e:
        return jsonify({'error': 'Failed to send email', 'details': str(e)}), 500

@auth_bp.route('/profile', methods=['GET'])
def get_profile():
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'error': 'Token missing'}), 401

    try:
        token = token.split(" ")[1]
        decoded = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])

        mongo = current_app.mongo
        user = mongo.db.users.find_one({"_id": ObjectId(decoded['id'])})

        if not user:
            return jsonify({'error': 'User not found'}), 404

        return jsonify({
            "username": user.get('username'),
            "email": user.get('email'),
            "role": user.get('role', 'user')
        }), 200

    except Exception as e:
        print("Profile error:", str(e))
        return jsonify({'error': 'Invalid token or internal error'}), 400
    
@auth_bp.route('/update-profile', methods=['PATCH'])
def update_profile():
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'error': 'Token missing'}), 401

    try:
        decoded = jwt.decode(token.split(' ')[1], current_app.config['SECRET_KEY'], algorithms=['HS256'])
        data = request.json
        mongo = current_app.mongo
        updated_fields = {
            'username': data.get('username'),
            'email': data.get('email'),
            'password': generate_password_hash(data.get('password'), method='pbkdf2:sha256', salt_length=16)
        }
        mongo.db.users.update_one({'_id': mongo.db.users.find_one({'_id': decoded['id']})['_id']}, {'$set': updated_fields})
        return jsonify({'message': 'Profile updated successfully'})
    except Exception as e:
        return jsonify({'error': 'Invalid token or update failed'}), 400

@auth_bp.route('/logout', methods=['POST'])
def logout():
    return jsonify({'message': 'Logged out successfully'})
