from flask import Blueprint, request, jsonify
import os
import cv2
import mediapipe as mp
import pyheif
from PIL import Image

analysis_bp = Blueprint('analysis', __name__)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Mediapipe setup
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(min_detection_confidence=0.5, min_tracking_confidence=0.5)
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles

# Landmark indices
RIGHT_EYE = [33, 133]
LEFT_EYE = [263, 362]
NOSE_TIP = [1]
MOUTH = [61, 146, 291, 375]


def convert_heic_to_jpg(src_path, dest_path):
    try:
        heif_file = pyheif.read(src_path)
        image = Image.frombytes(
            heif_file.mode, heif_file.size, heif_file.data,
            "raw", heif_file.mode, heif_file.stride
        )
        image.save(dest_path, format="JPEG")
        return dest_path
    except Exception as e:
        print("HEIC conversion error:", str(e))
        return None

def detect_face_landmarks(image_path):
    image = cv2.imread(image_path)
    rgb_frame = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    results = face_mesh.process(rgb_frame)
    if not results.multi_face_landmarks:
        return None, None, "No face detected"

    detected_landmarks = {
        "right_eye": [],
        "left_eye": [],
        "nose": [],
        "mouth": []
    }

    for face_landmarks in results.multi_face_landmarks:
        for idx in RIGHT_EYE:
            point = face_landmarks.landmark[idx]
            x, y = int(point.x * image.shape[1]), int(point.y * image.shape[0])
            detected_landmarks["right_eye"].append({"x": point.x, "y": point.y})
            cv2.circle(image, (x, y), 3, (0, 255, 0), -1)

        for idx in LEFT_EYE:
            point = face_landmarks.landmark[idx]
            x, y = int(point.x * image.shape[1]), int(point.y * image.shape[0])
            detected_landmarks["left_eye"].append({"x": point.x, "y": point.y})
            cv2.circle(image, (x, y), 3, (255, 0, 0), -1)

        for idx in NOSE_TIP:
            point = face_landmarks.landmark[idx]
            x, y = int(point.x * image.shape[1]), int(point.y * image.shape[0])
            detected_landmarks["nose"].append({"x": point.x, "y": point.y})
            cv2.circle(image, (x, y), 3, (0, 0, 255), -1)

        for idx in MOUTH:
            point = face_landmarks.landmark[idx]
            x, y = int(point.x * image.shape[1]), int(point.y * image.shape[0])
            detected_landmarks["mouth"].append({"x": point.x, "y": point.y})
            cv2.circle(image, (x, y), 3, (255, 255, 0), -1)

        mp_drawing.draw_landmarks(
            image=image,
            landmark_list=face_landmarks,
            connections=mp_face_mesh.FACEMESH_TESSELATION,
            landmark_drawing_spec=None,
            connection_drawing_spec=mp_drawing_styles.get_default_face_mesh_tesselation_style()
        )

    processed_path = image_path.replace(".jpg", "_processed.jpg")
    cv2.imwrite(processed_path, image)
    return True, detected_landmarks, processed_path

@analysis_bp.route('/analyze_skin', methods=['POST'])
def analyze_skin():
    if 'file' not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    file = request.files['file']
    file_path = os.path.join(UPLOAD_FOLDER, file.filename)
    file.save(file_path)

    ext = os.path.splitext(file_path)[1].lower()

    if ext == ".heic":
        converted_path = os.path.join(UPLOAD_FOLDER, "converted.jpg")
        result_path = convert_heic_to_jpg(file_path, converted_path)
        if result_path is None:
            return jsonify({"error": "HEIC conversion failed"}), 500
        image_path = result_path
    else:
        image_path = os.path.join(UPLOAD_FOLDER, "captured_image.jpg")
        os.rename(file_path, image_path)

    face_detected, landmarks, _ = detect_face_landmarks(image_path)

    if not face_detected:
        return jsonify({
            "face_detected": False,
            "message": "No face detected"
        }), 200

    return jsonify({
        "face_detected": True,
        "message": "Face detected successfully",
        "landmarks": landmarks
    }), 200