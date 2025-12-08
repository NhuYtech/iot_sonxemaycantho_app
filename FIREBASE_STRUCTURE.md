# 📊 Cấu trúc Firebase Realtime Database

## Cấu trúc dữ liệu cho app IoT Sơn Xe Máy Cần Thơ

### 1. `/sensor` - Dữ liệu cảm biến realtime
```json
{
  "sensor": {
    "temp": 28.5,      // Nhiệt độ (°C)
    "humi": 65,        // Độ ẩm (%)
    "mq2": 120,        // Giá trị Gas (ppm)
    "fire": 1          // Fire sensor (0=có lửa, 1=an toàn)
  }
}
```

### 2. `/control` - Điều khiển thiết bị
```json
{
  "control": {
    "relay1": 0,       // Relay 1 (0=tắt, 1=bật)
    "relay2": 0,       // Relay 2 (0=tắt, 1=bật)
    "buzzer": 0        // Còi báo động (0=tắt, 1=bật)
  }
}
```

### 3. `/settings` - Cài đặt hệ thống
```json
{
  "settings": {
    "behavior": {
      "mode": 0,           // 0=AUTO, 1=MANUAL
      "threshold": 200     // Ngưỡng cảnh báo Gas (ppm)
    },
    "dataInterval": 5      // Tần suất gửi dữ liệu (giây)
  }
}
```

### 4. `/wifiConfig` - Cấu hình WiFi
```json
{
  "wifiConfig": {
    "ssid": "sonxemaycantho_2",
    "timestamp": 1733654400000
  }
}
```

### 5. `/history/{YYYY-MM-DD}` - Lịch sử dữ liệu theo ngày
```json
{
  "history": {
    "2025-12-08": {
      "1733654400000": {
        "temp": 28.5,
        "humi": 65,
        "mq2": 120,
        "fire": 1,
        "timestamp": 1733654400000
      },
      "1733654460000": {
        "temp": 29.0,
        "humi": 64,
        "mq2": 125,
        "fire": 1,
        "timestamp": 1733654460000
      }
    }
  }
}
```

## 📝 Cách ESP32 ghi dữ liệu

### Code Arduino để ghi history:
```cpp
void saveToHistory() {
  // Đọc sensor
  float temp = dht.readTemperature();
  float humi = dht.readHumidity();
  int gas = analogRead(MQ2_PIN);
  int fire = digitalRead(FIRE_PIN);
  
  // Lấy timestamp
  unsigned long timestamp = millis();
  
  // Format path: history/YYYY-MM-DD/timestamp
  String date = getCurrentDate(); // "2025-12-08"
  String path = "history/" + date + "/" + String(timestamp);
  
  // Ghi vào Firebase
  Firebase.setFloat(firebaseData, path + "/temp", temp);
  Firebase.setFloat(firebaseData, path + "/humi", humi);
  Firebase.setInt(firebaseData, path + "/mq2", gas);
  Firebase.setInt(firebaseData, path + "/fire", fire);
  Firebase.setInt(firebaseData, path + "/timestamp", timestamp);
}
```

## 🔄 Cách App Flutter đọc dữ liệu

### 1. Đọc dữ liệu realtime:
```dart
final service = FirebaseRealtimeService();

// Lắng nghe sensor
service.getSensorStream().listen((data) {
  print('Gas: ${data['mq2']} ppm');
  print('Temp: ${data['temp']}°C');
});
```

### 2. Đọc lịch sử cho biểu đồ:
```dart
// Lấy dữ liệu ngày hôm nay
final history = await service.getHistoryData(DateTime.now());

// Hoặc lắng nghe realtime
service.getHistoryStream(DateTime.now()).listen((data) {
  // Xử lý data cho biểu đồ
});
```

## 📊 Biểu đồ 24 giờ

App sẽ:
1. Đọc tất cả dữ liệu trong ngày từ `/history/YYYY-MM-DD`
2. Phân loại theo giờ (0-23)
3. Tính trung bình mỗi giờ
4. Hiển thị trên biểu đồ

### Ví dụ xử lý:
```dart
// Data từ Firebase
{
  "1733654400000": { "temp": 28.5, "timestamp": 1733654400000 }, // 10:00
  "1733654460000": { "temp": 29.0, "timestamp": 1733654460000 }, // 10:01
  "1733658000000": { "temp": 30.5, "timestamp": 1733658000000 }  // 11:00
}

// Kết quả biểu đồ:
Hour 10: (28.5 + 29.0) / 2 = 28.75°C
Hour 11: 30.5°C
```

## 🚀 Tự động lưu history

Có 2 cách:

### Cách 1: ESP32 tự động lưu (Khuyến nghị)
```cpp
void loop() {
  // Gửi realtime
  Firebase.setFloat(firebaseData, "sensor/temp", temp);
  
  // Lưu history mỗi 5 phút
  if (millis() - lastSave > 300000) {
    saveToHistory();
    lastSave = millis();
  }
}
```

### Cách 2: App Flutter lưu
```dart
// Trong home.dart, khi nhận sensor data:
_sensorSubscription = _firebaseService.getSensorStream().listen((data) {
  // Lưu vào history
  _firebaseService.saveHistoryData(data);
});
```

## 📅 Retention Policy (Tùy chọn)

Để không lưu quá nhiều dữ liệu, có thể:
- Xóa data cũ hơn 30 ngày
- Hoặc dùng Firebase Rules để giới hạn:

```json
{
  "rules": {
    "history": {
      "$date": {
        ".write": "now < root.child('history').child($date).child('timestamp').val() + 2592000000"
      }
    }
  }
}
```

---

**Tác giả:** NhuYtech  
**Project:** CanTho FireGuard  
**Date:** 8/12/2025
