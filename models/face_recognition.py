import face_recognition
import cv2

def detect_faces(image_path):
    image = face_recognition.load_image_file(image_path)
    face_locations = face_recognition.face_locations(image)
    print(f"Found {len(face_locations)} face(s) in this image.")
    return face_locations
