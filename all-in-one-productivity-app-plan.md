# "Nexa" — All-in-One Productivity App
### Complete Product & Design Plan
*(To-Do • Notes • Expense Management • Resource Management • Daily Life OS)*

> Name "Nexa" is a placeholder — easy to rebrand. The plan below is written so any module can be built independently or together.

---

## 1. Vision & Positioning

**One-line pitch:** A single, beautifully designed app that replaces your to-do app, notes app, budget tracker, and file/resource organizer — so your daily life isn't scattered across five different apps.

**Core principles:**
- **One home, many tasks** — everything accessible within 2 taps from the home screen.
- **Fast capture** — adding a task, note, or expense should take under 5 seconds.
- **Beautiful, calm design** — not cluttered, not corporate; feels like a premium 2026 app (think Things 3 / Notion / Linear aesthetic, not a legacy enterprise tool).
- **Works offline first** — daily tools must never depend on internet.
- **Smart, not noisy** — gentle intelligence (auto-categorization, smart reminders) without being intrusive.

**Target users:** Students, freelancers, professionals, small business owners, families — anyone who wants to manage tasks, notes, money, and personal resources in one place instead of juggling apps.

---

## 2. Core Modules

### 2.1 To-Do / Tasks
- Quick-add bar (natural language: "Pay rent tomorrow 6pm #bills")
- Tasks, subtasks, checklists
- Due dates, times, recurring tasks (daily/weekly/custom)
- Priority levels (color-coded: Low/Med/High/Urgent)
- Tags/labels + custom lists ("Work", "Home", "Groceries")
- Kanban view + List view + Calendar view toggle
- Drag-and-drop reordering
- Reminders/notifications (push + in-app)
- Progress tracking (daily completion %, streaks)

### 2.2 Notes
- Rich text editor (bold, headings, checklists, bullet/numbered lists)
- Folders + nested subfolders + tags
- Quick capture widget (voice-to-text supported)
- Pin important notes to top
- Attach images, files, links inside notes
- Handwriting/sketch support (for tablet/stylus users) — Phase 2
- Full-text search across all notes
- Note templates (meeting notes, journal entry, recipe, etc.)

### 2.3 Expense Management
- Add expense/income in 2 taps (amount, category, note, date)
- Auto-categorization (Food, Transport, Bills, Shopping, etc.) with manual override
- Multiple accounts/wallets (Cash, Bank, Credit Card)
- Recurring expenses (rent, subscriptions) with auto-reminders before due date
- Monthly budget setting per category with progress bars
- Visual reports: pie chart (spend by category), line chart (spend over time), bar chart (income vs expense)
- Export to CSV/PDF for record-keeping
- Multi-currency support
- Bill splitting / shared expense tracking (Phase 2)

### 2.4 Resource Management
*("Resources" = important files, documents, and reference info a person needs to manage — IDs, warranties, subscriptions, passwords vault, inventory, contacts of importance.)*
- Document vault: store scanned copies of ID cards, certificates, warranties (PDF/image)
- Subscription tracker: track all recurring subscriptions (Netflix, gym, software) with renewal alerts
- Inventory tracker: for small business/home — track items, quantities, low-stock alerts
- Important contacts/links hub
- Secure notes/password vault (encrypted, biometric-locked) — optional module
- Tag & search across all stored resources

### 2.5 Supporting Features (glue that ties modules together)
- **Unified Home Dashboard** — today's tasks, recent notes, this month's spend snapshot, upcoming renewals — all in one glanceable screen
- **Global Search** — search tasks, notes, expenses, and resources from one search bar
- **Calendar View** — tasks, reminders, and bill due-dates overlaid on one calendar
- **Smart Reminders** — one unified notification engine for tasks, bills, and subscription renewals
- **Quick Actions Widget** (home-screen widget & lock-screen shortcut) — add task/note/expense instantly
- **Cross-module linking** — attach a note to a task, attach a receipt image to an expense, link a resource to a task

