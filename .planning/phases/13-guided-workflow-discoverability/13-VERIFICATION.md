---
phase: 13-guided-workflow-discoverability
verified: 2026-06-25T22:30:00Z
status: human_needed
score: 11/11 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Load one or more PLY files; confirm Anchors tab is enabled immediately without placing landmarks or checking Place Anchors"
    expected: "Anchors tab clickable; GPA tab remains disabled until all landmarks placed on current specimen"
    why_human: "Tab enablement is Tk widget state; cannot verify interactively from grep"
  - test: "Click each disabled tab (Surface Sliders, Curves, GPA before landmarks complete) and confirm status bar message appears without tab switching"
    expected: "Status bar shows sentence-case explanation (warning/info); active tab unchanged"
    why_human: "Requires live Tk event loop and visual confirmation of status bar"
  - test: "Observe e$stepLabel above the notebook while placing landmarks and toggling Place Anchors"
    expected: "Step label updates through Step 1/2/3 copy as gating state changes"
    why_human: "Passive label rendering requires running GUI"
  - test: "After loading specimens, check placement hint on Digitize tab without switching tabs; then switch Digitize ↔ Anchors ↔ GPA"
    expected: "Hint shows UI-SPEC copy on tabs 0–1; empty on tabs 2–4; ideally visible on Digitize tab immediately after load"
    why_human: "Hint only updates inside switchTab — initial post-load visibility unverified programmatically"
  - test: "Load 3+ specimens; use jump-to combobox, Previous, and Next; attempt jump with incomplete landmarks"
    expected: "Title shows Specimen N of M; combobox lists index:basename; guards block jump with warning and combobox re-syncs to current specimen"
    why_human: "Combobox selection sync and nav guards require interactive Tk session"
---

# Phase 13: Guided Workflow & Discoverability Verification Report

**Phase Goal:** Make the digitize order and placement model obvious — placement hints, transparent/streamlined tab-gating, "specimen N of M" with jump-to.
**Verified:** 2026-06-25T22:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Once a specimen loads, Anchors tab is enabled immediately, decoupled from landmark completion and Place Anchors checkbox (UX-WF-04) | ✓ VERIFIED | `refreshTabGating` sets tab 1 `normal` when `loaded <- length(e$activeDataList) > 0` (`3dDigitize.main.r:302-306`); called from `loadPly` (`1479`), `drawElements` (`1556`); digitize.r has no `e$tabState` / `tcl(e$nb` manipulation |
| 2 | GPA tab unlocks when current specimen landmark count is complete (UX-WF-04) | ✓ VERIFIED | `gpaOk <- loaded && e$activeDataList[[e$currImgId]][[3]] == e$landmarkNum` (`311-313`); refreshed from `updateDotNum` (`951`) |
| 3 | Surface Sliders and Curves tabs stay disabled; explain on click (UX-WF-02) | ✓ VERIFIED | `refreshTabGating` forces tabs 2–3 disabled (`307-309`); `switchTab` intercept returns with Surface/Curves messages (`383-386`) |
| 4 | Clicking a disabled tab does not switch tabs; writes explanation to status bar (UX-WF-02) | ✓ VERIFIED | Early return at `380-392` before tab-switch body; uses `setStatus` with warning/info tokens |
| 5 | Navigating Previous/Next never undoes unlock-on-load; gating from unified predicate (UX-WF-04) | ✓ VERIFIED | `onNext`/`onPrevious` call only `refreshTabGating(e)` (`1228`, `1297`); old `for (i in 1:4)` churn removed from `onNext` |
| 6 | Persistent step-indicator label above notebook shows gating step (UX-WF-02) | ✓ VERIFIED | `e$stepLabel` created (`660-661`), packed above notebook (`726`); `updateStepLabel` sets Step 1/2/3 copy (`317-336`); wired from `showPicture`, `loadPly`, `drawElements`, digitize handlers |
| 7 | Persistent placement hint updates with active tab (UX-WF-01) | ✓ VERIFIED | `e$hintLabel` created (`670-673`); `switchTab` updates via `HINT_TEXT` map (`395-401`) |
| 8 | Digitize/Anchor tabs show placement hint; Surface/Curves/GPA empty (UX-WF-01) | ✓ VERIFIED | `HINT_TEXT` keys `"0"` and `"1"` only; other tabs get `""` (`399-400`); matches approved UI-SPEC copy |
| 9 | Title label shows clean specimen counter Specimen N of M (UX-WF-03) | ✓ VERIFIED | Initial `Specimen: —` (`666`); `updateWidgets.digitize`/`anchor` and `loadPly` use `paste0("Specimen ", e$currImgId, " of ", length(...))` |
| 10 | Readonly jump-to combobox lists specimens and jumps on selection (UX-WF-03) | ✓ VERIFIED | `e$specimenCombo` + `populateSpecimenCombo` (`248-263`, `910-916`); `<<ComboboxSelected>>` → `jumpToSpecimen` |
| 11 | Combobox applies same nav guards as Previous/Next and stays in sync (UX-WF-03) | ✓ VERIFIED | `jumpToSpecimen` mirrors tab/landmark/anchor guards (`271-294`); 4× `refreshNavButtons(e); return(invisible())` on guard failure; `refreshNavButtons` syncs `e$specimenSelectVar` (`241-245`) |

