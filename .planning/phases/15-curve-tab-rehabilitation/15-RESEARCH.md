# Phase 15: Curve Tab Rehabilitation — Research

**Researched:** 2026-06-25
**Domain:** R/Tcl/Tk 8.6 curve tab UI + `.dgt` curve I/O + existing C `add("curve",…)` protocol (no renderer changes)
**Confidence:** HIGH (verified against live `3dDigitize.curve.r`, `3dDigitize.main.r`, `3dDigitize.digitize.r`, C `tcl_dispatch.c`; no new packages)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Control layout (UX-CRV-01)
- **D-01:** Replace modal `setCurvesNum` / `setCurrentCurvesNum` pop-ups with **inline `ttkspinbox` controls** on the Curves tab (Phase 11 pattern — no modal count windows).
- **D-02:** Spinbox validation: **minimum 1, no upper cap**; clamp on Return/FocusOut like landmark/anchor spinboxes.
- **D-03:** Rename the visible **Fit** button to **"Reset view"** (same behavior as Fit on other tabs).
- **D-04:** Vertical control order: **Total curves spinbox → Current curve spinbox → Compute Curves button → Reset view button**.

#### Compute Curves behavior
- **D-05:** **Implement real chord drawing** in `onComputeCurves()` — invoke the existing C-side curve rendering path (not a stub).
- **D-06:** Compute fires **only on manual button click** (per README workflow); placement may still call `add("curve",…)` incrementally, but Compute is the explicit (re)draw-all step.
- **D-07:** **Current curve spinbox = active edit index** — selects which curve the user is defining/editing; **Compute draws all** defined curves.
- **D-08:** During Compute, use **`busyStart` / `busyStop`** on the status bar with indeterminate progress (Phase 12 pattern).

#### Tab unlock & gating
- **D-09:** **Unlock Curves tab** when the **current specimen** has all landmarks placed (`activeDataList[[currImgId]][[3]] == landmarkNum`).
- **D-10:** Disabled-tab click message shows **landmark progress**: e.g. `"Place all N landmarks to unlock Curves — X of N placed"` (Phase 12/13 inline status pattern). Remove the stale `"Curves are coming in a later update"` message.
- **D-11:** Gate is **per current specimen only** (not all specimens in a multi-specimen session).
- **D-12:** **Surface Sliders tab unlocks with the same landmark-complete gate** as Curves (update `refreshTabGating()` — tabs 2 and 3 enabled together when landmarks complete on current specimen). Surface feature work remains out of scope.

#### Workflow polish
- **D-13:** **Wire `bind.curve()` on tab switch** to Curves (not at startup) — double-click → `onSelectCurve()` when `e$tab == 3`.
- **D-14:** Add **curve-specific placement hint** on `e$hintLabel`, e.g. `"Double-click 3 landmarks per curve segment · Current curve: N of M"`.
- **D-15:** **Extend single-level undo (Ctrl+Z)** to curve triplet placement — same `pushUndo`/`doUndo` pattern as Phase 14 landmarks/anchors.
- **D-16:** Replace duplicate-landmark `tkmessageBox` in `onSelectCurve()` with **inline `setStatus` warning** (Phase 12 non-blocking validation).

#### README & in-app text reconciliation (UX-CRV-02)
- **D-17:** **README is updated** to document the implemented UX (spinboxes, Reset view, Compute workflow) — README follows implementation, not legacy modal buttons.
- **D-18:** **Full README review** for v1.1 accuracy — section 4 (Curves), Known quirks (tab gating), and any stale v1.0 workflow text.
- **D-19:** **Sync all in-app text** with README — step indicator, keyboard shortcuts dialog, status messages, and Curves tab labels must match.
- **D-20:** Simplify curve description to: **"Define curves by selecting 3 landmarks per segment"** (drop "legacy chord segments" jargon; keep accurate that these are landmark-ID triplets, not splines).

### Claude's Discretion
- Exact spinbox label strings and hint wording (as long as they match README).
- Layout padding/spacing within the Curves tab frame (follow Digitize/Anchor tab density).
- Internal refactor of `setCurvesNum`/`setCurrentCurvesNum` handlers — may be removed or repurposed behind spinbox callbacks.
- Step-indicator wording if curves become an optional sub-step vs. staying outside the 3-step landmark→anchor→GPA flow.

