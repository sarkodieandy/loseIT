class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://inixrkdcipviqofuhgon.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImluaXhya2RjaXB2aXFvZnVoZ29uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTM0MTQsImV4cCI6MjA4NjQ4OTQxNH0.z3yVekj9rvcOW-SZSKC0cSQEkmh7roqq6T45SuPE6_4',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