**Score:** 11/11 truths verified (code-level)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `3dDigitize.main.r` — `refreshTabGating` | Unified gating predicate | ✓ VERIFIED | Defined `302-315`; 5+ call sites in main.r + digitize.r |
| `3dDigitize.main.r` — `updateStepLabel` / `e$stepLabel` | Passive gating step indicator | ✓ VERIFIED | Defined `317-337`; widget at `660-661` |
| `3dDigitize.main.r` — `switchTab` interception | Disabled-tab explain | ✓ VERIFIED | Lines `380-392`; wired via `tkbind` at `688-691` |
| `3dDigitize.main.r` — `e$hintLabel` | Placement hints | ✓ VERIFIED | Widget `670-673`; updated in `switchTab` |
| `3dDigitize.main.r` — `jumpToSpecimen` / `populateSpecimenCombo` / `e$specimenCombo` | Jump-to navigation | ✓ VERIFIED | `248-300`, `910-916`; populated in `loadPly`/`drawElements` |
| `3dDigitize.digitize.r` — gating hooks | Decoupled checkbox | ✓ VERIFIED | `onPlaceAnchor`/`updateDotNum`/`updateAnchorNum` call `refreshTabGating`; no tabState churn; `assign("bt", placeAnchors)` preserved (`131`) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `switchTab` | `e$statusLabel` | `setStatus(..., "warning")` on disabled tab | ✓ WIRED | `380-392` |
| `loadPly` / `onNext` / `onPrevious` / `drawElements` | `e$tabState` + notebook | `refreshTabGating(e)` | ✓ WIRED | Call sites verified |
| `updateStepLabel` | `e$stepLabel` | `tkconfigure(..., foreground = "#505050")` | ✓ WIRED | `335` |
| `e$specimenCombo` | `jumpToSpecimen` → `showPicture` | `<<ComboboxSelected>>` binding | ✓ WIRED | `913-916`, `295-298` |
| `switchTab` | `e$hintLabel` | `HINT_TEXT` + `tkconfigure` | ✓ WIRED | `395-401` |
| `refreshNavButtons` | `e$specimenSelectVar` | combobox sync | ✓ WIRED | `241-245` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `e$stepLabel` | step text | `e$activeDataList[[currImgId]][[3]]`, `e$landmarkNum`, `placeAnchorsVar` | Yes — derived from live specimen counts | ✓ FLOWING |
| `e$hintLabel` | hint text | `HINT_TEXT[id]` in `switchTab` | Static per-tab strings; empty until first `switchTab` call | ⚠️ STATIC until tab switch |
| `e$specimenCombo` | values | `e$activeDataList[[i]][[1]]` basenames | Yes — built from loaded specimens | ✓ FLOWING |
| `e$imgPath` | counter | `e$currImgId`, `length(e$activeDataList)` | Yes — updated on load/nav via `updateWidgets` | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No `Specimen Id:` on imgPath | `grep -rF 'Specimen Id:' R/3dDigitize.main.r R/3dDigitize.digitize.r` | 0 matches | ✓ PASS |
| No double-id status bug | `grep -F '" \u2014 ", e$currImgId, " of "' R/*.r` | 0 matches | ✓ PASS |
| jumpToSpecimen guard re-sync | `grep -cF 'refreshNavButtons(e); return(invisible())' R/3dDigitize.main.r` | 4 (≥3 required) | ✓ PASS |
| Package load | `R -q -e "devtools::load_all(...)"` | R unavailable in verifier WSL session | ? SKIP |

