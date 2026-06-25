# Phase 12: In-GUI Feedback & Status — Research

**Researched:** 2026-06-25
**Domain:** R/Tk ttk widget patterns — status bar, progressbar, modal replacement
**Confidence:** HIGH (all findings grounded in live source; no external packages)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Single shared `ttkprogressbar` docked right of the bottom status bar. Indeterminate
  (`mode="indeterminate"`, `start`/`stop`) for GPA Compute; determinate (`maximum = N`, step per
  file) for multi-file PLY load. Set toplevel cursor to `watch`; call `tcl("update")` after
  `busyStart` so UI paints before `gpagen`/`add("specimen", …)` seizes the event loop.
- **D-02:** Surface only meaningful workflow states: load complete + specimen counts, "Specimen
  {id} — {n} of {N}", landmark/anchor placed, delete-remaining, GPA complete/failed, saved paths.
  Leave developer/debug `print()` console-only.
- **D-03:** Navigation gates → shared bottom status bar with `warning` foreground + disable
  `Next ▸`/`◂ Previous`. Proactive: updates live as markers are placed. Compute gates →
  inline `ttklabel` near `Compute`/GPA Save/Plot, abort compute, disable Save/Plot until results
  exist. Leave `surface.r:309/531` and `geomorph.r:300` as modal (not flow-control).
- **D-04:** Amber `#b35900` on `clam` `#dcdad5` background; color-only, no Unicode glyph prefixes.

### Claude's Discretion
- Exact widget placement/order within the status frame; progressbar width (~160px per UI-SPEC).
- Indeterminate-bar animation/step interval.
- Exact helper signatures and internals for `setStatus(e, text, state)` / `busyStart(e, text, mode)` /
  `busyStop(e, text, state)` and how the state→foreground map is stored (mirror `e$imgPath`
  env-storage pattern).
- Precise set of additional `print()` sites that qualify as "meaningful" under D-02.

### Deferred Ideas (OUT OF SCOPE)
- Unicode glyph prefixes (`ℹ ✓ ⚠ ✕`) for color-blind accessibility — Phase 12 is color-only.
- Specimen "N of M" + jump-to navigation control — Phase 13 (UX-WF-03).
- Undo as recovery affordance behind frictionless delete — Phase 14 (UX-KEY-02).
- Surfacing Curve / Surface-Slider tab states — Phase 15.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UX-FB-01 | Persistent status area in the GUI; key console-only info surfaced in-app | Helper API (`setStatus`), env-stored widget (`e$statusLabel`), call-site survey of `print()` / `messageToC()` |
| UX-FB-02 | Long operations show busy/progress feedback so UI never looks frozen | `ttkprogressbar` API (indeterminate/determinate), `watch` cursor, `tcl("update","idletasks")` repaint gate |
| UX-FB-03 | Modal `tkmessageBox` flow-control gates replaced by inline messages + disabled controls | Exact call-site inventory (9 nav + 3 geomorph modals), button-storage gap in `createNavFrame`/`ui.geomorph`, proactive disable hook in `updateDotNum`/`updateAnchorNum` |
</phase_requirements>

---

## Summary

Phase 12 is a pure R-side Tk/ttk UI plumbing phase: no new packages, no new data structures, no
renderer changes. The deliverable is a bottom status bar (`ttkframe` + `ttklabel` + `ttkprogressbar`)
plus three helper functions (`setStatus`, `busyStart`, `busyStop`) that replace nine `tkmessageBox`
flow-control calls and instrument the two long blocking operations (`gpagen`, multi-file
`add("specimen", …)`) with busy/progress feedback.

The critical technical questions are fully answerable from the existing source:
1. The nav buttons (`prevBtn`, `nextBtn`) and the GPA action buttons (`cmputBtn`, `saveBtn`,
   `plotspecsBtn`) are NOT stored on the env `e` today — they must be added.
2. `e$bt` in the existing code is the **"Place Anchors" checkbutton**, NOT a navigation button;
   do not confuse it when adding `e$prevBtn`/`e$nextBtn`.
3. `tcl("update", "idletasks")` is safer than `tcl("update")` for the busy-before-blocking
   repaint because it processes only redraws without processing user events (avoiding re-entrant
   `onNext` / `compute` calls from a double-click during the update).
4. The determinate PLY progress bar requires refactoring `loadPly` to loop `add("specimen", …)`
   over all N files (C already pre-allocates with `set("specimen","allocate",N)`); the current
   code only calls `add("specimen")` for specimen 1.
