import os
import glob
from ultralytics import YOLO

# ==========================
# 🔹 Step 1: Find the Most Recent Trained Model
# ==========================
def get_latest_model():
    """Finds the latest trained YOLO model in 'runs/detect/trainX/weights/'."""
    model_paths = glob.glob("runs/detect/train*/weights/best.pt")  # Looking for retrainable .pt files
    if model_paths:
        return sorted(model_paths, key=os.path.getmtime, reverse=True)[0]  # Get the latest model
    return None  # Return None if no models found

MODEL_SAVE_PATH = get_latest_model()

if MODEL_SAVE_PATH:
    print(f"✅ Found existing trained model: {MODEL_SAVE_PATH}")
    while True:
        user_choice = input("Do you want to continue training it (improve) or retrain from scratch? (improve/retrain): ").strip().lower()
        if user_choice in ["improve", "retrain"]:
            break
        print("❌ Invalid input. Please type 'improve' or 'retrain'.")

    if user_choice == "improve":
        print("🔄 Continuing training on the existing model...")
        model = YOLO(MODEL_SAVE_PATH)
    else:
        print("🛑 Deleting old model and starting fresh...")
        os.remove(MODEL_SAVE_PATH)
        model = YOLO("yolov8m.pt")  # Start from scratch
else:
    print("🚀 No previous model found. Training from YOLOv8m base model.")
    model = YOLO("yolov8m.pt")

# ==========================
# 🔹 Step 2: Train YOLO Model (Only Once Per Run)
# ==========================
if __name__ == "__main__":
    print("🚀 Starting YOLOv8 Training on ACNE YOLO dataset...")

    model.train(
        data="Z:/datasets/MAIN DATASET/ACNE YOLO/data.yaml",
        epochs=2,  # ⬇ Set to 2 epochs for quick testing
        imgsz=640,
        batch=4,
        workers=2,
        device="cuda",
        resume=False,
        augment=True,
        amp=True
    )

    print("✅ Training Completed. Saving Model...")

    # ==========================
    # 🔹 Step 3: Automatically Save the Model
    # ==========================
    save_path = "runs/detect/latest_model/best.pt"
    os.makedirs(os.path.dirname(save_path), exist_ok=True)

    try:
        model.save(save_path)  # Save the model in retrainable format
        print(f"🎉 Model saved successfully at {save_path}")

    except Exception as e:
        print(f"❌ Model saving failed: {e}")

    # ==========================
    # 🔹 Step 4: Show Training Metrics (Simplified)
    # ==========================
    try:
        print("\n📊 Evaluating Model Performance...")
        metrics = model.val()  # Validate the model to get metrics

        print("\n📊 Training Results (Simplified):")
        print(f"✅ Model Accuracy: {metrics.box.map50:.2%}")  # mAP@50 as Accuracy %
        print(f"🎯 Precision (Correct Detections): {metrics.box.map50:.2%}")  # Precision %
        print(f"🔄 Recall (Missed Detections): {metrics.box.map:.2%}")  # Recall %
        print(f"⭐ Overall Accuracy (Strict Evaluation): {metrics.box.map:.2%}")  # mAP@50-95

    except Exception as e:
        print(f"⚠️ Could not retrieve training metrics: {e}")

    print("✅ Model training and saving completed successfully!")
