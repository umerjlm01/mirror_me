# MirrorMe Backend Alignment Guide

## ✅ Current Setup (InsightFace Only)

### Backend Architecture
- **Face Detection**: InsightFace (buffalo_l model)
- **Face Landmarks**: 5-point keypoints (eyes, nose, mouth)
- **Age/Gender Detection**: InsightFace built-in
- **Embeddings**: InsightFace ArcFace (512-d)
- **Celebrity Matching**: FAISS with embeddings

### API Flow

```
Image Upload → save_upload() → extract_face()
                                     ↓
                            InsightFaceService
                            (detect, align, age/gender)
                                     ↓
                            metadata {kps, age, gender, det_score, bbox}
                                     ↓
         ┌─────────────────────────────────────────────┐
         ↓                        ↓                     ↓
    Landmarks           Embeddings            Metadata
    (5 keypoints)      (get_embedding)       (age, gender)
         ↓                        ↓                     ↓
    Symmetry Analysis   Celebrity Matching   Return to App
    Feature Scoring
    Perfect Face Gen
```

## 🔧 Configuration

### Backend Requirements

**File**: `/home/umerjlm/Desktop/FSZ/face_detection_model/requirements.txt`

```
fastapi
uvicorn
deepface
tensorflow
opencv-python
numpy
mtcnn
faiss-cpu
insightface
onnxruntime
```

**Install with**:
```bash
cd /home/umerjlm/Desktop/FSZ/face_detection_model
pip install -r requirements.txt
```

**Run with**:
```bash
python -m uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend Configuration

**File**: `lib/core/constants/api_constants.dart`
```dart
static const String baseUrl = 'http://192.168.1.32:8000'; // Change IP
static const String analyzeFaceEndpoint = '/analyze-face';
```

**Dio Timeout Settings** (in `injection_container.dart`):
- Connect Timeout: 30 seconds
- Receive Timeout: 5 minutes (300 seconds)
- Send Timeout: 5 minutes (300 seconds)

⚠️ **Important**: These timeouts allow for slow network/processing delays

## 🔍 API Response Format

### Request
```
POST /analyze-face
Content-Type: multipart/form-data
file: <image_file>
```

### Successful Response (200)
```json
{
  "celebrity_match": {
    "name": "Celebrity Name",
    "confidence": 85.5
  },
  "top_matches": [
    {
      "name": "Celebrity 1",
      "confidence": 85.5
    },
    ...
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
  "explanation": "You share a remarkable resemblance...",
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
  "error": "Error message describing what went wrong"
}
```

## 🐛 Common Issues & Fixes

### Issue: Connection Timeout
**Cause**: Backend not running or wrong IP
**Fix**:
1. Check backend is running: `python -m uvicorn api.main:app --host 0.0.0.0 --port 8000`
2. Update API IP in `api_constants.dart`
3. Ensure Flutter device can reach backend IP

### Issue: No Face Detected
**Cause**: Low quality image or extreme angles
**Fix**: Try with clear, frontal face photo with good lighting

### Issue: Slow Response
**Cause**: Model initialization or network latency
**Fix**: First request may be slow (model loading), subsequent requests faster

## 📋 Services Integration

### 1. InsightFace Service
- **File**: `services/insightface_service.py`
- **Provides**: Detection, alignment, age/gender, embeddings
- **5-point landmarks**: [left_eye, right_eye, nose_tip, left_mouth, right_mouth]

### 2. Landmark Service
- **File**: `services/landmark_service.py`
- **Input**: Image path
- **Output**: 5-point numpy array in pixel coordinates

### 3. Symmetry Service
- **File**: `services/symmetry_service.py`
- **Calculates**: Eye, nose, and mouth symmetry scores
- **Uses**: 5-point landmarks only

### 4. Feature Scoring Service
- **File**: `services/feature_scoring_service.py`
- **Scores**: Eyes, nose, jawline, face_ratio
- **Uses**: 5-point landmarks with approximations

### 5. Perfect Face Service
- **File**: `services/perfect_face_service.py`
- **Generates**: Left-perfect and right-perfect face images
- **Uses**: Eye alignment and nose center

### 6. Embedding Service
- **File**: `services/embedding_service.py`
- **Provides**: 512-d ArcFace embeddings for similarity matching

### 7. Matching Service
- **File**: `services/matching_service.py`
- **Method**: FAISS index search with L2 normalization

### 8. Explanation Service
- **File**: `services/explanation_service.py`
- **Generates**: Human-readable analysis text

## ✅ Verification Checklist

- [ ] Backend running on correct IP and port
- [ ] Flutter app updated with correct API constants
- [ ] Dio timeout configured for long operations
- [ ] CORS enabled on backend
- [ ] All services importing correctly
- [ ] Test image with clear face photo
- [ ] Check logs for any errors
- [ ] Verify API returns age/gender data
- [ ] Check perfect faces are generated

## 🚀 Testing Flow

1. **Backend Test**:
   ```bash
   curl -X POST -F "file=@test_image.jpg" http://192.168.1.32:8000/analyze-face
   ```

2. **Frontend Test**:
   - Take/pick a photo
   - Observe loading screen
   - Check if results load within 5 minutes
   - Verify age/gender display in results

## 📱 App Flow

```
Home Screen → Camera/Gallery → Image Preview
    ↓
Compress Image (reduce size)
    ↓
Send to Backend (with 5 min timeout)
    ↓
Processing Screen (shows loading)
    ↓
Result Screen (displays all analysis + age/gender)
    ↓
Share or Save to History
```

## 🔗 Dependencies

**Backend**:
- fastapi: Web framework
- insightface: Face detection & analysis
- faiss: Similarity search
- opencv-python: Image processing
- numpy: Array operations

**Frontend**:
- dio: HTTP client
- flutter_bloc: State management
- image_picker: Camera/Gallery access
- shared_preferences: Local storage
- fl_chart: Data visualization