5. The proactive nav-gate validation hooks naturally into the already-called `updateDotNum` and
   `updateAnchorNum` — add button-state logic at the tail of each.

**Primary recommendation:** Implement in three waves: (0) add env widget storage; (1) build and
wire the status bar helpers; (2) convert all modal call sites and instrument long operations.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Status bar widget construction | Frontend (R-side Tk) | — | Pure Tk layout; no renderer involvement |
| `setStatus` / `busyStart` / `busyStop` helper API | Frontend (R-side Tk) | — | Thin wrappers over `tkconfigure` and `tcl()` |
| Nav-gate proactive disable | Frontend (R-side Tk) | — | Hooks into existing `updateDotNum`/`updateAnchorNum` tail |
| Compute-gate inline label | Frontend (R-side Tk, GPA tab) | — | `ttklabel` near `Compute` button in `gpagenCtlFrame` |
| Busy/progress for `gpagen` | Frontend (R-side Tk) | C/Tcl block | Repaint before C call; C never calls back with progress |
| Busy/progress for PLY load | Frontend (R-side Tk) | C/Tcl block | Loop `add("specimen",…)` per file; step bar per iteration |
| Console-parity routing (UX-FB-01) | Frontend (R-side Tk) | — | Replace `print()` → `setStatus()` at enumerated sites |

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `tcltk` | bundled with R | Tk widget bindings (`ttkframe`, `ttklabel`, `ttkprogressbar`, `ttkseparator`, `tkconfigure`, `tcl()`) | Already required; all target widgets are built-in Tk 8.6 |
| `tcltk2` | already in DESCRIPTION | `tk2spinbox` (used in Phase 11) | Already present; no new usage this phase |

**No new package installs required.** `ttkprogressbar` is a built-in Tk 8.6 widget accessed via
`tcltk::ttkprogressbar(...)` (or unqualified after `library(tcltk)`).

### Package Legitimacy Audit

> No external packages are installed by this phase. All widgets are built-in Tk 8.6 / ttk.

| Package | Registry | Verdict | Disposition |
|---------|----------|---------|-------------|
| `tcltk` | R built-in (not on CRAN) | OK | In use |
| `tcltk2` | CRAN | OK | Already in DESCRIPTION |

**Packages removed due to SLOP verdict:** none
**Packages flagged as suspicious:** none

---

## Architecture Patterns

### System Architecture Diagram

```
User action (click / place / nav)
        │
        ▼
Action handler (onNext / addDot / compute / loadPly / save)
        │
        ├──► busyStart(e, text, mode)  ←── set watch cursor
        │         │
        │         └──► tcl("update","idletasks")   [repaint BEFORE block]
        │
        ├──► [blocking C call: gpagen / add("specimen",…)]
        │
        └──► busyStop(e, text, state)  ←── restore cursor, stop bar
                  │
                  └──► setStatus(e, text, state)
                            │
                            └──► tkconfigure(e$statusLabel,
                                   text = text,
                                   foreground = .STATUS_FG[[state]])
```

Proactive nav-gate path (no user click required):

```
updateDotNum(e, ±1)  or  updateAnchorNum(e, ±1)
        │
        └──► [count vs. target check]
                  │
                  ├── count < target  →  setStatus(e, "{k} of {N} placed", "warning")
                  │                       tkconfigure(e$nextBtn, state="disabled")
                  │                       tkconfigure(e$prevBtn, state="disabled")
                  │
                  └── count == target →  clear warning
                                          tkconfigure(e$nextBtn, state="normal")
                                          tkconfigure(e$prevBtn, state="normal")
```

### Recommended Helper Signatures

```r
# State foreground lookup table — stored once, referenced everywhere
.STATUS_FG <- c(
  neutral = "#000000",
  info    = "#1a5fb4",
  success = "#2e7d32",
  warning = "#b35900",
  error   = "#c01c28"
)

setStatus <- function(e, text, state = "neutral") {
  tkconfigure(e$statusLabel, text = text,
              foreground = .STATUS_FG[[state]])
}

busyStart <- function(e, text, mode = "indeterminate") {
  setStatus(e, text, "info")
  tkconfigure(e$wnd, cursor = "watch")
  if (mode == "indeterminate") {
    tkconfigure(e$progressBar, mode = "indeterminate")
    tcl(e$progressBar, "start", 20)
  }
  # For determinate mode, caller configures maximum/value before calling busyStart
  tcl("update", "idletasks")   # force repaint; do NOT use tcl("update") — see Pitfall 1
}

busyStop <- function(e, text = NULL, state = "neutral") {
  tcl(e$progressBar, "stop")
  tkconfigure(e$progressBar, mode = "determinate", value = 0)
  tkconfigure(e$wnd, cursor = "")
  if (!is.null(text)) setStatus(e, text, state)
}
```

