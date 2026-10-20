# EleStock: Lab 1 design, explained

This document explains what is in the app after Lab 1 and why it is built that way. Read it before the defence. Every decision here is one you should be able to say out loud.

## 1. What Lab 1 delivers

Two pages, built with fake data:

| Page | File | Purpose |
|------|------|---------|
| **Inventory** (main page) | `lib/ui/inventory/inventory_screen.dart` | Every part and tool in the workshop, with search, a category filter and the stock of each item at a glance |
| **Item details** | `lib/ui/inventory/item_details_screen.dart` | One item: how many are left, where it is, when to reorder, the Take button and its history |

This is the same list → details pattern as the *Study spots* example from part B. The difference is that our list adapts to wide screens.

The remaining semester screens (login, item form, scanner, history, shopping list, profile) are in `docs/PROJECT_CARD.md` and `docs/BACKLOG.md`. They are planned, not built.

## 2. Folder structure

```
lib/
  main.dart                              app, theme, first screen
  domain/models/item.dart                what an item IS
  domain/models/stock_transaction.dart   what a stock movement IS
  data/fake_inventory.dart               where data comes FROM (fake today)
  ui/core/category_ui.dart               label and icon for each category
  ui/core/widgets/stock_badge.dart       "6 pcs" pill, coloured by stock level
  ui/core/widgets/transaction_tile.dart  one row of history
  ui/core/widgets/empty_state.dart       icon + message when there is nothing to show
  ui/core/widgets/coming_soon.dart       snackbar for buttons of later labs
  ui/inventory/inventory_screen.dart     main page
  ui/inventory/item_details_screen.dart  second page
test/
  domain/models_test.dart                unit tests for the models
  widget_test.dart                       widget tests for both pages
```

**The rule behind it** (from part B): *code that changes for different reasons lives in different places.*

- `domain/` changes when **what we track** changes, for example adding a supplier to an item. It is plain Dart with no Flutter import, so it is easy to test.
- `data/` changes when **where data comes from** changes. In lab 3 this fake list is replaced by drift (the local database) and Supabase. The models and screens should not need to change.
- `ui/` changes when **the design** changes.
- `ui/core/widgets/` holds widgets used on more than one screen. Widgets used by one screen only stay in that screen's file.

## 3. The models

### `Item`
```dart
class Item {
  final String id, name, location, unit;
  final ItemCategory category;
  final int quantity, lowStockThreshold;
  final String? partNumber, notes;   // optional, so they can be null

  bool get isLowStock => quantity <= lowStockThreshold;
  bool get isOutOfStock => quantity <= 0;
}
```
- **Immutable.** Every field is `final` and the constructor is `const`. To change stock, you create a new `Item`. Data can't change behind a widget's back, and two items with the same values behave the same.
- **`ItemCategory` is an enum, not a String.** A typo like `'conectors'` becomes a compile error, not a silent bug.
- **`isLowStock` lives on the model** because it is a business rule ("reorder at or below the threshold"), not a design decision. Both pages and, later, the shopping list and notifications use the same rule. It is unit-tested.
- `location` is one string ("Shelf A / Box 1"). That is enough for now. Splitting it into shelf and box is a lab 3 database decision.

### `StockTransaction`
One entry in the history: who, which item, what type (take / put back / restock / stock count), how many, when, and an optional note.
- `delta` turns the type and quantity into a signed change (take 4 → −4). This keeps the sign logic in one tested place, not in every widget.
- `newestFirst()` sorts a list by time, newest first. The fake data is **deliberately out of order**, so the sorting is proven to work (there is a test for it).
- We record transactions, not just the current number. "Who took the last crimp contacts" is the problem statement, and an overwritten number can't answer it. In lab 3 this also makes offline sync easier, because each transaction is one small, appendable change.

## 4. The fake data (`data/fake_inventory.dart`)

The lab asks for data "realistic enough to see how the screens behave". Each fake item is there to test something:

