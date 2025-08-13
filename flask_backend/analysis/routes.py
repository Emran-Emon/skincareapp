from flask import Blueprint, request, jsonify, current_app
import os
import cv2
import mediapipe as mp
import pyheif
import tensorflow as tf
import torch
from PIL import Image
import numpy as np
from ultralytics import YOLO

# Flask Blueprint
analysis_bp = Blueprint('analysis', __name__)

UPLOAD_FOLDER = "uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

w_pos_values = np.array([4.0, 5.7, 9.0], dtype=np.float32)
w_neg_values = np.ones_like(w_pos_values, dtype=np.float32)

w_pos = tf.constant(w_pos_values, dtype=tf.float32)
w_neg = tf.constant(w_neg_values, dtype=tf.float32)

@tf.keras.utils.register_keras_serializable()
def weighted_bce(y_true, y_pred, smooth=0.05):
    # label smoothing to reduce overconfidence
    y_true = y_true * (1.0 - smooth) + 0.5 * smooth
    bce = tf.keras.backend.binary_crossentropy(y_true, y_pred)
    weights = y_true * w_pos + (1.0 - y_true) * w_neg
    return tf.reduce_mean(bce * weights)

# Load TensorFlow skin model with custom loss
skin_model = tf.keras.models.load_model(
    "skin_3label.keras",
    custom_objects={"weighted_bce": weighted_bce}
)
skin_labels = ['Acne', 'Pigmentation', 'Wrinkles']

# Load Ultralytics YOLOv8 model for dark circles detection
dark_model = YOLO("dark_circles.pt")
dark_model.eval()
dark_label = ['Dark circles']

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

def preprocess_for_tf(image_path):
    image = cv2.imread(image_path)
    image = cv2.resize(image, (224, 224))
    image = image / 255.0
    return np.expand_dims(image, axis=0)

def preprocess_for_torch(image_path):
    image = Image.open(image_path).convert("RGB")
    image = image.resize((224, 224))
    image = np.array(image).astype(np.float32) / 255.0
    image = np.transpose(image, (2, 0, 1))
    image = torch.tensor(image).unsqueeze(0)
    return image

@analysis_bp.route('/skin_type_recommendations', methods=['GET'])
def skin_type_recommendations():
    skin_type = request.args.get('type', '').strip()

    mongo = current_app.mongo
    raw_products = mongo.db.products.find({
        "Skin Concerns": {
            "$regex": f"^{skin_type}\\s*Skin$",  # matches "Dry Skin", "Oily Skin"
            "$options": "i"  # case-insensitive
        }
    })

    recommended_products = []
    for product in raw_products:
        recommended_products.append({
            "skin_concern": str(product.get("Skin Concerns", "")).strip(),
            "product": str(product.get("Product", "")).strip(),
            "type": str(product.get("Product Type", "")).strip(),
            "ingredients": str(product.get("Ingredients", "")).strip(),
            "reviews": str(product.get("Reviews", "")).strip(),
            "price": str(product.get("Price", "")).strip()
        })

    return jsonify({"recommended_products": recommended_products}), 200

@analysis_bp.route('/analyze_skin', methods=['POST'])
def analyze_skin():
    mongo = current_app.mongo
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
            "message": "No face detected",
            "analysis": {},
            "recommended_products": []
        }), 200

    threshold = 0.3

    # TensorFlow model prediction (Acne, Pigmentation, Wrinkles)
    tf_input = preprocess_for_tf(image_path)
    tf_preds = skin_model.predict(tf_input)[0]
    tf_results = {skin_labels[i]: bool(tf_preds[i] >= threshold) for i in range(len(skin_labels))}

    # Torch model prediction (Dark circles) using Ultralytics YOLO
    print(f"Running YOLO detection on {image_path} with conf threshold {threshold}...")
    detections = dark_model.predict(image_path, imgsz=640, conf=threshold, verbose=False)[0]

    print("Raw YOLO detection output:")
    print(detections)

    boxes = detections.boxes
    if boxes is not None and len(boxes) > 0:
        confidences = boxes.conf.cpu().numpy()
        classes = boxes.cls.cpu().numpy()
        print(f"Detected {len(boxes)} boxes:")
        for i, conf in enumerate(confidences):
            cls_id = int(classes[i])
            label = dark_label[cls_id] if cls_id < len(dark_label) else f"class_{cls_id}"
            print(f" - Box {i}: class={label}, confidence={conf:.3f}")
        detected = any(conf > threshold for conf in confidences)
    else:
        print("No boxes detected by YOLO.")
        detected = False

    torch_results = {"Dark Circles": detected}

    # Merge both results
    prediction_dict = {**tf_results, **torch_results}

    # Get all detected concerns where prediction is True
    detected_concerns = [k for k, v in prediction_dict.items() if v]

    if detected_concerns:
        or_filters = [{"Skin Concerns": {"$regex": f"^{concern}$", "$options": "i"}} for concern in detected_concerns]
        raw_products = list(mongo.db.products.find({"$or": or_filters}, {"_id": 0}).limit(100))
    else:
        raw_products = []

    recommended_products = []
    for product in raw_products:
        recommended_products.append({
            "skin_concern": str(product.get("Skin Concerns", "")).strip(),
            "product": str(product.get("Product", "")).strip(),
            "type": str(product.get("Product Type", "")).strip(),
            "ingredients": str(product.get("Ingredients", "")).strip(),
            "reviews": str(product.get("Reviews", "")).strip(),
            "price": str(product.get("Price", "")).strip()
    })

    return jsonify({
        "face_detected": True,
        "message": "Face detected successfully",
        "landmarks": landmarks,
        "analysis": prediction_dict,
        "recommended_products": recommended_products
    }), 200