# Backlog: issues to create on GitHub

Create the milestones **Lab 1**, **Lab 2**, **Lab 3** and **Lab 4** first. Then copy each issue below: the title, the user story as the body, the labels and the milestone. Assign every **Lab 1** issue to one person.

Labels: `feature`, `ui`, `data`, `test`, `docs`, plus `device` and `ci` (optional extras).

## Lab 1: project card, structure, main page and item details (fake data)

| # | Title | User story / description | Labels | Owner |
|---|-------|--------------------------|--------|-------|
| 1 | Project card | Commit the approved card as `docs/PROJECT_CARD.md`, with the approval date | docs | A |
| 2 | Folder structure, models and fake data | As a developer, I want immutable `Item` and `StockTransaction` models with realistic fake data (long names, missing values, zero stock), so that the screens can be built before the backend exists | data | C |
| 3 | Inventory screen (main page) | As a team member, I want to see all parts with their stock and location, and search or filter them by category, so that I know what is in the workshop without opening boxes | feature, ui | B |
| 4 | Item details screen | As a team member, I want to open an item and see its stock, location and recent history, so that I know where the last pieces went | feature, ui | C |
| 5 | Adaptive master–detail inventory | As a team member using the workshop tablet, I want the list and the details side by side, so that I can browse quickly | ui | A |
| 6 | Theme and reusable widgets | Seed-colour light and dark theme, plus `StockBadge`, `TransactionTile` and `EmptyState` in `ui/core/widgets` | ui | A |
| 7 | Model and widget tests | Unit tests for low stock and transactions; widget tests for phone and wide layouts | test | B |
| 8 | Lab 1 report | Write `docs/reports/lab-1.md` with screenshots, then tag `lab-1` | docs | A |

## Lab 2: architecture, state, first tests

| Title | User story / description | Labels | Owner |
|-------|--------------------------|--------|-------|
| App shell: navigation bar and rail | As a team member, I want bottom navigation (a rail on tablets), so that I can move between sections | feature, ui | A |
| History screen | As a team lead, I want a history of every stock movement, newest first, so that I can see who took what and when | feature, ui | C |
| Shopping list screen | As the person who orders parts, I want a list of low-stock items, so that we order everything in one go before an event | feature, ui | C |
| Profile and settings screen | As a team member, I want to see my profile and change language and theme | feature, ui | A |
| Choose a state-management approach | Decide between Provider, Riverpod and BLoC, and note the choice in the README | docs | A |
| Inventory view model and repository | As a team member, I want search and the category and shelf filters to work, so that I find parts fast | feature, data | B |
| Item form screen | As a team member, I want to add and edit items with validation, so that the inventory stays accurate | feature, ui | B |
| Take and return stock | As a team member, I want to tap "Take 4" and have the stock drop and a transaction recorded, so that nobody has to write it down | feature | C |
| Shopping list logic | As the person who orders parts, I want items to appear automatically below their threshold and to mark them as ordered | feature | C |
| Loading, empty and error states | Every main screen shows a loading, an empty and an error state | ui | all |
| Unit tests: stock math and threshold rules | — | test | B |
| Unit tests: transaction deltas and history ordering | — | test | C |

## Lab 3: data and navigation

| Title | User story / description | Labels | Owner |
|-------|--------------------------|--------|-------|
| go_router with `/items/:id` | As a team member, I want a scanned QR code or a link to open the right item directly | feature | A |
| Login screen with Supabase Auth | As a team member, I want to log in with my team account, so that transactions are recorded under my name | feature, data | A |
| Supabase schema and services | Tables for items, transactions and orders, with row-level security for one team | data | C |
| drift schema (offline-first) | As a team member in the basement workshop, I want the app to work without signal | data | B |
| Sync queue and conflict handling | Local changes are queued and pushed when the device is back online; conflicts are resolved predictably | data | C |
| Sync status in profile | As a team member, I want to see whether my changes have been uploaded | ui | A |

## Lab 4: device features, quality, release

| Title | User story / description | Labels | Owner |
|-------|--------------------------|--------|-------|
| Scanner screen | As a team member, I want to scan a box's QR label to open its item | feature, device | C |
| Local notifications | As the person who orders parts, I want a notification when something runs low; as a team member, I want to know when an order arrives | feature, device | C |
| Polish translation | As an Erasmus or Polish member, I want the app in my language | feature | A |
| Accessibility pass | Semantics labels, contrast, large text and guideline tests on all main screens | test | all |
| Widget tests (6) and integration test (1) | The integration test covers the main flow: scan → take → shopping list | test | all |
| CI: format, analyze, test and release build | GitHub Actions on every push, building the APK and web | ci | A |
| Release v1.0.0 | APK and web build attached to a GitHub release | docs | A |
| (Bonus) Item photos | As a team member, I want a photo of each part, so that I recognise it in the box | feature, device | B |
