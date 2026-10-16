# Nexa — Project Memory

> Persistent context for AI and developers working on this project.

## Project Overview

**App name:** Nexa  
**Vision:** All-in-one productivity app & personal OS — Tasks, Notes, Expenses, Resources, and Focus Timer in a calm, glassmorphic, offline-first experience.  
**Plan source:** `all-in-one-productivity-app-plan.md`  
**Status:** Full Modern & Advanced Level Transformation Complete (v2.0)

## Tech Stack & Architecture

| Layer | Choice | Details |
|---|---|---|
| Platform | Flutter (Android, iOS, Web, Desktop) | Pure Dart codebase, native performance, cross-platform |
| Architecture | Feature-first folder structure | `lib/core/`, `lib/data/`, `lib/features/`, `lib/widgets/` |
| State Management | Flutter Riverpod (`AsyncNotifier`) | Reactive, immutable data flow, single source of truth |
| Storage | SharedPreferences (JSON persistence) | Offline-first, debounced writes (250ms), backup import/export |
| Design System | Glassmorphism & Modern iOS-style UI | Frosted backdrop filters, gradient borders, radial blobs, dark/light themes |
| Animations | Custom Animation System (`NexaAnim`) | Page slide/scale transitions, staggered list entry, count-up text, breathing pulse glow, spring physics, confetti bursts |
| Haptics | Semantic Haptic Feedback (`NexaHaptics`) | Tactile feedback for taps, swipes, completion, timer events |
| Charts | `fl_chart` | Interactive pie charts, curved line charts, gradient bar charts |
| Typography | Google Fonts (Inter) | Crisp, modern typography hierarchy |

## Codebase Architecture (`nexa/lib/`)

```
lib/
├── app.dart                   → MaterialApp configuration, theme mode, StoreGuard root
├── main.dart                  → App entry point, ProviderScope initialization
├── core/
│   ├── animations.dart        → Page transitions, StaggeredFadeIn, CountUpText, PulseGlow, AnimatedBlob, ShimmerBox
│   ├── haptics.dart           → NexaHaptics semantic tactile feedback system
│   ├── constants.dart          → Categories, priorities, recurrence, templates
│   ├── theme.dart              → NexaColors, light/dark themes, glass surface helpers
│   └── utils.js / utils.dart   → Date formatting, natural language parser, auto-categorize
├── data/
│   ├── models.dart            → Immutable models: UserPrefs, Task, SubTask, Note, Expense, Budget, Resource, FocusSession, AppData
│   └── app_store.dart         → AppStore (AsyncNotifier), persistence, CRUD, global search, computed stats
├── features/
│   ├── home/                  → Dashboard command center, animated greeting, streak, stat cards, alerts
│   ├── tasks/                 → List, Kanban, Calendar views, filter chips, swipe gestures, subtasks
│   ├── notes/                 → Grid/list views, folder chips, Markdown live editor, formatting toolbar, note colors
│   ├── expenses/              → Net balance card, spending overview, category budgets, interactive reports
│   ├── focus/                 → Pomodoro Focus Timer with gradient arc, breathing glow, session counters, focus stats
│   ├── resources/             → Document vault, subscription burn rate, inventory low-stock alerts, contacts
│   ├── onboarding/            → PageView swipe, animated orbs, personal name setup
│   ├── search/                → Global cross-module search with highlighted sections
│   └── settings/              → Profile card, theme switch, currency selector, biometric lock toggle, JSON/CSV export, clear data
├── widgets/
│   ├── glass.dart             → GlassCard, GradientBorderCard, GradientBackground, ProgressRing, GradientButton
│   ├── nav.dart               → Floating glass bottom bar, sliding active pill, rotating FAB, quick-add menu
│   ├── nav_scaffold.dart      → Root shell, animated tab switcher, profile avatar header, notification badges
│   ├── store_guard.dart       → AsyncValue unwrapper with shimmer skeleton loading & error retry
│   ├── tiles.dart             → TaskTile, NoteTile, ExpenseTile, ResourceTile with swipe actions
│   └── sheet.dart             → BottomSheet container wrapper
└── services/
    ├── export.dart            → Share JSON backup & CSV expense export
    └── notifications.dart     → Local notification scheduling
```

## Data Model (Implemented)

