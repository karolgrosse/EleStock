# EleStock: notes for Claude

Shared rules for every team member's Claude. Four people build this app in parallel, each with their own assistant. These rules keep the pieces fitting together. If a task seems to need breaking one of them, say so and ask; don't silently work around it.

Background: [README.md](README.md) (structure, team), [docs/PROJECT_CARD.md](docs/PROJECT_CARD.md) (scope, screens), [docs/WORKFLOW.md](docs/WORKFLOW.md) (git rules), [docs/DESIGN.md](docs/DESIGN.md).

## Who owns what

| Member | Owns |
|--------|------|
| Grosse (A) | Login, Profile and settings · auth, go_router, EN/PL, CI and release |
| Weindich (B) | Inventory, Item form · master–detail layout, drift database, validation |
| Koczorowska (C) | Item details, Scanner · QR scanning, take / put back logic |
| Szulik (D) | History, Shopping list · notifications, sync |

Work inside your own feature folder. Shared files (`lib/main.dart`, `pubspec.yaml`, `lib/domain/`, `lib/data/repositories/*_repository.dart`, `lib/ui/core/`) change only in small, separate PRs. Mention those PRs in the team chat.

## Git

- Never commit to `main`. One issue → one branch (`feature/<issue>-<name>` or `fix/<issue>-<name>`) → one PR, approved by one other member.
- Commit messages: `feat: …`, `fix: …`, `test: …`, `docs: …`, `chore: …`, in the imperative.
- Before pushing, all three must be clean: `dart format .`, `flutter analyze`, `flutter test`.
- Never run `flutter pub add` without saying so in the PR description. Two people adding packages in parallel causes `pubspec.lock` conflicts.

## Architecture

Data flows one way: **repository → view model → screen**. Events flow back: tap → view model method → repository.

```
lib/
  main.dart                 composition root: the ONLY place that creates repositories
  domain/models/            immutable models (final fields, const constructor, copyWith, ==, hashCode)
  data/
    repositories/           interfaces (item_repository.dart, transaction_repository.dart, …)
                            and fake implementations (fake_inventory_repository.dart)
  ui/
    core/widgets/           shared widgets: ErrorView, EmptyState, StockBadge, TransactionTile, …
    <feature>/              <feature>_screen.dart + <feature>_view_model.dart (+ private widgets)
```

### Layer rules

- **Screens and widgets never import from `data/`.** View models may import the repository *interfaces*, never a `Fake…` class.
- **Only `main.dart` creates repositories** (tests use `test/helpers/repositories.dart`). Nobody writes `FakeInventoryRepository()` inside a widget or view model.
- **Models are immutable.** Change them with `copyWith`, and build new lists instead of calling `add`/`remove` on existing ones.
- **No fake data in screens.** Fake data lives in `lib/data/fake_inventory.dart` and is served only through the fake repository.

### State management: provider + ChangeNotifier

This is the only approach in the project. Don't introduce Riverpod, BLoC, GetX or similar.

Every feature with data follows the pattern in `lib/ui/item_details/item_details_view_model.dart`. Copy its shape:

- **The state is a sealed class** with exactly one of: `<Feature>Loading`, `<Feature>Loaded`, `<Feature>Error(message)`, plus feature-specific cases if needed (e.g. `ItemDetailsNotFound`). Screens `switch` over it exhaustively.
- **The view model `extends ChangeNotifier`**, takes repository interfaces in its constructor and has a `factory <Feature>ViewModel.of(BuildContext context, …)` that reads them with `context.read<…Repository>()`. Screens use only the `.of` factory, so they never import `data/`.
- **Loading starts at creation**, never in `build()`: `ChangeNotifierProvider(create: (context) => XViewModel.of(context)..load(), …)`.
- **Async work after `dispose` must not notify.** Keep a `_disposed` flag and check it before `notifyListeners()`.
- **In widgets, use `context.watch` only in `build`** and `context.read` in callbacks (`onPressed`, etc.).
- **`setState` in widgets is only for purely local UI state**, such as an expanded tile or a text field controller. Data that comes from a repository never goes there.

### Shared state between screens

When stock or an item changes, `ItemRepository.itemUpdates` (a `Stream<Item>`) emits the updated item. Every view model that shows items (inventory list, details, shopping list, …) subscribes to it in its constructor, replaces the matching item in its state, and cancels the subscription in `dispose()`. This is how "Take 4" on Item details updates the inventory list without a reload.

Any new repository method that changes an item (e.g. create or edit in the item form) must also emit on `itemUpdates`.

### Repositories

- Interfaces are `abstract interface class` in `lib/data/repositories/`. Each method has a doc comment saying what it returns and what it throws.
- **Adding** a method to an interface is fine: update `FakeInventoryRepository` in the same PR. **Renaming or removing** one breaks other people's work, so agree with the team first.
- Fake implementations take `delay` and `failureRate` (0.0 never fails, 1.0 always fails). `main.dart` uses a non-zero failure rate, so error states actually show up.
- Domain errors are typed exceptions next to the interface (e.g. `InsufficientStockException`). View models catch them and turn them into state or a result enum. They never leak to widgets.

## UI conventions

- Every screen with data shows **loading** (`CircularProgressIndicator`), **empty** (`EmptyState`) and **error with retry** (`ErrorView(message:, onRetry: vm.load)`). Reuse those widgets; don't write new ones.
- Material 3, colours from `Theme.of(context).colorScheme` only. No hard-coded colours.
- Long text gets `maxLines` and `overflow: TextOverflow.ellipsis`. Test layouts at phone width (390 px) and wide (≥ 840 px, master–detail).
- Accessibility: icon-only buttons get a `tooltip`, and information carried by colour also gets a `Semantics` label (see `StockBadge`).
- After an `await` in a widget, check `context.mounted` before using `context`, or read `ScaffoldMessenger.of(context)` before the `await`.
- User-facing text is English for now. Polish arrives in lab 4 through ARB files, so keep strings simple and avoid building sentences from fragments.

## Tests

- Mirror `lib/` under `test/` (`test/ui/<feature>/…_test.dart`).
- Use `test/helpers/repositories.dart`: `instantRepository()` (no delay, no failures, or `failureRate: 1` to always fail) and `withRepository(widget)` to provide it like `main.dart` does.
- **Every view model has at least one test with a failing repository.** To fail only one call, subclass `FakeInventoryRepository` and override that method (see `_SaveFailsRepository` in `test/ui/item_details/item_details_view_model_test.dart`).
- Widget tests cover the error state at least once per screen.
- Don't use `pumpAndSettle` while a spinner is visible, because it never settles. Use `tester.pump(const Duration(seconds: 1))`.
- Test names describe behaviour: `'shows an error when the repository fails'`.

## Lab status

Lab 2 (current): layered architecture, all 8 main screens fed by view models, loading/empty/error everywhere, a form with validation (item form), 8+ view-model unit tests, 3+ widget tests. Lab 3 replaces the fake repository with drift (local, source of truth) + Supabase sync. Keep everything behind the repository interfaces, so that swap touches only `data/` and `main.dart`.
