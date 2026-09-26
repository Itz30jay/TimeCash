/// Flowra - Offline Planner & Expense Tracker
/// App-wide constants and configuration.
library;

class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Flowra';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Offline planner & expense tracker for everyone — students, working professionals, and anyone managing their time and money.';
  static const String githubRepoUrl = 'https://github.com/Itz30jay/Flowra';
  static const String githubProfileUrl = 'https://github.com/Itz30jay';
  static const String instagramUrl =
      'https://www.instagram.com/jay_dev._._';
  static const String developerName = 'Jay (Itz30jay)';

  // Donation configuration
  static const String donationUpiId = 'jaykishandas30@oksbi';
  static const String donationUpiName = 'Flowra Developer';
  static const String donationPaymentLink = '';
  // Set to true when you configure a valid UPI ID or payment link
  static const bool isDonationEnabled = true;

  // Notification channel
  static const String studyAlertChannelId = 'study_alerts';
  static const String studyAlertChannelName = 'Alerts & Reminders';
  static const String studyAlertChannelDesc =
      'High-priority reminders for your schedule';

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
  static const String keyUserName = 'user_name';
  static const String keyUserRole = 'user_role';

  // User roles
  static const String roleStudent = 'Student';
  static const String roleProfessional = 'Working Professional';
  static const String roleOther = 'Other';
  static const List<String> userRoles = [
    roleStudent,
    roleProfessional,
    roleOther,
  ];

  // Task categories/subjects covering both work and study contexts
  static const List<String> taskSubjects = [
    'Work',
    'Study',
    'Meeting',
    'Class',
    'Assignment',
    'Revision',
    'Exam Prep',
    'Errand',
    'Exercise',
    'Health',
    'Family',
    'Personal',
    'Other',
  ];

  // Default subject lists lightly personalized by role
  static const List<String> studentSubjects = [
    'Study',
    'Class',
    'Assignment',
    'Revision',
    'Exam Prep',
    'Exercise',
    'Personal',
  ];

  static const List<String> professionalSubjects = [
    'Work',
    'Meeting',
    'Errand',
    'Exercise',
    'Health',
    'Personal',
    'Other',
  ];

  static List<String> getTaskSubjectsForRole(String? role) {
    if (role == roleStudent) {
      final set = studentSubjects.toSet();
      final others = taskSubjects.where((s) => !set.contains(s)).toList();
      return [...studentSubjects, ...others];
    } else if (role == roleProfessional) {
      final set = professionalSubjects.toSet();
      final others = taskSubjects.where((s) => !set.contains(s)).toList();
      return [...professionalSubjects, ...others];
    }
    return taskSubjects;
  }

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
