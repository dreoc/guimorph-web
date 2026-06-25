# Phase 12: In-GUI Feedback & Status — Pattern Map

**Mapped:** 2026-06-25
**Files analyzed:** 3 source files (13 distinct change sites; no new files created this phase)
**Analogs found:** 13 / 13 (all in-codebase; no new architectural territory)

---

## File Classification

All phase work is **in-place edits** to three existing R source files. Change sites are grouped
by file and function because each distinct edit site has a separate role and analog.

| Change Site | File | Role | Data Flow | Closest Analog | Match Quality |
|-------------|------|------|-----------|----------------|---------------|
| `.STATUS_FG` lookup + `setStatus`/`busyStart`/`busyStop` helpers | `main.r` (new top-of-file section) | utility | request-response | `updateDotNum` (digitize.r:954–982) — `tkconfigure` to update widget + `e$lmColorLabel` foreground pattern | role-match |
| `ui.main` status bar widget construction | `main.r` (~line 529 insert) | widget/layout | request-response | `e$imgPath <- ttklabel(...)` (main.r:490–491) | exact |
| `createNavFrame` nav-button env storage | `main.r` (lines 723–724 insert) | widget/config | request-response | `assign("bt", placeAnchors, envir = e)` (digitize.r:131) | exact |
| `onNext` nav-gate modal replacement | `main.r` (lines 895–965) | event-handler | request-response | `tkconfigure(e$bt, state = "disabled")` (main.r:973) | role-match |
| `onPrevious` nav-gate modal replacement | `main.r` (lines 1071–1116) | event-handler | request-response | `tkconfigure(e$bt, state = "disabled")` (main.r:973) | role-match |
| `loadPly` determinate PLY loop refactor | `main.r` (lines 1273–1274) | event-handler | file-I/O | `set("specimen","allocate",N)` + `add("specimen",…)` (main.r:1273–1274) | exact |
| `showPicture` console-parity | `main.r` (line 746) | utility | request-response | `print(paste("showPicture : …"))` (main.r:746) — call to replace | exact |
| `ui.geomorph` env button+label storage | `geomorph.r` (lines 54–75 augment) | widget/layout | request-response | `assign("bt2", cmputBtn, envir = e)` (geomorph.r:55) + `e$landMarkNumLabel <- ttklabel(...)` (digitize.r:166–169) | exact |
| `.gm_results_or_warn` modal replacement | `geomorph.r` (lines 136–151) | utility | request-response | `tkconfigure(e$bt, state = "disabled")` (main.r:973) | role-match |
| `compute` modal replacement (landmark gate) | `geomorph.r` (line 167) | service | blocking | `tkconfigure(e$bt, state = "disabled")` (main.r:973) | role-match |
| `compute` modal replacement (anchor gate) | `geomorph.r` (line 195) | service | blocking | `tkconfigure(e$bt, state = "disabled")` (main.r:973) | role-match |
| `updateDotNum` proactive nav-gate hook | `digitize.r` (lines 967–981 augment) | utility | event-driven | `tcl(e$nb, "tab", i, state = "normal")` block (digitize.r:967–981) | exact |
| `updateAnchorNum` proactive nav-gate hook | `digitize.r` (lines 998–1005 augment) | utility | event-driven | `tcl(e$nb, "tab", i, state = "normal")` block (digitize.r:998–1005) | exact |

---

## Pattern Assignments

---

### `.STATUS_FG` / `setStatus` / `busyStart` / `busyStop` helpers
*(new utility block, to be inserted near top of `3dDigitize.main.r`)*

