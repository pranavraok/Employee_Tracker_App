class AppConstants {
  // Admin Access
  static const String adminPassword = 'admin@2026';

  // Supabase Configuration
  static const String supabaseUrl = 'https://lbysdpwfavtszcdbxwac.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxieXNkcHdmYXZ0c3pjZGJ4d2FjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MDA5NzksImV4cCI6MjA4MzI3Njk3OX0.z8E4ASWR_nc-w6NvoveG8X_ROGEtJw1bH13ULolx0UM';

  // Tracking Settings
  static const int locationIntervalSeconds = 30;

  // Work Hours (24-hour format)
  static const int workStartHour = 9;  // 9 AM
  static const int workEndHour = 24;   // 6 PM

  // Work Days (1 = Monday, 7 = Sunday)
  static const List<int> workDays = [1, 2, 3, 4, 5, 6]; // Monday-Saturday

  // Sync Settings
  static const int syncBatchSize = 50;
  static const int syncRetryAttempts = 3;
  }

