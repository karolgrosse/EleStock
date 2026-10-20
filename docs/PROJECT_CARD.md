# Project card: EleStock

**Section:** 3 people · **Approved:** _<date>_ (by _<lecturer>_) · **Status:** _approved / approved with changes_

## Problem

Student teams (SKN PolSl Racing and other student research clubs) keep connectors, PCBs, fasteners, sensors and tools in boxes around a shared workshop. Nobody knows what's left, who took the last crimp contacts, or what has to be ordered before an event.

## Users

Members of one university racing team who share a single inventory. Some of them are Erasmus students, so the app is in English and Polish.

## Main flow (5-minute demo)

1. Scan the QR label on a box. The item opens.
2. Tap **Take 4**. The stock drops and the transaction is recorded under your name in the shared **history**.
3. The item falls below its threshold and appears on the **shopping list**.
4. The low-stock item triggers a **notification**.

## Main screens (8)

| # | Screen | Route | Owner |
|---|--------|-------|-------|
| 1 | Login | `/login` | A |
| 2 | Inventory: search, filter by category and shelf | `/items` | B |
| 3 | Item details | `/items/:id` | B |
| 4 | Item form (create and edit) | `/items/new`, `/items/:id/edit` | B |
| 5 | Scanner | `/scan` | C |
| 6 | History: every stock movement (take, put back, restock, stock count), newest first | `/history` | C |
| 7 | Shopping list: low stock, mark as ordered | `/shopping` | C |
| 8 | Profile and settings: language, theme, sync status | `/profile` | A |

## Data

- **Remote:** Supabase (Postgres plus Auth). Users log in and can create, edit and delete items, transactions and orders.
- **Local:** drift (SQLite) is the source of truth, and a sync queue pushes changes to Supabase. The app is **offline-first** because workshops in basements and event paddocks often have bad signal.
- **Entities:** `Item`, `StockTransaction`, `OrderEntry`, `Member`.

## Device features (2)

1. **QR and barcode scanning** of box labels (`mobile_scanner`).
2. **Local notifications** when an item drops below its threshold and when an order arrives (`flutter_local_notifications`).
3. _Bonus:_ item photos from the camera.

## How it meets the section-of-3–4 requirements

| Requirement | How |
|-------------|-----|
| 8 main screens | See the table above |
| Navigation | go_router with the `/items/:id` path parameter. A bottom `NavigationBar` on phones becomes a `NavigationRail` on wide screens |
| Adaptive layout | Inventory is master–detail on tablet and desktop (a tablet mounted in the workshop) |
| Architecture | view → view model → repository → service, with one state-management approach (chosen before lab 2) |
| Remote data | Supabase with login. Users create, edit and delete data |
| Local data | drift, offline-first, with a sync queue |
| Device features | QR scanning and local notifications |
| Tests | 15 unit, 6 widget and 1 integration: stock math, threshold rules, history ordering, sync conflict handling |
| Accessibility | Semantics labels, contrast, large text, guideline tests |
| Languages | English and Polish (`flutter_localizations`, ARB files) |
| CI | format, analyze and test on every push, plus a release build |
| Release | Android APK and a web build, tag `v1.0.0` |

## Split of work

| Person | Screens | Hard technical part |
|--------|---------|---------------------|
| **A** _<name>_ | Login, Profile and settings | Auth, localization (EN and PL), CI and release build |
| **B** _<name>_ | Inventory, Item details, Item form | Adaptive master–detail layout, drift schema |
| **C** _<name>_ | Scanner, History, Shopping list | Notifications, sync queue to Supabase |

## Changes agreed at the pitch

_None yet._