- **UserPrefs**: name, theme ('auto'|'light'|'dark'), currency, onboarded, streak, lastCompletionDate, biometricLock, focusDurationMinutes, shortBreakMinutes, longBreakMinutes
- **Task**: id, title, description, dueDate, dueTime, priority, tags, listId, isCompleted, subtasks, recurrence, linkedNoteId, order, createdAt, completedAt
- **SubTask**: id, title, done
- **Note**: id, title, body, folderId, tags, pinned, attachments, createdAt, updatedAt, color
- **Expense**: id, amount, type ('expense'|'income'), category, accountId, note, date, receiptImage, isRecurring, linkedTaskId, createdAt
- **Budget**: id, category, monthlyLimit, monthYear
- **Resource**: id, type (document|subscription|inventory|contact), name, details, fileUrl, renewalDate, tags, quantity, lowStockThreshold, createdAt
- **FocusSession**: id, type ('focus'|'short_break'|'long_break'), durationMinutes, linkedTaskId, startedAt, completedAt, completed
- **AppData**: Root state aggregating all collections

## Implemented Features (Full Modernization)

### ✅ Core & Navigation
- [x] Floating frosted glass bottom navigation bar with sliding gradient pill indicator & spring physics
- [x] Rotating plus-to-X morphing FAB with quick-add bottom sheet
- [x] Notification badge dots on tab icons (overdue tasks & upcoming subscription renewals)
- [x] Staggered fade-in list entry animations across all views
- [x] Tactile haptic feedback for every interaction (swipes, complete, timer ticks)

### ✅ 1. Home Dashboard Command Center
- [x] Personalized time-of-day greeting with user name & animated streak badge
- [x] Daily brief banner & urgent renewal/low-stock alert cards
- [x] Gradient border stat cards with animated CountUp text for monthly spend
- [x] Today's progress ring with animated stroke
- [x] Quick-launch Focus Timer shortcut card

### ✅ 2. Tasks Module
- [x] List, Kanban, and Calendar view switcher
- [x] Filter chips (All, Today, Upcoming, Overdue, Completed)
- [x] Swipe-to-complete (right) and swipe-to-delete (left) gestures with haptic feedback
- [x] Natural language smart task adder ("Pay electricity bill tomorrow 6pm #bills")
- [x] Inline subtasks with progress tracking & drag-and-drop reordering

### ✅ 3. Notes Module
- [x] Folder chips & instant live search
- [x] Rich Markdown editor with live preview toggle
- [x] Markdown formatting toolbar (Bold, Italic, Headings, Lists, Checkboxes, Code)
- [x] Note color accents (Blue, Purple, Green, Orange, Pink, Yellow)
- [x] Auto-save indicator & word/character counter
- [x] Meeting & journal note templates

### ✅ 4. Expenses & Financial Analytics
- [x] Net Month Balance card (Income minus Expenses) with visual trend indicators
- [x] Count-up animated currency numbers
- [x] Category spending pie chart, daily line chart, and income vs expense bar chart
- [x] Monthly category budget progress bars with danger thresholds
- [x] CSV export for spreadsheet analysis

### ✅ 5. Focus Timer (Pomodoro) — NEW
- [x] Pomodoro timer with custom-painted gradient arc & breathing pulse glow
- [x] Session modes: Focus (25m), Short Break (5m), Long Break (15m)
- [x] Play / Pause / Reset / Skip controls with haptic timer feedback
- [x] Session completion modal suggesting the next cycle phase
- [x] Focus stats: Today's focus minutes count & weekly session tracking
- [x] 4-dot pomodoro progress indicator

### ✅ 6. Resources Vault
- [x] Document reference tracker (passport, IDs, licenses)
- [x] Subscription manager with renewal date alerts & cost summary
- [x] Inventory tracker with low-stock warning threshold
- [x] Important contacts directory with quick phone/email

### ✅ 7. Onboarding & Settings
- [x] Onboarding PageView with swipe physics, animated gradient orbs, and personal name setup
- [x] Settings profile card with name editor
- [x] Full light, dark, and auto theme switcher
- [x] Currency picker (USD, EUR, GBP, PKR, INR, JPY, CAD, AUD, etc.)
- [x] Biometric lock toggle
- [x] JSON full backup export & data import capability

## Design Tokens

- **Dark Theme (Default):** Background `#0B0B12`, Card `#16161F`, Border `#26262F`, Text `#F5F5F7`
- **Light Theme:** Background `#F2F3F8`, Card `#FFFFFF`, Border `#E4E5EE`, Text `#1A1A2E`
- **Primary Gradient:** `#5B5FEF` → `#8B5CF6` → `#D946EF`
- **Focus Gradient:** `#8B5CF6` → `#D946EF`
- **Success Gradient:** `#22C55E` → `#14B8A6`
- **Warm Gradient:** `#F97316` → `#EF4444`

## How to Run

```bash
cd nexa
flutter pub get
flutter run
```

## Last Updated

2026-08-04 — Full Modernization (v2.0): Added custom animations system, haptics, sliding bottom nav, Pomodoro Focus Timer, Markdown editor toolbar, Net balance card, swipe gestures, filter chips, StoreGuard skeleton loading, and name personalization.
