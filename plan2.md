# Segment34View — Phase 2 Improvement Plan

## Overview

The view refactoring from plan.md is complete: the view is ~1874 lines with most domain logic
extracted into dedicated helper files. This plan addresses remaining structural issues:
stray code that still lives in the wrong file, misleading comments left from the refactoring,
a dead private helper split, and a disorganized method order that makes the file hard to
navigate.

**No behavior changes in any step. Build must be clean after each step.**

---

## What we're NOT changing

**`loadResources`** — Not feasible to modularize. It has 6 device-specific variants (one per
screen-size annotation) that all must set the same 20+ layout instance vars. Any abstraction
would just move the coupling somewhere else.

**ActivityDataHelper module-level functions** (`getBarData`, `getBattData`, `getStressColor`)
— These are idiomatic Monkey C. They live in `ActivityDataHelper.mc`; a reader can find them
by file. Wrapping in a module declaration would require updating a dozen call sites for little
gain in a codebase without IDE navigation. Leave as-is.

---

## Step 1 — Merge `ActivityDataHelper.mc` + `ComplicationHelper.mc` → `DataHelper.mc`

`ActivityDataHelper` and `ComplicationHelper` both fetch live data from the same Garmin APIs
(`ActivityMonitor`, `Complications`, `System`, `UserProfile`). The boundary between them is
arbitrary — `getStressData` and `getBBData` already call `Complications.getComplication`.
Mixing module-level functions with a class for the same conceptual job is inconsistent; put
everything into one `DataHelper` class.

**Structure of `DataHelper.mc`:**
```monkeyc
// Module-level constants only (Monkey C doesn't allow const inside a class)
const BATT_FULL  = "|||||||||||||||||||||||||||||||||||";
const BATT_EMPTY = "{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{{";

class DataHelper {
    // Former ComplicationHelper state
    hidden var cgmComplicationId as Complications.Id? = null;
    hidden var cgmAgeComplicationId as Complications.Id? = null;
    var vo2RunTrend as String = "";
    var vo2BikeTrend as String = "";

    // Former ActivityDataHelper module-level cache vars
    hidden var _cachedRunDist7Days as Number = 0;
    hidden var _cachedBikeDist7Days as Number = 0;
    hidden var _cachedSwimDist7Days as Number = 0;
    hidden var _cachedRunDistMonth as Number = 0;
    hidden var _cachedRunDist28Days as Number = 0;
    hidden var _lastActivityDistUpdate as Number = 0;

    function initialize() {}

    // --- Activity & sensor data (was ActivityDataHelper module-level) ---
    function getBarData(data_source) { ... }
    function getStressData() { ... }
    function getStressColor(val) { ... }
    function getBBData() { ... }
    // ... all goal helpers, getBattData, getRestCalories,
    //     getWeeklyDistance, updateActivityDistCache,
    //     getWeeklyDistanceFromComplication

    // --- Complication data (was ComplicationHelper) ---
    function getIconState(setting) { ... }
    function getIconColor(setting) { ... }    // still (:AMOLED) / (:MIP) annotated
    // ... getCgmReading, getCgmAge, updateVo2History, etc.
}
```

**Callers to update:**
- `Segment34View.mc`:
  - `hidden var complications as ComplicationHelper` → `hidden var dataHelper as DataHelper`
  - `complications.*` → `dataHelper.*` (~8 sites)
  - Bare `getBattData(...)`, `getBarData(...)`, `getStressColor(...)` → `dataHelper.*` (~4 sites)
- `ValueResolver.mc`:
  - Constructor param renamed; `_complications.*` → `_dataHelper.*` (~10 sites)
  - Bare `getStressData()`, `getBBData()`, `getRestCalories()`, `getWeeklyDistance()`,
    `getWeeklyDistanceFromComplication(...)`, `updateActivityDistCache()` → `_dataHelper.*` (~12 sites)
- Delete `ActivityDataHelper.mc` and `ComplicationHelper.mc`

**Lines changed:** ~25 call sites total across view + resolver
**Risk:** Low — mechanical rename + conversion, no logic changes; build confirms completeness

---

## Step 2 — Move `Segment34Delegate` and `StoredWeather` to their own files

Both classes currently live at the bottom of `Segment34View.mc` because that's where they
ended up originally. They have nothing to do with rendering.

**`Segment34WatchFaceDelegate.mc`** (new file, ~70 lines):
- Move `class Segment34Delegate extends WatchUi.WatchFaceDelegate` (lines 1789–1856)
- It references `Segment34View` and `ValueResolver` — no imports needed beyond what it
  already uses; Monkey C resolves these in app scope
- It is NOT annotated `(:background)` so no `excludeAnnotations` changes needed

**`StoredWeather.mc`** (new file, ~25 lines):
- Move `class StoredWeather` (lines 1858–end of file)
- It is annotated `(:background_excluded)` — keep that annotation on the class
- Referenced by: `Segment34View`, `WeatherDisplayHelper`, `ValueResolver`, `SunCalc` —
  all resolved in app scope, no changes needed

**Lines removed from view:** ~95
**Risk:** Low — pure file moves, no logic changes

---

## Step 3 — Extract weather persistence to `WeatherStorage.mc`

`storeWeatherData()`, `readWeatherData()`, and `computeCcHash()` are about persisting and
reading structured weather data from `Application.Storage`. They are not about rendering or
display logic. They belong together in a dedicated class.

