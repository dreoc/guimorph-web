# Phase 4: Digitize Workflow - Pattern Map

**Mapped:** 2026-06-15
**Files analyzed:** 6
**Analogs found:** 6 / 6

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/3dDigitize.curve.r` | controller + I/O service | event-driven + file-I/O | self (existing curve module) | exact |
| `R/3dDigitize.main.r` | controller + orchestration | file-I/O + event-driven | self (`saveToDgt`/`openDgt`/`switchTab`) | exact |
| `R/3dDigitize.digitize.r` | controller + I/O service | event-driven + file-I/O | self (`addDot`/`updateDotNum`) | exact |
| `R/3dDigitize.surface.r` | I/O service | file-I/O | self (`read.surface`/`write.surface`) | exact |
| `R/rtkogl.R` | utility (R↔C bridge) | request-response | self (`add`/`set`/`shows`) | exact |
| `.planning/smoke-test-findings.md` | documentation | transform (append-only) | self (Phase 1–3 sections) | exact |

**Canonical package root:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`

**Phase nature:** Validation + targeted repair of existing legacy code — no greenfield files. Potential code edits are confined to digitize-path blockers (D-12): `loadPly` curve-slot init, `drawElements` curve assignment, optional `onSelectCurve` rbind guard.

---

## Pattern Assignments

### `R/3dDigitize.curve.r` (controller + I/O, event-driven + file-I/O)

**Analog:** self — curve module is the reference implementation for DGT-02

**Data structure comment** (lines 7–16) — slot `[[4]]` is curves (specimen 1 only):

```7:16:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r
#dgtDataList
#dgtDataList[imgId][[1]]: speciman dir
#dgtDataList[imgId][[2]]: font
#dgtDataList[imgId][[3]]: number of landmark
#dgtDataList[1][[4]]: curves
#dgtDataList[imgId][[5]]: template
#dgtDataList[imgId][[6]]: rotation
#dgtDataList[imgId][[7]]: zoom
#dgtDataList[imgId][[8]]: surface file
```

**UI pattern — legacy-only, dormant buttons commented** (lines 36–84):

```36:84:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r
  # there are additional buttons that were created to test a concept and that
  # have NOT been made active in this file as of 14 JULY 2020
  setCurveCountBtn <-
    ttkbutton(
      curveCtlFrame,
      text = "Set curves (total) number",
      command = function()
        setCurvesNum(e)
    )
  fitBtn <-
    ttkbutton(
      curveCtlFrame,
      text = "Fit",
      command = function()
        onFit(e)
    )
  # ...
  tkpack(ttklabel(curveCtlFrame, text = " "), pady = 6)
 ## tkpack(setCurveCountBtn)
 ## tkpack(setCurrentCurveCountBtn)
  tkpack(fitBtn)
 ## tkpack(computeCurvesBtn)
```

**Event bind pattern — double-click only** (lines 91–104):

```91:104:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r
bind.curve <- function(e)
{
  tkbind(e$canvasFrame, "<ButtonPress-1>", function(x, y) {
    e$dragX <- as.integer(x)
    e$dragY <- as.integer(y)
  })
  tkbind(e$canvasFrame, "<Double-Button-1>", function(x, y) {
    onSelectCurve(e, x, y)
  })
}
```

**Core curve bind — 3rd selection commits row + C notify** (lines 212–289):

```212:289:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r
onSelectCurve <- function(e, x, y)
{
  if (TRUE == set("dot", "selected", x, y))
  {
    id <- tclvalue(shows("landmark", "id"))
    if (id %in% e$curveLine)
    {
      tkmessageBox(
        title = "Information",
        message = "Duplicate dot in one curve is not allowed",
        icon = "info",
        type = "ok"
      )
      return ()
    }
    e$curveLine <- c(e$curveLine, as.numeric(id))
    e$curveDots <- c(e$curveDots, c(x, y, id))
    e$curveDotNum <- e$curveDotNum + 1
    if (e$curveDotNum == 2)
    {
      e$sliders <- c(e$sliders, id)
    }
    else if (e$curveDotNum == 3)
    {
      set("window", "mode", "digitize")
      changeDotColor(e)
      set("window", "mode", "curve")
      curves <- e$activeDataList[[1]][[4]]
      newCurve <- matrix(e$curveLine, nrow = 1, ncol = 3)
      curves <- rbind(curves, newCurve)
      e$activeDataList[[1]][[4]] <- curves
      add("curve", e$curveLine[1], e$curveLine[2], e$curveLine[3])
      e$curveDots <- c()
      e$curveDotNum <- 0
      e$curveLine <- c()
    }
  }
}
```

