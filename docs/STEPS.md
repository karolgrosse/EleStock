# Who does what – step by step

This page is the short version. Follow it top to bottom. The other docs (WORKFLOW, DESIGN, BACKLOG) are reference: open them only when a step points you there.

**Letters:** A = the repo owner (karolgrosse, the only one who can change GitHub settings). B, C and D: pick them and write the names here.

| Letter | Name | Owns for the whole semester |
|---|---|---|
| A | | Login, Profile & settings · auth, go_router, EN/PL, CI, release |
| B | | Inventory, Item form · tablet layout, drift database |
| C | | Item details, Scanner · QR scanning, take / put back |
| D | | History, Shopping list · notifications, sync |

> The Lab 1 code is already on `main` (the "initial commit"), so **ignore the `reference` branch part of WORKFLOW.md**. This page replaces it.

---

## Every time you do any work (all four)

1. `git switch main && git pull`
2. `git switch -c feature/<issue number>-<short-name>`
3. Do the work. Run `dart format .`, `flutter analyze`, `flutter test` and `flutter run`.
4. `git add . && git commit -m "feat: ..." && git push -u origin <branch>`
5. Open a PR on GitHub. First line `Closes #<issue>`, plus a screenshot.
6. Ask one person to review. Merge only after they approve (**Squash and merge**).

That's the whole workflow. Never push straight to `main`.

---

## Lab 1 – what's still missing

The lab needs 4 screens (one per person), a NavigationBar, issues on GitHub, a merged PR from everyone, a report and the `lab-1` tag. Inventory and Item details already exist. What's left:

### Step 0 – Maksym, right now
The doc and test changes on your laptop aren't on GitHub yet.
1. `git switch -c chore/tidy-docs`
2. `git rm -r --cached .claude` (that folder shouldn't be in the repo)
3. Commit everything, push, open a PR, ask anyone to review and merge it.

### A – GitHub setup + Profile screen
1. **Settings → Collaborators:** add B, C, D and the lecturer.
2. **Settings → Branches:** protect `main` (require a PR + 1 approval).
3. **Issues:** create milestones `Lab 1`–`Lab 4` and labels `feature ui data test docs device ci`.
4. Create the 6 Lab 1 issues from the table at the bottom and assign them. Then create the Lab 2–4 issues from BACKLOG.md.
5. Fill in the names and the approval date in `docs/PROJECT_CARD.md` (PR #1).
6. Build **Profile & settings** with fake data: name, team, a language switch and a theme switch that don't do anything yet, and a logout button (PR #3).

### B – App shell
1. Add a `NavigationBar` with 4 tabs: **Inventory, Scan, History, Profile**. Tabs whose screens aren't merged yet show `EmptyState` as a placeholder.
2. On wide screens (> 840 px) use a `NavigationRail` instead.
3. Open this PR **first**, because the others plug their screens into it (PR #2).
4. Check that the inventory master–detail still works on an iPad simulator or a wide macOS window.

### C – Scanner screen
1. Build **Scanner** with fake data: a grey box where the camera will be, and a text field "or type the item id". Entering a valid id opens Item details, and an unknown id shows an error.
2. Write one widget test for it.
3. Once B's shell is merged, replace the Scan placeholder with your screen (PR #4).

### D – History screen + report
1. Build **History**: every stock movement from the fake data, newest first, using the existing `TransactionTile`.
2. Write one widget test (newest item is first).
3. Once B's shell is merged, replace the History placeholder with your screen (PR #5).
4. When everything is merged: take 3 screenshots into `docs/screenshots/lab-1/`, fill in `docs/reports/lab-1.md`, and merge that (PR #6).
5. Tag it: `git switch main && git pull && git tag lab-1 && git push origin lab-1`

**Order:** Step 0 and A's setup → B's shell → A, C and D in parallel (you can build your screen in your own file before the shell is merged) → D's report and tag.

| # | Issue | Owner | Reviewer |
|---|---|---|---|
| 1 | Project card: names + approval date | A | B |
| 2 | App shell: NavigationBar / Rail | B | C |
| 3 | Profile & settings screen (fake data) | A | D |
| 4 | Scanner screen (fake data, manual id) | C | A |
| 5 | History screen (fake data) | D | B |
| 6 | Lab 1 report + tag | D | C |

---

## Labs 2–4 – one line each

**Before lab 2 (all):** read the Flutter architecture guide (~20 min) and agree on Provider, Riverpod or BLoC.

| | Lab 2 – logic, all screens | Lab 3 – real data | Lab 4 – device + release |
|---|---|---|---|
| **A** | Login screen (UI), settings work, view models for both | go_router with `/items/:id`, Supabase login, redirect to login | Polish translation, release build in CI, `v1.0.0` |
| **B** | Inventory view model, Item form with validation | drift database, repositories on top of it | Accessibility pass on all screens |
| **C** | Take / put back logic | Stock computed from transactions | Real QR scanning, integration test of the main flow |
| **D** | Shopping list screen, History view model | Supabase tables, sync queue | Low-stock notifications |

**Every lab, everyone:** loading / empty / error states and tests for your own screens, at least one merged PR, and review one PR from someone else. The report is written by a different person each time (lab 2: C, lab 3: B, lab 4: A).
