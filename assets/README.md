# Assets Folder

## Cách thay logo app:

1. **Chuẩn bị file logo:**
   - Kích thước: 1024x1024 px (khuyến nghị)
   - Định dạng: PNG với nền trong suốt
   - Đặt tên: `icon.png`

2. **Copy file logo vào thư mục này:**
   - Đường dẫn: `assets/icon.png`

3. **Chạy lệnh tạo icon:**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. **Rebuild app:**
   ```bash
   flutter clean
   flutter run
   ```

## Lưu ý:
- File `icon.png` cần có nền trong suốt để hiển thị đẹp trên mọi nền
- Nếu muốn dùng icon khác cho iOS, đặt tên `icon_ios.png`
- Logo sẽ tự động được tạo với nhiều kích thước khác nhau cho Android và iOS