**New file `WeatherStorage.mc`** — a `WeatherStorage` class:
- Move: `storeWeatherData()`, `readWeatherData()`, `computeCcHash()`
- Move state: `isLowMem`, `lastHfTime`, `lastCcHash` → become instance vars on `WeatherStorage`
- Public interface:
  ```monkeyc
  class WeatherStorage {
      var isLowMem as Boolean = false;
      hidden var _lastHfTime as Number? = null;
      hidden var _lastCcHash as Number? = null;

      function store() as Void { ... }         // was storeWeatherData()
      function read() as StoredWeather { ... } // was readWeatherData()
      hidden function _ccHash(cc) as Number { ... } // was computeCcHash()
  }
  ```
- View holds `hidden var weatherStorage as WeatherStorage = new WeatherStorage();`
- `updateWeather()` stays on the view (it's orchestration) but calls:
  - `weatherStorage.store()` instead of `storeWeatherData()`
  - `weatherStorage.read()` instead of `readWeatherData()`
- The `isLowMem` read in `storeWeatherData` was the only place it's set; now both read
  and write are inside `WeatherStorage`, so the view's `isLowMem` var is removed entirely

**Lines removed from view:** ~180
**Risk:** Low-medium — state migration for 3 vars, but they're only touched by these functions

---

## Step 4 — Inline `calculateFieldXCoords` + remove stale comments

Two small cleanup items that don't warrant separate steps:

**Inline `calculateFieldXCoords`:**
- `calculateFieldXCoords` has exactly one caller: `calculateLayout`. It's a 10-line private
  implementation detail. Inlining it into `calculateLayout` removes the false impression that
  it's a reusable operation and makes `calculateLayout` self-contained.

**Remove stale "lives in X" comments from the class variable block:**
- Line 73: `// cachedGraphData2 lives in graphRenderer` — `cachedGraphData2` is correctly
  accessed as `graphRenderer.cachedGraphData2` in the code; the comment at the top of the
  class is noise.
- Line 114: `// graphGoalLine, cachedGraphYMin, cachedGraphYMax live in graphRenderer` —
  these vars are entirely internal to `GraphRenderer` and are never referenced in the view
  at all. The comment is archaeology from the refactoring. Remove it.

**Remove stale refactoring archaeology comments in `computeDisplayValues`:**
- `// From updateSlowData logic` — the refactoring context that motivated this comment no
  longer exists in the codebase. Remove.
- `// From updateData logic` — same.

**Lines changed:** ~15 (deletions + inline)
**Risk:** Very low

---

## Step 5 — Reorganize method order in `Segment34View.mc`

Currently methods appear in roughly the order they were added or kept during refactoring.
Grouping them by role makes the file readable top-to-bottom: you can see the whole lifecycle
and update chain in one continuous pass.

**Proposed order** (each group gets a `// === SECTION ===` banner):

```
=== INITIALIZATION & SETTINGS ===
  initialize()
  reloadSettings()
  updateProperties()
  loadFontVariant()
  loadAODGraphics()
  loadResources()  [all 6 annotated variants]
  updateActiveLabels()

=== LAYOUT ===
  calculateLayout()          [inlined from step 4, now includes field X coords]
  calculateBarLimits()
  calculateSquareLayout()    [Square variant + Round no-op stub]

=== LIFECYCLE CALLBACKS ===
  onLayout()
  onShow()
  onHide()
  onExitSleep()
  onEnterSleep()
  onSettingsChanged()
  forceDataRefresh()

=== UPDATE ENTRY POINTS ===
  onUpdate()
  onPartialUpdate()

=== DRAW CHAIN ===
  computeDisplayValues()
  getClockData()
  getValueForSeconds()
  computeBottomField2Values()    [Square variant + Round no-op stub]
  getFieldWidths()
  drawWatchface()
  drawAOD()                  [empty stub + AMOLED variant]
  drawPattern()
  drawDataField()
  drawBottomFieldsWithIcons()    [Square variant + Round variant]
  drawIconWithOverlay()
  drawSideBars()
  drawOneBar()
  drawMoveBarTicks()
  drawBatteryIcon()          [MIP variant + AMOLED variant]

=== DATA UPDATES ===
  updateColorTheme()
  updateWeather()

=== SQUARE DEVICE SETUP ===
  loadBottomField2Property() [Square variant + Round no-op stub]
```

**Notes:**
- No logic changes whatsoever — purely moving function bodies within the file
- The Square/Round stubs stay with their corresponding real implementation to keep
  annotated pairs together (easier to compare)
- `updateActiveLabels()` moves into INITIALIZATION & SETTINGS because it is called from
  `updateProperties()` and is about property state, not rendering

**Lines changed:** all of them (reordering), **logic changed:** zero
**Risk:** Medium — large diff, but purely mechanical; build verifies correctness

---

## Summary

| # | What | Lines removed/changed | Risk |
|---|---|---|---|
| 1 | Merge ActivityDataHelper + ComplicationHelper → DataHelper.mc | 2 files → 1, ~10 rename sites | Low |
| 2 | Delegate + StoredWeather to own files | −95 from view | Low |
| 3 | WeatherStorage.mc | −180 from view | Low-medium |
| 4 | Inline calculateFieldXCoords + remove stale comments | ~15 deletions | Very low |
| 5 | Reorganize method order | 0 net (reorder only) | Medium |

**Estimated view size after:** ~1600 lines