**`.dgt` curve I/O** (lines 110–158):

```110:158:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.curve.r
read.curve <- function(content)
{
  startLine <- grep("Curve=", content, ignore.case)
  num <- sub("Curve=", "", content[startLine], ignore.case)
  if (num == 0) { return (NULL) }
  endLine <- as.numeric(startLine) + as.numeric(num)
  tmp <- content[(startLine + 1):endLine]
  matrix(as.numeric(unlist(strsplit(tmp, " "))), ncol=3, byrow=TRUE)
}

write.curve <- function(fileName, curves)
{
  if (length(curves) > 0) {
    write(paste("Curve=", nrow(curves), sep = ""), fileName, append = TRUE)
    write.table(curves, fileName, sep = " ", col.names = FALSE, row.names = FALSE, append = TRUE)
    write("", fileName, append = TRUE)
  } else {
    write(paste("Curve=0", sep = ""), fileName, append = TRUE)
  }
}
```

**Potential fix pattern (if `rbind` fails on first curve):** Coerce empty `list()` slot before rbind — copy from `3dDigitize.geomorph.r` lines 136–144 (list→matrix guard used downstream):

```136:144:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.geomorph.r
  curves <- NULL
  if (itob(tclvalue(e$curves))) {
    curves <- matrix(e$activeDataList[[1]][[4]],ncol=3)
  }
  if (is.list(curves)){
    curves<-matrix(unlist(curves),ncol=3)
  }
```

Prefer init-as-empty-matrix at source (`loadPly`/`drawElements`) over inline coercion in `onSelectCurve`.

---

### `R/3dDigitize.main.r` (controller + orchestration, file-I/O + event-driven)

**Analog:** self — main module owns session lifecycle, tab dispatch, save/reload

**S3 tab/mode dispatch** (lines 46–48, 201–217, 281–411):

```46:48:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
bind <- function(e) {
  UseMethod("bind", e)
}
```

```281:411:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
  else if (id == 3 && e$tabState[3] == 1)
  {
    e$tab <- 3
    set("window", "mode", "curve")
    if ( !is.null (e$dgtcurvestuff))
    {
      draw.curves(e$dgtcurvestuff)
    }
    if (length(e$activeDataList) > 0) {
      curves <- e$activeDataList[[1]][[4]]
      if (length(curves) > 0) {
        add ("initialize", 2, 0, 0 )
        add ("InfoCurves", nrow(curves), 3, length(e$activeDataList))
        for (j in 1:nrow(curves)) {
          add ("curve", as.integer(curves[j,1]), as.integer(curves[j,2]), as.integer(curves[j,3]))
        }
        add ("InfoCurves_complete", 0, 0, 0)
      }
    }
    class(e) <- "curve"
    showPicture(e)
  }
```

**File menu wiring** (lines 543–561):

```543:561:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    label = "Load ply File",
    command = function()
      loadPly(e)
  )
    label = "Save to DGT",
    command = function()
      saveToDgt(e)
  )
    label = "Load DGT File",
    command = function()
      openDgt(e)
  )
```

**loadPly — multi-specimen init (BUG SITE: `[[4]] <- list()`)** (lines 1264–1305):

```1264:1305:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
      dgtDataList[[length(dgtDataList) + 1]] <-
        list(imgList[[i]], 0.01, 0, list(), "NULL", c(0, 0), 0, "NULL", 0)
    # ...
      e$activeDataList <- dgtDataList
      set("specimen", "allocate", length(e$activeDataList))
      add("specimen", e$activeDataList[[1]][[1]], e$currImgId)
```

**Fix pattern:** Replace `list()` at slot 4 with `matrix(nrow = 0, ncol = 3)` in both `loadPly` (line 1266) and `drawElements` specimen loop (line 1532). Mirror the matrix shape used by `read.curve` and `onSelectCurve`.

**saveToDgt — multi-specimen loop** (lines 1618–1703):

