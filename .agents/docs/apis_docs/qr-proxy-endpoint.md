# API Spec: Proxy QR Image Endpoint

## Status: ✅ Backend deployed + Flutter integrated

## Tổng quan

Backend đã update `TopUpResponseDto` với field `qrImageBase64` (PNG đã encode Base64).
Backend cũng cung cấp fallback endpoint `GET /wallet/topup/{orderId}/qr-image` cho
trường hợp proxy thất bại.

Flutter client integrate 3-tier fallback chain:

1. **`qrImageBase64`** (ưu tiên) → render `Image.memory` ngay, không cần network.
2. **`qrUrl`** (mobile only) → `Dio` download → `Image.memory`.
3. **`paymentUrl`** → `QrImageView` local (QR matrix thuần, luôn work).

## 1. Backend response — `qrImageBase64` (đã có)

```json
{
  "paymentUrl": "https://vietqr.app/img?...",
  "qrUrl": "https://vietqr.app/img?...",
  "qrImageBase64": "iVBORw0KGgoAAAANSUhEUgAA...",
  "orderId": "1983EBFA5333CF7F42",
  "expectedBvc": 20,
  "expiresAt": "2026-08-15T09:21:36.9581535Z",
  "idempotencyKey": "y3G1WcEHip6..."
}
```

## 2. Fallback endpoint — `GET /api/v1/wallet/topup/{orderId}/qr-image` (đã có)

```
GET /api/v1/wallet/topup/1983EBFA5333CF7F42/qr-image
Authorization: Bearer <token>
→ 200 image/png (10-minute cache)
```

### Flutter client integration

#### Method trong `WalletRemoteDatasource`

```dart
Future<Either<Failure, Uint8List>> getQrImageBytes(String orderId);
```

#### Service: `lib/features/wallet/data/datasources/wallet_remote_datasource.dart`

```dart
@override
Future<Either<Failure, Uint8List>> getQrImageBytes(String orderId) async {
  if (orderId.isEmpty) {
    return const Left(ServerFailure(message: 'OrderId trống.'));
  }
  try {
    final response = await dio.get<List<int>>(
      ApiEndpoints.walletTopupQrImage(orderId),
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    if (response.statusCode == 200 && response.data != null) {
      return Right(Uint8List.fromList(response.data!));
    }

    return Left(ServerFailure(
      message: 'Failed to fetch QR image: ${response.statusCode}',
    ));
  } on DioException catch (e) {
    return Left(_handleDioError(e));
  } catch (e) {
    return Left(ServerFailure(message: e.toString()));
  }
}
```

#### Endpoint helper

```dart
// lib/core/constants/api_endpoints.dart
static String walletTopupQrImage(String orderId) =>
    '/api/v1/wallet/topup/$orderId/qr-image';
```

## 3. Flutter integration chi tiết

### TopUpQuoteEntity — field mới

```dart
final String? qrImageBase64;  // PNG base64 từ backend

/// Decode base64 → Uint8List PNG bytes. Null nếu rỗng/invalid.
Uint8List? get qrImageBytes {
  final base64 = qrImageBase64;
  if (base64 == null || base64.isEmpty) return null;
  try {
    return base64Decode(base64);
  } catch (_) {
    return null;
  }
}
```

### TopUpQuoteModel — parse JSON

```dart
qrImageBase64: json['qrImageBase64'] as String?,
```

### QrNetworkImage — priority chain

```dart
@override
Widget build(BuildContext context) {
  final base64Bytes = _base64Bytes;
  final hasBase64 = base64Bytes != null && base64Bytes.isNotEmpty;

  // Tier 1: Render ảnh QR từ base64 (NO network).
  if (hasBase64) {
    return _frameRemoteImage(bytes: base64Bytes, size: size);
  }

  // Tier 2: Mobile — download từ qrUrl qua Dio.
  if (!kIsWeb) {
    // ... FutureBuilder ...
  }

  // Tier 3: Web (no base64) — render QR matrix local.
  return _fallbackOrLocalQr(size: size);
}
```

### QrDownloadService — ưu tiên bytes

```dart
Future<String> downloadAndSaveQr({
  required String qrUrl,
  required String orderId,
  Uint8List? qrImageBytes,  // ← optional: truyền bytes từ base64
}) async {
  if (qrImageBytes != null && qrImageBytes.isNotEmpty) {
    // Tier 1: write bytes trực tiếp. Không tốn HTTP request.
    await file.writeAsBytes(qrImageBytes, flush: true);
  } else {
    // Tier 2: download từ qrUrl (mobile only).
    await _dio.download(qrUrl, filePath, ...);
  }
}
```

## Lợi ích

- ✅ Web hiển thị ảnh QR đẹp từ VietQR (có logo bank + viền) — bypass CORS.
- ✅ Mobile không cần download từ CDN nếu đã có base64.
- ✅ Tiết kiệm 1 HTTP request mỗi lần hiển thị/tải QR.
- ✅ CORS-safe trên mọi platform (base64 đi trong JSON).
- ✅ Fallback endpoint đảm bảo robustness khi proxy fail.