### Status Bar Construction in `ui.main`

The status bar must be packed `side = "bottom", fill = "x"` **before** `centerFrame` and `tn`
are packed (Tk stacks `side="bottom"` in reverse order relative to `side="left"`). Insert after
tab setup but before the two `tkpack` calls at lines 529–530:

```r
# Status bar (pack BEFORE centerFrame/tn to anchor it at the window bottom)
statusFrame <- ttkframe(e$wnd)
sepStatus   <- ttkseparator(e$wnd, orient = "horizontal")

e$statusLabel  <- ttklabel(statusFrame, text = "Ready — open a PLY file to begin.",
                           foreground = "#000000")
e$progressBar  <- ttkprogressbar(statusFrame, mode = "determinate",
                                 length = 160, value = 0)
e$statusFrame  <- statusFrame

tkpack(e$progressBar, side = "right", padx = 8, pady = 4)
tkpack(e$statusLabel, side = "left",  padx = 8, pady = 4, anchor = "w")

tkpack(sepStatus,   side = "bottom", fill = "x")
tkpack(statusFrame, side = "bottom", fill = "x")
# then pack centerFrame and tn as before
```

### Env Widget Storage Gaps (MUST fix before any helper can work)

**`createNavFrame` (main.r:690–723) — nav buttons never stored on `e`:**
```r
# Add before return(btnFrame):
e$nextBtn <- nextBtn
e$prevBtn <- prevBtn
```

**`ui.geomorph` (geomorph.r:25–76) — action buttons not stored; inline label missing:**
```r
# After existing button creation:
e$computeBtn     <- cmputBtn
e$saveBtn        <- saveBtn
e$plotBtn        <- plotspecsBtn
e$gpaStatusLabel <- ttklabel(gpagenCtlFrame, text = "",
                             foreground = .STATUS_FG[["warning"]])
tkgrid(e$gpaStatusLabel, sticky = "w", padx = 8)
```

### `ttkprogressbar` API (Tk 8.6 / tcltk)

**Create:**
```r
e$progressBar <- ttkprogressbar(parent, mode = "determinate",
                                length = 160, value = 0)
```

**Indeterminate mode (GPA Compute):**
```r
tkconfigure(e$progressBar, mode = "indeterminate")
tcl(e$progressBar, "start", 20)   # 20ms step interval
# ... blocking call ...
tcl(e$progressBar, "stop")
tkconfigure(e$progressBar, mode = "determinate", value = 0)
```

**Determinate mode (PLY load):**
```r
tkconfigure(e$progressBar, mode = "determinate",
            maximum = as.numeric(nSpecimens), value = 0)
for (i in seq_len(nSpecimens)) {
  setStatus(e, paste0("Loading ", basename(imgList[[i]]),
                      " (", i, " of ", nSpecimens, ")\u2026"), "info")
  tcl("update", "idletasks")
  add("specimen", imgList[[i]], i)
  tkconfigure(e$progressBar, value = as.numeric(i))
}
```

**Note on `start`:** `tcl(bar, "start", N)` is the Tcl widget command, called via `tcl()` in R.
The R-level `tcltk::ttkprogressbar()` constructor does NOT have a `start` argument.

### Anti-Patterns to Avoid

- **Using `tkpack` order for the status bar after `centerFrame`:** Tk resolves `side="bottom"`
  in declaration order — if `centerFrame` is packed first, the status bar pushes above it. Always
  pack `statusFrame` (and its separator) before packing `centerFrame`/`tn`.
- **Using `tkconfigure(progressBar, mode="indeterminate", start=…)` in one call:** `start` is a
  widget *command*, not a configure option. Call `tkconfigure(…, mode="indeterminate")` first,
  then `tcl(bar, "start", interval)` separately.
- **Using `tcl("update")` instead of `tcl("update","idletasks")` before blocking calls:** see
  Pitfall 1 below.
