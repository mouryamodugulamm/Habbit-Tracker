# Clean Architecture — Habit Tracker

This document describes the layered architecture used in the app. Dependencies flow **inward**: outer layers depend on inner layers; inner layers know nothing about outer layers.

---

## Layer overview

```
┌─────────────────────────────────────────────────────────┐
│  PRESENTATION (UI, Riverpod, Screens, Widgets)           │  ← User-facing
├─────────────────────────────────────────────────────────┤
│  DATA (Repositories impl, DataSources, Models, Hive)    │  ← Implementation
├─────────────────────────────────────────────────────────┤
│  DOMAIN (Entities, Repository interfaces)                │  ← Business rules
├─────────────────────────────────────────────────────────┤
│  CORE (Theme, Constants, Errors, Utils)                 │  ← Shared foundation
└─────────────────────────────────────────────────────────┘
```

---

## 1. Core

**Path:** `lib/core/`

**Purpose:** Shared foundation used across the app. No business logic; no dependency on domain, data, or presentation.

**Contains:**
- **constants/** — App-wide values (e.g. storage keys, default durations, feature flags).
- **theme/** — `ThemeData`, colors, text styles (e.g. `AppTheme`).
- **errors/** — Base exceptions and failure types used by data/domain.
- **utils/** — Pure helpers, extensions, formatters (e.g. date/string extensions).

**Dependencies:** Flutter SDK only (and packages used for theme/utils, e.g. Google Fonts). No domain/data/presentation imports.

---

## 2. Domain

**Path:** `lib/domain/`

**Purpose:** Business rules and contracts. No Flutter UI, no Hive/HTTP, no Riverpod.

**Contains:**
- **entities/** — Plain Dart classes representing core concepts (e.g. `Habit`, `StreakResult`). Immutable, no serialization logic.
- **repositories/** — Abstract classes (interfaces) defining *what* operations the app needs (e.g. `HabitRepository`). No implementation details.
- **usecases/** — Single-responsibility operations (AddHabit, DeleteHabit, GetHabits, ToggleHabitCompletion, CalculateStreak). Depend only on repository interfaces and entities.

**Dependencies:** Only `core` (for shared types/errors if needed). Implementations live in **data**.

---

## 3. Data

**Path:** `lib/data/`

**Purpose:** Implementations of domain contracts and all I/O (local DB, notifications, etc.).

**Contains:**
- **datasources/** — Concrete I/O: local (e.g. Hive boxes), remote (if any), notification APIs. Return/accept raw or serializable data.
- **models/** — Serializable classes (e.g. Hive adapters, JSON DTOs). Map to/from **domain entities**.
- **repositories/** — Repository implementations that use datasources and models, and return **domain entities** to the rest of the app.

**Dependencies:** `domain` (entities + repository interfaces), `core`. Presentation must **not** import data implementations directly; it uses domain interfaces only (via Riverpod injection).

---

## 4. Presentation

**Path:** `lib/presentation/`

**Purpose:** Everything the user sees and interacts with. State and UI only.

**Contains:**
- **providers/** — Riverpod providers that depend on **domain** repository interfaces (injected from `main` or a provider override). Hold UI state and call repository methods.
- **screens/** — Full-screen widgets (pages).
- **widgets/** — Reusable UI pieces (buttons, cards, list items, calendar/chart wrappers).

**Dependencies:** `domain` (entities + repository interfaces), `core` (theme, constants). **No** direct imports of `data` (no `data/datasources`, `data/models`, or `data/repositories`). Data is accessed only via injected repository interfaces.

---

## Dependency rule (summary)

- **Core** ← used by domain, data, presentation.
- **Domain** ← used by data (implementations) and presentation (interfaces + entities).
- **Data** → implements domain; **never** imported by presentation.
- **Presentation** → uses domain + core; repository implementations are wired in `main.dart` (or test overrides).

---

## File layout (reference)

```
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── theme/
│   ├── errors/
│   └── utils/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

This structure keeps the app testable, scalable, and ready for production feature work.

---

## Initialization order (main.dart)

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `_initHive()` — Hive.initFlutter()
3. `_registerHiveAdapters()` — register all Hive TypeAdapters
4. `_initNotifications()` — flutter_local_notifications (when implemented)
5. `runApp(ProviderScope(child: HabitTrackerApp()))`