### Probe Execution

Step 7c: SKIPPED — no phase-declared probes or `scripts/*/tests/probe-*.sh` for this UI phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| UX-WF-01 | 13-02 | Placement model discoverable via on-screen hint | ✓ SATISFIED | `e$hintLabel` + UI-SPEC `HINT_TEXT` in `switchTab` (`395-401`). Copy uses rotate/delete per approved UI-SPEC, not REQUIREMENTS.md example wording |
| UX-WF-02 | 13-01 | Disabled tabs explain why; gating reads intentional | ✓ SATISFIED | `switchTab` interception + `e$stepLabel` passive indicator |
| UX-WF-03 | 13-02 | Specimen N of M + jump-to control | ✓ SATISFIED | Counter in `e$imgPath`; `e$specimenCombo` + `jumpToSpecimen` |
| UX-WF-04 | 13-01 | Streamlined unified tab-gating; CON-02 preserved | ✓ SATISFIED | Single `refreshTabGating` predicate; unlock-on-load; no `.dgt` reader changes |

All four phase requirement IDs declared in plan frontmatter are accounted for. No orphaned requirements for Phase 13 in REQUIREMENTS.md.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `3dDigitize.main.r` | 1996 | `TBD` in `execueTakeSnapShot` | ℹ️ Info | Pre-existing (May 2020); outside phase edit scope; not in gating/hint/combobox paths |
| `3dDigitize.main.r` | 670 | `e$hintLabel` init `text = ""` | ⚠️ Warning | Hint not seeded on load/showPicture — may be blank until first tab switch |

### Human Verification Required

### 1. Unlock-on-load tab gating

**Test:** Load a PLY; observe Anchors and GPA tab states before placing landmarks.
**Expected:** Anchors enabled immediately; GPA disabled until landmark count complete.
**Why human:** Tk tab `state` is runtime widget behavior.

### 2. Disabled-tab click-to-explain

**Test:** Click Surface Sliders, Curves, and locked GPA tab.
**Expected:** Status bar shows explanation; tab does not switch.
**Why human:** Requires live GUI interaction and visual status bar read.

### 3. Step label progression

**Test:** Place landmarks; toggle Place Anchors; complete anchors.
**Expected:** Step label advances Step 1 → 2 → 3 per gating.
**Why human:** Dynamic label text during digitizing workflow.

### 4. Placement hint visibility

**Test:** After load, check hint on Digitize tab without switching; then switch tabs.
**Expected:** Hint shows on tabs 0–1 per UI-SPEC; empty on 2–4. Note if hint is blank until first tab click.
**Why human:** Hint update path only runs in `switchTab`; post-load seeding not grep-verifiable.

### 5. Jump-to combobox navigation

**Test:** Load 3 specimens; jump via combobox; attempt jump with incomplete landmarks; use Previous/Next.
**Expected:** Counter and combobox stay in sync; guards block with warning and combobox re-syncs.
**Why human:** Combobox `<<ComboboxSelected>>` and guard re-sync require interactive session.

### Gaps Summary

No automated blockers found. All 11 plan must-haves have substantive, wired implementations in `3dDigitize.main.r` and `3dDigitize.digitize.r`. Code-level verification passes; interactive Tk behavior (tab states, hint initial visibility, combobox sync under rejection) requires human UAT before marking phase complete.

---

_Verified: 2026-06-25T22:30:00Z_
_Verifier: Claude (gsd-verifier)_
