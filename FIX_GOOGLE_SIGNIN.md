# Hướng dẫn Fix lỗi Google Sign In

## Lỗi hiện tại:
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

## Nguyên nhân:
- Chưa cấu hình SHA-1 certificate trong Firebase Console
- Error code 10 = DEVELOPER_ERROR (thiếu cấu hình)

## Giải pháp:

### Bước 1: Lấy SHA-1 Certificate
Chạy lệnh sau trong terminal:

```bash
cd android
gradlew signingReport
```

Hoặc trên PowerShell:
```powershell
cd android
.\gradlew signingReport
```

Bạn sẽ thấy output như này:
```
Variant: debug
Config: debug
Store: C:\Users\YourName\.android\debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: AA:BB:CC:DD:EE:FF:11:22:33:44:55:66:77:88:99:00:AA:BB:CC:DD  ← Copy dòng này
SHA-256: ...
```

**Copy SHA-1** (dòng có 20 cặp ký tự phân tách bởi dấu hai chấm)

### Bước 2: Thêm SHA-1 vào Firebase Console

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn project: **sonxemay-cantho**
3. Click vào icon ⚙️ (Settings) → **Project Settings**
4. Cuộn xuống phần **Your apps**
5. Chọn app Android: **com.example.iot_sonxemaycantho_app**
6. Nhấn **Add fingerprint**
7. Paste SHA-1 certificate vừa copy
8. Nhấn **Save**

### Bước 3: Bật Google Sign-in

1. Trong Firebase Console, vào **Authentication** (menu bên trái)
2. Chọn tab **Sign-in method**
3. Tìm **Google** trong danh sách providers
4. Click **Enable**
5. Nhập **Project support email** (email của bạn)
6. Nhấn **Save**

### Bước 4: Tải google-services.json mới

1. Trong Firebase Console, vào **Project Settings**
2. Cuộn xuống phần **Your apps** → Android app
3. Nhấn **Download google-services.json**
4. Thay thế file cũ tại: `android/app/google-services.json`

### Bước 5: Rebuild app

```bash
flutter clean
flutter pub get
flutter run
```

## Kiểm tra lại:

1. Mở app
2. Vào tab **Tài khoản**
3. Nhấn **Đăng nhập**
4. Chọn **Đăng nhập với Google**
5. Chọn tài khoản Google
6. ✅ Đăng nhập thành công!

## Lưu ý quan trọng:

- SHA-1 debug và release khác nhau
- Cần thêm cả 2 SHA-1 nếu muốn test trên cả debug và release build
- Khi build production, cần lấy SHA-1 từ keystore release và thêm vào Firebase

## Lấy SHA-1 cho Release Build:

```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

## Các error code thường gặp:

- **Error 10**: Thiếu SHA-1 certificate (lỗi hiện tại của bạn)
- **Error 12**: User cancelled
- **Error 7**: Network error
- **Error 16**: Cancelled by system
