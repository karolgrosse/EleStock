# EleStock

EleStock is a shared workshop inventory for student racing teams. You scan a box and take parts, and every stock movement is recorded in a shared history. Items running low go on a shopping list and trigger a reminder. It works offline in basement workshops and event paddocks.

See [docs/PROJECT_CARD.md](docs/PROJECT_CARD.md) for the scope, [docs/DESIGN.md](docs/DESIGN.md) for how the app is built and why, and [docs/BACKLOG.md](docs/BACKLOG.md) for the planned issues.

## Run

```bash
flutter pub get
flutter run
```

Without Supabase keys the app uses built-in fake accounts. Log in with **`demo@elestock.dev`** / **`elestock`**.

To log in with your real team account (Supabase Auth):

1. Ask Grosse for `supabase.json` and put it in the project folder. It is gitignored: never commit it. Its shape is in [supabase.example.json](supabase.example.json).
2. Run with the keys:

   ```bash
   flutter run --dart-define-from-file=supabase.json
   ```

Accounts are created by the team lead in the Supabase dashboard. There is no sign-up in the app.

Before every PR, run `dart format .`, `flutter analyze` and `flutter test`. CI runs the same checks.

## Architecture

```
lib/
  main.dart                   composition root: creates the repositories, theme
  domain/models/              Item, StockTransaction, OrderEntry, Member (immutable, copyWith, ==)
  data/
    fake_inventory.dart       fake items, transactions and orders
    repositories/             interfaces + FakeInventoryRepository, FakeAuthRepository,
                              SupabaseAuthRepository
  ui/
    core/                     shared widgets: ErrorView, EmptyState, StockBadge, TransactionTile
    auth/                     login form, auth gate, session              (LoginViewModel, SessionViewModel)
    shell/                    NavigationBar on phones, NavigationRail from 840 px
    profile/                  member, theme and language, log out     (SettingsViewModel)
    inventory/                list, search, filter, master–detail     (InventoryViewModel)
    item_details/             stock, take / put back, item history    (ItemDetailsViewModel)
    item_form/                create and edit an item, validation     (ItemFormViewModel)
    scanner/                  manual id entry until the camera arrives (ScannerViewModel)
    history/                  every stock movement, newest first      (HistoryViewModel)
    shopping_list/            low-stock items, order and receive      (ShoppingListViewModel)
docs/                         project card, design notes, backlog, lab reports, screenshots
```

**Data flow.** Data flows one way, repository → view model → screen, and events flow back: a tap calls a view model method, which calls the repository. Screens never import `data/`. Only `main.dart` knows the fake implementation, so lab 3 can replace it with drift and Supabase without touching the screens.

**State management: provider + ChangeNotifier.** It is the approach from the course example, it needs one small package, and it has only three concepts to learn (`ChangeNotifier`, `context.watch`, `context.read`). That is enough for eight screens sharing a few repositories. Each view model holds a sealed state (loading, loaded or error) that the screen switches over. Shared state between screens goes through `ItemRepository.itemUpdates`: after a take on item details, the inventory list, the history and the shopping list update without a reload.

**Repositories** (`lib/data/repositories/`):

| Interface | Provides |
|-----------|----------|
| `ItemRepository` | all items, one item by id, creating and editing an item, and the `itemUpdates` stream that emits every changed item |
| `TransactionRepository` | the stock history (all of it or one item's), and recording a take, put back, restock or stock count, which also changes the item's stock |
| `OrderRepository` | orders of low-stock items: list them, place one, and receive one, which records a restock |
| `AuthRepository` | the logged-in member, a stream of sign-ins and sign-outs, signing in with email and password, and signing out |

`FakeInventoryRepository` implements the first three on one in-memory store, with a `delay` and a `failureRate` (0.0 never fails, 1.0 always fails). The app runs with a 20 % failure rate, so error states show up.

`AuthRepository` has two implementations: `SupabaseAuthRepository` (real accounts, used when `main.dart` gets Supabase keys) and `FakeAuthRepository` (demo accounts with the same `delay` and `failureRate`, used without keys and in tests).

The team rules for this structure are in [CLAUDE.md](CLAUDE.md).

## Team

| Member | Area |
|--------|------|
| Grosse | Login, profile and settings · auth, go_router, localization, CI and release |
| Weindich | Inventory, item form · master–detail layout, drift database |
| Koczorowska | Item details, scanner · QR scanning, stock logic |
| Szulik | History, shopping list · notifications, sync |

How we work (branches, PRs, reviews): [docs/WORKFLOW.md](docs/WORKFLOW.md).

## Status

Lab 1: the main page (inventory) and item details run with fake data.

Lab 2: layered architecture with view models and fake repositories. All 8 screens from the project card are built and reachable from the app shell: login, profile and settings, inventory, item details, item form, scanner, history and shopping list, with loading, empty and error states and tests. Login already uses Supabase Auth.