### Deferred Ideas (OUT OF SCOPE)
- **Per-specimen curve storage / bind on specimen switch** — curves remain in `activeDataList[[1]][[4]]` for this phase (noted in STATE.md as future work).
- **Full Surface Sliders rehabilitation** — tab unlock only; surface placement/compute features remain as-is or stubbed.
- **Multi-specimen independent curve sets** — would require `.dgt` format extension; out of scope (CON-02).
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UX-CRV-01 | Curve tab controls re-enabled and functional (spinboxes, Compute, Reset view) | `ui.curve()` currently packs only `Fit`; modal buttons commented out (`## tkpack`). Rehab = inline spinboxes (Phase 11 `onLmCountChange` pattern), wire `onComputeCurves` to batch C redraw (mirror `switchTab` id==3), call `bind.curve(e)` on tab entry |
| UX-CRV-02 | Curve definition round-trips `.dgt`; README/in-app text matches controls | `read.curve`/`write.curve` already implement `Curve=N` + N×3 matrix; `saveToDgt`/`openDgt`/`drawElements` wired. README §4 + Known quirks stale; sync `HINT_TEXT`, `switchTab` messages, shortcuts dialog per D-19 |
</phase_requirements>

---

## Summary

Phase 15 is the only v1.1 phase that touches curve **behavior** (not just chrome). The heavy lifting already exists: `.dgt` I/O (`read.curve`/`write.curve`), landmark-triplet storage in `activeDataList[[1]][[4]]`, incremental `add("curve", p1, p2, p3)` in `onSelectCurve`, and a full batch-redraw sequence in `switchTab` when `id == 3`. What is broken is the **UI shell** (controls commented out, `onComputeCurves` stubbed) and **gating** (`refreshTabGating` hard-disables tabs 2–3; `switchTab` shows "coming later" for Curves).

The implementation path is R-side Tk/ttk only (CON-01): reuse Phase 11 `ttkspinbox` + clamp handlers, Phase 12 `setStatus`/`busyStart`/`busyStop`, Phase 13 `refreshTabGating`/`updateHintLabel`, and Phase 14 `pushUndo`/`doUndo` extensions. **Do not modify** `rtkogl.R`, `tcl_dispatch.c`, or `.dgt` format (CON-02).

`onComputeCurves` should extract (or call) the same batch protocol already proven in `switchTab` id==3: `add("initialize", 2, 0, 0)` → `add("InfoCurves", …)` → per-row `add("curve", …)` → `add("curveSetDotSliderColor", …)` → `add("InfoCurves_complete", 0, 0, 0)` → `showPicture(e)`. The simpler `draw.curves()` helper (SetCurveIndex per row only) is insufficient for Compute — it omits `InfoCurves`, slider coloring, and completion handshake [VERIFIED: codebase grep `3dDigitize.main.r` lines 543–592 vs `3dDigitize.curve.r` lines 170–175].

