/// TimeCash - Offline Study Planner & Expense Tracker
/// App-wide constants and configuration.
library;

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'TimeCash';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Offline study planner & expense tracker for students';
  static const String githubRepoUrl = 'https://github.com/Itz30jay/TimeCash';
  static const String githubProfileUrl = 'https://github.com/Itz30jay';
  static const String instagramUrl =
      'https://www.instagram.com/jay_dev._._';
  static const String developerName = 'Jay (Itz30jay)';

  // Donation configuration - change these to your own payment details
  static const String donationUpiId = 'developer@upi';
  static const String donationUpiName = 'TimeCash Developer';
  static const String donationPaymentLink = '';
  // Set to true when you configure a valid UPI ID or payment link
  static const bool isDonationEnabled = false;

  // Notification channel
  static const String studyAlertChannelId = 'study_alerts';
  static const String studyAlertChannelName = 'Study Alerts';
  static const String studyAlertChannelDesc =
      'High-priority reminders for your study schedule';

  // Default settings
  static const String defaultCurrency = '₹';
  static const String defaultCurrencyCode = 'INR';
  static const double defaultMonthlyBudget = 0.0;
  static const int defaultPreAlertMinutes = 5;

  // Shared preferences keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyCurrencySymbol = 'currency_symbol';
  static const String keyCurrencyCode = 'currency_code';
  static const String keyMonthlyBudget = 'monthly_budget';
  static const String keyThemeMode = 'theme_mode';
  static const String keyPreAlertEnabled = 'pre_alert_enabled';
  static const String keyPreAlertMinutes = 'pre_alert_minutes';
  static const String keyShowNextTaskNotification = 'show_next_task_notif';

  // Task categories/subjects
  static const List<String> taskSubjects = [
    'Study',
    'Revision',
    'Class',
    'Assignment',
    'Exam Prep',
    'Exercise',
    'Personal',
  ];

  // Task priorities
  static const List<String> taskPriorities = ['Normal', 'Important', 'Critical'];

  // Task repeat types
  static const List<String> repeatTypes = [
    'Once',
    'Daily',
    'Weekdays',
    'Weekly',
    'Custom',
  ];

  // Notification types
  static const List<String> notificationTypes = [
    'Silent popup',
    'Sound + vibration',
    'Alarm-style reminder',
  ];

  // Task statuses
  static const String statusUpcoming = 'Upcoming';
  static const String statusRunning = 'Running';
  static const String statusCompleted = 'Completed';
  static const String statusMissed = 'Missed';
  static const String statusSkipped = 'Skipped';

  // Expense categories
  static const List<String> expenseCategories = [
    'Food',
    'Travel',
    'College',
    'Recharge / Internet',
    'Shopping',
    'Entertainment',
    'Health',
    'Other',
  ];

  // Payment methods
  static const List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Card',
    'Other',
  ];

  // Currency options
  static const Map<String, String> currencies = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  // Donation preset amounts
  static const List<int> donationPresets = [10, 20, 50, 100];
}