| Fake item | What it tests |
|-----------|---------------|
| DT crimp contacts: 6 left, threshold 20 | **low stock** colour on the badge |
| M5 nyloc nut: 0 left | **out of stock**: red badge, Take button disabled |
| BMS slave PCB with a very long name | **long text**: no overflow, the name wraps or is cut with "…" |
| Crimp tool: threshold 0 | an item that is never "low" |
| Items with no part number or notes | **missing values**: those rows are simply not shown |
| A member name with an "(Erasmus, powertrain)" suffix | long names in the history |

`fakeItemById(id)` looks an item up by its id. The wide layout uses it already, and in lab 3 the route `/items/:id` will use it too (see question 1 below).

## 5. Page 1: Inventory (main page)

From top to bottom:
1. **AppBar** with the title and a **QR scan button**. Scanning is the fastest way into the app (the demo flow starts there), so it gets the most visible spot. It shows "coming in a later lab" for now.
2. **SearchBar**: filters by name as you type.
3. **Category FilterChips** in a horizontal scrolling row. Tap one to filter, tap it again to clear. It scrolls sideways because six chips don't fit on a phone.
4. **The list** (`ListView.builder`). Each row is a `ListTile`:
   - *leading*: category icon, so you can recognise the type at a glance
   - *title*: the name, max 2 lines, then "…"
   - *subtitle*: the location, which is the second thing you need: where to walk
   - *trailing*: `StockBadge`, which shows how many are left
5. **FloatingActionButton (+)** to add an item (lab 2).
6. **EmptyState** when search and filter match nothing, so the user never sees a blank screen.

**Why `ListView.builder`?** It only builds the rows that are visible, so it stays fast with 500 items. Plain `ListView(children: …)` builds everything up front. The lab requires `.builder`.

**Why a StatefulWidget?** The page holds three bits of state: the search text, the selected category and the selected item. For lab 1 `setState` is enough. In lab 2 this state moves to a view model (view → view model → repository).

### Adaptive layout (master–detail)
```dart
LayoutBuilder(builder: (context, constraints) {
  final wide = constraints.maxWidth >= 840;
  if (!wide) return list;                     // phone: list only
  return Row(children: [
    SizedBox(width: 380, child: list),        // left: the same list
    VerticalDivider(width: 1),
    Expanded(child: ItemDetailsView(...)),    // right: details
  ]);
});
```
- **Why?** The project card says the app runs on a **tablet mounted in the workshop**. Pushing a new screen for every item on a 12" screen wastes space and taps.
- **Why 840?** It is Material 3's "expanded" window class: tablets in landscape and desktops. Below that, two columns get too narrow.
- **Why `LayoutBuilder` and not `MediaQuery`?** `LayoutBuilder` measures the space *this widget* gets, not the whole screen. That still works if the page is later placed next to a navigation rail.
- On a phone, a tap does `Navigator.push(ItemDetailsScreen)`. On a wide window, a tap only stores the id in `_selectedId`, and the right pane rebuilds.
- `ValueKey(selected.id)` on the details pane: when you pick a different item, Flutter treats it as a new widget, so the scroll position resets to the top instead of staying halfway down the previous item.

## 6. Page 2: Item details

The details are split into **two widgets**:
- `ItemDetailsScreen` = `Scaffold` + `AppBar` + `ItemDetailsView`. Used on phones.
- `ItemDetailsView` = only the content. Used inside the screen on phones, and in the right pane on wide windows.

This split is what makes master–detail possible without duplicating code. A Scaffold inside a Scaffold would give two app bars.

The content is ordered by **what the user needs first**:
1. **Name, `StockBadge`, category chip.** What is this and how many are left?
2. **Location, part number, reorder threshold, notes.** Where is it and when do we order? Part number and notes are only shown when they exist (`if (item.partNumber != null)`).
3. **Take** (filled, the primary action) and **Put back / restock** (outlined, secondary). *Take* is disabled when the stock is 0 (`onPressed: null` greys it out automatically).
4. **History** of this item, newest first, using `TransactionTile`. If there is none, it shows `EmptyState`.