- **Leaving nav/action buttons as locals in `createNavFrame`/`ui.geomorph`:** helpers cannot
  `tkconfigure` them without env references.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Progress animation | Custom Tk canvas loop | `ttkprogressbar` `start`/`stop` | Built-in; theme-aware; correct on all DPI |
| Color-accessible state indicators | Custom color management | `.STATUS_FG` named vector + `tkconfigure(..., foreground=…)` | One lookup, consistent everywhere |
| Cursor busy state | Custom cursor stack | `tkconfigure(e$wnd, cursor="watch"/"")` | Tk propagates watch cursor to all children automatically |
| Event loop pump | Custom `Sys.sleep` + poll | `tcl("update","idletasks")` | Correct Tk idiom; safe re-entrancy profile |

---

## Common Pitfalls

### Pitfall 1: `tcl("update")` vs `tcl("update","idletasks")` — re-entrant GL event risk

**What goes wrong:** Using `tcl("update")` (full event flush) before a blocking C call processes
pending mouse/keyboard events in addition to redraws. If the user double-clicks "Compute" during
the update, a second `compute()` call starts before `gpagen` returns from the first, corrupting
`e$gm.results`. The GL `<Configure>` handler (150ms debounce) also fires, pushing `set("window","size")`
into a C call that is mid-compute.

**Why it happens:** `tcl("update")` re-enters the Tcl event loop fully, including user-input
events. `tcl("update","idletasks")` (R expression: `tcl("update", "idletasks")`) processes only
idle callbacks (widget redraws, pending `after idle` tasks) — it does NOT pull user events.

**How to avoid:** Use `tcl("update", "idletasks")` in `busyStart`. This guarantees the status
label and progressbar repaint before the blocking call without the re-entrancy hazard.

**Warning signs:** Double-clicking Compute causes two `print("compute")` lines in the console
without an intervening `busyStop` message.

**Note on CONTEXT.md wording:** D-01 says `tcl("update")`. The existing `ui.main` code at
line 561 uses `tcl("update")` for the pre-GL-bind flush (safe there because no GL call is
in flight). The safer choice for `busyStart` is `tcl("update","idletasks")`. Both are R calls
to Tcl `update` vs `update idletasks`; the R form is `tcl("update")` vs `tcl("update","idletasks")`.

### Pitfall 2: `loadPly` only calls `add("specimen",…)` for specimen 1

**What goes wrong:** The determinate per-file PLY progress bar (D-01 / UI-SPEC) requires iterating
`add("specimen",…)` over all N files with status updates between iterations. The current
`loadPly` (main.r:1274) only calls `add("specimen", e$activeDataList[[1]][[1]], 1)` once.
Subsequent specimens are loaded lazily on `onNext`/`onPrevious`.

**Why it happens:** Lazy load was the original design — specimens are loaded on demand.

**How to fix:** Replace the single `add("specimen"…)` call with a loop over all specimens,
with `busyStart`/step status updates. The C engine already pre-allocates via
`set("specimen","allocate",N)` at line 1273, so all N slots exist. Loading all upfront is safe.

**Impact on navigation:** If all specimens are pre-loaded, `onNext`/`onPrevious` no longer need
to call `add("specimen",…)` for the C engine — only `showPicture(e)`. Verify that
`add("specimen",…)` is idempotent or already-loaded-safe before simplifying nav handlers.

**Alternative (minimal change):** Keep lazy loading; show an indeterminate bar for the initial
single-file load and add per-file status text during navigation. This contradicts D-01 (determinate
per file) and the UI-SPEC copy contract.

### Pitfall 3: `e$bt` is the "Place Anchors" checkbutton — NOT a nav button

**What goes wrong:** Searching for nav button references via `e$bt` yields the wrong widget.
`ui.digitize` (digitize.r:131) assigns the "Place Anchors" `ttkcheckbutton` to `e$bt`. The calls
`tkconfigure(e$bt, state = "disabled"/"normal")` in `onNext` (line 973) and `onPrevious`
(line 1121) control that checkbox, not navigation.

**How to avoid:** Add `e$nextBtn <- nextBtn` and `e$prevBtn <- prevBtn` to `createNavFrame`.
Do not repurpose `e$bt`.

### Pitfall 4: Status bar packed in wrong position renders above the notebook

**What goes wrong:** If `statusFrame` is packed with `side="bottom"` after `centerFrame` and `tn`
are already packed with `side="left"`, Tk inserts the status bar above the side-packed content,
splitting the layout.

