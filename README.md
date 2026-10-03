# BoardVerse Mobile

Ứng dụng Flutter dành cho **Player**: đăng nhập, khám phá quán / board game, ghép lobby, đặt bàn, check-in QR, giải đấu và trải nghiệm trong phiên chơi.

Repo này là client mobile. Backend mặc định: `https://boardverse-server.onrender.com`.

---

## Yêu cầu môi trường

| Thành phần | Ghi chú |
|---|---|
| **Flutter SDK** | Dart SDK `^3.12.1` (xem `pubspec.yaml`). Cài [Flutter](https://docs.flutter.dev/get-started/install) rồi chạy `flutter doctor`. |
| **Git** | Clone source. |
| **JDK 17** | Bắt buộc khi build Android (Gradle dùng Java 17). |
| **Android Studio** (hoặc SDK + emulator) | Chạy trên máy ảo / thiết bị Android. `minSdk` lấy từ Flutter SDK hiện tại. |
| **Xcode + CocoaPods** | Chỉ cần nếu chạy **iOS** (máy macOS). |
| **Chrome** | Tùy chọn: chạy bản web (`flutter run -d chrome`). Một số tính năng native (camera GPS, Google Sign-In mobile) hạn chế trên web. |

Kiểm tra nhanh:

```bash
flutter --version
flutter doctor -v
```

Sửa hết mục đỏ của `flutter doctor` trước khi chạy app (Android toolchain, licenses, iOS nếu dùng Mac).

---

## 1. Clone source

```bash
git clone <URL-repo>
cd boardverse_mobile
```

---

## 2. Tạo file `.env`

App **bắt buộc** có file `.env` ở **thư mục gốc** (cùng cấp `pubspec.yaml`). File này đã git-ignore; không có `.env` thì `dotenv.load` sẽ fail lúc khởi động.

```bash
# Windows PowerShell
Copy-Item .env.example .env

# macOS / Linux
cp .env.example .env
```

Mở `.env` và điền giá trị thật (xin team, hoặc dùng bộ key dự án nếu được chia sẻ riêng). Các biến cần có:

| Biến | Mục đích |
|---|---|
| `API_BASE_URL` | Base URL REST API. Mặc định production trên Render. |
| `GOOGLE_WEB_CLIENT_ID` | OAuth Web — dùng khi chạy Chrome / web. |
| `GOOGLE_SERVER_CLIENT_ID` | OAuth Web Client ID dùng làm `serverClientId` trên Android/iOS. |
| `GOOGLE_IOS_CLIENT_ID` | OAuth Client loại iOS (`com.boardverse.boardverseMobile`). |
| `CLOUDINARY_CLOUD_NAME` | Cloud upload ảnh. |
| `CLOUDINARY_UPLOAD_PRESET` | Unsigned upload preset. |
| `CLOUDINARY_DEFAULT_FOLDER` | Thư mục mặc định (thường `boardverse/uploads`). |
| `CLOUDINARY_AUTO_OPTIMIZE` | `true` / `false`. |

`pubspec.yaml` khai báo asset `.env` — **không đổi tên file** và không đặt `.env` ngoài thư mục gốc.

---

## 3. Cài dependency

```bash
flutter pub get
```

Code `*.g.dart` / `*.freezed.dart` đã có trong repo. Chỉ chạy code-gen khi sửa model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 4. Chạy ứng dụng

Liệt kê thiết bị:

```bash
flutter devices
```

### Android (khuyến nghị để test đủ tính năng)

1. Bật emulator hoặc cắm máy, bật USB debugging.
2. File `android/app/google-services.json` đã có trong repo (package `com.boardverse.boardverse_mobile`). Giữ nguyên trừ khi đổi Firebase project.
3. Chạy:

```bash
flutter run
# hoặc chỉ định máy
flutter run -d <deviceId>
```

**Google Sign-In trên Android:** SHA-1 của keystore debug phải được khai báo trên Google Cloud / Firebase. SHA-1 debug hiện tại trong `google-services.json`:

`02:FF:9E:1D:51:EE:1A:37:82:61:48:80:4E:25:35:39:E9:EE:10:B4`

Nếu máy bạn dùng keystore debug khác (máy mới / OS khác), lấy SHA-1 rồi nhờ người giữ Google Cloud thêm vào OAuth Android client:

```bash
cd android
./gradlew signingReport
```

(Windows: `.\gradlew.bat signingReport`)

### Chrome (web)

```bash
flutter run -d chrome
```

Trên Google Cloud Console, OAuth **Web application** phải có **Authorized JavaScript origins** trùng origin đang chạy (ví dụ `http://localhost:<port>`). Port Flutter web thường đổi mỗi lần chạy.

### iOS (chỉ macOS)

```bash
cd ios
pod install
cd ..
flutter run -d ios
```

- Bundle ID: `com.boardverse.boardverseMobile`
- Application ID Android: `com.boardverse.boardverse_mobile`

---

## 5. Test

```bash
flutter test
flutter analyze
```

---

## Quyền hệ thống (đã khai báo sẵn)

Không cần sửa manifest/plist khi clone lần đầu. App xin lúc runtime:

- **Internet**
- **Camera** — quét QR check-in
- **Vị trí** — gợi ý quán gần bạn
- **Thư viện ảnh** — avatar, decode QR từ ảnh

---

## Cấu trúc thư mục (rút gọn)

```
boardverse_mobile/
├── .env.example          # Mẫu biến môi trường
├── lib/
│   ├── main.dart
│   ├── core/             # DI, network, theme, navigation
│   └── features/         # Từng module nghiệp vụ (auth, lobby, …)
├── android/              # Native Android + google-services.json
├── ios/
├── web/
├── test/
└── pubspec.yaml
```

Kiến trúc: **feature-first + Clean Architecture** (domain / data / presentation), state bằng **Cubit** (`flutter_bloc`), HTTP **Dio**, DI **GetIt**.

---

## Lỗi thường gặp

| Hiện tượng | Cách xử lý |
|---|---|
| `Unable to load asset: ".env"` hoặc crash ngay `main()` | Chưa tạo `.env` ở thư mục gốc. Copy từ `.env.example`. |
| `flutter pub get` lỗi version Dart | Nâng Flutter SDK sao cho `dart --version` thỏa `^3.12.1`. |
| Android build fail Java / JDK | Cài JDK 17, trỏ `JAVA_HOME` đúng bản 17. |
| Google Sign-In Android: `ApiException: 10` | SHA-1 debug chưa khớp OAuth client. Chạy `signingReport`, thêm SHA-1 lên Google Cloud. |
| Google Sign-In web không hiện / redirect lỗi | Thiếu `GOOGLE_WEB_CLIENT_ID` hoặc chưa thêm origin localhost vào Google Cloud. |
| Upload ảnh fail | Thiếu `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_UPLOAD_PRESET`. |
| API timeout / CORS trên web | Backend Render có thể sleep lần gọi đầu; đợi rồi retry. CORS chủ yếu ảnh hưởng Chrome. |
| `kotlin incremental caches` trên Windows | Repo đã tắt incremental Kotlin trong `android/gradle.properties`. Clean rồi chạy lại: `flutter clean && flutter pub get && flutter run`. |

---

## Ghi chú cho người nhận source

1. File `.env` **không** nằm trong Git — luôn tạo local từ `.env.example`.
2. App mobile chỉ cho role **User / Player**. Tài khoản Admin / Cafe Manager / Staff đăng nhập sẽ bị từ chối trên điện thoại.
3. Backend production trên Render có thể chậm lần request đầu (cold start).
4. Không commit `.env`, keystore release, hay secret mới.
