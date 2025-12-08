# Hướng dẫn cập nhật ESP32 để ghi History Data

## Vấn đề hiện tại
- App đang lắng nghe data từ path `/history/YYYY-MM-DD/{timestamp}`
- ESP32 chưa ghi data vào path này
- Biểu đồ không hiển thị vì không có data

## Giải pháp

### 1. Thêm code vào ESP32 để ghi history data

```cpp
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <time.h>

// Thêm biến time
struct tm timeinfo;

// Setup time (thêm vào setup())
void setup() {
  // ... code hiện tại ...
  
  // Config time
  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov");
  Serial.println("Waiting for time sync...");
  while (!getLocalTime(&timeinfo)) {
    delay(1000);
    Serial.print(".");
  }
  Serial.println("\nTime synced!");
}

// Hàm lưu history (gọi mỗi 5 phút hoặc khi có thay đổi)
void saveHistoryData() {
  if (!Firebase.ready()) return;
  
  // Lấy thời gian hiện tại
  if (!getLocalTime(&timeinfo)) {
    Serial.println("Failed to get time");
    return;
  }
  
  // Tạo date key: YYYY-MM-DD
  char dateKey[11];
  strftime(dateKey, sizeof(dateKey), "%Y-%m-%d", &timeinfo);
  
  // Tạo timestamp key
  unsigned long timestamp = millis();
  
  // Đọc giá trị sensor
  float temp = dht.readTemperature();
  float humi = dht.readHumidity();
  int gasValue = analogRead(MQ2_PIN);
  int fireValue = digitalRead(FIRE_PIN);
  
  // Tạo path: history/YYYY-MM-DD/timestamp
  String basePath = "history/" + String(dateKey) + "/" + String(timestamp);
  
  // Ghi từng field
  if (Firebase.RTDB.setFloat(&fbdo, basePath + "/temp", temp)) {
    Serial.println("✅ Saved temp to history");
  }
  
  if (Firebase.RTDB.setFloat(&fbdo, basePath + "/humi", humi)) {
    Serial.println("✅ Saved humi to history");
  }
  
  if (Firebase.RTDB.setInt(&fbdo, basePath + "/mq2", gasValue)) {
    Serial.println("✅ Saved gas to history");
  }
  
  if (Firebase.RTDB.setInt(&fbdo, basePath + "/fire", fireValue)) {
    Serial.println("✅ Saved fire to history");
  }
  
  if (Firebase.RTDB.setInt(&fbdo, basePath + "/timestamp", timestamp)) {
    Serial.println("✅ Saved timestamp");
  }
  
  Serial.println("📊 History data saved to: " + basePath);
}

// Trong loop(), gọi mỗi 5 phút
void loop() {
  // ... code hiện tại ...
  
  static unsigned long lastHistorySave = 0;
  unsigned long now = millis();
  
  // Lưu history mỗi 5 phút (300000ms)
  if (now - lastHistorySave >= 300000 || lastHistorySave == 0) {
    saveHistoryData();
    lastHistorySave = now;
  }
}
```

### 2. Cấu trúc data trong Firebase

Sau khi ESP32 ghi, Firebase sẽ có cấu trúc:

```
history/
  2025-12-08/
    1733654400000/
      temp: 28.5
      humi: 65.2
      mq2: 120
      fire: 0
      timestamp: 1733654400000
    1733654700000/
      temp: 29.1
      humi: 64.8
      mq2: 125
      fire: 0
      timestamp: 1733654700000
```

### 3. Test ngay lập tức

Để test không cần đợi 5 phút, bạn có thể:

**Option A: Gọi ngay trong setup()**
```cpp
void setup() {
  // ... code hiện tại ...
  
  // Đợi 5 giây để Firebase ready
  delay(5000);
  
  // Test lưu history
  Serial.println("📊 Testing history save...");
  saveHistoryData();
}
```

**Option B: Tạo command từ app**
```cpp
// Lắng nghe command "saveHistory" từ Firebase
if (Firebase.RTDB.getString(&fbdo, "control/command")) {
  String cmd = fbdo.stringData();
  if (cmd == "saveHistory") {
    saveHistoryData();
    Firebase.RTDB.setString(&fbdo, "control/command", "");
  }
}
```

### 4. Giải pháp tạm thời (Test data)

Nếu chưa update ESP32, có thể tạo test data trực tiếp trên Firebase Console:

1. Mở Firebase Console
2. Vào Realtime Database
3. Tạo structure:
```
history/
  2025-12-08/
    1733654400000/
      temp: 28.5
      humi: 65.0
      mq2: 120
      fire: 0
      timestamp: 1733654400000
```

### 5. Kiểm tra trên app

Sau khi ESP32 ghi data hoặc tạo test data:
1. Mở app
2. Vào trang Thống kê
3. Xem console log (trong VS Code Debug Console)
4. Sẽ thấy:
```
🔍 Testing Firebase connection...
🔍 Test result: XX entries found
📊 Listening to history path: history/2025-12-08
📊 History data received: true
📊 Processed XX history entries
🔄 Processing history data: XX entries
✅ Data keys: timestamp1, timestamp2, ...
```

## Lưu ý

- **Timestamp**: Nên dùng Unix timestamp (millis()) để dễ sort
- **Tần suất**: 5 phút là hợp lý, tránh spam Firebase
- **Time sync**: Phải config NTP để có ngày chính xác
- **Timezone**: Việt Nam là GMT+7 (7*3600)
- **Retention**: Nên xóa data cũ sau 30 ngày để tiết kiệm storage

## Test script cho Firebase Console

Copy paste vào Firebase Console để tạo 24 giờ test data:

```javascript
// Chạy trong Firebase Console > Realtime Database > REST API test
const date = '2025-12-08';
const baseTimestamp = Date.now() - (24 * 60 * 60 * 1000); // 24h trước

for (let hour = 0; hour < 24; hour++) {
  const timestamp = baseTimestamp + (hour * 60 * 60 * 1000);
  const data = {
    temp: 25 + Math.random() * 10,
    humi: 60 + Math.random() * 20,
    mq2: 100 + Math.floor(Math.random() * 100),
    fire: 0,
    timestamp: timestamp
  };
  
  // Ghi vào Firebase
  firebase.database().ref(`history/${date}/${timestamp}`).set(data);
}
```
