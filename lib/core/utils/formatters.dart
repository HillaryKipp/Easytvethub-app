import 'package:intl/intl.dart';

const _tvetAcronyms = {
  'ICT',
  'CDACC',
  'KNEC',
  'TVET',
  'CBET',
  'KNQF',
  'GIS',
  'HIV',
  'AIDS',
  'PPE',
  'OHS',
  'OSHA',
  'AI',
  'HR',
  'PR',
  'UI',
  'UX',
  'IT',
  'CAD',
  'CAM',
  'CNC',
  'PLC',
  'HVAC',
  'AC',
  'DC',
  'LAN',
  'WAN',
  'SQL',
  'HTML',
  'CSS',
  'API',
  'NITA',
  'KUCCPS',
  'HELB',
  'TVETA',
};

const _minorWords = {
  'a',
  'an',
  'and',
  'as',
  'at',
  'but',
  'by',
  'for',
  'from',
  'in',
  'into',
  'nor',
  'of',
  'on',
  'or',
  'per',
  'the',
  'to',
  'up',
  'via',
  'with',
};

/// Formats titles with Kenyan TVET acronym preservation and minor-word casing.
String toTitleCase(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return '';

  final words = trimmed.split(RegExp(r'\s+'));
  final buffer = <String>[];

  for (var i = 0; i < words.length; i++) {
    final word = words[i];
    if (word.isEmpty) continue;

    // Handle hyphenated or slash-separated segments (e.g., HIV/AIDS, UI/UX)
    if (word.contains('/') || word.contains('-')) {
      final separator = word.contains('/') ? '/' : '-';
      final parts = word.split(separator);
      final formattedParts = parts.asMap().entries.map((entry) {
        return _formatSingleWord(entry.value, isFirst: i == 0 && entry.key == 0);
      }).join(separator);
      buffer.add(formattedParts);
    } else {
      buffer.add(_formatSingleWord(word, isFirst: i == 0));
    }
  }

  return buffer.join(' ');
}

String _formatSingleWord(String raw, {required bool isFirst}) {
  if (raw.isEmpty) return raw;

  // Preserve surrounding punctuation like parentheses
  final match = RegExp(r'^([^a-zA-Z0-9]*)([a-zA-Z0-9]+)([^a-zA-Z0-9]*)$')
      .firstMatch(raw);
  if (match == null) return raw;

  final prefix = match.group(1) ?? '';
  final core = match.group(2) ?? '';
  final suffix = match.group(3) ?? '';

  final upper = core.toUpperCase();
  if (_tvetAcronyms.contains(upper)) {
    return '$prefix$upper$suffix';
  }

  // Roman numerals (I, II, III, IV, V, VI)
  if (RegExp(r'^(I|II|III|IV|V|VI)$', caseSensitive: false).hasMatch(core) &&
      core.length <= 3 &&
      !isFirst) {
    return '$prefix$upper$suffix';
  }

  final lower = core.toLowerCase();
  if (!isFirst && _minorWords.contains(lower)) {
    return '$prefix$lower$suffix';
  }

  final capitalized = lower[0].toUpperCase() + lower.substring(1);
  return '$prefix$capitalized$suffix';
}

/// Maps KNQF level numbers to KNEC tier names.
String getKnecTierName(int? level) {
  switch (level) {
    case 6:
      return 'Diploma';
    case 5:
      return 'Certificate';
    case 4:
      return 'Artisan';
    default:
      return level != null ? 'Level $level' : 'General';
  }
}

/// Normalizes department names so Home can merge identical departments
/// across Modular CDACC, Non-Modular CDACC, and KNEC when "All Courses" is active.
String normalizeDepartmentName(String name) {
  var cleaned = name.trim().toUpperCase();
  cleaned = cleaned.replaceAll(RegExp(r'\s+DEPARTMENT$'), '');
  cleaned = cleaned.replaceAll(RegExp(r'\bSCIENCES\b'), 'SCIENCE');
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
  return cleaned.trim();
}

/// Formats dates cleanly in Kenyan English style (e.g., 15 Mar 2025).
String formatDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('d MMM yyyy').format(date);
}

/// Short label for a programme slug (used on badges).
String programmeShortLabel(String slug, {String? fallbackName}) {
  final s = slug.toLowerCase();
  if (s.contains('modular')) return 'Modular CDACC';
  if (s.contains('knec')) return 'KNEC';
  if (s.contains('cdacc')) return 'CDACC';
  return fallbackName != null ? toTitleCase(fallbackName) : 'TVET';
}

/// Estimates reading time in minutes for a markdown body.
int estimateReadingTimeMinutes(String? content, {int? explicitMinutes}) {
  if (explicitMinutes != null && explicitMinutes > 0) return explicitMinutes;
  if (content == null || content.trim().isEmpty) return 3;
  final words = content.trim().split(RegExp(r'\s+')).length;
  return (words / 200).ceil().clamp(1, 60);
}
