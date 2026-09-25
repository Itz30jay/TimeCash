# TimeCash ⏳💰

[![CI/CD Pipeline](https://github.com/Itz30jay/TimeCash/actions/workflows/ci.yml/badge.svg)](https://github.com/Itz30jay/TimeCash/actions/workflows/ci.yml)
[![Flutter Version](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

**TimeCash** is a 100% offline-first Flutter mobile application built specifically for students. It combines a study timetable scheduler with strong reminders and an intuitive daily expense tracker.

> **Zero Cloud. Zero Ads. Complete Privacy.**  
> All study schedules, tasks, expenses, and budget data remain entirely on your device. The app operates reliably across airplane mode, low-power mode, force-close, and phone restarts.

---

## ✨ Features

### 📅 1. Study Timetable & Routine Planner
- **Daily & Weekly Views**: Interactive weekly horizontal timeline and detailed daily schedule.
- **Subject Filtering**: Single-tap filter chips (All, Study, Class, Revision, Assignment, Exam Prep, Exercise, Personal).
- **Date Picker Jump**: Quick calendar picker to jump to any date across past or upcoming weeks.
- **Task Management**: Subject tagging, priority levels (Normal, Important, Critical), start/end times, and notes.
- **Recurrence Support**: Flexible recurring schedules (Daily, Weekdays, Weekly, or Custom days of week).
- **Time Collision Detection**: Automatic overlap warnings when scheduling conflicting study sessions.
- **Session Progress Tracking**: Statuses include *Upcoming*, *Running* (with live countdown), *Completed*, and *Missed*.
- **Direct Focus Integration**: Launch Focus Mode timer directly from any task in Timetable or Home.

### 🔔 2. Strong & Exact Reminders (Offline)
- **High-Priority Channel**: Configured with `Importance.max` and `Priority.max` to break through silent mode.
- **Alarm-Style Reminders**: Uses Android exact alarm APIs (`exactAllowWhileIdle`) and `fullScreenIntent` for critical tasks.
- **Pre-Alert Warnings**: Optional notifications 5, 10, or 15 minutes before scheduled start time.
- **Action Buttons in Notification**:
  - `▶ Start Now` — Changes task status to Running.
  - `⏰ Snooze 10m` — Reschedules notification for 10 minutes later.
  - `✓ Done` — Marks task completed directly from notification tray.
- **Survives Phone Reboot**: Android `BOOT_COMPLETED` receiver automatically reschedules all future alarms upon device restart or timezone change.
- **Do Not Disturb (DND) Guidance**: Built-in instructions guiding users to whitelist TimeCash in device DND settings.

### ⏱️ 3. Study Focus & Pomodoro Mode
- **Distraction-Free Focus Timer**: Full-screen timer with circular progress ring.
- **Pomodoro Presets**: 25m Standard, 45m Deep Study, 60m Intensive, plus 5m and 15m Breaks.
- **Task Integration**: Link a scheduled study task to the focus timer; automatically completes the task upon timer expiry.
- **Early Completion**: Mark sessions done early with haptic feedback.
- **Motivational Student Quotes**: Encouraging prompts throughout focus sessions.

### 💳 4. Student Expense & Budget Tracker
- **Fast Logging**: Quick-add dialog with categories (Food, Travel, College, Recharge, Shopping, Entertainment, Health, Other).
- **Search & Category Filters**: Search expenses by note or keyword and filter instantly by category chips.
- **Payment Method Tagging**: Cash, UPI, Card, or Other.
- **Monthly Budget Limits**: Set overall monthly spending budget with real-time progress bars.
- **Budget Alerts**: Automatic warnings when spending reaches 80% or exceeds budget limit.
- **Spending Analytics**:
  - Category breakdown with interactive pie charts.
  - 30-day spending trends with line charts.
  - Month-over-month percentage comparisons.
  - Top category and most expensive day highlights.

### 📊 5. Reports & Analytics
- **Study Report**: Planned vs. completed tasks, completion rate, and weekly completion bar chart.
- **Financial Report**: Daily average spending, budget remaining, category bar charts, and intelligent automated financial insights.

### 💾 6. Data Privacy, Demo Data & Export
- **100% Offline SQLite Storage**: Relational schema indexed for fast local querying.
- **One-Tap Demo Data**: "Load Demo Student Data" option in Settings to instantly explore timetable and expenses.
- **CSV Data Export**: One-tap export of all expenses into a clean CSV file saved directly to device storage.
- **Clear All Data**: Complete data purge option in Settings for complete user control.

### 💖 7. Optional Developer Support
- **Support the Developer**: Transparent donation screen with preset amounts and direct UPI deep linking (`upi://pay`).
- **No In-App Purchases or Subscriptions**: Purely optional external UPI trigger.

---

## 🏗 Architecture & Tech Stack

```
APK/
├── android/                   # Native Android host configuration
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml      # Exact alarms, boot receiver, permissions
│   │   │   ├── kotlin/.../MainActivity.kt
│   │   │   └── res/                     # Vector icons, splash screen & styles
│   │   └── build.gradle                 # MinSdk 26 (Android 8.0+), Java 11 desugaring
│   ├── build.gradle
│   └── settings.gradle
├── lib/
│   ├── main.dart              # App entry point, Provider tree, Bottom navigation
│   ├── models/                # Immutable data models
│   │   ├── task.dart          # Task model with overlap & status logic
│   │   ├── expense.dart       # Expense model
│   │   └── budget.dart        # Category/Monthly budget model
│   ├── services/              # Offline core services
│   │   ├── database_service.dart     # SQLite database, queries, indexes
│   │   ├── notification_service.dart # Local notifications, alarms & boot listeners
│   │   ├── settings_service.dart     # SharedPreferences storage
│   │   └── export_service.dart       # CSV data generation and file export
│   ├── providers/             # State management (Provider pattern)
│   │   ├── task_provider.dart
│   │   ├── expense_provider.dart
│   │   └── settings_provider.dart
│   ├── screens/               # Mobile UI screens
│   │   ├── home_screen.dart          # Greeting, Next task countdown, today stats
│   │   ├── timetable_screen.dart     # Weekly selector, daily timeline
│   │   ├── expenses_screen.dart      # Budget bar, category charts, expense list
│   │   ├── reports_screen.dart       # Study & Money analytics tabs
│   │   ├── settings_screen.dart      # Permissions, theme, currency, CSV export
│   │   ├── onboarding_screen.dart    # Intro flow, permission request, budget setup
│   │   ├── add_edit_task_screen.dart # Task form with collision checks
│   │   ├── add_edit_expense_screen.dart # Expense logging form
│   │   ├── study_focus_screen.dart   # Pomodoro & study focus mode timer
│   │   └── donation_screen.dart      # Preset amounts & UPI launcher
│   ├── utils/
│   │   ├── constants.dart     # Categories, currencies, defaults
│   │   ├── helpers.dart       # Date, time, currency formatting
│   │   └── theme.dart         # Indigo-centered Light & Dark Material 3 theme
│   └── widgets/
│       └── common_widgets.dart# TaskCard, ExpenseCard, StatCard, ChartCard, etc.
└── test/                      # Unit & Widget test suite
```

---

## 🔒 Android Permissions Rationale

| Permission | Purpose |
|------------|---------|
| `POST_NOTIFICATIONS` | Send task reminders on Android 13+ (API 33+). |
| `SCHEDULE_EXACT_ALARM` | Fire study reminders at the exact scheduled minute. |
| `USE_EXACT_ALARM` | Exact alarms on Android 14+ for alarm/reminder apps. |
| `RECEIVE_BOOT_COMPLETED` | Reschedule all notifications after phone reboot. |
| `USE_FULL_SCREEN_INTENT` | Display full-screen heads-up reminder for critical study tasks. |
| `VIBRATE` & `WAKE_LOCK` | Ensure device vibrates and wakes screen at alarm time. |
| `WRITE_EXTERNAL_STORAGE` | Export CSV report to storage (Android 9 and below). |
| `INTERNET` | Open optional UPI / donation payment link in external app. |

---

## 🚀 Building & Running

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.5.0 or newer)
- [Android SDK](https://developer.android.com/) (minSdk 26, compileSdk 34+)
- Java JDK 11 or 17

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Tests
```bash
flutter test
```

### 3. Run on Connected Device / Emulator
```bash
flutter run
```

### 4. Build Release APK
To generate a standalone APK:
```bash
flutter build apk --release
```
The output APK file will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

### 5. Build Android App Bundle (for Google Play Store)
```bash
flutter build appbundle --release
```
The output AAB file will be located at:
`build/app/outputs/bundle/release/app-release.aab`

---

## 💡 Tips for Best Reminder Reliability

1. **Battery Optimization**: On devices running aggressive battery managers (Xiaomi/MIUI, OnePlus/OxygenOS, Samsung/OneUI), set TimeCash battery usage to **"Unrestricted"**.
2. **Do Not Disturb**: Allow TimeCash under **Settings → Sound & vibration → Do Not Disturb → Apps** so alarms can sound during focus hours.
3. **Exact Alarms**: Grant the "Alarms & Reminders" permission when prompted on Android 12+.

---

## 📄 License
This project is open-source under the MIT License.
