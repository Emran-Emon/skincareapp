from flask import Flask, request, jsonify
import os
from flask_cors import CORS
from face_mesh import detect_face_landmarks

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

@app.route('/analyze_skin', methods=['POST'])
def analyze_skin():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files['file']
    file_path = os.path.join(UPLOAD_FOLDER, "captured_image.jpg")
    file.save(file_path)

    # Call face detection function from face_mesh.py
    detected_landmarks, processed_image_path = detect_face_landmarks(file_path)

    if detected_landmarks is None:
        return jsonify({"message": "No face detected"}), 200

    return jsonify({"message": "Face detected", "landmarks": detected_landmarks})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)