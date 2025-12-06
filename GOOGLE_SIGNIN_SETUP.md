# Hướng dẫn cấu hình Google Sign In

## Đã hoàn thành:
✅ Đã thêm package `google_sign_in` vào `pubspec.yaml`
✅ Đã tạo trang đăng nhập (`lib/pages/login.dart`)
✅ Đã cập nhật `AuthService` hỗ trợ Google Sign In
✅ Đã tích hợp vào trang Account

## Các bước cần làm tiếp:

### 1. Cấu hình Firebase Console
1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn project **sonxemay-cantho**
3. Vào **Authentication** → **Sign-in method**
4. Bật **Google** provider
5. Thêm email hỗ trợ dự án

### 2. Cấu hình Android
1. Lấy SHA-1 certificate fingerprint:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
2. Thêm SHA-1 vào Firebase:
   - Vào **Project Settings** → **Your apps** → Android app
   - Thêm SHA-1 fingerprint

3. Tải file `google-services.json` mới và thay thế file cũ trong `android/app/`

### 3. Cấu hình iOS (nếu cần)
1. Thêm URL Scheme vào `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
       </array>
     </dict>
   </array>
   ```

2. Tải file `GoogleService-Info.plist` và thêm vào `ios/Runner/`

### 4. Chạy ứng dụng
```bash
flutter clean
flutter pub get
flutter run
```

## Sử dụng:
1. Mở app
2. Chuyển đến tab **Tài khoản**
3. Nhấn nút **Đăng nhập**
4. Chọn **Đăng nhập với Google**

## Tính năng đã có:
- ✅ Đăng nhập bằng Google
- ✅ Đăng nhập bằng Email/Password
- ✅ Hiển thị thông tin user sau khi đăng nhập
- ✅ Đăng xuất
- ✅ UI đẹp với Material Design 3

## Lưu ý:
- Google Sign In chỉ hoạt động trên thiết bị thật hoặc emulator có Google Play Services
- Cần cấu hình đúng SHA-1 để Google Sign In hoạt động trên Android