**Why it happens:** Tk's packer resolves `side="bottom"` in declaration order relative to what
has already claimed the remaining space.

**How to avoid:** Pack the separator and `statusFrame` BEFORE `tkpack(centerFrame, …)` and
`tkpack(tn, …)` in `ui.main`.

### Pitfall 5: `return()` in modal-replaced handlers silently discards the proactive gate

**What goes wrong:** The original pattern is `tkmessageBox(…); return()`. If the modal is removed
but the `return()` is kept, the nav gate still blocks (just silently). If the `return()` is also
removed without enabling the proactive disable, navigation proceeds unconditionally.

**How to avoid:** For each replaced gate:
1. Remove `tkmessageBox(…)` and its `return()`.
2. Add `setStatus(e, "<warning>", "warning")` + `tkconfigure(<btn>, state="disabled")`.
3. The proactive hook in `updateDotNum`/`updateAnchorNum` clears the warning and re-enables
   the button when the count condition is met.

---

## Code Examples

### Setting watch cursor before blocking call

```r
# Source: R tcltk package documentation (built-in)
busyStart <- function(e, text, mode = "indeterminate") {
  setStatus(e, text, "info")
  tkconfigure(e$wnd, cursor = "watch")
  if (mode == "indeterminate") {
    tkconfigure(e$progressBar, mode = "indeterminate")
    tcl(e$progressBar, "start", 20)
  }
  tcl("update", "idletasks")
}
```

### Proactive nav-gate disable (tail of updateDotNum)

```r
# Append to updateDotNum() after existing tab-enable logic:
nTarget <- as.integer(e$landmarkNum)
if (!is.null(e$nextBtn) && !is.null(e$prevBtn)) {
  if (nDots < nTarget) {
    gateMsg <- paste0("Place all ", nTarget,
                      " landmarks before continuing \u2014 ",
                      nDots, " of ", nTarget, " placed.")
    setStatus(e, gateMsg, "warning")
    tkconfigure(e$nextBtn, state = "disabled")
    tkconfigure(e$prevBtn, state = "disabled")
  } else {
    # Counts met — restore status and enable nav
    setStatus(e, paste0("Specimen ", e$currImgId,
                        " \u2014 ", e$currImgId, " of ",
                        length(e$activeDataList)), "neutral")
    tkconfigure(e$nextBtn, state = "normal")
    tkconfigure(e$prevBtn, state = "normal")
  }
}
```

### Determinate PLY load loop (refactored section of loadPly)

```r
# Replace lines 1273-1274 in loadPly with:
set("specimen", "allocate", nSpecimens)
tkconfigure(e$progressBar, mode = "determinate",
            maximum = as.numeric(nSpecimens), value = 0)
for (i in seq_len(nSpecimens)) {
  fname <- e$activeDataList[[i]][[1]]
  setStatus(e, paste0("Loading ", basename(fname),
                      " (", i, " of ", nSpecimens, ")\u2026"), "info")
  tkconfigure(e$wnd, cursor = "watch")
  tcl("update", "idletasks")
  add("specimen", fname, i)
  tkconfigure(e$progressBar, value = as.numeric(i))
}
tkconfigure(e$wnd, cursor = "")
s <- if (nSpecimens == 1) "" else "s"
setStatus(e, paste0("Loaded ", nSpecimens, " specimen", s, "."), "success")
tkconfigure(e$progressBar, mode = "determinate", value = 0)
```

### Compute gate replacement (geomorph.r:167)

```r
# Replace:
#   tkmessageBox(title="Information", message=paste("Incorrect num of landmark for specimen",i), …)
#   return()
# With:
msg <- paste0("Specimen ", i, " needs ", as.numeric(e$landmarkNum),
              " landmarks \u2014 ", nrow(landmarks),
              " placed. Complete it before Compute.")
tkconfigure(e$gpaStatusLabel, text = msg,
            foreground = .STATUS_FG[["warning"]])
tkconfigure(e$saveBtn,  state = "disabled")
tkconfigure(e$plotBtn,  state = "disabled")
return()     # abort compute — return() stays; it's the right behavior here
```

---

## Call-Site Inventory: All Modals to Convert

### Navigation gates (`onNext` and `onPrevious` in main.r)

