class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hqfohglkxnkqquugzwaz.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhxZm9oZ2xreG5rcXF1dWd6d2F6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQxMjE3OTEsImV4cCI6MjEwOTY5Nzc5MX0.7qQvKGygIK__lt6c2y80-XyhXVWFIbe2E6EK_uYdCrs',
  );
  static const siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://easytvethub.com',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get searchIndexUrl => '$siteUrl/search-index.json';

  static String canonicalUrl(String path) {
    final normalizedSite = siteUrl.endsWith('/')
        ? siteUrl.substring(0, siteUrl.length - 1)
        : siteUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$normalizedSite$normalizedPath';
  }
}
