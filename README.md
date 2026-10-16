# Nexa – All-in-One Productivity Suite (Web & Flutter Mobile) 🚀📝

> Tasks · Notes · Expenses · Resources — one calm, unified, offline-first experience.

Nexa is an all-in-one personal productivity application combining task tracking, notes organization, personal expense budgeting, and resource vaults in a single cohesive workspace. Available as both a lightweight single-page web app and a native Flutter mobile app for Android.

## 🌟 Modules & Features

### 1. 📋 Tasks
- Multi-view organization: List, Kanban board, and Calendar views.
- Priorities, deadlines, subtasks, checklists, and completion streaks.
- Natural language quick-add for fast task creation.

### 2. 📝 Notes
- Folder-based organization and tag management.
- Full Markdown editor with live preview.
- Quick search, note pinning, and pre-built templates.

### 3. 💳 Expenses
- Income and expense tracking with real-time category breakdown.
- Budgeting with visual progress bars and overspend alerts.
- Visual chart reports (pie, line, and bar charts) powered by `fl_chart`.

### 4. 🗄️ Resources & Vault
- Secure personal document vault.
- Subscription manager with renewal alerts.
- Asset & home inventory tracker with low-stock warnings.
- Contacts hub for important personal connections.

### 5. 🔍 Unified Search & Dashboard
- Global search across all four modules from a single command bar.
- Daily greeting, habit streak badges, today's schedule, and financial snapshots.

## 🛠️ Architecture & Tech Stack

### Web App (`/`)
- Single-page application in Vanilla JavaScript, HTML5, and CSS3.
- Offline persistence with browser `localStorage`.
- No server required: double click `index.html` to run anywhere.

### Mobile App (`/nexa`)
- **Framework**: [Flutter](https://flutter.dev/) (Dart)
- **State Management**: `flutter_riverpod`
- **Charts**: `fl_chart`
- **Markdown**: `flutter_markdown`
- **Local Persistence**: `shared_preferences`
- **Security**: Biometric authentication via `local_auth`
- **Notifications**: `flutter_local_notifications`

## 🚀 Getting Started

### Running the Web Version
Simply open `index.html` directly in any modern browser.

### Running the Flutter Mobile Version
```bash
cd nexa
flutter pub get
flutter run
```

## 📄 License

This project is licensed under the MIT License.