`ListView` and `Wrap` are used instead of `Column` and `Row`, so a long name or large system text scrolls or wraps instead of showing yellow-black overflow stripes.

## 7. Reusable widgets (`ui/core/widgets/`)

The lab requires at least two, each used on more than one screen:

| Widget | Used in | Why a separate widget |
|--------|---------|-----------------------|
| `StockBadge` | list rows, details header | The colour rule (normal / low / out) must look identical everywhere |
| `EmptyState` | inventory (no results, nothing selected), details (no history) | One consistent "nothing here" look |
| `TransactionTile` | details history (and the global history screen later) | One history row format |

`StockBadge` also sets a **Semantics** label ("6 pcs, low stock"). A screen-reader user can't see that the badge is orange, so the meaning is also given as words.

## 8. Theme

```dart
ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFE65100)))
```
- **One seed colour** (racing orange) generates the whole Material 3 palette, light and dark. `darkTheme` makes the app follow the phone's dark mode automatically, which matters in a dim workshop.
- **No hard-coded colours or font sizes in widgets.** They use `Theme.of(context).colorScheme.error`, `textTheme.headlineSmall` and so on. Changing the seed recolours the whole app consistently, dark mode works for free, and text grows with the user's accessibility font setting.
- Badge colours come from the scheme: `secondaryContainer` (normal), `tertiaryContainer` (low), `error` (out of stock).

## 9. Placeholders

Buttons for later labs (scan, add, edit, take, put back) call `showComingSoon()`, which shows a snackbar. They exist so the **design** is complete and reviewable, and they don't fail silently when tapped.

## 10. Tests

- `test/domain/models_test.dart` (7 unit tests): low-stock threshold (at, above, zero), transaction deltas, and `newestFirst` ordering.
- `test/widget_test.dart` (3 widget tests):
  - on a phone-sized screen, tapping an item pushes the details screen
  - on a 1280px screen, tapping an item shows details in the right pane and pushes no new screen
  - the details history is listed newest first

Run with `flutter test`. `dart format .` and `flutter analyze` must report nothing.

## 11. Likely questions, with answers

These follow the part B discussion questions, applied to our app.

1. **"The details screen receives a whole `Item`. What breaks when a QR code only knows the id?"**
   The QR code on a box will contain only the item id. A screen that needs a full `Item` object can't be opened from it. That's why the wide layout already stores only `_selectedId` and looks the item up. In lab 3, go_router's `/items/:id` will do the same: take the id from the path and load the item from the repository.

2. **"Where would the stock change after 'Take 4' live?"**
   Not in a widget. Widgets are rebuilt and thrown away, and two widgets (the list badge and the details) must show the same number. It goes into a view model backed by a repository in lab 2. That's also why the buttons are placeholders today.

3. **"Data will come from Supabase. What changes?"**
   Only `data/`: the fake list is replaced by a repository reading drift and Supabase. `domain/models` stay the same, and the screens only change from reading `fakeItems` to asking the view model.

4. **"Why is `StockBadge` in `ui/core/widgets` and not in the inventory file?"**
   Because two screens use it, and the low-stock colour rule must look identical on both.

5. **"Why `Theme.of(context).textTheme` and not `TextStyle(fontSize: 22)`?"**
   It follows the theme, dark mode and the user's font-size setting. A hard-coded size ignores all three.

6. **"Give an item a very long name."**
   The BMS PCB in the fake data already has one. In the list, the title is cut after 2 lines with "…". In the details, the full name wraps, because the page is a scrolling `ListView`. The AppBar title is cut after 1 line.

7. **"Why record transactions and not only the current count?"**
   The problem is "who took the last crimp contacts". A count alone can't answer that. The history can, and it lets stock be recalculated if two offline devices sync later.

8. **"Why does the layout switch at 840 px?"**
   It's the Material 3 breakpoint for expanded windows: tablets in landscape and desktops. Below it, two columns are too cramped to read.
