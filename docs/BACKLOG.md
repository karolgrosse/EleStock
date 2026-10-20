# Backlog: issues to create on GitHub

Create the milestones **Lab 1**, **Lab 2**, **Lab 3** and **Lab 4** first. Then copy each issue below: the title, the user story as the body, the labels and the milestone. Assign every issue to its owner.

Labels: `feature`, `ui`, `data`, `test`, `docs`, plus `device` and `ci`.

Owners: **A** (auth, settings, languages, CI), **B** (inventory, form, local database), **C** (item details, scanner, stock logic), **D** (history, shopping list, notifications, sync). See [WORKFLOW.md](WORKFLOW.md) for how the work moves through pull requests.

## Lab 1: project card, structure, main page and item details (fake data)

The numbers match the PR order in [WORKFLOW.md](WORKFLOW.md). Create them in this order, so the GitHub issue numbers match too.

| # | Title | User story / description | Labels | Owner |
|---|-------|--------------------------|--------|-------|
| 1 | Project card, backlog and design notes | Commit `docs/` (project card with the approval date, backlog, design, workflow) and the README | docs | A |
| 2 | CI and PR template | GitHub Actions runs format, analyze and test on every push and PR. Add the PR template | ci | A |
| 3 | Models and fake data | As a developer, I want immutable `Item` and `StockTransaction` models with realistic fake data (long names, missing values, zero stock), so that the screens can be built before the backend exists. Include unit tests | data, test | C |
| 4 | Theme and reusable widgets | Seed-colour light and dark theme in `main.dart`, plus `StockBadge`, `TransactionTile`, `EmptyState` and the category icons in `ui/core`. Include a `StockBadge` widget test | ui | D |
| 5 | Item details screen | As a team member, I want to open an item and see its stock, location and recent history, so that I know where the last pieces went. Include widget tests | feature, ui | C |
| 6 | Inventory screen (main page) | As a team member, I want to see all parts with their stock and location, search them and filter by category. On the workshop tablet I want the list and details side by side. Include widget tests | feature, ui | B |
| 7 | Lab 1 report | Write `docs/reports/lab-1.md` with screenshots, then tag `lab-1` | docs | D |

## Lab 2: architecture, state, all main screens

| Title | User story / description | Labels | Owner |
|-------|--------------------------|--------|-------|
| Choose a state-management approach | All four decide between Provider, Riverpod and BLoC. Note the choice in the README | docs | A |
| App shell: navigation bar and rail | As a team member, I want bottom navigation (a rail on tablets), so that I can move between sections | feature, ui | A |
| Profile and settings screen | As a team member, I want to see my profile and change the language and theme | feature, ui | A |
| Login screen (UI only) | As a team member, I want to log in with my team account | feature, ui | A |
| Inventory view model and repository | Move search, filter and selection state out of the widget into a view model | feature, data | B |
| Item form screen | As a team member, I want to add and edit items with validation, so that the inventory stays accurate | feature, ui | B |
| Take and put back stock | As a team member, I want to tap "Take 4" and have the stock drop and a transaction recorded, so that nobody has to write it down | feature | C |
| Scanner screen (UI only) | Camera preview placeholder and a manual id entry fallback | feature, ui | C |
| History screen | As a team lead, I want a history of every stock movement, newest first, so that I can see who took what and when | feature, ui | D |
| Shopping list screen | As the person who orders parts, I want items below their threshold listed automatically, and to mark them as ordered | feature, ui | D |
| Loading, empty and error states | Every main screen shows loading, empty and error states. Each owner does their own screens | ui | all |
| Unit tests for each view model | Each owner tests their own view models | test | all |

## Lab 3: data and navigation

| Title | User story / description | Labels | Owner |
|-------|--------------------------|--------|-------|
| go_router with `/items/:id` | As a team member, I want a scanned QR code or a link to open the right item directly | feature | A |
| Login with Supabase Auth | As a team member, I want to log in, so that my transactions are recorded under my name. Logged-out users are redirected to `/login` | feature, data | A |
| drift schema (offline-first) | As a team member in the basement workshop, I want the app to work without signal | data | B |
| Repositories on top of drift | Items and transactions are read from and written to the local database | data | B |
| Supabase schema and services | Tables for items, transactions and orders, with row-level security for one team | data | D |
| Sync queue and conflict handling | Local changes are queued and pushed when the device is back online. Conflicts are resolved predictably | data | D |
| Stock is computed from transactions | Taking and putting back write a transaction, and the item's stock follows from it | data | C |
| Sync status in profile | As a team member, I want to see whether my changes have been uploaded | ui | A |

## Lab 4: device features, quality, release

| Title | User story / description | Labels | Owner |
|-------|--------------------------|--------|-------|
| QR scanning | As a team member, I want to scan a box's QR label to open its item | feature, device | C |
| Local notifications | As the person who orders parts, I want a notification when something runs low | feature, device | D |
| Polish translation | As an Erasmus or Polish member, I want the app in my language | feature | A |
| CI: release build | GitHub Actions builds the APK and the web version | ci | A |
| Release v1.0.0 | APK and web build attached to a GitHub release | docs | A |
| Integration test: main flow | scan → take → item appears on the shopping list | test | C |
| Accessibility pass | Semantics labels, contrast, large text and guideline tests. Each owner covers their own screens | test | all |
| (Bonus) Item photos | As a team member, I want a photo of each part, so that I recognise it in the box | feature, device | C |
