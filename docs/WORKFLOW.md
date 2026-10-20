# How we work: git, pull requests, who does what

| Name | GitHub | Semester area |
|------|--------|---------------|
| Grosse | | Login, Profile and settings · auth, go_router, EN/PL, CI and release |
| Weindich | | Inventory, Item form · master–detail, drift database, validation |
| Koczorowska | | Item details, Scanner · QR scanning, take / put back logic, photos |
| Szulik | | History, Shopping list · notifications, sync to Supabase |

Everybody owns two of the eight screens and one hard technical part, and writes the tests for their own code.

---

## The rules

1. **Nobody pushes to `main`.** Every change goes through a pull request (PR), and `main` is protected so GitHub enforces this.
2. **One issue → one branch → one PR.** Name branches `feature/<issue>-<short-name>` or `fix/<issue>-<short-name>`, for example `feature/5-item-details`.
3. **Every PR is approved by one other person** before it is merged. The author never merges without that approval.
4. **Before you push:** `dart format .`, `flutter analyze` and `flutter test` must all be clean. CI checks the same thing on GitHub.
5. **Commit messages are short, in the imperative, with a type:** `feat: add item details screen`, `fix: wrap long item names`, `docs: add lab 1 report`, `test: …`, `chore: …`.
6. **The PR description starts with `Closes #<issue>`**, says what changed in one or two sentences and, for UI changes, includes a screenshot. The PR template fills in these headings for you.
7. **You must be able to explain every line you merge.** The lecturer can ask any of you about any part. Read [DESIGN.md](DESIGN.md).

---

## One-time setup

### Person A: create the repository

Do this **in a new, empty folder**, not in the folder with the finished code:

```bash
flutter create --org pl.polsl --platforms android,ios,web,macos elestock
cd elestock
git init -b main
git add .
git commit -m "chore: create Flutter project"
```

On GitHub, create an **empty** repository called `elestock` (no README, no .gitignore). Then:

```bash
git remote add origin git@github.com:<owner>/elestock.git
git push -u origin main
```

On GitHub:
1. **Settings → Collaborators:** add B, C, D and the lecturer.
2. **Settings → Branches → Add rule** for `main`: tick *Require a pull request before merging* and *Require approvals: 1*. After PR #2 (CI) is merged, come back and also tick *Require status checks to pass* and choose the `check` job.
3. **Issues → Milestones:** create `Lab 1`, `Lab 2`, `Lab 3` and `Lab 4`.
4. **Issues → Labels:** create `feature`, `ui`, `data`, `test`, `docs`, `device` and `ci`.
5. Create the seven **Lab 1 issues** from [BACKLOG.md](BACKLOG.md) **in order**, so they get numbers #1–#7. Give each one its label, the `Lab 1` milestone and its owner. Create the Lab 2–4 issues too.
6. Optional: **Projects → New → Board** with the columns To do, In progress, In review and Done.

### Person A: share the prepared code as a `reference` branch

The finished Lab 1 code is in the folder this document came from. Push it as a separate branch, so that everyone can copy their own files from it into their own PR:

```bash
cd <path to the folder with the finished code>
git add .
git commit -m "chore: lab 1 reference code"
git remote add origin git@github.com:<owner>/elestock.git
git push origin main:reference
```

Nobody merges `reference`. It is only a place to copy from. Delete it once all Lab 1 PRs are merged.

### Everyone: clone

```bash
git clone git@github.com:<owner>/elestock.git
cd elestock
flutter pub get
flutter run
```

---

## The loop for every issue

```bash
# 1. Start from an up-to-date main
git switch main
git pull

# 2. Make a branch for your issue
git switch -c feature/5-item-details

# 3. Do the work
#    (in Lab 1: copy your files from the reference branch, see the table below)

# 4. Check
dart format .
flutter analyze
flutter test
flutter run          # look at it on a simulator or emulator

# 5. Commit and push
git add .
git commit -m "feat: add item details screen"
git push -u origin feature/5-item-details
```

6. On GitHub, open the PR. Start the description with `Closes #5`, add a screenshot, and request a review from the reviewer named in the table below.
7. **Reviewer:** read the code, pull the branch and run it (`git fetch && git switch feature/5-item-details && flutter run`). Then either *Approve* or *Request changes* with a comment.
8. **Author:** merge with **Squash and merge** (each PR becomes one commit on `main`), then click *Delete branch*.
9. Everyone else runs `git switch main && git pull` before starting their next branch.

### When main moved on while you were working

If GitHub says your branch is out of date or has conflicts:

```bash
git switch feature/5-item-details
git fetch
git merge origin/main
# if there are conflicts: open the files, keep the correct parts,
# remove the <<<<<<< ======= >>>>>>> markers, then:
git add .
git commit
git push
```

Conflicts are rare if each PR touches only its own files, which is how the work below is split.

---

## Lab 1: the seven PRs, in order

Each PR copies its files from the `reference` branch with:

```bash
git fetch
git checkout origin/reference -- <paths from the table>
```

Then **read every file you copied** and run it before you commit. You are the one who explains it at the defence.

| # | Owner | Reviewer | Branch | Paths to take from `reference` | Can start after |
|---|-------|----------|--------|--------------------------------|-----------------|
| 1 | A | B | `docs/1-project-card` | `docs/PROJECT_CARD.md docs/BACKLOG.md docs/DESIGN.md docs/WORKFLOW.md README.md` | setup |
| 2 | A | C | `chore/2-ci` | `.github .gitignore` | setup |
| 3 | C | D | `feature/3-models` | `lib/domain lib/data test/domain` | setup |
| 4 | D | C | `feature/4-theme-widgets` | `lib/ui/core test/ui/core` (+ edit `lib/main.dart`, see below) | #3 merged |
| 5 | C | B | `feature/5-item-details` | `lib/ui/inventory/item_details_screen.dart test/ui/inventory/item_details_screen_test.dart` | #4 merged |
| 6 | B | A | `feature/6-inventory` | `lib/ui/inventory/inventory_screen.dart test/ui/inventory/inventory_screen_test.dart lib/main.dart` | #5 merged |
| 7 | D | A | `docs/7-lab-1-report` | `docs/reports` (then fill it in) | #6 merged |

PRs #1, #2 and #3 can be opened at the same time. #4 to #7 build on each other, so `main` compiles after every merge. While waiting, you can already make your branch and read your files. Just don't open the PR until the one before it is merged; then run `git merge origin/main` on your branch.

Every person has at least one merged PR, and everyone reviews at least one.

### Details for each PR

- **#1 (A), docs.** Fill in the names in this file and in the project card, and add the approval date from the pitch.
- **#2 (A), CI.** Once it's merged, add the required status check to the branch protection (setup step 2).
- **#3 (C), models.** Plain Dart only, so nothing changes on screen yet. `flutter test` runs the new unit tests.
- **#4 (D), theme and widgets.** The `main.dart` in `reference` already opens `InventoryScreen`, which doesn't exist yet. So in this PR **write `main.dart` by hand** with the theme and a temporary home page. Also **delete** `test/widget_test.dart`, the counter test from `flutter create`, which no longer fits the app:

  ```dart
  import 'package:flutter/material.dart';

  void main() => runApp(const EleStockApp());

  class EleStockApp extends StatelessWidget {
    const EleStockApp({super.key});

    static const _seed = Color(0xFFE65100);

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'EleStock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: _seed)),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _seed,
            brightness: Brightness.dark,
          ),
        ),
        // Temporary until the inventory screen is merged in #6.
        home: const Scaffold(body: Center(child: Text('EleStock'))),
      );
    }
  }
  ```
  ```bash
  git rm test/widget_test.dart
  ```
- **#5 (C), item details.** The screen can't be opened from the app yet (the list arrives in #6). The widget tests open it directly, and that's enough for this PR.
- **#6 (B), inventory.** Taking `lib/main.dart` from `reference` swaps the temporary home for `InventoryScreen`. Test both layouts: a phone, and a wide window (iPad simulator, or macOS with `flutter run -d macos` and drag the window wider than 840 px).
- **#7 (D), report.** Take screenshots (phone list, phone details, tablet master–detail) into `docs/screenshots/lab-1/`. Fill in the PR numbers and "who did what". After it's merged, tag the lab:

  ```bash
  git switch main
  git pull
  git tag lab-1
  git push origin lab-1
  ```
  Then delete the `reference` branch on GitHub (Branches → 🗑).

---

## From Lab 2 on

- At the start of each lab, everyone picks their issues from the milestone and moves them to *In progress* on the board.
- **Small PRs.** One screen or one feature per PR. A PR you can review in 10 minutes gets reviewed today; one that takes an hour sits for a week.
- **Pull `main` every time you start something:** `git switch main && git pull`.
- **Touch only your own files when you can.** Shared files (`main.dart`, the router, `pubspec.yaml`) change in small, separate PRs, so conflicts stay small.
- **Adding a package** (`flutter pub add …`) changes `pubspec.yaml` and `pubspec.lock`. Say so in the team chat, so nobody adds the same one in parallel.
- **The lab report** is written by a different person each lab. The tag is pushed only after the report PR is merged. Work pushed after the tag counts for the next lab.
