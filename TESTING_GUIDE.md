# Complete Integration Testing Guide

## 🧪 Backend Service Verification

### 1. InsightFace Service Test
```python
# Test file: test_insightface.py
from services.insightface_service import insightface_service
import cv2

# Test with a sample image
img_path = "test_image.jpg"

# Test 1: Face detection
faces = insightface_service.get_faces(img_path)
print(f"✓ Faces detected: {len(faces)}")
assert len(faces) > 0, "No faces detected"

# Test 2: Extract aligned face
aligned_face, metadata = insightface_service.extract_aligned_face(img_path)
print(f"✓ Aligned face extracted, shape: {aligned_face.shape}")
print(f"✓ Metadata: {metadata.keys()}")
assert aligned_face is not None, "Failed to extract aligned face"
assert 'kps' in metadata, "Missing kps in metadata"
assert 'age' in metadata, "Missing age in metadata"
assert 'gender' in metadata, "Missing gender in metadata"

# Test 3: Get embedding
embedding = insightface_service.get_embedding(img_path)
print(f"✓ Embedding shape: {len(embedding)}")
assert len(embedding) == 512, "Embedding should be 512-d"
```

**Run**:
```bash
cd /home/umerjlm/Desktop/FSZ/face_detection_model
python test_insightface.py
```

---

### 2. Landmark Service Test
```python
# Test file: test_landmarks.py
from services.landmark_service import landmark_service
import numpy as np

img_path = "test_image.jpg"

# Extract landmarks
landmarks = landmark_service.get_landmarks(img_path)
print(f"✓ Landmarks shape: {landmarks.shape}")
assert landmarks.shape == (5, 2), f"Expected (5, 2), got {landmarks.shape}"

# Get key features
features = landmark_service.get_key_features(landmarks)
print(f"✓ Features extracted: {features.keys()}")
assert 'left_eye' in features, "Missing left_eye"
assert 'right_eye' in features, "Missing right_eye"
assert 'nose_tip' in features, "Missing nose_tip"
```

**Run**:
```bash
python test_landmarks.py
```

---

### 3. Symmetry Service Test
```python
# Test file: test_symmetry.py
from services.landmark_service import landmark_service
from services.symmetry_service import symmetry_service
import numpy as np

img_path = "test_image.jpg"

# Get landmarks
landmarks = landmark_service.get_landmarks(img_path)

# Calculate symmetry
symmetry = symmetry_service.calculate_symmetry(landmarks)
print(f"✓ Overall symmetry: {symmetry['overall_score']:.2f}")
print(f"✓ Eye symmetry: {symmetry['eye_symmetry']:.2f}")
print(f"✓ Nose alignment: {symmetry['nose_alignment']:.2f}")
print(f"✓ Mouth alignment: {symmetry['mouth_alignment']:.2f}")

# Verify scores are between 0 and 1
for key, value in symmetry.items():
    assert 0 <= value <= 1, f"{key} out of range: {value}"
```

**Run**:
```bash
python test_symmetry.py
```

---

### 4. Feature Scoring Service Test
```python
# Test file: test_features.py
from services.landmark_service import landmark_service
from services.feature_scoring_service import feature_scoring_service

img_path = "test_image.jpg"

# Get landmarks
landmarks = landmark_service.get_landmarks(img_path)

# Calculate features
features = feature_scoring_service.calculate_scores(landmarks)
print(f"✓ Eyes score: {features['eyes']:.2f}")
print(f"✓ Nose score: {features['nose']:.2f}")
print(f"✓ Jawline score: {features['jawline']:.2f}")
print(f"✓ Face ratio score: {features['face_ratio']:.2f}")

# Verify scores
for key, value in features.items():
    assert 0.1 <= value <= 1.0, f"{key} out of range: {value}"
```

**Run**:
```bash
python test_features.py
```

---

### 5. Perfect Face Service Test
```python
# Test file: test_perfect_faces.py
from services.landmark_service import landmark_service
from services.perfect_face_service import perfect_face_service
import base64

img_path = "test_image.jpg"

# Get landmarks
landmarks = landmark_service.get_landmarks(img_path)

# Generate perfect faces
perfect_faces = perfect_face_service.generate_perfect_faces(img_path, landmarks)
print(f"✓ Perfect faces generated")
print(f"✓ Left face size: {len(perfect_faces['left_perfect_face']) / 1024:.1f} KB")
print(f"✓ Right face size: {len(perfect_faces['right_perfect_face']) / 1024:.1f} KB")

# Verify format
assert perfect_faces['left_perfect_face'].startswith('data:image/jpeg;base64,')
assert perfect_faces['right_perfect_face'].startswith('data:image/jpeg;base64,')
```

**Run**:
```bash
python test_perfect_faces.py
```

---

### 6. Full API Endpoint Test
```bash
# Health check
curl http://192.168.1.32:8000/

# Analyze face
curl -X POST -F "file=@path_to_test_image.jpg" http://192.168.1.32:8000/analyze-face | python -m json.tool
```

---

## 📱 Flutter App Testing

### Test 1: API Connection
```dart
// In main.dart or a test file
import 'package:dio/dio.dart';

void testConnection() async {
  final dio = Dio();
  try {
    final response = await dio.get('http://192.168.1.32:8000/');
    print('✓ Backend connected: ${response.data}');
  } catch (e) {
    print('✗ Connection failed: $e');
  }
}
```