| Approx. Line | Function | Message | Replacement |
|--------------|----------|---------|-------------|
| ~897 | `onNext` | "It's the last specimen" | Status: "Already at the last specimen ({N} of {N})." + disable `e$nextBtn` |
| ~913 | `onNext` | "Incorrect number of landmarks" | Status: "Place all {target} landmarks…" (warning) + disable both nav btns |
| ~926 | `onNext` | "Anchors are enabled, place correct number…" | Status: "Place all {target} anchors…" (warning) + disable nav |
| ~942 | `onNext` | "Incorrect number of anchors" | Status: same anchor warning + disable nav |
| ~958 | `onNext` | "Please open digitizing tab to switch specimen" | Status: "Switch to the 3D Digitizing tab to change specimen." (warning) |
| ~1073 | `onPrevious` | "It's the first specimen" | Status: "Already at the first specimen (1 of {N})." + disable `e$prevBtn` |
| ~1085 | `onPrevious` | "Incorrect number of landmarks" | Same as ~913 above |
| ~1098 | `onPrevious` | "Incorrect number of anchors" | Same as ~942 above |
| ~1109 | `onPrevious` | "Please open digitizing tab…" | Same as ~958 above |

**Total nav modals to remove: 9** (all in `onNext` + `onPrevious`)

First/last-specimen disable is also proactive: wire into `showPicture` or the tail of each
nav handler — disable `e$nextBtn` if `e$currImgId == length(e$activeDataList)`, disable
`e$prevBtn` if `e$currImgId == 1`.

### Compute / Save / Plot gates (geomorph.r)

| Approx. Line | Function | Message | Replacement |
|--------------|----------|---------|-------------|
| ~144 | `.gm_results_or_warn` | "Run Compute first" | `e$gpaStatusLabel`: "Run Compute before saving or plotting results." (warning); disable `e$saveBtn`, `e$plotBtn` |
| ~167 | `compute` | "Incorrect num of landmark for specimen {i}" | `e$gpaStatusLabel`: "Specimen {i} needs {target} landmarks…" (warning); `return()` keeps |
| ~195 | `compute` | "Incorrect num of anchor for specimen {i}" | `e$gpaStatusLabel`: "Specimen {i} needs {target} anchors…" (warning); `return()` keeps |

**Note:** The `return()` inside `compute` gates stays — the compute is correctly aborted; only
the modal is replaced with an inline label.

### Modals to leave unchanged

| File | Line | Message | Reason |
|------|------|---------|--------|
| `surface.r` | ~309 | "Template created" | Informational confirmation, not flow-control |
| `surface.r` | ~531 | "Specimen is downsampled" | Informational notice, not flow-control |
| `geomorph.r` | ~300 | `tryCatch` rgl/plot error | Genuine error dialog; no nav gate function |

---

## Runtime State Inventory

> Omitted — this is a greenfield addition (new widgets, new helpers), not a rename/refactor phase.
> No stored data, live service config, OS registrations, secrets, or build artifacts reference
> the changed identifiers.

---

## Environment Availability

| Dependency | Required By | Available | Notes |
|------------|------------|-----------|-------|
| R ≥ 4.6 + Tk 8.6 | All widget creation | ✓ (CON-03 baseline) | `ttkprogressbar` is Tk 8.6+ |
| `tcltk` | `ttkprogressbar`, `tkconfigure`, `tcl()` | ✓ built-in | No install needed |
| `tcltk2` | `tk2spinbox` (Phase 11, unchanged) | ✓ in DESCRIPTION | No change needed |
| `geomorph::gpagen` | UX-FB-02 busy wrapping | ✓ in DESCRIPTION | Only wrapped, not changed |

**Missing dependencies with no fallback:** none.

---

## Validation Architecture

> Nyquist validation is ENABLED (no `config.json` found; treat as enabled per spec).

### Test Framework

