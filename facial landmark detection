import cv2
import mediapipe as mp

# Initialize Mediapipe Face Mesh
mp_face_mesh = mp.solutions.face_mesh
face_mesh = mp_face_mesh.FaceMesh(min_detection_confidence=0.5, min_tracking_confidence=0.5)

# Initialize Mediapipe Drawing Utils
mp_drawing = mp.solutions.drawing_utils
mp_drawing_styles = mp.solutions.drawing_styles

# Open Webcam
cap = cv2.VideoCapture(0)

# Define important landmark indexes
RIGHT_EYE = [33, 133]
LEFT_EYE = [263, 362]
NOSE_TIP = [1]
MOUTH = [61, 146, 291, 375]

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break
    
    # Convert BGR to RGB (Required for Mediapipe)
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    
    # Process frame with Face Mesh
    results = face_mesh.process(rgb_frame)

    if results.multi_face_landmarks:
        for face_landmarks in results.multi_face_landmarks:
            # Highlight Specific Facial Features
            for idx in RIGHT_EYE:
                point = face_landmarks.landmark[idx]
                x, y = int(point.x * frame.shape[1]), int(point.y * frame.shape[0])
                cv2.circle(frame, (x, y), 3, (0, 255, 0), -1)  # Green for Right Eye

            for idx in LEFT_EYE:
                point = face_landmarks.landmark[idx]
                x, y = int(point.x * frame.shape[1]), int(point.y * frame.shape[0])
                cv2.circle(frame, (x, y), 3, (255, 0, 0), -1)  # Blue for Left Eye

            for idx in NOSE_TIP:
                point = face_landmarks.landmark[idx]
                x, y = int(point.x * frame.shape[1]), int(point.y * frame.shape[0])
                cv2.circle(frame, (x, y), 3, (0, 0, 255), -1)  # Red for Nose Tip

            for idx in MOUTH:
                point = face_landmarks.landmark[idx]
                x, y = int(point.x * frame.shape[1]), int(point.y * frame.shape[0])
                cv2.circle(frame, (x, y), 3, (255, 255, 0), -1)  # Yellow for Mouth

            # Draw full face mesh
            mp_drawing.draw_landmarks(
                image=frame,
                landmark_list=face_landmarks,
                connections=mp_face_mesh.FACEMESH_TESSELATION,
                landmark_drawing_spec=None,
                connection_drawing_spec=mp_drawing_styles.get_default_face_mesh_tesselation_style()
            )
    
    # Show the frame
    cv2.imshow("Face Landmarks with Highlighted Features", frame)
    
    # Press 'q' to exit
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
