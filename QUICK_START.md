# Quick Start Guide - MirrorMe

## 🚀 Start Backend (Fast API Server)

### Step 1: Navigate to Backend Directory
```bash
cd /home/umerjlm/Desktop/FSZ/face_detection_model
```

### Step 2: Activate Virtual Environment (if exists)
```bash
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate  # On Windows
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

### Step 4: Run Backend Server
```bash
python -m uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

**Expected Output**:
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Started server process [PID]
INFO:     Waiting for application startup.
INFO:     Application startup complete
```

✅ **Backend is ready** when you see "Application startup complete"

---

## 📱 Start Flutter App

### Step 1: Update Backend URL
**File**: `lib/core/constants/api_constants.dart`

```dart
static const String baseUrl = 'http://192.168.1.32:8000'; // Change to your IP
```

🔍 **Find your IP**:
```bash
# macOS/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# Windows
ipconfig

# Look for IPv4 Address (usually starts with 192.168.x.x or 10.x.x.x)
```

### Step 2: Navigate to App Directory
```bash
cd /home/umerjlm/Desktop/FSZ/mirror_me_app
```

### Step 3: Get Dependencies
```bash
flutter pub get
```

### Step 4: Run App
```bash
# On emulator
flutter run

# Or for specific device
flutter devices  # List devices
flutter run -d <device_id>
```

✅ **App is ready** when splash screen appears

---

## ✅ Test the Integration

### Method 1: Direct API Test
```bash
# Replace IP with your actual IP
curl -X POST -F "file=@path_to_image.jpg" http://192.168.1.32:8000/analyze-face

# On Windows PowerShell
Invoke-WebRequest -Uri "http://192.168.1.32:8000/analyze-face" -Method Post -Form @{file=Get-Item "path_to_image.jpg"}
```

### Method 2: Health Check
```bash
curl http://192.168.1.32:8000/
# Expected: {"status":"MirrorMe AI Face Intelligence API is running 🚀"}
```

### Method 3: App Test
1. Open Flutter app
2. Tap "Take Photo" or "Pick Photo"
3. Select/capture a face photo
4. Wait for analysis (should complete within 5 minutes)
5. Check if age and gender appear in results

---

## 🔧 Troubleshooting

### Backend Won't Start
```bash
# Check if port 8000 is in use
lsof -i :8000  # macOS/Linux
netstat -ano | findstr :8000  # Windows

# Kill process on port 8000
kill -9 <PID>  # macOS/Linux
taskkill /PID <PID> /F  # Windows

# Try different port
python -m uvicorn api.main:app --host 0.0.0.0 --port 8001
```

### Flutter Can't Connect to Backend
1. **Check IP**: Ensure backend IP matches in `api_constants.dart`
2. **Check Firewall**: Allow port 8000 through firewall
3. **Check Network**: Device and backend should be on same WiFi
4. **Check Backend**: Verify backend is running with `curl http://IP:8000/`

### App Timeout After 5 Minutes
- Image might be too large → compress more
- Backend might be stuck → check backend logs
- Network might be slow → check WiFi signal
- Model might be failing → check backend terminal for errors

### "No Face Detected"
- Photo needs to show clear face
- Face should be frontal and not extreme angle
- Image should have good lighting
- Face should take up at least 50% of frame

---

## 📊 API Endpoints

| Method | Endpoint | Body | Response |
|--------|----------|------|----------|
| GET | `/` | - | `{status: "..."}` |
| POST | `/analyze-face` | `file: <image>` | Full analysis JSON |
| GET | `/celeb-images/<name>/<image>` | - | Celebrity image |

---

## 🎯 Expected Behavior

### First Request (Model Loading)
- Takes 20-30 seconds
- Backend initializes InsightFace model
- Subsequent requests much faster

### Subsequent Requests
- Takes 5-15 seconds (depending on network)
- Model already loaded in memory
- Much faster response

### Response Time Breakdown
- Upload: 2-5 seconds
- Face Detection: 1-3 seconds
- Analysis: 3-8 seconds
- Total: 6-16 seconds (typical)

---

## 📝 Logs & Debugging

### Backend Logs
Appear in terminal where you ran `uvicorn`. Look for:
- ✅ `200` = Success
- ⚠️ `400` = Bad request
- ❌ `500` = Server error
- 🔴 `Connection refused` = Backend not running

### Flutter Logs
```bash
# View all logs
flutter logs

# Filter for errors
flutter logs | grep -i error
```

---

## 🛑 Stop Services

### Stop Backend
```bash
Press Ctrl+C in terminal where uvicorn is running
```

### Stop App
```bash
Press Ctrl+C in terminal where flutter run is running
# Or close emulator/device
```

---

## ✨ You're All Set!

Backend should be running on `http://<your-ip>:8000`  
App should be ready to analyze faces!

Good luck! 🚀
