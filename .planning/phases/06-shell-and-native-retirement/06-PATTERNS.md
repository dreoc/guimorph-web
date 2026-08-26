# Phase 6: Shell and Native Retirement - Pattern Map

**Mapped:** 2026-08-13
**Files analyzed:** 17 (new + modified + deleted)
**Analogs found:** 14 / 17 (3 are pure deletions with no "analog to copy")

> This is a **removal + shell-completion** phase, not a new-tech phase. Almost every
> new construct copies an existing in-repo pattern. The three highest-leverage
> analogs are:
> 1. `R/transport.R` `.gmw_digitize_handler` — the per-route `grepl` dispatch +
>    `excludeStaticPath` + server-owned `.gmw_session` pattern the new `/files`,
>    `/open`, `/status`, `/tabstate`, `/msgack`, `/color` routes clone.
> 2. `R/view3d.R` `GMW_VIEW3D_TEMPLATE` — the HUD/toolbar/keyboard-shortcut DOM +
>    the `MESH_URL = "%s";` HEAD/BODY split marker the tab strip / menu bar /
>    status bar / modal layer grows into (staying under the 8192-byte HEAD cap).
> 3. `R/rtkogl.R` survivors — `GUImorphWeb()`/`dbg()`/`.plot_show()`/`.onAttach()`
>    must be **relocated before** the file is deleted (Landmine 1 / "decapitation").

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `R/transport.R` (grow: `/files`,`/open`,`/status`,`/tabstate`,`/msgack`,`/color` routes) | route/controller | request-response + file-I/O | its own `.gmw_digitize_handler` branches (`/overlays` GET, `/export` validated body) | exact (self-analog) |
| `R/view3d.R` (grow: tab strip, menu bar, status bar, modal layer) | component/view | template-render | its own `GMW_VIEW3D_TEMPLATE` `#t` toolbar + `#h` HUD + `MESH_URL` split | exact (self-analog) |
| `R/shell.R` (NEW: relocated `GUImorphWeb`/`dbg`/`.plot_show`/`.onAttach`) | entry/config | request-response (boot) | `transport.R` `.gmw_serve_mesh` (boot shell + print+open URL); survivors' current defs in `rtkogl.R` | role-match |
| `NEWS.md` (NEW) | docs/config | file-I/O (static) | — (no in-repo NEWS.md) | no analog → use RESEARCH template |
| `R/3dDigitize.main.r` (strip Tk chrome, keep data/model) | model + view (mixed) | transform / file-I/O (kept) | own kept `read.vertex.3D` / `.dgt` logic; delete `ui.main`/menu/nav/status Tk | exact (self, delete side) |
| `R/3dDigitize.digitize.r` (strip `ui.digitize`/`ui.anchor` Tk + `tk_chooseColor`) | view builder | event-driven (Tk) → delete | color → browser `<input type=color>` (RESEARCH Don't-Hand-Roll) | role-match |
| `R/3dDigitize.surface.r` (strip `ui.surface` Tk + `tkmessageBox`) | view builder | event-driven (Tk) → delete | msgbox → reusable DOM modal | role-match |
| `R/3dDigitize.curve.r` (strip `ui.curve` Tk) | view builder | event-driven (Tk) → delete | curve logic already server-side (`/curve` route) | role-match |
| `R/3dDigitize.geomorph.r` (strip `ui.geomorph` tk2* + `tkmessageBox` + `tkgetSaveFile`) | view builder | event-driven (Tk) → delete | GPA options → `/gpa`/`/gpaopts` route body | role-match |
| `DESCRIPTION` (drop `tcltk`/`tcltk2`/`rgl`; bump `1.0.0`) | config | static edit | current `DESCRIPTION` Imports/Suggests block | exact (self-analog) |
| `NAMESPACE` (drop tcltk imports + `loadDgt`; regen) | config (generated) | static edit | roxygen tags in `3dDigitize.main.r`:10–30 | exact (self-analog) |
| `tests/testthat/test-transport.R` (rewrite :121–133 to assert engine ABSENCE) | test | source-scan + request-response | its own `readLines`-grep assertions at :121–133 | exact (self, invert) |
| new source-scan test (DESCRIPTION/NAMESPACE/`inst/libs` clean) | test | source-scan | `test-transport.R`:124–132 `readLines`+`grepl` idiom | role-match |
| new source-scan test (no `add(`/`set(`/`del(`/`shows(`; no `.gmw_engine`) | test | source-scan | same `readLines`+`grepl` idiom | role-match |
| new test (`NEWS.md` present + 1.0.0 + pin 0.10.0 + GUImorph link) | test | source-scan | same idiom | role-match |
| `R/rtkogl.R` | engine binding | (deleted) | — pure deletion after survivors relocate | delete-only |
| `inst/libs/*` + `tkogl2/` tree | build artifact | (deleted) | — pure deletion | delete-only |

## Pattern Assignments

### `R/transport.R` — new shell routes (route/controller, request-response + file-I/O)

**Analog:** `R/transport.R` itself — the `.gmw_digitize_handler` dispatch. Every new
route is another `grepl("/suffix$", path)` branch beside the existing twelve, and
every new suffix is added to `dyn_suffixes` so `excludeStaticPath()` routes it to R.

**Register the new suffixes** (copy the `dyn_suffixes` + `static_map` shape, `transport.R`:484–500):

```484:500:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
  dyn_suffixes <- c("close", "pick", "anchor", "curve", "delete", "undo",
                    "specimen", "overlays", "downsample", "gpa", "export", "save")
  static_map <- c(
    list(httpuv::staticPath(dir)),
    lapply(dyn_suffixes, function(x) httpuv::excludeStaticPath())
  )
  server <- httpuv::startServer(
    host = "127.0.0.1", port = port,
    app = list(
      staticPaths = stats::setNames(
        static_map,
        c(paste0("/", token),
          paste0("/", token, "/", dyn_suffixes))
      ),
      call = .gmw_digitize_handler(token)
    )
  )
```
→ append `"files","open","savepath","tabstate","status","msgack","color"` to `dyn_suffixes`.

**GET read route pattern (bare text body, JSON-free)** — copy `/overlays` for `/files`, `/status` (`transport.R`:384–397):

```384:397:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
    if (grepl("/overlays$", path)) {
      s   <- .gmw_session_ensure(token)
      rec <- s$specimens[[s$current]]
      flat <- function(m) {
        if (is.matrix(m) && nrow(m) > 0L)
          paste(as.vector(t(m)), collapse = ",") else ""
      }
      body <- paste0("L=", flat(rec$land),
                     ";A=", flat(rec$anchor),
                     ";S=", flat(rec$surfaces))
      return(list(status = 200L,
                  headers = list("Content-Type" = "text/plain"),
                  body = body))
    }
```
→ `/files` returns `paste(list.files(dir, pattern="\\.(dgt|ply)$"), collapse="\n")`;
`/status` returns the bare specimen index / mode / counts CSV.

**Validated-body-against-allowlist pattern (NEVER join req path to FS)** — copy `/export` for `/open` (`transport.R`:410–421):

```410:421:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
    if (grepl("/export$", path)) {
      fmt <- strsplit(read_body(), ",", fixed = TRUE)[[1]][1]
      # Allow-list only; the format token is NEVER treated as or joined to a path.
      if (!is.na(fmt) && fmt %in% c("csv", "rds", "dgt")) {
        try(.gmw_export_session(token, fmt), silent = TRUE)
      }
      return(ok204)
    }
```
→ `/open`: `sel <- read_body()[1]`; enumerate `entries <- list.files(dir, ...)`; open **only if
`sel %in% entries`** (path-traversal guard, D-03 / RESEARCH Pitfall 5 / Security V12). Never
`file.path(dir, untrusted)` with unchecked input.

**Body read (single-shot rook input), header comment on the no-path-join invariant** (`transport.R`:260–268):

```260:268:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
  function(req) {
    path <- req$PATH_INFO

    # Bare CSV text body; base-R parse only (no JSON dep). `path` is only ever
    # matched with grepl below; it is NEVER joined to the filesystem. Read the
    # body at most once (the rook input stream is single-shot).
    read_body <- function() {
      tryCatch(rawToChar(req$rook.input$read()), error = function(e) "")
    }
```

**Server-owned browse dir** — add a `browse_dir` slot to the session (mirror `.gmw_session_init`, `transport.R`:684–693) so `/files`/`/open` read `.gmw_session_get(token)$browse_dir %||% getwd()`; `GUImorphWeb(dir=)` seeds it.

---

### `R/view3d.R` — tab strip / menu bar / status bar / modal layer (component/view, template-render)

**Analog:** `R/view3d.R` itself. The shell grows onto the existing `#t` toolbar and
`#h` HUD, and ALL parameter-free markup goes in the BODY (after the `MESH_URL = "%s";`
marker) to stay under the 8192-byte HEAD `sprintf` cap (RESEARCH Pitfall 3).

**The HEAD/BODY split marker — the hard constraint** (`view3d.R`:81–96):

```81:96:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  # Render note: base-R sprintf caps a single `fmt` string at 8192 bytes. Every
  # %s injection slot lives in the parameterised HEAD (up to and including the
  # `MESH_URL = "%s";` globals line); everything after it is a parameter-free JS
  # BODY whose only format token is the doubled `%%`. Splitting there keeps the
  # sprintf'd fmt tiny (well under the cap even as the JS body grows with the
  # picking wiring) while the byte-for-byte output is identical to a single
  # sprintf over the whole template.
  marker <- 'MESH_URL = "%s";'
  at <- regexpr(marker, GMW_VIEW3D_TEMPLATE, fixed = TRUE)
  cut <- at + attr(at, "match.length")
  head_fmt <- substr(GMW_VIEW3D_TEMPLATE, 1L, cut - 1L)
  body_raw <- substr(GMW_VIEW3D_TEMPLATE, cut, nchar(GMW_VIEW3D_TEMPLATE))
  paste0(
    sprintf(head_fmt, title, background, background, cloud_js, mesh_js, mesh_url),
    gsub("%%", "%", body_raw, fixed = TRUE)
  )
```
→ tab/menu/status/modal HTML+CSS+JS is parameter-free → put it AFTER the marker (in `body_raw`);
escape any literal `%` as `%%`. Do NOT add new `%s` HEAD slots for shell chrome.

**Toolbar DOM pattern to clone for the tab strip + menu bar** (`view3d.R`:134–156):

```134:156:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  #t{position:fixed;left:12px;top:12px;display:flex;gap:6px;flex-wrap:wrap}
  #t button{font:12px system-ui,sans-serif;padding:3px 8px;border:1px solid #bbb;
     border-radius:4px;background:rgba(255,255,255,.9);cursor:pointer}
  #t button:hover{background:#eef}
  #t .sep{width:1px;background:#ccc;margin:0 2px}
</style></head><body>
<canvas id="c"></canvas>
<div id="t">
  <button id="btn-l" type="button">Landmark</button>
  ...
  <button id="btn-save" type="button">Save .dgt</button>
</div>
<div id="h">drag rotate &middot; scroll zoom &middot; <kbd>r</kbd> reset &middot;
  ... mode: <b id="m">landmark</b></div>
```

**Button wiring + POST-then-redraw pattern to clone for menu items** (`view3d.R`:599–619):

```599:619:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  function on(id, fn){
    var el = document.getElementById(id); if (el) el.addEventListener("click", fn);
  }
  function post(route, body){
    return fetch(route, { method: "POST", body: (body == null ? "" : String(body)) })
             .catch(function(){});
  }
  on("btn-l",  function(){ setMode("landmark"); });
  ...
  on("btn-ds", function(){ post("downsample").then(redraw); });
  on("btn-gpa", function(){ post("gpa").then(redraw); });
  on("btn-csv", function(){ post("export", "csv"); });
  on("btn-save", function(){ post("save"); });
```
→ File-menu items are `on("menu-load-dgt", …)` calling `fetch("files")` then `post("open", sel)`.

**Specimen nav MUST reuse RE-SERVE (A4) — do not reinvent** (`view3d.R`:587–597):

```587:597:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  function switchSpecimen(n){
    try { navigator.sendBeacon("specimen", String(n)); } catch(e){}
    fetch("specimen", { method: "POST", body: String(n) })
      .then(function(r){ return r.text(); })
      .then(function(txt){
        var url = (txt || "").split("\\n")[0];
        if (url) loadSpecimen(url);
        redraw();
      }).catch(function(){});
  }
  window.GMW_SWITCH_SPECIMEN = switchSpecimen;
```
→ new prev/next buttons + specimen `<select>` call `switchSpecimen(n)`; do NOT change index
without the mesh RE-SERVE + `redraw()` (RESEARCH Pitfall 4).

**Keyboard-shortcut + live status readout pattern (parity for `[`/`]`, Ctrl+S)** (`view3d.R`:444–461):

```444:461:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/view3d.R
  function setMode(m){
    mode = m;
    if (m === "curve") curveSel = [];
    var mi = document.getElementById("m"); if (mi) mi.textContent = mode;
  }
  window.addEventListener("keydown", function(e){
    if (e.key === "a" || e.key === "A") setMode("anchor");
    else if (e.key === "c" || e.key === "C") setMode("curve");
    else if (e.key === "l" || e.key === "L") setMode("landmark");
    else if (e.key === "d" || e.key === "D") setMode("delete");
    else if (e.key === "u" || e.key === "U") doUndo();
  });
```
→ add `[`/`]` → `switchSpecimen`, `Ctrl+S`/`Cmd+S` → `post("save")`, and update a `#status`
region the same way `#m` is updated.

---

### `R/shell.R` (NEW) — relocated survivors (entry/config, boot)

**Analog:** `transport.R` `.gmw_serve_mesh` for the *boot* behavior; the survivors'
own current defs in `rtkogl.R` for what to move verbatim.

**The entry point to rewire (`rtkogl.R`:409–416) — REMOVE `.gmw_require_engine()` + Tk path:**

```409:416:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
GUImorphWeb <- function(debug = FALSE) {
  .gmw_require_engine()
  options(guimorph.debug = isTRUE(debug))
  e <- new.env()
  class(e) <- "main"
  ui(e)
  invisible(init(e))
}
```
→ new body: `options(guimorph.debug=…)`, seed the server-owned browse dir, then boot the
browser shell via `.gmw_serve_mesh(...)` (print+open URL). Keep the `@export` roxygen and the
`debug` arg; add `dir = getwd(), open = TRUE` (RESEARCH Open Q1 recommendation). NO `ui(e)`/`init(e)`.

**Boot behavior to mirror (print-first, try-open, never error)** (`transport.R`:515–537):

```515:537:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
  url <- sprintf("http://127.0.0.1:%d/%s/", port, token)
  ...
  # PRINT FIRST (D-05): this line cannot fail and is the guaranteed-correct path.
  message("Viewport: ", url,
          "\n  If it did not open, paste that URL into a browser.")
  ...
  if (isTRUE(open)) try(utils::browseURL(url), silent = TRUE)
  invisible(url)
```

**`dbg` — move VERBATIM (`rtkogl.R`:844). transport.R already depends on the package-level def** (its own is only a source-alone fallback, `transport.R`:36–38):

```842:844:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
# gated debug printer: prints only when options(guimorph.debug=TRUE),
# which GUImorphWeb(debug=TRUE) sets. Preserves every debugging note.
dbg <- function(...) if (isTRUE(getOption("guimorph.debug", FALSE))) print(...)
```

```36:38:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/transport.R
if (!exists("dbg", mode = "function")) {
  dbg <- function(...) if (isTRUE(getOption("guimorph.debug", FALSE))) print(...)
}
```

**`.plot_show` — move VERBATIM to `view3d.R` (beside `.gmw_view3d`); it is Tk/engine-free** (`rtkogl.R`:923–934):

```923:934:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
.plot_show <- function(draw, width = 800, height = 600) {
  if (.isMacOS()) {
    f <- tempfile(pattern = "guimorph-plot-", fileext = ".png")
    grDevices::png(f, width = width, height = height)
    ok <- FALSE
    tryCatch({ draw(); ok <- TRUE }, finally = grDevices::dev.off())
    if (ok) utils::browseURL(f)
  } else {
    grDevices::dev.new()
    draw()
  }
}
```
→ note it depends on `.isMacOS()` (`rtkogl.R`:866) — relocate that helper too.

**`.onAttach` — move VERBATIM (`rtkogl.R`:936–943). `.onLoad` (513–592) is DELETED, not moved:**

```936:943:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/rtkogl.R
.onAttach <- function(libname, pkgname) {
  gmv <- tryCatch(as.character(utils::packageVersion("geomorph")), error = function(err) "not found")
  packageStartupMessage(
    "GUImorphWeb ", utils::packageVersion(pkgname), " (beta) - Windows and macOS\n",
    "3D geometric morphometric digitizing for the geomorph ecosystem.\n",
    "Using geomorph ", gmv, "\n",
    "Issues / updates: https://github.com/dreoc/guimorph-web"
  )
```
→ update the "(beta) - Windows and macOS" text for the 1.0.0 browser architecture (builder's discretion).

**Helper survivors to co-locate with their callers** (`rtkogl.R`:855–892): `.pkg_version`,
`.module_banner`, `.isMacOS`, `normalizeWheelDelta`, `shortcutLabel`. `bindPlatformAccelerator`/
`bindDeleteGesture` (`rtkogl.R`:894–907) are Tk-only → DELETE. Audit each caller before moving/deleting.

---

### `R/3dDigitize.main.r` — strip Tk chrome, keep data/model (mixed, delete side)

**Analog:** the file's own kept logic (`read.vertex.3D`, `.dgt`/merge/export) stays; the Tk
builders are deleted. This is the largest strip (~102 `tk*` calls).

**The window/notebook/tab chrome to DELETE (`ui.main`, `3dDigitize.main.r`:657–751)** — replaced by the `view3d.R` DOM tab strip:

```657:729:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
ui.main <- function(e)
{
  e$wnd <- tktoplevel(width = 1400, height = 1200)
  tktitle(e$wnd) <- "GUImorphWeb - 3D Morphometrics"
  ...
  tn <- ttknotebook(rightPanel, width = 400, height = 670)
  ...
  tkbind(tn, '<Button-1>', function(W, x, y) {
    id <- tclvalue(tcl(W, "identify", "tab", x, y))
    if (nzchar(id)) switchTab(e, id)
  })
  digitizeFrame <- ui.digitize(e, tn)
  anchorFrame <- ui.anchor(e, tn)
  ...
  tkadd(tn, digitizeFrame, text = "3D Digitizing")
  ...
  for (i in 1:4) {
    tcl(tn, "tab", i, state = "disabled")
    e$tabState[i] <- 0 #indicate these tabs are disabled
  }
```
→ the tab **enable/disable gating** (`refreshTabGating`, `3dDigitize.main.r`:364) becomes
server-owned state exposed over the new `/tabstate` route; the browser reads it and greys tabs.

**Status-bar + progress Tk to DELETE (`setStatus`/`busyStart`/`busyStop`, `3dDigitize.main.r`:268–288)** — replaced by the `#h`/`#m` HUD status region:

```268:288:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
setStatus <- function(e, text, state = "neutral") {
  tkconfigure(e$statusLabel, text = text,
              foreground = .STATUS_FG[[state]])
}
busyStart <- function(e, text, mode = "indeterminate") {
  setStatus(e, text, "info")
  tkconfigure(e$wnd, cursor = "watch")
  ...
}
```

**Specimen-nav Tk to DELETE (`refreshNavButtons`/`populateSpecimenCombo`/`jumpToSpecimen`, `3dDigitize.main.r`:294–362)** — the `tkconfigure`/`tclvalue` combo becomes a DOM `<select>` + prev/next wired to `switchSpecimen` (RE-SERVE). Note `jumpToSpecimen` still calls the engine verb `add("specimen", …)` (`3dDigitize.main.r`:358) → that call is removed (see Shared Pattern: engine-verb removal).

**S3 generics to remove (`3dDigitize.main.r`:75–89)** — after rewire the entry no longer `UseMethod`-dispatches:

```75:89:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
ui <- function(e) {
  UseMethod("ui", e)
}
init <- function(e) {
  UseMethod("init", e)
}
bind <- function(e) {
  UseMethod("bind", e)
}
updateWidgets <- function(e) {
  UseMethod("updateWidgets", e)
}
```
→ audit `.geomorph.r`/`.surface.r`/`.digitize.r`/`.curve.r` for `*.main` method defs before deleting the generics (RESEARCH Removal Surface (d)).

**Roxygen import directives to remove (`3dDigitize.main.r`:10–30)** — then re-`document()`:

```10:30:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/3dDigitize.main.r
#' @docType package
...
#' @import geomorph
...
#' @import Rvcg
...
#' @import tcltk
...
#' @import tcltk2
```
→ delete `@import tcltk` + `@import tcltk2`; `@docType package` is deprecated (drop or migrate to `"_PACKAGE"`); keep `@import geomorph`/`@import Rvcg`.

---

### `R/3dDigitize.{digitize,surface,curve,geomorph}.r` — strip Tk tab builders (view builders, delete side)

**Analog:** same delete-the-Tk / keep-the-logic split as `main.r`. Dialog replacements use
the browser-native widgets called out in RESEARCH "Don't Hand-Roll":
- `tk_chooseColor` (`digitize.r`:481,500) → `<input type="color">` returning `#rrggbb`, stored R-side over the new `/color` route.
- `tkmessageBox` (`geomorph.r`, `surface.r`, `main.r`) → ONE reusable DOM modal (title + message + OK), acked over `/msgack`; model it on the `view3d.R` `#h` HUD text-swap + `post()` plumbing.
- `tkgetSaveFile` (`geomorph.r`:314,368; `main.r`:1961,2088,3567) → browser save-name text field in the picker modal; R still owns the path (`/savepath`), consistent with the Phase-5 `/save`-carries-no-path invariant.
- `tkgetOpenFile` (multi-select merge `main.r`:3549 uses `multiple=TRUE`) → checkbox multi-select list in the picker modal (RESEARCH A5 — own task).
- GPA options: currently `tclVar`-backed `tk2checkbutton`s (`geomorph.r`:52–110) → the browser GPA tab posts boolean flags as bare CSV over `/gpa` (or `/gpaopts`); keep `.build_geomorph_data`/`compute` untouched (RESEARCH Open Q2).

---

### `DESCRIPTION` — dependency severance + version bump (config)

**Analog:** the current file (`DESCRIPTION`:12–24):

```12:24:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION
Imports:
    geomorph (>= 4.1.1),
    Rvcg,
    tcltk,
    tcltk2,
    httpuv
Encoding: UTF-8
License: GPL (>= 2)
LazyData: true
Suggests:
    rgl,
    htmlwidgets,
    testthat
```
→ `Imports:` remove `tcltk`, `tcltk2` (leaves `geomorph, Rvcg, httpuv`); `Suggests:` remove `rgl`
(leaves `htmlwidgets, testthat`); `Version:` `0.10.0` → `1.0.0`; bump `Date:`; update
`Description:` text ("based on OpenGL and Tk widgets", :8–9) to the browser architecture.
**Before removing `rgl`:** grep `rgl::` for guarded call sites (RESEARCH A4).

---

### `NAMESPACE` — regenerated, not hand-edited (config)

**Analog:** the current generated file:

```1:11:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/NAMESPACE
# Generated by roxygen2: do not edit by hand

export(GUImorphWeb)
export(gmw_close)
export(gmw_picks)
export(gmw_session)
export(loadDgt)
import(Rvcg)
import(geomorph)
import(tcltk)
import(tcltk2)
```
→ End state after removing `@import tcltk`/`@import tcltk2` (main.r:27,30), deleting `loadDgt`
(and its `@export`, `rtkogl.R`:443), and re-`document()`: keep `export(GUImorphWeb/gmw_close/
gmw_picks/gmw_session)` + `import(Rvcg)`/`import(geomorph)`; drop the 3 tcltk/loadDgt lines.
Edit roxygen tags then regenerate — never hand-edit NAMESPACE.

---

### Tests — rewrite engine-presence → engine-absence + new source-scans (test, source-scan)

**Analog:** the `readLines` + `grepl` source-scan idiom ALREADY in `test-transport.R`:121–132 —
this is the exact block that INVERTS after deletion (RESEARCH Pitfall 6):

```121:133:integrated-guimorph-development_EOC/Project/GUImorphDevelopment/tests/testthat/test-transport.R
test_that("lifecycle work never touches the tkogl2 engine state", {
  skip_if_no_pkg_source()

  # transport.R must never write the CMP-01 oracle engine env.
  tsrc <- readLines(file.path(pkg_root, "R", "transport.R"), warn = FALSE)
  expect_false(any(grepl(".gmw_engine$", tsrc, fixed = TRUE)))
  expect_false(any(grepl(".gmw_engine <-", tsrc, fixed = TRUE)))

  # rtkogl.R still carries the native oracle load path (proving it was untouched).
  rsrc <- readLines(file.path(pkg_root, "R", "rtkogl.R"), warn = FALSE)
  expect_true(any(grepl(".onLoad", rsrc, fixed = TRUE)))
  expect_true(any(grepl("Tkogl2", rsrc, fixed = TRUE)))
})
```
→ REWRITE the second half to assert the engine is GONE: `expect_false(file.exists(file.path(pkg_root,"R","rtkogl.R")))`,
no `inst/libs/tkogl2*`, no `.gmw_engine`/`.onLoad` tcl-load anywhere in `R/`. New source-scan
tests reuse this same `readLines`+`grepl` shape for DESCRIPTION/NAMESPACE cleanliness, the
`add(`/`set(`/`del(`/`shows(` call-site scan, and `NEWS.md` content. RETIRE
`test-picking-parity.R` / `test-retina-picking-parity.R`; skip/rewrite the `-rewrite` byte gate
in `test-dgt-cross-platform.R` (D-04). Green the 4 `assignInNamespace`-on-tcltk stub tests
(mooted with `tcltk` gone).

## Shared Patterns

### Engine-verb call-site removal (`add`/`set`/`del`/`shows`)
**Source of the bridge:** `rtkogl.R` (`add`:8, `del`:338, `set`:675, `shows`:601) — all DELETED.
**Apply to:** every caller across `3dDigitize.main.r` (e.g. `add("specimen", …)`:358,
`set("window","id",…)`:783, `set("window","size",…)`:788/799), and the digitize/surface/curve tabs.
**Rule:** grep `add\(`/`set\(`/`del\(`/`shows\(` and remove each — the browser now renders/picks
and the Phase-5 session/route layer already holds the state these maintained (RESEARCH Pitfall 2).
Remove `.gmw_require_engine()` from `GUImorphWeb()` FIRST, then delete `inst/libs/`, then verify
the workflow engine-absent BEFORE deleting `rtkogl.R` (sequence: grow-shell → rewire-entry →
verify engine-absent → demolish).

### No-path-join / server-owns-path invariant (V5/V12)
**Source:** `transport.R` handler header + every branch (only `grepl`s the suffix, never
`file.path(dir, req-path)`), :263–268 / :410–421.
**Apply to:** the NEW `/files` and `/open` routes (the phase's main new attack surface). R
enumerates the dir; the browser returns only a member of that enumerated set; R validates
membership before opening. Scope listing to a server-owned `browse_dir`, filter to `.dgt`/`.ply`,
bind `127.0.0.1` only. Wrap the `.dgt` reader in `tryCatch` → browser error modal, never crash.

### Bare-CSV, JSON-free wire format
**Source:** `transport.R` `read_body()` + `as.numeric`/`as.integer` arity+finiteness checks
(:200–206, :318–324); `view3d.R` `post()`/`sendBeacon` relative targets (:606–609).
**Apply to:** all new routes and all new shell fetches — no JSON dependency, relative same-origin
targets only, bounded/validated bodies, `204` on the happy path (or `200` + bare text for GET reads).

### Debug logging (`dbg`) dependency
**Source:** `transport.R`:36–38 fallback guard; `rtkogl.R`:844 authoritative def.
**Apply to:** relocation ordering — the package-level `dbg` must exist in a surviving file
(`shell.R`) before `rtkogl.R` is deleted, or `transport.R` logging under `guimorph.debug=TRUE`
breaks (RESEARCH Pitfall 1 warning sign).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `NEWS.md` | docs/config | static | No `NEWS.md` exists in the repo. Use the RESEARCH "NEWS.md Migration Note" template: `# GUImorphWeb 1.0.0` header, breaking-change note (native OpenGL/Tk + `rgl` removed), migration → GUImorph (`dreoc/GUImorph`, `upstream` remote) primary + pin `GUImorphWeb 0.10.0` fallback, and the D-04 won't-verify note. R `NEWS.md` conventions (`#` version headers, `##` subsections); accompany with a `1.0.0` git tag (`create_tag: true`). |
| `R/rtkogl.R` | engine binding | (deleted) | Pure deletion — no "analog to copy." Its ONLY non-deletable content is the survivors (`GUImorphWeb`/`dbg`/`.plot_show`/`.onAttach` + helpers) covered by the `R/shell.R` assignment above. Delete LAST. |
| `inst/libs/*` + `tkogl2/` sibling tree | build artifact | (deleted) | Pure deletion (`tkogl2.dylib`, `x64/tkogl2.dll`, `x64/glut64.dll`, and the entire `integrated-guimorph-development_EOC/Project/tkogl2/` CMake/MSVC/C/ObjC tree incl. `test/gate/` CMP-01 machinery). No pattern to copy. |

## Metadata

**Analog search scope:** `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/{R,tests/testthat}`, `DESCRIPTION`, `NAMESPACE`.
**Files scanned (read):** `transport.R`, `view3d.R`, `rtkogl.R` (survivors + engine sections), `3dDigitize.main.r` (generics/status/nav/notebook), `DESCRIPTION`, `NAMESPACE`, `test-transport.R`, roxygen-import grep.
**Pattern extraction date:** 2026-08-13