| Property | Value |
|----------|-------|
| Framework | None exists — no `tests/` directory, no `testthat` config in package |
| Config file | None — Wave 0 must create `tests/testthat/` and `tests/testthat.R` |
| Quick run command | `devtools::test()` (after framework setup) |
| Full suite command | `devtools::test()` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | Notes |
|--------|----------|-----------|-------------------|-------|
| UX-FB-01 | `setStatus`, `busyStart`, `busyStop` helpers exist with correct signatures | unit | `devtools::test()` (test file: `tests/testthat/test-status-helpers.R`) | ✅ Automatable: inspect env after mock-call |
| UX-FB-01 | `e$statusLabel` is a Tk widget handle stored on env after `ui.main` | unit/smoke | Source inspection + `is.character(class(e$statusLabel))` | ✅ Can be tested with a mocked `e` env |
| UX-FB-02 | `ttkprogressbar` widget exists on `e$progressBar` | unit | Same test file; check `!is.null(e$progressBar)` | ✅ Automatable |
| UX-FB-02 | GPA Compute sets watch cursor and calls `tcl("update","idletasks")` — visual | manual | — | ❌ Requires running GUI |
| UX-FB-02 | Determinate bar steps per file during PLY load — visual | manual | — | ❌ Requires running GUI |
| UX-FB-03 | No `tkmessageBox` at the 9 nav-gate call sites | static grep | `grep -n 'tkmessageBox' R/3dDigitize.main.r` — must return 0 for the 9 sites | ✅ Automatable via R CMD check or grep |
| UX-FB-03 | No `tkmessageBox` at geomorph.r:167/195/144 | static grep | `grep -n 'tkmessageBox' R/3dDigitize.geomorph.r` — must return only the rgl error handler (line ~300) | ✅ Automatable |
| UX-FB-03 | `e$nextBtn` and `e$prevBtn` exist and are Tk widget handles | unit | Test env storage post-`createNavFrame` | ✅ Automatable |
| UX-FB-03 | Nav buttons disable on landmark/anchor gate — visual | manual UAT | — | ❌ Requires running GUI |
| UX-FB-03 | Warning color (#b35900) renders correctly on clam background | manual UAT | — | ❌ Requires running GUI |

### Sampling Rate

- **Per task commit:** `grep -c 'tkmessageBox' R/3dDigitize.main.r R/3dDigitize.geomorph.r` (verify decreasing)
- **Per wave merge:** `devtools::test()` (green required)
- **Phase gate:** Full test suite green + manual UAT checklist below before `/gsd-verify-work`

### Manual UAT Checklist (visual checks that cannot be automated)

These require launching `GUImorph::start()` on Windows R 4.6+:

- [ ] Status bar renders at full window width at bottom, below viewport, with separator above
- [ ] "Ready — open a PLY file to begin." displayed at app launch
- [ ] Indeterminate bar animates visibly during GPA Compute (not just a static bar)
- [ ] Watch cursor appears during Compute and PLY load; restores on completion
- [ ] "Computing GPA alignment for {N} specimens…" shown in blue during compute
- [ ] "GPA complete — {N} specimens aligned." shown in green on success
- [ ] Determinate bar steps per file during multi-file PLY load
- [ ] "Loading {file} ({i} of {N})…" copy matches UI-SPEC for each step
- [ ] Landmark placed → "Placed landmark {k} of {target} on specimen {id}." in neutral color
- [ ] "{k} of {target} placed" warning text in amber (#b35900) when count incomplete
- [ ] Next ▸ and ◂ Previous buttons disabled while landmark count incomplete on Digitize tab
- [ ] Buttons re-enable when count met (proactive, without requiring a click)
- [ ] "Already at the last specimen…" shows when already on last specimen (no modal popup)
- [ ] "Already at the first specimen…" shows when already on first specimen (no modal popup)
- [ ] Inline GPA label shows "Run Compute before saving or plotting results." warning
- [ ] Save Result / Plot Aligned Specimens disabled when no GPA results; re-enabled after Compute
- [ ] Inline compute error label appears (not a modal) when landmark count wrong for a specimen

### Wave 0 Gaps

- [ ] `tests/testthat.R` — package test entry point
- [ ] `tests/testthat/test-status-helpers.R` — covers UX-FB-01, UX-FB-02 helper signatures
- [ ] `tests/testthat/test-modal-removal.R` — covers UX-FB-03 static call-site checks
- [ ] Framework install: `devtools::install(".")` after adding `Suggests: testthat` to DESCRIPTION

---

## Security Domain

> UX-FB-03 replaces modal call sites; no authentication, session management, data-at-rest, or
> network surface is changed. The phase touches only widget state and text strings.

### Applicable ASVS Categories

| ASVS Category | Applies | Notes |
|---------------|---------|-------|
| V2 Authentication | no | No auth changes |
| V3 Session Management | no | Desktop app, no session tokens |
| V4 Access Control | no | No permission model |
| V5 Input Validation | partial | Status copy strings contain runtime values — construct with `paste0`/`sprintf`, not `eval`/`parse`. File paths from `tkgetOpenFile` are trusted (system dialog). |
| V6 Cryptography | no | No cryptographic operations |

**Applicable threat pattern for V5:** Status label text is built from `e$currImgId`, `e$landmarkNum`,
and filename strings obtained from the Tk file picker. These are R integers/character vectors passed
to `paste0` — no injection surface. No user-typed free text is interpolated into widget labels.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `tkmessageBox` as flow-control gate | Inline `ttklabel` + disabled button | Phase 12 (this) | User never blocked by modal; gate is proactive |
| `print()` as the only feedback | `setStatus()` surfaces key states in GUI | Phase 12 (this) | Console parity without losing console output |
| No busy indication | `ttkprogressbar` + watch cursor | Phase 12 (this) | UI never looks frozen during 10–60s compute |

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `add("specimen", file, i)` is idempotent (or loading the same slot twice is harmless) for the pre-load refactor | Code Examples (PLY loop) | If not idempotent, loading all N up-front may corrupt C-side specimen memory; fall back to lazy-load with indeterminate bar |
| A2 | `tkconfigure(e$wnd, cursor = "watch")` propagates watch cursor to all child widgets including the GL canvas | Common Pitfalls / busyStart | If the GL canvas window does not inherit cursor from its parent, user sees arrow cursor over viewport during compute; fix: also `tkconfigure(e$canvasFrame, cursor = "watch")` |

---

## Open Questions

1. **`add("specimen",…)` idempotency for pre-load loop**
   - What we know: C allocates `N` slots via `set("specimen","allocate",N)`. Currently only slot 1 is
     populated at load time.
   - What's unclear: Whether calling `add("specimen", file, i)` for `i = 2..N` at load time conflicts
     with the subsequent call in `onNext`/`onPrevious`.
   - Recommendation: Inspect `rtkogl.R`'s `add` shim and the C-side `add` handler for "already loaded"
     guard logic before finalizing the loop approach. If not idempotent, remove the `add` call from nav
     handlers once pre-loaded, or keep lazy-load with an indeterminate bar (documenting the UI-SPEC
     tension in a decision comment).

2. **`e$prevBtn` / `e$nextBtn` enable/disable scope for the "tab != 0" gate**
   - What we know: The "Please open digitizing tab…" gate (main.r:~958) fires when `e$tab != 0`.
     D-03 says: "Status hint; do not block silently."
   - What's unclear: Should both nav buttons be disabled (the current `return()` behavior), or only
     show the warning and allow nav? The UI-SPEC copy says "do not block silently" — this implies
     the status hint is shown but navigation is NOT blocked (i.e., the gate is removed as a hard block
     and replaced with a softer warning).
   - Recommendation: Show warning in status, do NOT disable nav buttons for this specific gate (only
     disable for landmark/anchor count violations). Confirm with user if ambiguous.

---

## Sources

### Primary (HIGH confidence — grounded in live source)
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` — layout,
  nav handlers, `loadPly`, `createNavFrame`, `showPicture`, existing `tcl("update"/"update idletasks")` usage
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` —
  `ui.digitize`, `updateDotNum`, `updateAnchorNum`, `addDot`, `addAnchor`, `e$bt` assignment
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r` —
  `ui.geomorph`, `compute`, `.gm_results_or_warn`, `gpagen` call site, modal call sites
- `.planning/phases/12-in-gui-feedback-status/12-CONTEXT.md` — locked decisions D-01..D-04
- `.planning/phases/12-in-gui-feedback-status/12-UI-SPEC.md` — exact copy strings, color tokens,
  spacing, modal replacement table
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION` — package imports
  (no new packages required)

### Secondary (MEDIUM confidence — R docs / tcltk package)
- R `tcltk` package help (`?ttkprogressbar`) — `ttkprogressbar` mode, length, value options [ASSUMED:
  training knowledge; consistent with Tk 8.6 widget manual]
- Tcl/Tk 8.6 `ttk::progressbar` widget manual — `start`, `stop`, `step` widget commands [ASSUMED]

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; confirmed in DESCRIPTION
- Architecture: HIGH — all widget patterns grounded in live source code
- Call-site inventory: HIGH — all 12 modal locations read directly from source
- `ttkprogressbar` API: MEDIUM — training knowledge consistent with Tk 8.6 docs; verify `start`/`stop` command syntax against `?ttkprogressbar` in target R 4.6 session before plan execution

**Research date:** 2026-06-25
**Valid until:** 2026-09-25 (stable Tk 8.6 API; no fast-moving dependencies)