---

## 3. Information Architecture (Navigation)

```
Bottom Navigation (5 tabs):
 🏠 Home        → Dashboard: today's tasks, notes preview, spend summary, alerts
 ✅ Tasks       → List/Kanban/Calendar toggle
 🗒️ Notes       → Folder view + search
 💰 Expenses    → Overview, Add, Reports, Budgets
 📁 Resources   → Vault, Subscriptions, Inventory

Floating "+" Action Button (context-aware):
 → On Home: shows menu (Add Task / Add Note / Add Expense / Add Resource)
 → On each module: directly adds that item type

Top-right: Global search icon + Settings (theme toggle, account, backup)
```

---

## 4. Design System

### 4.1 Visual Style
- **Style direction:** Minimal, soft-modern UI — rounded corners (16–20px radius), soft shadows, generous white space, subtle micro-animations (like Linear/Notion/Things 3).
- **Typography:** A clean geometric sans-serif (e.g., Inter, SF Pro, or Poppins) — one font family, 3 weights (Regular/Medium/Semibold).
- **Iconography:** Consistent line-icon set (e.g., Lucide/Phosphor icons) — same stroke width throughout.
- **Motion:** Subtle spring animations on task completion (checkmark bounce), swipe gestures for delete/archive, smooth screen transitions (250–300ms ease).

### 4.2 Light & Dark Theme

**Light Theme**
| Element | Color |
|---|---|
| Background | `#FAFAFA` |
| Surface/Card | `#FFFFFF` |
| Primary Accent | `#5B5FEF` (indigo/violet) |
| Secondary Accent | `#22C55E` (success green) |
| Text Primary | `#1A1A1E` |
| Text Secondary | `#6B7280` |
| Border/Divider | `#E5E7EB` |
| Danger/Overdue | `#EF4444` |

**Dark Theme**
| Element | Color |
|---|---|
| Background | `#121214` |
| Surface/Card | `#1C1C1F` |
| Primary Accent | `#818CF8` (softer indigo for dark bg) |
| Secondary Accent | `#4ADE80` |
| Text Primary | `#F5F5F7` |
| Text Secondary | `#9CA3AF` |
| Border/Divider | `#2C2C30` |
| Danger/Overdue | `#F87171` |

- Auto theme switch based on system setting + manual override toggle in Settings.
- Category colors (for tasks/expenses tags) stay vivid and consistent across both themes (e.g., Food = orange, Bills = red, Work = blue) so users build color memory.

### 4.3 Key UI Patterns
- **Cards** for tasks/notes/expenses with swipe actions (swipe right = complete/archive, swipe left = delete/edit)
- **Bottom sheets** for quick-add forms (not full-page navigation) — keeps flow fast
- **Empty states** with friendly illustrations + one-tap "add your first..." prompts
- **Progress rings/bars** for budgets and daily task completion
- **Skeleton loaders** instead of spinners for perceived speed

---

## 5. Suggested Tech Stack

| Layer | Recommendation | Why |
|---|---|---|
| Frontend (cross-platform) | **Flutter** (or React Native) | One codebase → iOS + Android + optional desktop/web |
| State management | Riverpod (Flutter) / Redux Toolkit (RN) | Predictable, scalable |
| Local database | **SQLite (via Drift/Isar)** or Realm | Offline-first, fast |
| Backend/Sync | **Supabase** or Firebase | Auth, cloud sync, realtime, storage for files/images |
| Auth | Email, Google, Apple Sign-In, biometric app-lock | Frictionless + secure |
| Notifications | Firebase Cloud Messaging + local notifications | Reminders work even offline |
| Charts | fl_chart (Flutter) / Victory or Recharts (RN/web) | For expense reports |
| File storage | Supabase Storage / Firebase Storage (encrypted for vault) | For resource documents |

**Offline-first architecture:** all modules write to local DB first (instant UI response), then sync to cloud in background when online. Conflict resolution via last-write-wins + timestamps, or optional manual merge for notes.

