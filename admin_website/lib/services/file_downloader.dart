// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class FileDownloader {
  static void downloadBytes(
    List<int> bytes,
    String fileName, {
    String mimeType = 'application/octet-stream',
  }) {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  static void downloadString(
    String content,
    String fileName, {
    String mimeType = 'text/csv;charset=utf-8',
  }) {
    if (kIsWeb) {
      // Prepend BOM for Excel to properly handle UTF-8
      final bomContent = '\uFEFF$content';
      final blob = html.Blob([bomContent], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  static void openUrl(String url) {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    }
  }
}
