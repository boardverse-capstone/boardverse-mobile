import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Service để decode QR/barcode từ FILE ẢNH.
///
/// Dùng Google ML Kit (chính xác cao, hỗ trợ cả khi ảnh xấu/góc nghiêng).
/// `mobile_scanner` không hỗ trợ decode từ file, nên phải dùng package riêng.
///
/// Phục vụ chế độ "Tải ảnh QR" trong `PlayerQrCheckInPage` — tiện cho
/// test/debug khi:
/// - Không có camera (emulator, dev tool)
/// - Muốn quét QR từ screenshot POS thay vì đưa điện thoại qua lại
///
/// Luồng:
/// 1. User nhấn nút → mở ImagePicker → chọn ảnh
/// 2. Service nhận file path → ML Kit decode → trả về raw text của QR
/// 3. UI extract token từ raw text (dùng regex giống scanner thường)
///
/// Lưu ý: KHÔNG dùng service này để tự động submit token — UI vẫn dùng
/// logic `_tokenRegex` / `_tokenExtractRegex` để filter cho chắc.
class QrImageDecoder {
  /// Barcode scanner dùng singleton — ML Kit tự quản lý resource.
  static final BarcodeScanner _scanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode],
  );

  /// Decode QR từ file ảnh. Trả về raw text của QR, hoặc null nếu:
  /// - File không tồn tại
  /// - Không tìm thấy QR trong ảnh
  /// - Có nhiều QR → trả về QR đầu tiên
  ///
  /// [imagePath] — absolute path đến file ảnh (từ ImagePicker).
  static Future<String?> decodeFromFile(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      return null;
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    try {
      final barcodes = await _scanner.processImage(inputImage);
      if (barcodes.isEmpty) return null;

      // Lấy raw value của QR đầu tiên tìm được.
      // Có thể có nhiều QR trong 1 ảnh → lấy cái đầu tiên (POS chỉ tạo 1).
      return barcodes.first.rawValue;
    } finally {
      // KHÔNG close _scanner — nó là singleton.
      // InputImage cũng tự dispose.
    }
  }

  /// Dispose singleton khi app shutdown (optional — Flutter tự GC).
  static Future<void> dispose() async {
    await _scanner.close();
  }
}