**Primary recommendation:** Rehab `ui.curve` with two spinboxes + two buttons; update `refreshTabGating` to unlock tabs 2+3 on current-specimen landmark completion; call `bind.curve(e)` inside `switchTab` id==3; implement `onComputeCurves` as a shared `.redrawAllCurves(e)` helper wrapped in `busyStart`/`busyStop`; extend `doUndo` for curve triplet placement; update README §4 + Known quirks.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Curve count / current-index UI | R/Tk client (`ui.curve`, spinbox handlers) | — | Pure widget state; no C involvement until user acts |
| Landmark triplet selection | R/Tk canvas bindings (`bind.curve` → `onSelectCurve`) | C engine (`set("dot","selected")`, `shows("landmark","id")`) | Double-click picks existing landmark IDs via established pick protocol |
| Curve matrix persistence | R (`activeDataList[[1]][[4]]`) | `.dgt` file (`write.curve`/`read.curve`) | v1.0 global curve storage — not per-specimen [VERIFIED: `3dDigitize.curve.r` comments + `saveToDgt`] |
| Chord rendering / batch redraw | C/OpenGL via Tcl `add("curve",…)` protocol | R orchestration (`onComputeCurves`, `switchTab`) | CON-01: renderer unchanged; R sends shape strings |
| Tab gating (Curves + Surface unlock) | R (`refreshTabGating`, `switchTab` intercept) | — | Notebook `tcl(e$nb, "tab", i, state=…)` is Tk-only |
| Status / busy / undo feedback | R (`setStatus`, `busyStart`, `pushUndo`/`doUndo`) | — | Phase 12–14 patterns; no C changes |
| User-facing documentation | README + in-app labels | — | UX-CRV-02 reconciliation |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| R + tcltk | 4.6+ / Tk 8.6 | GUI widgets, bindings, env storage | Project runtime (CON-03) [VERIFIED: `.cursor/rules` PROJECT.md] |
| tcltk2 | CRAN (pinned in DESCRIPTION) | Themed widgets if needed | Already imported |
| Existing `add`/`set`/`del` protocol | In-package `rtkogl.R` | Curve C dispatch | CON-01 — only integration surface |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| testthat | Suggests in DESCRIPTION | Unit tests for spinbox clamp, `.dgt` curve I/O, gating predicate | Nyquist validation (no GUI) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Batch redraw via `initialize`+`InfoCurves` loop | `draw.curves()` only | `draw.curves` lacks full C handshake; chords may not render correctly [VERIFIED: codebase] |
| Modal `setCurvesNum` pop-ups | Inline spinboxes | User locked D-01; Phase 11 precedent |
| Per-specimen `[[4]]` index | Keep global `[[1]][[4]]` | CON-02 + deferred in CONTEXT |

**Installation:** No new packages. Existing `Imports:` sufficient.

**Version verification:** Package `DESCRIPTION` lists `testthat` in `Suggests:`; R/tcltk ship with Windows R 4.6+ [VERIFIED: DESCRIPTION + CON-03].

---

## Package Legitimacy Audit

> Phase installs **no external packages**. Existing dependencies only.

| Package | Registry | Verdict | Disposition |
|---------|----------|---------|-------------|
| — | — | — | No new installs |

**Packages removed due to [SLOP] verdict:** none  
**Packages flagged as suspicious [SUS]:** none

---

## Architecture Patterns

### System Architecture Diagram

```
User (Curves tab)
    │
    ├─► ttkspinbox (total / current) ──► e$curveMaxCurves / e$curveCurrentCurveNumber
    │                                      └─► add("SetCurveIndex", …) on current change
    │
    ├─► Double-click canvas ──► bind.curve ──► onSelectCurve
    │       │                                      ├─► set("dot","selected") / shows("landmark","id")
    │       │                                      ├─► append row → activeDataList[[1]][[4]]
    │       │                                      ├─► add("curve", id1, id2, id3)  [incremental]
    │       │                                      └─► pushUndo(curve_place)
    │       └─► (stacked) bind.digitize addDot — no-op when landmarks complete [VERIFIED: addDot guard]
    │
    ├─► Compute Curves button ──► onComputeCurves ──► busyStart
    │                                      └─► .redrawAllCurves(e)
    │                                            ├─► add("initialize", 2, 0, 0)
    │                                            ├─► add("InfoCurves", nRows, 3, nSpecimens)
    │                                            ├─► loop add("curve", …)
    │                                            ├─► loop add("curveSetDotSliderColor", …)
    │                                            ├─► add("InfoCurves_complete", 0, 0, 0)
    │                                            └─► showPicture(e) → busyStop
    │
    ├─► File → Save DGT ──► write.curve(file, activeDataList[[1]][[4]])
    │
    └─► File → Load DGT ──► read.curve → drawElements → dgtcurvestuff + [[1]][[4]]

refreshTabGating ──► unlock nb tabs 2+3 when curr specimen landmarks complete
switchTab id==3 ──► bind.curve(e) + class(e)<-"curve" + optional tab-switch redraw
```

### Recommended Project Structure

```
integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/
├── 3dDigitize.curve.r      # ui.curve, bind.curve, onSelectCurve, onComputeCurves,
│                           # spinbox handlers, .redrawAllCurves (new), read/write.curve
├── 3dDigitize.main.r       # refreshTabGating, switchTab, saveToDgt/openDgt (minimal)
├── 3dDigitize.digitize.r   # doUndo extension for curve_place; .overrideCtrlZ on curve spins
└── tests/testthat/
    ├── test-undo-helpers.R           # extend for curve undo messaging
    ├── test-curve-io.R               # Wave 0: read.curve/write.curve round-trip
    └── test-curve-tab-gating.R       # Wave 0: refreshTabGating predicate
README.md                   # §4 Curves + Known quirks (D-17–D-20)
```