```1618:1703:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
saveToDgt <- function(e)
{
  nSpecimen <- length(e$activeDataList)
  if (nSpecimen <= 0) {
    tkmessageBox(title = "Information", message = "Nothing to be saved", icon = "info", type = "ok")
    return ()
  }
  fileName <- tclvalue(tkgetSaveFile(filetypes = "{DGT {.dgt}}"))
  if (!nchar(fileName)) { return () }
  file.create(fileName, showWarnings = TRUE)
  curves <- e$activeDataList[[1]][[4]]
  write.curve(fileName, curves)
  write.template(fileName, e$templOrig)
  for (i in 1:nSpecimen)
  {
    specimenId <- basename(e$activeDataList[[i]][[1]])
    landmarks <- getLandmark(i)
    anchors <- getAnchor(i)
    if (is.null(landmarks)) { next() }
    write.digitize(fileName, specimenId, landmarks)
    write.anchors(fileName, specimenId, anchors)
    write.surface(fileName, e$activeDataList[[i]][[5]], e$activeDataList[[i]][[8]])
    write("", fileName, append = TRUE)
  }
}
```

**openDgt — same-session reload via GUI** (lines 2458–2719):

```2458:2719:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
openDgt <- function(e)
{
  init.main(e)
  dgtfileName <- tclvalue(tkgetOpenFile(filetypes = "{DGT {.dgt}}"))
  if ("" == dgtfileName) { return(FALSE) }
  e$dgtPath <- dirname(dgtfileName)
  e$dgtFileName <- dgtfileName
  rawContent <- scan(file = dgtfileName, what = "char", sep = "\n", quiet = TRUE)
  olddat <- read.digitize(e, content = rawContent)
  anchors <- read.anchors(rawContent)
  surfaceData <- read.surface(rawContent)
  if(is.null(surfaceData)) { return(FALSE) }
  curves <- read.curve(rawContent)
  if(is.null(curves)) { e$dgtcurvestuff <- NULL }
  else { e$dgtcurvestuff <- curves }
  drawElements(e, olddat, surfaceData, curves, anchors)
}
```

**drawElements — curve restore DISABLED (`if(0)`) — fix target for DGT-04** (lines 1527–1588):

```1527:1588:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
    dgtDataList[[specId]] <-
      list(
        specimens[[i]], 0.01, e$landmarkNum,
        list(),   # <-- slot 4: same init bug as loadPly
        tmpt[i], c(0, 0), 0, surfaces[, , i], anchorNum, landmarks, anchor
      )
if(0)   # <-- curve restore block disabled; DGT-04 fix: re-enable
{
    if (length(curves) != 0)
    {
      draw.curves(curves)
      dgtDataList[[1]][[4]] <- curves
    }
}
    e$activeDataList <- dgtDataList
```

**Fix pattern for curve restore:** Copy the `switchTab` id==3 C-dispatch loop (lines 340–388 in same file) — same `add("InfoCurves",…)` / `add("curve",…)` / `add("InfoCurves_complete",…)` sequence. Minimal fix: change `if(0)` to `if(1)` and assign `dgtDataList[[1]][[4]] <- curves` when non-null.

**getLandmark — live C coords at save time** (lines 1712–1732):

```1712:1732:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
getLandmark <- function(id)
{
  lmkStr <- tclvalue(shows("landmark", "xyz", id))
  if (lmkStr != "") {
    lmkV <- strsplit(lmkStr, " ")[[1]]
    matrix(as.numeric(lmkV), nrow = length(lmkV) / 3, ncol = 3, byrow = TRUE)
  } else { NULL }
}
```

**onFit smoke handler** (lines 1095–1126):

```1095:1126:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
onFit <- function(e)
{
  if (length(e$activeDataList) == 0) { return() }
  imgId <- e$currImgId
  set("specimen", "angle", "x", -e$activeDataList[[imgId]][[6]][1])
  set("specimen", "angle", "y", -e$activeDataList[[imgId]][[6]][2])
  # scale reset loops ...
  e$activeDataList[[imgId]][[6]] <- c(0, 0)
  e$activeDataList[[imgId]][[7]] <- 0
}
```

---

### `R/3dDigitize.digitize.r` (controller + I/O, event-driven + file-I/O)

**Analog:** self — landmark placement is validated baseline (DGT-01); curve workflow depends on these landmark IDs

**Default landmark count — tab unlock pitfall** (lines 29–36):

```29:36:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
init.digitize <- function(e)
{
  e$landmarkNum <- 5
  e$anchorNum <- 5
  e$landmarksPresentInMemory <- 0
  e$anchorsPresentInMemory <- 0
}
```

