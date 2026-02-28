# Code Review — Habit Tracker

Senior mobile engineer review: performance, refactoring, code smells, testing, folder cleanup, and scalability.

---

## 1. Performance improvements

### 1.1 Avoid full list reload on every mutation (high impact)

**Issue:** `loadHabits()` is called after every add, delete, and toggle. That refetches the entire list and re-runs `_rescheduleRemindersIfNeeded()` (N schedule calls). For toggle in particular, the list is already in memory; only one habit changed.

**Suggestion:**
- **Optimistic updates:** For toggle, update state in place: find the habit by id, apply the toggle logic to a copy, replace in the list, set `state = state.copyWith(habits: AsyncValue.data(newList))`. Then call the use case in the background; on failure, revert and show error.
- Or at minimum: after toggle, only re-fetch instead of also re-scheduling every habit’s reminder. E.g. split `loadHabits()` into “fetch list” and “reschedule reminders”, and call reschedule only from the initial load (or when add/delete), not on toggle.

### 1.2 Streak computation and `streakForHabitProvider` (medium impact)

**Issue:** `streakForHabitProvider(habitId)` is a family provider. When the habits list updates, every visible `streakForHabitProvider(habitId)` recomputes. `CalculateStreak.execute()` does sorting and iteration. With many habits on screen this is repeated per habit.

**Suggestion:**
- Cache streak results per habit id in a single provider that holds `Map<String, StreakResult>`, derived once from the current list. UI reads from that map. One computation pass per list change instead of N.
- Or keep the family but ensure `CalculateStreak.execute` is cheap (it already is; just be aware if the list or logic grows).

### 1.3 HabitDetailScreen: recompute completedSet and percentage every build

**Issue:** `completedSet` and `completionPercentageLastDays(habit, 30)` are computed in `_buildContent` on every build.

**Suggestion:** Memoize or move to a derived provider / helper that only recomputes when `habit` (or `habit.completedDates`) changes. For a single habit screen the cost is low; good habit for scalability.

### 1.4 List view

**Issue:** `SliverList` with `SliverChildBuilderDelegate` is already lazy; good. No obvious over-fetch or large list issues.

**Suggestion:** If the list ever grows large (hundreds of items), consider `ListView.builder` semantics and ensure Hive isn’t loading the whole box into memory at once. Currently `getAll()` does `box.values.toList()` — for very large datasets, consider pagination or streaming.

---

## 2. Refactoring opportunities

### 2.1 Invert notification dependency (presentation → domain)

**Issue:** `HabitNotifier` (presentation) depends on `NotificationService` (data). Clean Architecture prefers presentation to depend only on domain; infrastructure (notifications) should be behind an abstraction.

**Suggestion:**
- Add in **domain:** `abstract class HabitReminderScheduler { Future<void> scheduleDaily(String habitId, String name, int minutesSinceMidnight); Future<void> cancel(String habitId); }`
- **Data:** Implement it with `NotificationService` (or a thin wrapper).
- **Presentation:** Notifier depends on `HabitReminderScheduler?` (injected). Main or providers wire the implementation. Tests can inject a no-op or mock.

### 2.2 Provider wiring and “presentation” importing data

**Issue:** `habit_providers.dart` imports data (datasources, repository impl, notification service). The doc says “presentation must not import data.”

**Suggestion:**
- Treat `habit_providers.dart` as part of the **composition root** (e.g. move to `lib/app/` or `lib/di/`), not “presentation.” Then presentation = screens + widgets + state (notifier, state classes); they only depend on domain + core. Providers in `app/` or `di/` depend on data and domain and wire everything.
- Or explicitly document that “provider wiring” is the exception and lives in presentation for simplicity, and accept the dependency.

### 2.3 Extract “completion percentage” to domain

**Issue:** `completionPercentageLastDays(Habit habit, int days)` is a static method on `HabitDetailScreen`. It’s pure logic and belongs in domain.

**Suggestion:** Move to a small use case (e.g. `GetCompletionPercentage`) or a static/extension on `Habit`, e.g. `Habit.completionPercentageLastDays(int days)`. Reuse from detail screen and any future stats UI. Easier to unit test.

