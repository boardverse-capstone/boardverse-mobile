# ==============================================
# BoardVerse ProGuard Rules
# Giữ các classes cần thiết cho MLKit & mobile_scanner
# ==============================================

# ─── Google Play Core Library ─────────────────
# Flutter reference các classes này cho deferred components
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ─── MLKit Barcode Scanning ────────────────────
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }

# Giữ native methods của MLKit
-keepclasseswithmembernames class * {
    native <methods>;
}

# ─── Google Mobile Services (GMS) ─────────────
-keep class com.google.android.gms.** { *; }
-keep interface com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ─── ZXing (barcode library) ─────────────────
-keep class com.google.zxing.** { *; }
-keep interface com.google.zxing.** { *; }

# ─── mobile_scanner package ───────────────────
-keep class dev.steenbakker.mobile_scanner.** { *; }
-keep interface dev.steenbakker.mobile_scanner.** { *; }

# ─── Flutter specific ──────────────────────────
# Giữ Flutter engine classes
-keep class io.flutter.** { *; }
-keep interface io.flutter.** { *; }

# Giữ các plugin classes
-keep class io.flutter.plugins.** { *; }

# ==============================================
# Các rules mặc định của Flutter (tham khảo)
# ==============================================

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.googlemobileads.** { *; }

# Keep `Mirror` classes for reflection
-keep class dart.** { *; }
-keep class reflect.** { *; }

# Vu biz logic
-keep class com.duanqu.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ==============================================
# Generic rules
# ==============================================

# Keep generic signature of Call, Result (used in Flutter)
-keepattributes Signature

# Keep annotations for reflection
-keepattributes *Annotation*

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