### Test 2: Complete Analysis Flow
1. **Start app**: `flutter run`
2. **Tap "Take Photo"** or **"Pick Photo"**
3. **Select/capture a clear face photo**
4. **Wait for analysis** (should show loading screen)
5. **Verify results display**:
   - ✅ Celebrity name
   - ✅ Match confidence
   - ✅ Age (from InsightFace)
   - ✅ Gender (from InsightFace)
   - ✅ Symmetry scores
   - ✅ Feature scores
   - ✅ Perfect faces visible

### Test 3: Error Handling
- Test with **blurry image** → Should show "No face detected"
- Test with **no internet** → Should show timeout error
- Test with **profile photo** → Should analyze (might have lower scores)
- Test with **multiple faces** → Should analyze largest face

---

## ✅ Alignment Verification Checklist

### Backend
- [ ] `insightface_service.py` returns metadata with kps, age, gender, det_score
- [ ] `landmark_service.py` returns 5-point landmarks from metadata
- [ ] `symmetry_service.py` calculates scores using 5 landmarks
- [ ] `feature_scoring_service.py` calculates scores using 5 landmarks
- [ ] `perfect_face_service.py` generates base64 images using 5 landmarks
- [ ] `embedding_service.py` returns 512-d vectors
- [ ] `api/main.py` has CORS enabled
- [ ] `api/main.py` returns proper error handling
- [ ] All services handle None/empty inputs gracefully

### Frontend
- [ ] `injection_container.dart` has correct Dio timeout (5 minutes receive)
- [ ] `api_service.dart` has error handling for timeouts
- [ ] `api_constants.dart` has correct backend IP
- [ ] `face_analysis_bloc.dart` handles errors properly
- [ ] `face_analysis_repository_impl.dart` parses response correctly
- [ ] `result_screen.dart` displays age and gender

### Integration
- [ ] Backend and frontend on same network
- [ ] Firewall allows port 8000
- [ ] FAISS index exists and loads
- [ ] Dataset has celebrity folders
- [ ] App compresses images before upload

---

## 🔍 Response Structure Validation

### Expected Response (200 OK)
```json
{
  "celebrity_match": {
    "name": "Celebrity Name",
    "confidence": 85.5
  },
  "top_matches": [
    {"name": "Celeb1", "confidence": 85.5},
    {"name": "Celeb2", "confidence": 82.3}
  ],
  "symmetry": {
    "overall_score": 0.92,
    "eye_symmetry": 0.88,
    "nose_alignment": 0.95,
    "mouth_alignment": 0.91
  },
  "features": {
    "eyes": 0.85,
    "nose": 0.78,
    "jawline": 0.89,
    "face_ratio": 0.92
  },
  "explanation": "You share...",
  "perfect_faces": {
    "left_perfect_face": "data:image/jpeg;base64,...",
    "right_perfect_face": "data:image/jpeg;base64,..."
  },
  "insightface_analysis": {
    "age": 25,
    "gender": "Female",
    "det_score": 0.95,
    "bbox": [100, 50, 350, 400]
  }
}
```

### Error Response
```json
{
  "error": "No face detected in the image."
}
```

---

## 🐛 Troubleshooting Responses

| Response | Cause | Solution |
|----------|-------|----------|
| `"error": "No face detected"` | Low quality or no face | Use clearer photo |
| `Connection timeout` | Network slow or backend down | Check backend running |
| `"error": "Connection refused"` | Wrong IP or port | Update API constants |
| Long response time (60+ sec) | First request model loading | Normal, try again |
| `"error": "Analysis failed"` | Backend crash | Check backend logs |

---

## 📊 Performance Metrics to Track

```
Metric                          | Expected  | Status
─────────────────────────────────────────────────────
First Request                   | 20-30s    | ⏳ Model loading
Subsequent Requests             | 5-15s     | ✅ Normal
Image Upload Time               | 2-5s      | 📤
Face Detection                  | 1-3s      | 👤
Embeddings Computation          | 1-2s      | 🧮
Symmetry Calculation            | <1s       | ⚖️
Feature Scoring                 | <1s       | 📏
Perfect Face Generation         | 2-3s      | ✨
FAISS Search (Top 5)            | <1s       | 🔍
Total Response Time             | 5-16s     | ⏱️
```

---

## ✨ Success Indicators

✅ **Backend Ready When**:
- Terminal shows "Application startup complete"
- `curl http://IP:8000/` returns status message
- First face analysis takes 20-30 seconds
- Subsequent analyses take 5-15 seconds

✅ **App Ready When**:
- Splash screen displays
- Camera/Gallery buttons responsive
- Analysis completes without timeout
- Results show age/gender correctly

✅ **Integration Complete When**:
- All values displayed in results
- No crashes or exceptions
- Perfect faces images render
- Multiple photos analyzed successfully

---

## 🚀 Production Ready Checklist

- [ ] Backend logs are clean (no errors)
- [ ] App handles all error cases gracefully
- [ ] Timeout configured for 5+ minutes
- [ ] CORS properly enabled
- [ ] All 8 services working correctly
- [ ] Response includes all required fields
- [ ] Age/gender data displaying
- [ ] Perfect faces generating properly
- [ ] Celebrity matching working
- [ ] Tested with multiple face photos
- [ ] Tested error scenarios
- [ ] Documentation complete
