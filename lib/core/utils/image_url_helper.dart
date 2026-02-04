// ─────────────────────────────────────────────────────────────────────────────
// lib/core/utils/image_url_helper.dart
// Helper to fix image URLs for Android emulator
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ImageUrlHelper {
  ImageUrlHelper._();

  /// Fixes image URLs for Android emulator
  /// Replaces 127.0.0.1 with 10.0.2.2 for Android emulator
  /// Replaces localhost with 10.0.2.2 for Android emulator
  static String fixUrl(String? url) {
    if (url == null || url.isEmpty) return '';

    // No changes needed for web
    if (kIsWeb) return url;

    try {
      // For Android emulator, replace localhost/127.0.0.1 with 10.0.2.2
      if (Platform.isAndroid) {
        return url
            .replaceAll('http://127.0.0.1:', 'http://10.0.2.2:')
            .replaceAll('http://localhost:', 'http://10.0.2.2:')
            .replaceAll('https://127.0.0.1:', 'https://10.0.2.2:')
            .replaceAll('https://localhost:', 'https://10.0.2.2:');
      }
    } catch (_) {
      // Platform not available, return original URL
    }

    return url;
  }

  /// Constructs full image URL from storage path
  /// Example: "company/logo.jpg" → "http://10.0.2.2:8000/storage/company/logo.jpg"
  static String buildStorageUrl(String? path, String baseUrl) {
    if (path == null || path.isEmpty) return '';

    // If path is already a full URL, just fix it
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return fixUrl(path);
    }

    // Remove /api from baseUrl and add /storage
    final storageBaseUrl = baseUrl.replaceAll('/api', '') + '/storage/';
    final fullUrl = storageBaseUrl + path;

    return fixUrl(fullUrl);
  }
}