### Pattern 1: Inline count spinbox (Phase 11)

**What:** `tclVar` + `ttkspinbox` with `<Return>`/`<FocusOut>` clamp handlers.  
**When:** Total curves and current curve index (D-01, D-02).  
**Difference from landmarks:** min 1, **no 100 cap** — use large `to` (e.g. `9999`) or equivalent [CITED: https://www.tcl-lang.org/man/tcl8.6/TkCmd/spinbox.htm].

**Example (adapt from `onLmCountChange`):**

```r
# Source: 3dDigitize.digitize.r onLmCountChange (lines 658–671); Tcl 8.6 spinbox
onCurveMaxChange <- function(e) {
  val <- suppressWarnings(as.integer(tclvalue(e$curveMaxVar)))
  if (is.na(val) || val < 1L) val <- 1L
  tclvalue(e$curveMaxVar) <- as.character(val)
  e$curveMaxCurves <- val
  # Clamp current index into 1..max
  onCurveCurrentChange(e)
}

onCurveCurrentChange <- function(e) {
  maxC <- suppressWarnings(as.integer(tclvalue(e$curveMaxVar)))
  if (is.na(maxC) || maxC < 1L) maxC <- 1L
  val <- suppressWarnings(as.integer(tclvalue(e$curveCurrentVar)))
  if (is.na(val) || val < 1L) val <- 1L
  if (val > maxC) val <- maxC
  tclvalue(e$curveCurrentVar) <- as.character(val)
  e$curveCurrentCurveNumber <- val
  add("SetCurveIndex", val, -1, -2)
}
```

### Pattern 2: Batch curve redraw (canonical — from `switchTab`)

**What:** Full C curve pipeline for all rows in `activeDataList[[1]][[4]]`.  
**When:** `onComputeCurves`, tab switch replay, curve undo reversal.  
**Do not use:** `draw.curves()` alone for Compute — it skips `InfoCurves` / slider colors.

```r
# Source: 3dDigitize.main.r switchTab id==3 (lines 543–592)
.redrawAllCurves <- function(e) {
  curves <- e$activeDataList[[1]][[4]]
  if (is.null(curves) || length(curves) == 0 || nrow(curves) == 0) {
    setStatus(e, "No curve segments defined yet.", "warning")
    return(invisible(FALSE))
  }
  nSpec <- length(e$activeDataList)
  add("initialize", 2, 0, 0)
  add("InfoCurves", nrow(curves), 3, nSpec)
  add("SetLandmarkIndex", e$currImgId, -1, -2)
  add("SetCurveIndex", e$currImgId, 0, 0)
  for (j in seq_len(nrow(curves))) {
    add("curve", as.integer(curves[j, 1]), as.integer(curves[j, 2]), as.integer(curves[j, 3]))
  }
  for (j in seq_len(nrow(curves))) {
    add("curveSetDotSliderColor", as.integer(curves[j, 2]))
  }
  add("InfoCurves_complete", 0, 0, 0)
  showPicture(e)
  invisible(TRUE)
}

onComputeCurves <- function(e) {
  busyStart(e, "Computing curves\u2026", "indeterminate")
  on.exit(busyStop(e), add = TRUE)
  ok <- .redrawAllCurves(e)
  if (ok) busyStop(e, paste0("Drew ", nrow(e$activeDataList[[1]][[4]]), " curve segment(s)."), "success")
}
```

### Pattern 3: Tab gating extension

**What:** Extend `refreshTabGating` to enable notebook tabs 2 (Surface) and 3 (Curves) when current specimen landmarks complete.  
**When:** After `loadPly`, `drawElements`, `updateDotNum`, nav — same call sites as today [VERIFIED: `refreshTabGating` at `3dDigitize.main.r:303–316`].

```r
# Source: Phase 13 refreshTabGating + CONTEXT D-09/D-11/D-12
refreshTabGating <- function(e) {
  if (is.null(e$nb)) return(invisible())
  loaded <- length(e$activeDataList) > 0
  tcl(e$nb, "tab", 1, state = if (loaded) "normal" else "disabled")
  e$tabState[1] <- if (loaded) 1L else 0L
  lmOk <- loaded && e$activeDataList[[e$currImgId]][[3]] == as.integer(e$landmarkNum)
  for (i in c(2L, 3L)) {
    tcl(e$nb, "tab", i, state = if (lmOk) "normal" else "disabled")
    e$tabState[i] <- if (lmOk) 1L else 0L
  }
  tcl(e$nb, "tab", 4, state = if (lmOk) "normal" else "disabled")
  e$tabState[4] <- if (lmOk) 1L else 0L
  invisible()
}
```

### Pattern 4: `bind.curve` on tab entry (not startup)

**What:** `switchTab` id==3 calls `bind.curve(e)` before curve interaction.  
**When:** Each entry to Curves tab (D-13).  
**Note:** `bind.digitize(e)` runs once at startup; its `<Double-Button-1>` → `addDot` remains stacked. Safe because `addDot` only places when `dotNum < landmarkNum` — Curves tab is gated on landmark completion, so `addDot` is a no-op [VERIFIED: `addDot` lines 982–985, D-09 gate].

### Pattern 5: Curve undo (extend Phase 14)

**What:** On triplet completion in `onSelectCurve`, `pushUndo` with `action = "curve_place"` storing the row vector. `doUndo` removes last matrix row (or stored row) and calls `.redrawAllCurves(e)`.  
**When:** After successful third landmark pick (D-15).  
**C constraint:** No single-curve delete API — full batch redraw after matrix edit is the correct R-only reversal (CON-01) [VERIFIED: `curveReleaseArray` only via `initialize` selector 2].

```r
# In onSelectCurve, after e$activeDataList[[1]][[4]] <- curves:
pushUndo(e, list(action = "curve_place", row = as.integer(newCurve[1, ])))

# In doUndo, new branch:
} else if (entry$action == "curve_place") {
  curves <- e$activeDataList[[1]][[4]]
  if (!is.null(curves) && nrow(curves) > 0) {
    e$activeDataList[[1]][[4]] <- if (nrow(curves) == 1) NULL else curves[-nrow(curves), , drop = FALSE]
    .redrawAllCurves(e)
    msg <- "Undid curve segment placement"
    ok <- TRUE
  }
}
```

### Pattern 6: Dynamic hint (Phase 13)

Extend `updateHintLabel` `HINT_TEXT` map:

```r
"3" = "Double-click 3 landmarks per curve segment \u00b7 Current curve: {cur} of {max}"
```

Refresh hint when spinboxes change and on tab switch (D-14). Consider helper `updateCurveHint(e)` called from spinbox handlers.

### Anti-Patterns to Avoid

- **Calling `draw.curves()` for Compute:** Omits `InfoCurves` / slider-color passes — incomplete render.
- **Leaving modal `setCurvesNum`/`setCurrentCurvesNum`:** Violates D-01; dead code should be removed or gutted.
- **Enabling Curves before landmarks complete:** Breaks D-09/D-11; `onSelectCurve` needs placed landmarks to pick IDs.
- **Per-specimen `[[4]]`:** Breaks CON-02 `.dgt` format and deferred scope.
- **C engine edits for undo/delete:** CON-01 — use batch redraw.
- **Calling `bind.curve` at `ui.main` startup without tab guard:** Wastes bindings; D-13 specifies tab switch only (stacking is acceptable given `addDot` guard).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| `.dgt` curve serialization | Custom format | `read.curve` / `write.curve` | v1.0 `Curve=N` + matrix already deployed |
| OpenGL chord rendering | R-side line drawing | `add("curve", p1, p2, p3)` | C engine owns mesh projection |
| Progress spinner | New widget | `busyStart`/`busyStop` on `e$progressBar` | Phase 12 API exists in `3dDigitize.main.r:212–227` |
| Modal validation | `tkmessageBox` for duplicates | `setStatus(…, "warning")` | D-16 + UX-FB-03 |
| Multi-level undo | Stack/list history | Single-slot `e$undo` + `pushUndo` | Phase 14 D-10 |
| Tab enable/disable scatter | Per-callsite `tcl(tab,…)` | `refreshTabGating(e)` single predicate | Phase 13 pattern |

**Key insight:** Curve rehabilitation is **wiring and gating**, not new geometry — the C path and `.dgt` I/O already work when tabs are reachable.

---

## Common Pitfalls

### Pitfall 1: `activeDataList[[1]][[4]]` unset on fresh PLY session

**What goes wrong:** First `rbind(curves, newCurve)` when `[[4]]` missing.  
**Why:** PLY load does not initialize `[[4]]` until curves saved/loaded.  
**How to avoid:** `curves <- e$activeDataList[[1]][[4]]` then `if (is.null(curves)) curves <- matrix(nrow=0, ncol=3)` before `rbind`; ensure `[[1]]` exists when specimens loaded.  
**Warning signs:** `rbind` error or `nrow(NULL)` failure.

### Pitfall 2: Compute vs incremental `add("curve")` double-draw

**What goes wrong:** User sees duplicate chords or C warnings.  
**Why:** `onSelectCurve` already calls `add("curve",…)` per segment; Compute redraws all.  
**How to avoid:** Expected per D-06 — Compute is explicit full refresh; document in README. `.redrawAllCurves` must call `initialize(2)` first to release prior C state [VERIFIED: `tcl_state.c` selector 2 → `curveReleaseArray`].  
**Warning signs:** C log "curve array" errors on repeated Compute.

### Pitfall 3: Stacked double-click bindings

**What goes wrong:** Both `addDot` and `onSelectCurve` fire.  
**Why:** Only `bind.digitize` at startup; `bind.curve` adds another handler [CITED: https://www.tcl-lang.org/man/tcl8.6/TkCmd/bind.htm — multiple bindings execute unless `break`].  
**How to avoid:** Rely on landmark-complete gate + `addDot` count guard; optionally add `if (e$tab != 3) return()` at top of `onSelectCurve`.  
**Warning signs:** Landmark count increases on Curves tab (should not happen when gated).

### Pitfall 4: `refreshTabGating` not called after landmark placement

**What goes wrong:** Curves tab stays gray after placing final landmark.  
**Why:** Gating only updates where `refreshTabGating` is wired (`updateDotNum` etc.).  
**How to avoid:** Verify `updateDotNum` still calls `refreshTabGating` after changes [VERIFIED: `3dDigitize.digitize.r:1088`].  
**Warning signs:** User completes landmarks but Curves disabled until nav.

### Pitfall 5: Spinbox stores widget handle instead of integer

**What goes wrong:** Legacy `setCurvesNum` assigns `e$curveMaxCurves <- temp` (tkentry widget) [VERIFIED: `3dDigitize.curve.r:324–325`].  
**Why:** Pre-v1.1 modal code conflated widget and value.  
**How to avoid:** Separate `e$curveMaxVar` (`tclVar`) and `e$curveMaxCurves` (integer), matching `e$lmCountVar` / `e$landmarkNum` split.  
**Warning signs:** `tclvalue(e$curveMaxCurves)` errors.

### Pitfall 6: Undo without C redraw

**What goes wrong:** Matrix row removed but viewer still shows chord.  
**Why:** C curve array not updated on R-only matrix edit.  
**How to avoid:** Always call `.redrawAllCurves(e)` after undo mutation (Pitfall 2 initialize path).  
**Warning signs:** `.dgt` save correct but viewer stale.

### Pitfall 7: README / in-app drift

**What goes wrong:** Users follow modal button names that no longer exist.  
**Why:** README §4 still documents "Set curves (total) number" buttons [VERIFIED: README.md lines 112–114].  
**How to avoid:** D-17–D-20 pass across README, `HINT_TEXT`, `switchTab` messages, shortcuts dialog (Fit vs Reset view: button says "Reset view"; Ctrl+F can remain "Fit view" as same `onFit` action per D-03/D-19 discretion).

---

## Code Examples

### `.dgt` curve round-trip (existing — do not change format)

```r
# Source: 3dDigitize.curve.r read.curve / write.curve
# Header: Curve=3
# Body:  three space-separated landmark IDs per row (1-based)
write.curve(fileName, matrix(c(1,2,3, 4,5,6), ncol=3, byrow=TRUE))
```

### Disabled-tab status message (Curves)

```r
# Source: switchTab interception pattern 3dDigitize.main.r:393–405
nPlaced <- e$activeDataList[[e$currImgId]][[3]]
target <- as.integer(e$landmarkNum)
setStatus(e,
  paste0("Place all ", target, " landmarks to unlock Curves \u2014 ",
         nPlaced, " of ", target, " placed."),
  "warning")
```

### `ui.curve` pack order (D-04)

```r
# Total curves label + spin, Current curve label + spin, Compute, Reset view
tkpack(ttklabel(curveCtlFrame, text = " "), pady = 6)
sapply(list(e$curveMaxSpin, e$curveCurrentSpin, computeCurvesBtn, resetViewBtn),
       tkpack, pady = 3)
.overrideCtrlZ(e$curveMaxSpin, e)
.overrideCtrlZ(e$curveCurrentSpin, e)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Modal `setCurvesNum` pop-ups | Inline `ttkspinbox` | Phase 15 (planned) | UX-CTL-02 parity on Curves tab |
| Curves tab hard-disabled | Unlock on landmark complete | Phase 15 (planned) | UX-CRV-01 |
| `onComputeCurves` stub | Batch `.redrawAllCurves` | Phase 15 (planned) | Real chord display |
| `tkmessageBox` duplicate curve | `setStatus` warning | Phase 15 (planned) | UX-FB-03 alignment |

**Deprecated/outdated:**
- `setCurvesNum` / `setCurrentCurvesNum` modal functions — replace with spinbox handlers (may delete modal UI code).
- README "legacy chord segments" phrasing — replace per D-20.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `addDot` no-op when landmarks complete is sufficient to prevent stacked-binding conflicts | Pattern 4 | Double placement on Curves tab if gate bypassed |
| A2 | `ttkspinbox` `to = 9999` satisfies "no upper cap" for practical sessions | Pattern 1 | User cannot set >9999 curves (unlikely in morphometrics) |
| A3 | Surface tab remains functionally limited after unlock — only gating changes | Summary | User expects full surface workflow |
| A4 | Ctrl+F shortcuts dialog can keep "Fit view" while button says "Reset view" | Pitfall 7 | Minor terminology inconsistency |

**If assumptions A2/A4 need user lock:** confirm during plan review.

---

## Open Questions

1. **Step indicator for optional curves**
   - What we know: D-20 leaves curves outside 3-step landmark→anchor→GPA flow (discretion).
   - What's unclear: Whether to add a passive "Optional: Curves" line when GPA unlocked.
   - Recommendation: Keep step label unchanged unless user requests; mention curves only in `hintLabel` on tab 3.

2. **Surface tab message when enabled but still limited**
   - What we know: D-12 unlocks tab; surface features out of scope.
   - What's unclear: Replace "aren't part of this version" only for disabled-state gating, or always.
   - Recommendation: Landmark-progress message when `!lmOk`; when enabled, allow switch — existing surface tab behavior (no new messaging required).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Windows R | CON-03 runtime | ✓ (target) | 4.6+ | — |
| Tcl/Tk 8.6 | ttk widgets, bindings | ✓ (bundled with R) | 8.6 | None — CON-03 |
| C `tkogl2.dll` | `add("curve",…)` | ✓ (v1.0 shipped) | MSVC build | No fallback — CON-01 |
| testthat | Unit tests | ✓ (Suggests) | CRAN | Skip automated tests if absent |

**Missing dependencies with no fallback:**
- Windows R + `tkogl2.dll` for manual UAT (expected dev path per PROJECT.md).

**Missing dependencies with fallback:**
- None for implementation; WSL cannot run GUI — UAT on Windows R per CON-03.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | testthat (Suggests in DESCRIPTION) |
| Config file | `tests/testthat.R` |
| Quick run command | `R -q -e "testthat::test_file('tests/testthat/test-curve-io.R')"` |
| Full suite command | `R -q -e "devtools::test('integrated-guimorph-development_EOC/Project/GUImorphDevelopment')"` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| UX-CRV-01 | Spinbox clamps min 1, current ≤ max | unit | `testthat::test_file('tests/testthat/test-curve-spinbox.R')` | ❌ Wave 0 |
| UX-CRV-01 | `refreshTabGating` enables tabs 2+3 when landmarks complete | unit | `testthat::test_file('tests/testthat/test-curve-tab-gating.R')` | ❌ Wave 0 |
| UX-CRV-02 | `read.curve`/`write.curve` round-trip | unit | `testthat::test_file('tests/testthat/test-curve-io.R')` | ❌ Wave 0 |
| UX-CRV-02 | README mentions spinboxes + Compute (not modal buttons) | manual | grep README after edit | — |
| UX-CRV-01 | Compute draws chords in viewer | manual UAT | Windows R GUI session | — |
| UX-CRV-02 | Save/load `.dgt` preserves curve matrix | manual UAT | Save DGT → reload | — |

### Sampling Rate

- **Per task commit:** `testthat::test_file` for touched test files
- **Per wave merge:** `devtools::test()` filtered to curve + undo tests
- **Phase gate:** Manual UAT on Windows R — Curves tab unlock, place triplets, Compute, Save/Load DGT, Ctrl+Z curve undo

### Wave 0 Gaps

- [ ] `tests/testthat/test-curve-io.R` — temp file `write.curve` → `read.curve` equality
- [ ] `tests/testthat/test-curve-tab-gating.R` — mock `e` with `nb=NULL` guard + predicate on `tabState`
- [ ] `tests/testthat/test-curve-spinbox.R` — extract clamp logic to testable `.clampCurveCount(val, floor=1L)` or source handlers with mocks
- [ ] Extend `test-undo-helpers.R` — `curve_place` branch messaging
- [ ] Framework: testthat already in Suggests — no install gap

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Spinbox integer clamp (min 1, current ≤ max); reject `NA` |
| V6 Cryptography | no | — |

### Known Threat Patterns for R/Tk GUI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malformed `.dgt` curve section | Tampering | Existing `read.curve` numeric parse; no format change |
| Non-integer spinbox input | Tampering | `suppressWarnings(as.integer)` + clamp (Phase 11 pattern) |
| Path injection via file dialogs | Spoofing | Unchanged — use existing `tkgetOpenFile`/`tkgetSaveFile` |

`security_enforcement`: enabled (default). Phase is local GUI — low attack surface.

---

## Project Constraints (from .cursor/rules/)

- **GSD workflow:** Execute via `/gsd-execute-phase` or `/gsd-quick` — do not bypass planning artifacts [.cursor/rules GSD Workflow Enforcement].
- **CON-01 (PROJECT):** No C/OpenGL renderer changes — R-side Tk only.
- **CON-02:** Preserve v1.0 `.dgt` format — `Curve=N` header + N×3 integer matrix.
- **CON-03:** Windows R 4.6+ only for runtime UAT.
- **RTK prefix:** Shell commands use `rtk` when running git/grep in execution (`.cursorrules`).
- **No new packages** without legitimacy audit — none required this phase.

---

## Sources

### Primary (HIGH confidence)

- Live codebase: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r` — UI stub, I/O, `onSelectCurve`, `bind.curve`
- Live codebase: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` — `refreshTabGating`, `switchTab` id==3 batch redraw, `busyStart`/`busyStop`, `saveToDgt`
- Live codebase: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` — spinbox pattern, undo helpers
- Live codebase: `integrated-guimorph-development_EOC/Project/tkogl2/src/tcl_dispatch.c` — `curve`, `InfoCurves`, `initialize` selectors
- `.planning/phases/15-curve-tab-rehabilitation/15-CONTEXT.md` — locked decisions D-01–D-20

### Secondary (MEDIUM confidence)

- [Tcl 8.6 spinbox](https://www.tcl-lang.org/man/tcl8.6/TkCmd/spinbox.htm) — widget options `from`/`to`/`increment`
- [Tcl 8.6 bind](https://www.tcl-lang.org/man/tcl8.6/TkCmd/bind.htm) — multiple binding execution order
- `.planning/phases/11-direct-manipulation-controls/` — spinbox precedent
- `.planning/phases/14-keyboard-shortcuts-undo/14-02-PLAN.md` — undo extension contract for Phase 15

### Tertiary (LOW confidence)

- None requiring validation — curve C protocol verified in source.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new deps; patterns copied from Phases 11–14 in same package
- Architecture: HIGH — `switchTab` id==3 provides canonical batch redraw; I/O verified
- Pitfalls: HIGH — legacy modal/spinbox confusion and binding stack documented in source

**Research date:** 2026-06-25  
**Valid until:** 2026-07-25 (stable Tk/R stack)
