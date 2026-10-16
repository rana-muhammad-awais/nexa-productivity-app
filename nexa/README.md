# Nexa — All-in-One Productivity App (Flutter/Android)

> Tasks · Notes · Expenses · Resources — one calm, offline-first experience.

A native Android port of the Nexa web app, implementing **all functionalities** from the product plan:

- **Tasks**: List/Kanban/Calendar views, natural-language quick-add, priorities, subtasks, drag-reorder, streaks
- **Notes**: Folders, tags, pin, Markdown editor with live preview, templates
- **Expenses**: Add income/expense with live auto-categorization, budgets with progress bars, visual reports (pie/line/bar charts)
- **Resources**: Document vault, subscription tracker with renewal alerts, inventory with low-stock alerts, contacts hub
- **Home Dashboard**: Greeting, today's progress ring, month spend, overdue/upcoming tasks, recent notes, renewal & low-stock alerts, streak badge
- **Global Search**: Search across tasks, notes, expenses, and resources from one bar
- **Settings**: Theme (system/light/dark), currency, biometric lock toggle, load sample data, export JSON/CSV, clear all data
- **Onboarding**: First-run welcome slides

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.22+ (Dart) |
| State management | flutter_riverpod |
| Persistence | shared_preferences (JSON blob, offline-first) |
| Charts | fl_chart |
| Markdown | flutter_markdown |
| Icons | lucide_icons |
| Font | Inter (google_fonts) |
| Notifications | flutter_local_notifications |
| Biometric lock | local_auth |
| Export/Share | share_plus |

## Prerequisites

- Flutter SDK 3.22+ ([install](https://docs.flutter.dev/get-started/install))
- Android SDK (API 21+)
- Java 17+ (bundled with Android Studio or standalone)

## Build & Run

```bash
cd nexa/

# 1. Install dependencies
flutter pub get

# 2. Run on connected device/emulator
flutter run

# 3. Or build APK
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Run tests
flutter test

# Static analysis
flutter analyze
```

## Project Structure

```
nexa/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── app.dart                         # MaterialApp, theme resolution
│   ├── core/
│   │   ├── theme.dart                    # Light/dark ColorSchemes (plan §4.2)
│   │   ├── constants.dart               # Categories, priorities, templates
│   │   └── utils.dart                    # NL parser, auto-categorize, formatting
│   ├── data/
│   │   ├── models.dart                   # Task, Note, Expense, Resource, AppData
│   │   └── app_store.dart               # Riverpod Notifier + localStorage persistence
│   ├── services/
│   │   ├── notifications.dart           # Local reminder engine
│   │   └── export.dart                   # JSON + CSV export via share sheet
│   ├── widgets/                          # Shared UI primitives
│   │   ├── bottom_nav.dart, fab.dart
│   │   ├── quick_menu.dart               # FAB context-aware add menu
│   │   ├── sheet.dart                    # Bottom sheet + button helpers
│   │   ├── empty_state.dart, progress_ring.dart
│   │   ├── tag_chip.dart, tiles.dart    # TaskTile, NoteTile, ExpenseTile, ResourceTile
│   │   └── nav_scaffold.dart            # Root shell (top bar + nav + FAB)
│   └── features/
│       ├── home/                         # Dashboard
│       ├── tasks/                        # List/kanban/calendar + NL quick-add + detail
│       ├── notes/                         # Folder view + templates + editor
│       ├── expenses/                     # 4 tabs: overview/transactions/budgets/reports
│       ├── resources/                    # 4 types: documents/subscriptions/inventory/contacts
│       ├── search/                        # Unified global search
│       ├── settings/                      # Theme, currency, biometric, export, sample data
│       └── onboarding/                    # First-run welcome
├── test/
│   └── utils_test.dart                   # 24 unit tests (NL parse, auto-categorize, formatting)
└── android/                              # Android platform shell
```

## Design Tokens

Matches plan §4.2 exactly:

| Element | Light | Dark |
|---|---|---|
| Background | `#FAFAFA` | `#121214` |
| Surface | `#FFFFFF` | `#1C1C1F` |
| Primary | `#5B5FEF` | `#818CF8` |
| Text | `#1A1A1E` | `#F5F5F7` |
| Success | `#22C55E` | `#4ADE80` |
| Danger | `#EF4444` | `#F87171` |

## What's Included vs. Future

### ✅ Implemented (this build)
- All Phase 1 MVP + Resources modules
- Local notifications reminder engine
- Biometric app lock (toggle in Settings)
- CSV export for expenses
- JSON full backup/export

### 🔲 Future (requires backend/infra — Phase 2+)
- Cloud sync (Supabase/Firebase)
- Auth (email, Google, Apple)
- FCM push notifications
- Home-screen widgets
- Handwriting/sketch notes
- Bill splitting / shared expenses
- Pro subscription tier
- Desktop/web app

The codebase is structured so these features can be added without refactoring.