---

## 6. Data Model (High-Level)

```
User { id, name, email, theme_pref, currency_pref }

Task { id, user_id, title, description, due_date, priority,
       recurrence_rule, list_id, tags[], is_completed, subtasks[] }

Note { id, user_id, title, body(rich_text), folder_id, tags[],
       pinned, attachments[], created_at, updated_at }

Expense { id, user_id, amount, type(income/expense), category,
          account_id, note, date, receipt_image, is_recurring }

Budget { id, user_id, category, monthly_limit, month_year }

Resource { id, user_id, type(document/subscription/inventory/contact),
           name, details(json), file_url, renewal_date, tags[] }

Reminder { id, linked_type, linked_id, remind_at, is_sent }
```

---

## 7. Smart / Differentiating Features (what makes it feel "amazing")

1. **Natural language quick-add** — type "Team meeting Friday 3pm" → auto-parses date/time.
2. **Unified daily brief** — a morning summary notification: "3 tasks due today, ₹2,400 spent this week, Netflix renews in 2 days."
3. **Smart linking** — attach a note or receipt directly to a task or expense.
4. **Auto-categorization** for expenses using merchant/keyword pattern matching.
5. **Streaks & gentle gamification** — task completion streak, "no-spend day" badges (optional, can be toggled off for users who dislike gamification).
6. **One search bar, everything** — search across tasks, notes, expenses, resources at once.
7. **Home-screen widgets** — today's tasks + quick balance at a glance without opening the app.

---

## 8. Monetization (optional, if this is a commercial product)

**Freemium model:**
- Free tier: unlimited tasks/notes, basic expense tracking, 1 budget category, limited resource vault storage (e.g., 50MB)
- **Pro tier** (monthly/yearly subscription or one-time unlock): unlimited budgets & categories, advanced reports, unlimited vault storage, cross-device cloud sync, custom themes, recurring bill AI suggestions, data export.

---

## 9. Non-Functional Requirements

- **Performance:** app cold-start under 1.5s; list scrolling at 60fps even with 1000+ items.
- **Offline-first:** full functionality without internet; sync resumes automatically.
- **Security:** biometric app lock, encrypted local DB for sensitive data (resource vault/passwords), encrypted cloud storage.
- **Backup:** automatic daily local backup + manual "export all data" option (JSON/CSV).
- **Accessibility:** support system font scaling, screen-reader labels, sufficient color contrast in both themes (WCAG AA minimum).
- **Cross-device sync:** changes on phone reflect on tablet/desktop within seconds when online.

---

## 10. Build Roadmap (Phased)

**Phase 1 — MVP (8–10 weeks)**
- To-Do module (full) + Notes module (basic) + Expense module (basic add/view/report)
- Light & dark theme, onboarding, local storage only (no cloud yet)
- Home dashboard combining all three

**Phase 2 — Sync & Resources (6–8 weeks)**
- Cloud sync + accounts/login
- Resource management module (vault + subscriptions)
- Budgets, recurring expenses, notifications/reminders engine
- Home-screen widgets

**Phase 3 — Polish & Intelligence (6+ weeks)**
- Natural language quick-add
- Smart categorization, cross-module linking
- Advanced reports & data export
- Password/secure vault, inventory tracking
- Pro subscription tier + payments

**Phase 4 — Expansion**
- Desktop/web app
- Shared/family accounts (shared budgets, shared task lists)
- Bill-splitting, calendar integrations (Google Calendar sync)

---

## 11. Next Steps

Once you've reviewed this, useful next steps I can help with:
- Wireframes/mockups of the key screens (Home, Task list, Add-expense sheet, Notes editor) as visual designs
- A clickable prototype (HTML/React) of the core flows
- Database schema as an actual SQL file
- A detailed screen-by-screen UI spec

Let me know which module you'd like to go deeper on first, and if you have questions about anything above.