UAT must call **Set number of landmarks = 3** before placement (D-03 acceptance with minimum landmarks).

**Double-click landmark placement** (lines 291–316, 919–956):

```314:316:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
  tkbind(e$canvasFrame, "<Double-Button-1>", function(x, y) {
    addDot(e, x, y)
  })
```

```919:956:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
addDot <- function(e, x, y)
{
  if (length(e$activeDataList) > 0)
  {
    dotNum <- e$activeDataList[[e$currImgId]][[3]]
    if (dotNum < as.integer(e$landmarkNum))
    {
      coord <- convertCoor(e, x, y)
      if (TRUE == add("dot", coord[1], coord[2], coord[3])) {
        updateDotNum(e, 1)
      }
    }
  }
}
```

**Tab unlock when landmark count reached** (lines 1000–1022):

```1000:1022:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
updateDotNum <- function(e, delt)
{
  nDots <- e$activeDataList[[e$currImgId]][[3]] + delt
  e$activeDataList[[e$currImgId]][[3]] <- nDots
  if (nDots == e$landmarkNum && tclvalue(e$placeAnchorsVar) == "0")
  {
    for (i in 2:4) {
      tcl(e$nb, "tab", i, state = "normal")
      e$tabState[i] <- 1
    }
  }
}
```

**read.digitize — path resolution for reload** (lines 1107–1146):

```1107:1146:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
  if (grepl("/.", sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case)[1])) {
    ID <- sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case)
  } else {
    ID <- paste(e$dgtPath, "/",
                sub("ID=", "", content[grep("ID=", content, ignore.case)], ignore.case), sep = "")
  }
  dimnames(coords)[[3]] <- as.list(ID)
  return(coords)
```

**write.digitize + write.anchors — per-specimen sections** (lines 1209–1237):

```1209:1237:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.digitize.r
write.digitize <- function(fileName, Id, landmarks, anchors)
{
  write(paste("LM3=", nrow(landmarks), sep = ""), fileName, append = TRUE)
  write.table(landmarks, fileName, col.names = FALSE, row.names = FALSE, append = TRUE)
}
write.anchors <- function(fileName, Id, anchors)
{
  write(paste("AC3=", nrow(anchors), sep = ""), fileName, append = TRUE)
  if (length(anchors) != 0) write.table(anchors, fileName, col.names = FALSE, row.names = FALSE, append = TRUE)
  else write("NULL", fileName, append = TRUE)
  write(paste("ID=", Id, sep = ""), fileName, append = TRUE)
}
```

---

### `R/3dDigitize.surface.r` (I/O service, file-I/O)

**Analog:** self — surface section gates `openDgt` success

**read.surface — NULL when no Surface= lines** (lines 577–607):

```577:607:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.surface.r
  if (0 == length(nsurf))
  {
    return (NULL)
  }
  surfaces <- read.vertex.3D(content, "Surface=")
  if (all(is.na(surfaces)) == TRUE) { return(NULL) }
  return(list(template = tmpt, surfaces = surfaces, sliderNum = nsurf))
```

**write.surface — emits Surface=0 for empty downsample** (lines 639–647):

```639:647:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.surface.r
  if (length(surface) >= 2)
  {
    write.vertex.3D(surface, "Surface=", fileName)
  }
  else
  {
    write("Surface=0", fileName, append = TRUE)
  }
```

Fresh saves via `saveToDgt` should always produce parseable `Surface=0`, avoiding Pitfall 4 (`openDgt` NULL surface abort at main.r:2580–2583).

---

### `R/rtkogl.R` (utility bridge, request-response)

**Analog:** self — all digitize tabs dispatch through these Tcl wrappers

**add — C engine dispatch** (lines 7–8):

```7:8:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
add <- function(shape, arg1, arg2, arg3)
{
```

Curve workflow calls: `add("curve", id1, id2, id3)`, `add("SetCurveIndex", j, -1, -1)`, `add("InfoCurves", nrows, 3, nSpecimens)`.

**set — window mode + dot selection** (lines 566–593):

```577:593:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
  if (shape == "window")
  {
    else if (attr == "mode")
    {
      result <- tcl("setWindow", attr, arg1, 0, 0, 0)
      return (TRUE)
    }
  }
```

**shows — landmark ID lookup for curve bind** (lines 519–523):

