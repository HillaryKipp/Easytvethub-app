class DriveLinkHelper {
  /// Converts Google Drive share links into direct download URLs.
  static String toDirectDownloadUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    final fileMatch = RegExp(
      r'drive\.google\.com/file/d/([a-zA-Z0-9_-]+)',
    ).firstMatch(trimmed);
    if (fileMatch != null) {
      return 'https://drive.google.com/uc?export=download&id=${fileMatch.group(1)}';
    }

    final openMatch = RegExp(
      r'drive\.google\.com/open\?id=([a-zA-Z0-9_-]+)',
    ).firstMatch(trimmed);
    if (openMatch != null) {
      return 'https://drive.google.com/uc?export=download&id=${openMatch.group(1)}';
    }

    final ucMatch = RegExp(
      r'drive\.google\.com/uc\?.*id=([a-zA-Z0-9_-]+)',
    ).firstMatch(trimmed);
    if (ucMatch != null) {
      return 'https://drive.google.com/uc?export=download&id=${ucMatch.group(1)}';
    }

    return trimmed;
  }

  /// Returns true if the URL points to Google Drive.
  static bool isGoogleDriveUrl(String url) {
    return url.toLowerCase().contains('drive.google.com');
  }

  /// Derives a friendly file extension label from a URL.
  static String getFileExtensionLabel(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf') || isGoogleDriveUrl(lower)) return 'PDF';
    if (lower.endsWith('.docx') || lower.endsWith('.doc')) return 'DOC';
    if (lower.endsWith('.xlsx') || lower.endsWith('.xls')) return 'XLS';
    if (lower.endsWith('.pptx') || lower.endsWith('.ppt')) return 'PPT';
    if (lower.endsWith('.zip')) return 'ZIP';
    return 'PDF';
  }

  /// Checks whether an HTTP Content-Type header indicates an HTML response
  /// (e.g. Google Drive virus-scan interstitial or sign-in page).
  static bool isHtmlContentType(String? contentType) {
    if (contentType == null) return false;
    final lower = contentType.toLowerCase();
    return lower.contains('text/html') || lower.contains('application/xhtml');
  }
}