### 2.4 Centralize navigation

**Issue:** `Navigator.of(context).push(MaterialPageRoute(...))` and direct screen constructors are repeated in HomeScreen and HabitCard.

**Suggestion:** Introduce a simple router (e.g. `AppRouter` with `static void toAddHabit(BuildContext c)`, `toHabitDetail(c, habitId)`). Later you can replace with `go_router` or `auto_route` for deep links and a single place for routes.

---

## 3. Code smell fixes

### 3.1 Habit.copyWith cannot clear reminder

**Issue:** `reminderMinutesSinceMidnight: reminderMinutesSinceMidnight ?? this.reminderMinutesSinceMidnight` means you can’t set the reminder to `null` (clear reminder) via copyWith.

**Suggestion:** Use a sentinel or an optional wrapper (e.g. `Optional<int?>.of(null)`), or a separate `copyWithReminderCleared()`. Common pattern: `copyWith({int? reminderMinutesSinceMidnight, bool clearReminder = false})` and if `clearReminder` then set to null.

### 3.2 Silent failure in main

**Issue:** `_initNotifications()` catches all exceptions and returns `null`. No logging; no feedback. If timezone or plugin init fails, the app continues with no reminders and the user doesn’t know why.

**Suggestion:** At minimum log the error (`debugPrint` or a logger). Consider a non-fatal crash report or a one-time “Reminders unavailable” snackbar/dialog so the user knows.

### 3.3 NotificationService timezone fallback

**Issue:** `catch (_)` when getting local timezone then fallback to UTC. Silent and can cause reminders at wrong times for users in other zones.

**Suggestion:** Log the failure and consider a user-visible “Using default timezone” or retry. Prefer `flutter_timezone` handling so UTC is a last resort and is explicit in logs.

### 3.4 Magic numbers

**Issue:** `0x7FFFFFFF` for notification id; `30` for completion percentage days; `100` for max name length in AddHabitScreen.

**Suggestion:** Move to `AppConstants` or named constants (e.g. `NotificationService.maxNotificationId`, `HabitDetailScreen.defaultCompletionDays`, `AddHabitScreen.maxNameLength` already exists — good). Improves readability and future tuning.

### 3.5 Duplicate “Today’s progress” logic

**Issue:** “Completed today” is computed in HomeScreen and in `HabitCard.isCompletedToday()`. Logic is simple but duplicated.

**Suggestion:** One place only: e.g. extension on `Habit` like `bool get isCompletedToday` using `Habit.toDate(DateTime.now())`, and use it from both HomeScreen (for count) and HabitCard.

---

## 4. Testing strategy

### 4.1 Current state

- Single widget test: pumps app, checks app bar title and FAB. Does **not** override providers, so when the first frame runs, `loadHabits()` is invoked and tries to use Hive — but Hive was never initialized (main() wasn’t run). Test may be flaky or fail depending on timing.

### 4.2 Recommendations

**Unit tests (high priority):**
- **Domain**
  - `CalculateStreak`: test empty list, single day, consecutive days, gap > 1, same-day duplicates, longest vs current.
  - `Habit.toDate`, `copyWith`, equality/hashCode.
  - `ToggleHabitCompletion` logic (mock repo): add date, remove date, same day dedup.
- **Data**
  - `HabitModel.fromEntity` / `toEntity` round-trip, including `reminderMinutesSinceMidnight`.
  - Repository impl: mock datasource, verify get/add/update/delete and entity mapping.

**Notifier tests (high value):**
- Override use cases with fakes. Call `loadHabits()`, `addHabit()`, `deleteHabit()`, `toggleCompletion()` and assert on `state.habits` (loading → data/error).
- Verify that when `notificationService` is null, add/delete don’t throw and still update state.

**Widget / integration:**
- Override `habitNotifierProvider` (or repository) with a stub that returns a fixed list so the widget test doesn’t touch Hive. Then test empty state, list with one habit, tap to detail, FAB opens add screen.
- Optional: integration test that runs main(), opens box, adds a habit, reopens app and asserts persistence (slower, more brittle).

