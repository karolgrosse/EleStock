# EleStock

EleStock is a shared workshop inventory for student racing teams. You scan a box and take parts, and every stock movement is recorded in a shared history. Items running low go on a shopping list and trigger a reminder. It works offline in basement workshops and event paddocks.

See [docs/PROJECT_CARD.md](docs/PROJECT_CARD.md) for the scope, [docs/DESIGN.md](docs/DESIGN.md) for how the app is built and why, and [docs/BACKLOG.md](docs/BACKLOG.md) for the planned issues.

## Run

```bash
flutter pub get
flutter run
```

Before every PR, run `dart format .`, `flutter analyze` and `flutter test`. CI runs the same checks.

## Structure

```
lib/
  main.dart                     app and theme
  domain/models/                Item, StockTransaction (plain immutable Dart)
  data/                         fake data (lab 1); repositories and services later
  ui/core/                      shared widgets (StockBadge, TransactionTile, EmptyState)
  ui/inventory/                 main page (master–detail on wide screens) and item details
docs/                           project card, design notes, backlog, lab reports
```

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