```519:523:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
    else if (attr == "id")
    {
      result <- tcl("show", shape, attr, 0,0, 0)
    }
```

Used by `onSelectCurve`: `set("dot","selected", x, y)` then `shows("landmark", "id")`.

---

### `.planning/smoke-test-findings.md` (documentation, append-only)

**Analog:** self — existing Phase 1–3 structure

**Append pattern** (lines 1–15, 67–71):

```1:15:.planning/smoke-test-findings.md
# GUImorph Smoke Test Findings

**Date:** 2026-06-13 (initial); **corrected 2026-06-15  
**Environment:** Windows R, PowerShell, WSL UNC paths  
**DLL loaded:** MinGW `inst/libs/x64/tkogl2.dll` (deployed 2026-06-15)

---

## Correction (2026-06-15)
...
```

Phase 4 section should follow same structure: dated header, session summary table, validated/not-validated lists, issues with status (FIXED/CLOSED/OPEN), console reference snippets. Append only — do not rewrite prior phases (D-13).

---

## Shared Patterns

### Tab-driven S3 mode dispatch
**Source:** `3dDigitize.main.r:46-48`, `switchTab`
**Apply to:** All canvas interaction changes between Digitize/Curve/Anchor/Surface tabs

```r
bind <- function(e) { UseMethod("bind", e) }
# switchTab sets: set("window", "mode", "curve"|"digitize"|…)
# then: class(e) <- "curve"; bind(e)  → bind.curve(e)
```

### R↔C stringly-typed protocol
**Source:** `rtkogl.R` — `add`, `set`, `shows`
**Apply to:** `onSelectCurve`, `draw.curves`, `saveToDgt` (`getLandmark`), `openDgt` (`draw.digitize`)

| Operation | R call |
|-----------|--------|
| Place landmark | `add("dot", x, y, z)` |
| Select landmark at pixel | `set("dot", "selected", x, y)` |
| Get landmark ID | `tclvalue(shows("landmark", "id"))` |
| Bind curve to C | `add("curve", id1, id2, id3)` |
| Query coords at save | `shows("landmark", "xyz", specimenId)` |

### `.dgt` sectioned text format
**Source:** `write.curve`, `write.digitize`, `write.anchors`, `write.surface` in respective modules
**Apply to:** All save/reload validation

Save order in `saveToDgt`: `Curve=` → `TemplateNumber=` → per-specimen (`LM3=` → coords → `AC3=` → coords → `ID=` → `Template=` → `Surface=`).

Read order in `openDgt`: digitize → template → anchors → surface → curves → `drawElements`.

### activeDataList empty guards (Phase 2 pattern)
**Source:** `3dDigitize.main.r` — `length(e$activeDataList) == 0` checks in `onFit`, `switchTab`, navigation
**Apply to:** Any new guard in curve/save paths

```1097:1099:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
  if (length(e$activeDataList) == 0) {
    return()
  }
```

### User feedback via tkmessageBox
**Source:** `saveToDgt`, `onSelectCurve`, `openDgt`
**Apply to:** Blocker-only messages — UX quirks (single-click vs double-click) go to smoke-test-findings, not new dialogs (D-12)

### Debug print() logging — keep for Phase 4
**Source:** all digitize modules
**Apply to:** Do not remove verbose `print()` in curve/save paths (D-11); cleanup deferred to Phase 9

### Double-click gesture convention
**Source:** `bind.digitize` (place), `bind.curve` (select existing)
**Apply to:** Document in smoke-test-findings when users report "nothing happens" on single-click (D-12, D-13)

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| *(none)* | — | — | All Phase 4 targets are modifications/validation of existing legacy R modules with in-repo analogs |

---

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/`, `.planning/smoke-test-findings.md`
**Files scanned:** 15 R sources (canonical package); tkogl2 parallel copy ignored per PROJECT.md
**Pattern extraction date:** 2026-06-15

**High-priority fix sites for planner:**
1. `loadPly` line 1266 — `list()` → `matrix(nrow=0, ncol=3)` for slot `[[4]]`
2. `drawElements` lines 1532 + 1558–1586 — same slot init + re-enable curve assignment block
3. Runtime confirm before edit — `onSelectCurve` rbind may already fail (Pitfall 2)

**Validation command baseline:**
```r
setwd("integrated-guimorph-development_EOC/Project/GUImorphDevelopment")
devtools::load_all(".")
warnings()
GUImorph()
```