**Test layout suggestion:**
- `test/domain/` — use case and entity tests.
- `test/data/` — repository and model tests.
- `test/presentation/` or `test/notifier/` — HabitNotifier tests.
- Keep `test/widget_test.dart` but make it provider-override based so it’s deterministic.

---

## 5. Folder cleanup

### 5.1 Empty or redundant directories

- **`lib/core/services/`** — Empty (NotificationService moved to data). Remove the folder or add a README if you plan to put shared (non-data) services here.
- **`lib/core/utils/`** — Only `.gitkeep`. Either add your first util (e.g. date/string formatters) or leave as-is for future use; no action required.

### 5.2 .gitkeep

- Any directory that now has real Dart files no longer needs `.gitkeep` for Git to track the folder; Git tracks files. You can remove `.gitkeep` from `lib/domain/entities`, `lib/domain/repositories`, `lib/data/datasources`, etc., if those dirs already contain at least one file. Keeps the tree clean.

### 5.3 Barrel files

- `core/core.dart`, `domain/domain.dart`, `data/data.dart`, `presentation/providers/providers.dart` are good. Ensure `data/data.dart` doesn’t export generated files (e.g. `habit_model.g.dart`) if that could pull in generated code where not needed; currently you export `habit_model.dart` which has a part, so that’s fine.

---

## 6. Scalability improvements

### 6.1 Feature-based structure (optional)

- If you add more features (e.g. settings, onboarding, analytics), consider grouping by feature: `lib/features/habits/` (domain entities + use cases for habits), `lib/features/habits/data/`, `lib/features/habits/presentation/` and a shared `lib/core/`, `lib/shared/`. Not required at current size but helps when the app grows.

### 6.2 Routing and deep links

- Introduce a router (e.g. `go_router`) and route names: `/`, `/habits/add`, `/habits/:id`. Enables deep links and a single place for “where can the app go.” Helps with analytics and restoration.

### 6.3 Error types and user messages

- Today errors are generic (“Something went wrong” + exception toString). Introduce a small `AppError` or `Failure` type in core (e.g. `StorageFailure`, `PermissionDenied`) and map exceptions in the data layer to these. Presentation can show user-friendly messages per type and optionally report raw errors.

### 6.4 Logging and crash reporting

- Add a simple logger (e.g. `logger` package or a one-line wrapper around `debugPrint`/`developer.log`) and use it in catch blocks and critical paths. Later plug in crash reporting (e.g. Firebase Crashlytics) in the same places.

### 6.5 Configuration and flavors

- Move config (e.g. “enable notifications”, API base URLs if you add backend) to a small config class or env (e.g. `--dart-define`). Prepares for dev/staging/prod and feature flags.

---

## 7. Priority summary

| Priority | Area | Action |
|----------|------|--------|
| P0 | Testing | Override providers in widget test so it doesn’t rely on Hive; add unit tests for CalculateStreak and notifier. |
| P0 | Code smell | Log (or surface) notification init failures; fix copyWith so reminder can be cleared. |
| P1 | Performance | Avoid full reload + full reschedule on every toggle; consider optimistic toggle. |
| P1 | Refactor | Move completion percentage to domain; consider HabitReminderScheduler abstraction. |
| P2 | Scalability | Introduce router; consider feature folders when adding next feature. |
| P2 | Cleanup | Remove empty `core/services`; remove redundant .gitkeep; centralize magic numbers. |

---

## 8. What’s already in good shape

- Clear layering (core, domain, data, presentation) and ARCHITECTURE.md.
- Use cases are single-purpose and domain-focused.
- Riverpod usage is consistent; state is centralized in HabitNotifier.
- Design system (theme, spacing, text styles) is consistent.
- Hive and notifications are initialized in main with a clear order.
- No business logic in UI; screens only dispatch and display.

This gives a solid base; the items above will harden production readiness, testability, and maintainability as the app grows.