**Analog 1 — `tkconfigure` update-widget-text pattern:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` lines 954–965

```r
updateDotNum <- function(e, delt)
{
  nDots <- e$activeDataList[[e$currImgId]][[3]]
  nDots <- nDots + delt
  tkconfigure(e$landMarkNumLabel, text = paste("Number of Landmarks: ", nDots))
  e$activeDataList[[e$currImgId]][[3]] <- nDots
  print (paste("Updated number of (landmarks) dots", nDots))

  if (!is.null(e$lmCountSpin)) {
    tkconfigure(e$lmCountSpin, from = max(1L, as.integer(nDots)))
  }
```

**Analog 2 — foreground color applied directly to a stored widget:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` lines 154–160

```r
  e$lmColorLabel <-
    tklabel(
      lmColorFrame,
      text = 'aa',
      foreground = '#ff0000',
      background = '#ff0000'
    )
```

**Core helper pattern (copy verbatim from RESEARCH.md — no codebase analog exists yet):**

```r
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
  tcl("update", "idletasks")   # NOT tcl("update") — avoids re-entrant compute calls
}

busyStop <- function(e, text = NULL, state = "neutral") {
  tcl(e$progressBar, "stop")
  tkconfigure(e$progressBar, mode = "determinate", value = 0)
  tkconfigure(e$wnd, cursor = "")
  if (!is.null(text)) setStatus(e, text, state)
}
```

**Placement:** Insert this block just after `get_digitize_date()` / other version-stamp functions
at the top of `3dDigitize.main.r`, before `init.main`.

---

### `ui.main` — status bar widget construction
*(insert in `3dDigitize.main.r` before `tkpack(centerFrame, …)` at line 529)*

**Analog — env-stored ttklabel pattern:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` lines 489–492

```r
  titleFrame <- ttkframe(centerFrame)
  e$imgPath <- ttklabel(titleFrame, text = "Specimen Id: NA")
  tkpack(e$imgPath)
  tkpack(titleFrame)
```

**Core construction pattern** (mirror structure; pack `side = "bottom"` BEFORE `centerFrame`/`tn`):

```r
  # Status bar — pack BEFORE centerFrame/tn so Tk anchors it at window bottom
  statusFrame    <- ttkframe(e$wnd)
  sepStatus      <- ttkseparator(e$wnd, orient = "horizontal")

  e$statusLabel  <- ttklabel(statusFrame,
                             text = "Ready \u2014 open a PLY file to begin.",
                             foreground = "#000000")
  e$progressBar  <- ttkprogressbar(statusFrame, mode = "determinate",
                                   length = 160, value = 0)
  e$statusFrame  <- statusFrame

  tkpack(e$progressBar, side = "right", padx = 8, pady = 4)
  tkpack(e$statusLabel, side = "left",  padx = 8, pady = 4, anchor = "w")

  tkpack(sepStatus,   side = "bottom", fill = "x")
  tkpack(statusFrame, side = "bottom", fill = "x")
  # THEN pack centerFrame and tn as before (lines 529-530)
```

**Anti-pattern to avoid:** Do NOT pack `statusFrame` after `centerFrame`/`tn` are already packed;
Tk's `side="bottom"` resolves in declaration order — too late and the bar renders above the notebook
(Pitfall 4 in RESEARCH.md).

---

### `createNavFrame` — nav-button env storage
*(insert in `3dDigitize.main.r` after line 705, before `tkpack` block at 707)*

**Analog 1 — `assign()` env widget storage:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` line 131

```r
  assign("bt", placeAnchors, envir = e)
```

**Analog 2 — same pattern, GPA tab:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r` line 55

```r
  assign("bt2", cmputBtn, envir = e)
```

**Core storage pattern** (add immediately after `nextBtn` definition at line 705, before the `tkpack`
block):

```r
  e$prevBtn <- prevBtn
  e$nextBtn <- nextBtn
```

**Note:** Do NOT use `assign()`; direct `e$xxx <-` assignment is the newer pattern used for all
other widget references (`e$imgPath`, `e$landMarkNumLabel`, etc.). `assign("bt", …, envir = e)` at
digitize.r:131 is an older form. Use `e$prevBtn <- prevBtn` directly.

---

### `onNext` — nav-gate modal replacement
*(edit `3dDigitize.main.r` lines 895–965)*

**Analog — existing button-state disable immediately after the now-dead gate block:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` line 973

```r
  tkconfigure(e$bt, state = "disabled")
```

**Existing modal pattern to replace** (all 4 blocks in `onNext`, lines 895–965):

```r
  if (e$currImgId == length(e$activeDataList))
  {
    tkmessageBox(title = "Information", message = "It's the last specimen",
                 icon = "info", type = "ok")
    return ()
  }
  # ... (similar tkmessageBox + return() blocks at lines 913, 926, 942, 958)
```

**Replacement pattern:**

```r
  # Last-specimen gate — disable Next instead of modal
  if (e$currImgId == length(e$activeDataList))
  {
    setStatus(e,
      paste0("Already at the last specimen (", e$currImgId,
             " of ", length(e$activeDataList), ")."),
      "warning")
    tkconfigure(e$nextBtn, state = "disabled")
    return()
  }

  # Landmark count gate — proactive; paired with updateDotNum hook
  if (e$tab == 0 && nCurrLM < as.integer(e$landmarkNum))
  {
    setStatus(e,
      paste0("Place all ", e$landmarkNum,
             " landmarks before continuing \u2014 ",
             nCurrLM, " of ", e$landmarkNum, " placed."),
      "warning")
    tkconfigure(e$nextBtn, state = "disabled")
    tkconfigure(e$prevBtn, state = "disabled")
    return()
  }

  # "Tab != 0" gate — status hint only, do NOT hard-block nav (D-03)
  if (e$tab != 0)
  {
    setStatus(e, "Switch to the 3D Digitizing tab to change specimen.", "warning")
    return()
  }
```

**Error handling note:** `return()` is retained in ALL nav gates — it correctly aborts navigation.
Only `tkmessageBox(…)` is removed; the `return()` stays (Pitfall 5 in RESEARCH.md).

---

### `onPrevious` — nav-gate modal replacement
*(edit `3dDigitize.main.r` lines 1071–1116)*

**Analog:** Same as `onNext` above — identical modal-replace pattern.
Also: `tkconfigure(e$bt, state = "normal")` at main.r:1121 — existing enable pattern on prev nav.

**Existing disable call to preserve context:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` line 1121

```r
  if (as.integer(e$currImgId) == 1)
  {
    tkconfigure(e$bt, state = "normal")
  }
```

**Replacement pattern** (mirror `onNext` substitution):

```r
  if (e$currImgId == 1)
  {
    setStatus(e,
      paste0("Already at the first specimen (1 of ",
             length(e$activeDataList), ")."),
      "warning")
    tkconfigure(e$prevBtn, state = "disabled")
    return()
  }
  # landmark/anchor/tab gates: same setStatus + tkconfigure pattern as onNext
```

---

### `loadPly` — determinate PLY loop refactor
*(edit `3dDigitize.main.r` lines 1273–1274)*

**Analog — existing single-specimen add call being replaced:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` lines 1273–1274

```r
      set("specimen", "allocate", length(e$activeDataList))
      add("specimen", e$activeDataList[[1]][[1]], e$currImgId)
```

**Core loop pattern** (replace lines 1273–1274):

```r
      nSpecimens <- length(e$activeDataList)
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

**Open question flag (A1):** If `add("specimen", file, i)` is not idempotent when called again
during `onNext`/`onPrevious`, remove the `add` call from nav handlers after pre-loading. See
RESEARCH.md §Open Questions #1.

---

### `showPicture` — console-parity status
*(edit `3dDigitize.main.r` line 746)*

**Analog — existing `print()` call being augmented:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` line 746

```r
  print(paste("showPicture : calling set 'specimen, id' : ", e$currImgId) )
```

**Replacement pattern** (keep `print()` for console; add `setStatus()` alongside):

```r
  print(paste("showPicture : calling set 'specimen, id' : ", e$currImgId))
  setStatus(e,
    paste0("Specimen ", e$currImgId,
           " \u2014 ", e$currImgId,
           " of ", length(e$activeDataList)),
    "neutral")
```

---

### `ui.geomorph` — env button + inline label storage
*(edit `3dDigitize.geomorph.r` lines 54–75)*

**Analog 1 — existing `bt2` assignment in this same function:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r` line 55

```r
  assign("bt2", cmputBtn, envir = e)
```

**Analog 2 — count labels stored on env, digitize tab:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` lines 166–169

```r
  e$specimenNumLabel <-
    ttklabel(digCtlFrame, text = "Number of Specimens: 0")
  e$landMarkNumLabel <-
    ttklabel(digCtlFrame, text = "Number of Landmarks: 0")
```

**Core storage pattern** (add after `tkgrid(plotspecsBtn)` at line 74, before `return()`):

```r
  # Store action buttons so helpers can tkconfigure them
  e$computeBtn <- cmputBtn
  e$saveBtn    <- saveBtn
  e$plotBtn    <- plotspecsBtn

  # Inline validation label near Compute/Save/Plot
  e$gpaStatusLabel <- ttklabel(gpagenCtlFrame, text = "",
                               foreground = .STATUS_FG[["warning"]])
  tkgrid(e$gpaStatusLabel, sticky = "w", padx = 8)
```

**Note:** `cmputBtn` is already assigned to `e$bt2` via `assign("bt2", …)` at line 55. Adding
`e$computeBtn <- cmputBtn` adds a semantically named alias — both point to the same Tcl widget
handle. `e$bt2` may be used elsewhere; do not remove it.

---

### `.gm_results_or_warn` — "Run Compute first" modal replacement
*(edit `3dDigitize.geomorph.r` lines 136–151)*

**Analog — button-disable-as-feedback pattern:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r` line 973

```r
  tkconfigure(e$bt, state = "disabled")
```

**Existing modal to replace** (geomorph.r lines 141–149):

```r
  if (is.null(gm.res)) {
    tkmessageBox(title = "Information", message = "Run Compute first",
                 icon = "info", type = "ok")
    return(NULL)
  }
```

**Replacement pattern:**

```r
  if (is.null(gm.res)) {
    tkconfigure(e$gpaStatusLabel,
                text = "Run Compute before saving or plotting results.",
                foreground = .STATUS_FG[["warning"]])
    tkconfigure(e$saveBtn, state = "disabled")
    tkconfigure(e$plotBtn, state = "disabled")
    return(NULL)
  }
```

---

### `compute` — landmark/anchor gate modal replacement + busy wrapping
*(edit `3dDigitize.geomorph.r` lines 154–200)*

**Analog — `tkconfigure` disable pattern (same file):**
The `.gm_results_or_warn` replacement above (once edited) is the direct peer.

**Existing landmark gate to replace** (geomorph.r line 167):

```r
    if(is.null(landmarks) || nrow(landmarks) != as.numeric(e$landmarkNum)) {
      tkmessageBox(title = "Information", message = paste("Incorrect num of landmark for specimen", i), icon = "info", type = "ok")
      return ()
    }
```

**Replacement pattern (landmark):**

```r
    if (is.null(landmarks) || nrow(landmarks) != as.numeric(e$landmarkNum)) {
      msg <- paste0("Specimen ", i, " needs ", as.numeric(e$landmarkNum),
                    " landmarks \u2014 ",
                    if (is.null(landmarks)) 0 else nrow(landmarks),
                    " placed. Complete it before Compute.")
      tkconfigure(e$gpaStatusLabel, text = msg,
                  foreground = .STATUS_FG[["warning"]])
      tkconfigure(e$saveBtn, state = "disabled")
      tkconfigure(e$plotBtn, state = "disabled")
      return()   # return() stays — aborting compute is correct behavior
    }
```

**Replacement pattern (anchor, geomorph.r line 195):**

```r
      if (nrow(anchors) != as.numeric(e$anchorNum)) {
        msg <- paste0("Specimen ", i, " needs ", as.numeric(e$anchorNum),
                      " anchors \u2014 ", nrow(anchors),
                      " placed. Complete it before Compute.")
        tkconfigure(e$gpaStatusLabel, text = msg,
                    foreground = .STATUS_FG[["warning"]])
        tkconfigure(e$saveBtn, state = "disabled")
        tkconfigure(e$plotBtn, state = "disabled")
        return()
      }
```

**Busy-wrapping pattern** (wrap the `gpagen` call site in `compute`):

```r
  # Before gpagen call:
  busyStart(e, paste0("Computing GPA alignment for ", nSpecimen, " specimens\u2026"),
            mode = "indeterminate")

  # ... existing gpagen call ...

  # After gpagen call (success path):
  busyStop(e,
           paste0("GPA complete \u2014 ", nSpecimen, " specimens aligned."),
           "success")
  tkconfigure(e$saveBtn, state = "normal")
  tkconfigure(e$plotBtn, state = "normal")
  tkconfigure(e$gpaStatusLabel, text = "")
```

---

### `updateDotNum` — proactive nav-gate hook
*(append to `3dDigitize.digitize.r` after line 981, within function body)*

**Analog — existing tab-enable block in the same function:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` lines 967–981

```r
  if (nDots == e$landmarkNum && tclvalue(e$placeAnchorsVar) == "1")
  {
    tcl(e$nb, "tab", 1, state = "normal")
    e$tabState[1] <- 1
  }
  else if (nDots == e$landmarkNum &&
           tclvalue(e$placeAnchorsVar) == "0")
  {
    for (i in 2:4)
    {
      tcl(e$nb, "tab", i, state = "normal")
      e$tabState[i] <- 1
    }
  }
```

**Core proactive-gate pattern** (append after the tab-enable block, still inside `updateDotNum`):

```r
  # Proactive nav-gate: disable nav while landmark count incomplete
  nTarget <- as.integer(e$landmarkNum)
  if (!is.null(e$nextBtn) && !is.null(e$prevBtn)) {
    if (nDots < nTarget) {
      setStatus(e,
        paste0("Place all ", nTarget, " landmarks before continuing \u2014 ",
               nDots, " of ", nTarget, " placed."),
        "warning")
      tkconfigure(e$nextBtn, state = "disabled")
      tkconfigure(e$prevBtn, state = "disabled")
    } else {
      setStatus(e,
        paste0("Specimen ", e$currImgId,
               " \u2014 ", e$currImgId,
               " of ", length(e$activeDataList)),
        "neutral")
      tkconfigure(e$nextBtn, state = "normal")
      tkconfigure(e$prevBtn, state = "normal")
    }
  }
```

**Guard note:** `!is.null(e$nextBtn)` guards against calls that fire before `ui.main` has built
the status bar (e.g. during `drawElements` / `.dgt` reload at startup). Mirror this guard in
`updateAnchorNum`.

---

### `updateAnchorNum` — proactive nav-gate hook
*(append to `3dDigitize.digitize.r` after line 1005, within function body)*

**Analog — existing tab-enable block in the same function:**
`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r` lines 998–1005

```r
  if (nAnchors == e$anchorNum)
  {
    for (i in 2:4)
    {
      tcl(e$nb, "tab", i, state = "normal")
      e$tabState[i] <- 1
    }
  }
```

**Core proactive-gate pattern** (append after the tab-enable block):

```r
  nTarget <- as.integer(e$anchorNum)
  if (!is.null(e$nextBtn) && !is.null(e$prevBtn) &&
      tclvalue(e$placeAnchorsVar) == "1") {
    if (nAnchors < nTarget) {
      setStatus(e,
        paste0("Place all ", nTarget, " anchors before continuing \u2014 ",
               nAnchors, " of ", nTarget, " placed."),
        "warning")
      tkconfigure(e$nextBtn, state = "disabled")
      tkconfigure(e$prevBtn, state = "disabled")
    } else {
      setStatus(e,
        paste0("Specimen ", e$currImgId,
               " \u2014 ", e$currImgId,
               " of ", length(e$activeDataList)),
        "neutral")
      tkconfigure(e$nextBtn, state = "normal")
      tkconfigure(e$prevBtn, state = "normal")
    }
  }
```

---

## Shared Patterns

### Env widget storage
**Source:** `e$imgPath <- ttklabel(...)` (main.r:490–491), `assign("bt", …, envir = e)`
(digitize.r:131), `assign("bt2", …, envir = e)` (geomorph.r:55)
**Apply to:** All new widget references (`e$statusLabel`, `e$progressBar`, `e$nextBtn`,
`e$prevBtn`, `e$computeBtn`, `e$saveBtn`, `e$plotBtn`, `e$gpaStatusLabel`)
**Rule:** Prefer `e$widgetName <- widget` over `assign("name", widget, envir = e)` — the direct
form is used for all newer widget storage.

```r
e$statusLabel <- ttklabel(statusFrame, text = "Ready \u2014 open a PLY file to begin.",
                          foreground = "#000000")
```

### Modal replacement
**Source:** `tkmessageBox(…); return()` sites at main.r:897/913/926/942/958/1073/1085/1098/1109
and geomorph.r:143/167/195
**Apply to:** All 12 modal call sites enumerated in RESEARCH.md §Call-Site Inventory
**Rule:** Remove `tkmessageBox(…)`. Keep `return()` where it correctly aborts navigation or
compute. Replace feedback with `setStatus(e, text, state)` + `tkconfigure(<btn>, state="disabled")`.

```r
# Pattern: replace this —
tkmessageBox(title = "Information", message = "...", icon = "info", type = "ok")
return()

# — with this:
setStatus(e, "<UI-SPEC copy>", "warning")
tkconfigure(e$nextBtn, state = "disabled")   # where applicable
return()
```

### Button state management
**Source:** `tkconfigure(e$bt, state = "disabled")` (main.r:973),
`tkconfigure(e$bt, state = "normal")` (main.r:1121)
**Apply to:** `e$nextBtn`, `e$prevBtn` in nav gates; `e$saveBtn`, `e$plotBtn` in compute gates
**Rule:** `tkconfigure(<stored widget handle>, state = "disabled"/"normal")` — widget must be
stored on `e` first; helpers cannot configure widgets not on the env.

```r
tkconfigure(e$nextBtn, state = "disabled")
tkconfigure(e$prevBtn, state = "disabled")
# ...restore:
tkconfigure(e$nextBtn, state = "normal")
tkconfigure(e$prevBtn, state = "normal")
```

### `tcl("update", "idletasks")` repaint gate
**Source:** RESEARCH.md §Pitfall 1; existing `tcl("update")` at main.r:561 (safe only there;
not before blocking calls)
**Apply to:** `busyStart` implementation; any per-iteration status update inside `loadPly` loop
**Rule:** Use `tcl("update", "idletasks")` (not `tcl("update")`) before blocking C calls to
repaint without re-entering user-input event processing.

```r
tcl("update", "idletasks")   # safe before gpagen / add("specimen",…)
# NOT: tcl("update")          # re-entrant — processes mouse/key events too
```

---

## No Analog Found

All 13 change sites have codebase analogs. The only site with **no direct in-file analog** is the
`.STATUS_FG` / helper trio (`setStatus`/`busyStart`/`busyStop`) — no equivalent utility block
exists anywhere in the codebase. The RESEARCH.md §Recommended Helper Signatures provides the
prescriptive implementation to copy verbatim.

| Site | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.STATUS_FG` + `setStatus`/`busyStart`/`busyStop` | utility | request-response | No status-bar helper pattern exists; `tkconfigure` per-call is the closest analog (role-match only) |

---

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/`
(3dDigitize.main.r, 3dDigitize.geomorph.r, 3dDigitize.digitize.r)
**Files scanned:** 3 source files (~2760 total lines read across targeted ranges)
**Pattern extraction date:** 2026-06-25
