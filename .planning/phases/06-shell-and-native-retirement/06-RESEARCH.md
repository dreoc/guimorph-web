# Phase 6: Shell and Native Retirement - Research

**Researched:** 2026-08-13
**Domain:** R package surgery (Tk chrome removal, native-engine deletion, browser-shell completion) — not a new-tech phase
**Confidence:** HIGH (removal surface enumerated directly from source; browser attach points read in full)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 (full toolkit severance):** Phase 6 drops **`tcltk` AND `tcltk2`** from `Imports` in addition to `tkogl2` and `rgl`. No Tk window survives. Every dialog, menu, tab, and status readout becomes browser-rendered. Goes beyond the literal wording of UI-03 (which names only `tkogl2` + `rgl`); it is the intended end state.
- **D-02 (engine deletion boundary):** Delete `R/rtkogl.R` (the in-package engine binding), remove the engine load/guard from `transport.R`/onLoad, AND drop the sibling `tkogl2/` project tree (CMake, MSVC/Rtools, WGL/NSGL backends, `gfx_backend.h` seam). Retire the CMP-01 test machinery. Full removal from the package and repo build surface — nothing archived in-tree.
- **D-03 (file opening = browser-served picker):** With `tcltk` gone, `tkgetOpenFile`/`tkgetSaveFile` are removed. Opening files is done via an **R-served directory listing/picker over `httpuv`**, selected inside the same browser shell; R opens the chosen path. No native OS chooser, no `file.choose()`. Consistent with server-owns-state and the Phase 5 rule that R owns the path (`/save` carries no path). Message boxes (`tkmessageBox`) and color pickers (`tk_chooseColor`) must also be reimplemented as browser-rendered UI. (Exact styling = builder's discretion.)
- **D-04 (close PICK-03 / DAT-02 gates as won't-verify):** Deleting `tkogl2` destroys the only oracle for the still-DEFERRED PICK-03 milestone gate and the DAT-02 `-rewrite` byte gate. No Windows host available across Phases 4–6. Do **not** block Phase 6 on a capture. Formally close both as won't-verify, document the limitation (harness complete and drop-in-ready — the gap is host availability, not code), delete the engine, retire the two pending todos. The parity reader (accepts both dialects) and the automated primary gates remain in place.
- **D-05 (version bump to 1.0.0):** Removing native engine + `rgl` + Tk chrome is breaking; bump GUImorphWeb to **1.0.0**.
- **D-06 (pin target = 0.10.0):** The pinnable "last version that still bundled the native engine" is **0.10.0** (current `DESCRIPTION` version).
- **D-07 (migration destination):** `NEWS.md` points native-path users **primarily to GUImorph** (`dreoc/GUImorph`, the `upstream` remote) with **pin `GUImorphWeb 0.10.0`** as the frozen-package fallback.

### Claude's Discretion
- **Shell layout & fidelity** — faithful mirror of the Tk arrangement (center viewport + tabbed control panel + menu + status bar) vs a browser-native redesign. Resolve against the existing `view3d.R` HUD/toolbar patterns; feature parity (UI-01) is the only hard constraint.
- **Dialog/menu styling** — how browser-rendered dialogs, menus, and message boxes look and behave.
- **Shortcuts & status-bar content** — which accelerators (`[`/`]` prev-next, Ctrl+S, etc.) and status readouts (specimen index, mode, counts) carry over. Preserve parity; exact set is builder's discretion.

### Deferred Ideas (OUT OF SCOPE)
- The deferred macOS→Windows `.dgt` upstream leg (GUImorph's own cross-platform parity), Linux support, WebGPU as a first-class target, and the Phase 5 live-surface COMPUTE stub — all belong to other phases/projects. (No new ideas were raised in discussion.)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| UI-01 | Tabs, dialogs, specimen navigation, and status bar reimplemented in the browser shell at parity with the Tk chrome | §"Tk Removal Surface" enumerates every widget/tab/menu/status/dialog to replace; §"Browser Shell Attach Points" shows how `view3d.R` HUD/toolbar + `transport.R` routes host the new tabs/menu/status/picker |
| UI-02 | The complete workflow runs with the native engine uninstalled and absent from the library path | §"Native Engine Removal Surface" (delete `inst/libs/*`, `.onLoad`, `.gmw_engine`, engine verbs); §"Runtime State Inventory"; §"Landmine 1" (relocate `GUImorphWeb()` entry before deleting `rtkogl.R`) |
| UI-03 | `tkogl2` deleted, `rgl` removed from dependencies entirely, migration note ships in `NEWS.md` | §"DESCRIPTION / NAMESPACE Mechanics"; §"tkogl2 Build-Tree Removal"; §"NEWS.md Migration Note" |
</phase_requirements>

## Summary

This is a **removal + shell-completion** phase, not a new-technology phase. Nothing is installed; the entire stack for the replacement browser shell already exists and is proven: `three.js`/`three-mesh-bvh` are vendored (WEB-00), `httpuv` transport is locked (WEB-01), the browser viewport with a HUD, mode toolbar, keyboard shortcuts, digitizing modes, and analytical action buttons is live in `R/view3d.R` (679 lines), and the server-owned session model with a per-route dispatch handler is live in `R/transport.R` (`.gmw_digitize_handler`, 12 dynamic subpaths). Phase 6 finishes the browser shell to Tk parity (tabs, menu, dialogs, specimen nav, status bar, file picker) and then physically deletes the Tk/OpenGL surface.

The work splits cleanly into three tracks the planner can wave: **(A) grow the browser shell** onto `view3d.R`'s existing page + add the missing `httpuv` routes to `.gmw_digitize_handler` (tab-state, file-list/open, message/color-picker acks, status), **(B) rewire the entry point** — `GUImorphWeb()` currently calls `.gmw_require_engine()` then builds the Tk window via `ui.main()`; it must instead boot the browser shell (serve mesh + open URL) — **and (C) demolish** the Tk chrome and native engine: delete `R/rtkogl.R`, the four `3dDigitize.*` Tk UI builders' widget code, `inst/libs/` engine binaries, the sibling `tkogl2/` tree, retire the CMP-01/parity tests, edit `DESCRIPTION`/`NAMESPACE`, bump to 1.0.0, and ship `NEWS.md`.

The single most dangerous item is that **`rtkogl.R` is not a pure engine file** — it holds the exported `GUImorphWeb()` entry point, the package-wide `dbg()` logger that `transport.R` depends on, `.plot_show()` used by result plots, and `.onAttach()`. A naïve `rm R/rtkogl.R` deletes the entry point and breaks in-package logging. Survivors must be relocated first (Landmine 1).

**Primary recommendation:** Sequence the phase as *grow-shell → rewire-entry → verify workflow engine-absent → demolish*. Never delete `rtkogl.R` or `inst/libs/` until `GUImorphWeb()` boots the browser shell and the full digitize→GPA→save workflow passes with the engine already unreachable. Relocate the non-engine survivors out of `rtkogl.R` as an explicit early task.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Tabs / control panels (digitize, anchor, surface, curve, GPA) | Browser / Client (DOM) | R route (state) | Tab content is view/input; the enable/disable gating state stays server-owned in `.gmw_session` |
| Menu (File: Load PLY/DGT, Add PLY, Save, Export, Merge; Help) | Browser / Client | R route + R filesystem | Menu items are DOM; each action's actual file I/O is an existing R route/function (server-owns-state) |
| File open / save picker (D-03) | R / Backend (`httpuv`) | Browser (list render) | R must enumerate the directory and own the chosen path — no native chooser, no `file.choose()` |
| Message boxes / warnings (`tkmessageBox`) | Browser / Client | R route (ack) | Purely presentational; R already knows the condition and returns text over a route or inlines it |
| Color picker (`tk_chooseColor`) | Browser / Client | R route | `<input type=color>` is native-to-browser; R stores the chosen hex |
| Specimen navigation (prev/next/jump, combo) | Browser / Client | R route (`/specimen` RE-SERVE, A4) | Already implemented server-side; browser adds the prev/next/combo controls |
| Status bar (specimen index, mode, counts, progress) | Browser / Client | R route (counts) | HUD text; counts read from server-owned session |
| 3D render / picking / overlays | Browser / Client (three.js) | R route (mesh bytes) | Already the browser's job since Phase 2/4 — this is what replaces the native OpenGL engine |
| `.dgt` read/write, GPA, export | R / Backend | — | Unchanged; R owns the data contract (DAT-01/02 depend on it) |

## Standard Stack

No packages are added in this phase. The stack is fixed and already present; the phase **removes** from it.

### Core (retained, unchanged)
| Library | Version constraint | Purpose | Why Standard |
|---------|-------------------|---------|--------------|
| `geomorph` | >= 4.1.1 | GPA + morphometrics + export | Inherited analytical layer; validated, reused as-is |
| `Rvcg` | (current) | mesh I/O, downsample, kmeans backend | Replaced Morpho in Phase 1 |
| `httpuv` | (locked, Phase 2) | loopback transport + the new browser shell routes | Already the transport; the file picker (D-03) and shell-state routes are served here |

### Removed this phase
| Library | From | Removed by | Note |
|---------|------|-----------|------|
| `tcltk` | `Imports` | D-01 | All `tk*` widget/dialog call sites removed first |
| `tcltk2` | `Imports` | D-01 | `tk2*` widgets in `3dDigitize.geomorph.r` etc. removed first |
| `rgl` | `Suggests` | UI-03 | Already demoted to `Suggests` in Phase 1; now removed entirely (verify no guarded `rgl::` call sites remain) |
| `tkogl2` (native engine) | `inst/libs/` + `.onLoad` + sibling `tkogl2/` tree | D-02 | Compiled `.dll`/`.dylib` + build tree + CMP-01 gate |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| R-served `httpuv` picker (D-03) | Native `tkgetOpenFile` / `file.choose()` | **Rejected by D-01/D-03** — no Tk survives; native chooser violates "no external application" and server-owns-path |
| Deleting `rtkogl.R` wholesale | Relocate survivors then delete | Wholesale delete removes `GUImorphWeb()`, `dbg()`, `.plot_show()`, `.onAttach()` — see Landmine 1 |

## Package Legitimacy Audit

**Not applicable — this phase installs no external packages.** It only *removes* `tcltk`, `tcltk2`, and `rgl` and deletes the bundled `tkogl2` native engine. No registry verification is required. (`geomorph`, `Rvcg`, `httpuv` are pre-existing locked dependencies from earlier phases.)

## Architecture Patterns

### System Architecture Diagram (end state, Tk gone)

```
                         R session
                            │
              GUImorphWeb(dir=…) [rewired entry]
                            │
        ┌───────────────────┴───────────────────┐
        │  httpuv listener (127.0.0.1:<port>)    │
        │  per-token, server-owns-state          │
        │                                        │
        │  staticPaths:  /<token>/  → temp dir   │
        │    (index.html, guimorphweb-three.js,  │
        │     specimen.ply bytes)                │
        │                                        │
        │  excludeStaticPath → .gmw_digitize_    │
        │    handler(token)  [single dispatch]   │
        │    existing: pick anchor curve delete  │
        │      undo specimen overlays downsample │
        │      gpa export save close             │
        │    NEW (Phase 6): files open savepath  │
        │      tabstate status msgack color …    │
        └───────────────┬────────────────────────┘
                        │ HTTP (same-origin, bare CSV bodies, no JSON)
                        ▼
             Browser page (view3d.R template)
   ┌──────────────────────────────────────────────┐
   │  three.js canvas  (render + BVH pick + overlays)│
   │  #t toolbar (modes + analytical actions)        │
   │  NEW: tab strip · menu bar · status bar         │
   │  NEW: modal layer (file picker, msgbox, color)  │
   └──────────────────────────────────────────────┘

  DELETED: tkogl2 native engine (inst/libs/*, sibling tree),
           Tk toplevel/notebook/menu/statusbar, tk* dialogs.
```

Data flow to trace (Load DGT → digitize → GPA → save): browser menu "Load DGT" → GET `/files` (R lists dir) → user picks → POST `/open` (R reads `.dgt`, loads session, re-serves specimen mesh) → browser renders + digitizes over existing routes → "GPA"/"Save" POST existing `/gpa` `/save` (path chosen R-side). No Tk, no native engine anywhere on the path.

### Recommended Project Structure (R/ after Phase 6)

```
R/
├── view3d.R          # browser page template + HTML builder (GROWS: tabs/menu/status/modals)
├── transport.R       # httpuv server + .gmw_digitize_handler (GROWS: file/shell routes)
├── shell.R (NEW?)    # relocated GUImorphWeb() entry + dbg()/.plot_show()/.onAttach() survivors
├── 3dDigitize.main.r        # KEEP data/model + .dgt/merge/export logic; STRIP ui.main/createMenu/createNavFrame/setStatus(Tk)
├── 3dDigitize.digitize.r    # KEEP landmark/anchor logic; STRIP ui.digitize/ui.anchor Tk widgets + tk_chooseColor + toplevels
├── 3dDigitize.surface.r     # KEEP downsample/template logic; STRIP ui.surface Tk + tkmessageBox + toplevel
├── 3dDigitize.curve.r       # KEEP curve logic; STRIP ui.curve Tk widgets
├── 3dDigitize.geomorph.r    # KEEP GPA/PCA/export logic; STRIP ui.geomorph tk2* widgets + tkmessageBox + tkgetSaveFile
├── parity.R          # KEEP (parity reader/gate helpers stay)
├── template_kmeans.R # KEEP (Rvcg kmeans)
├── gm_utils.R        # KEEP
└── rtkogl.R          # DELETE last, after survivors relocated
```

### Pattern 1: Adding a shell route to the single dispatch handler
The proven pattern is one `excludeStaticPath()` entry per new suffix + one `grepl("/suffix$", path)` branch in `.gmw_digitize_handler`. Bodies are bare CSV/text parsed with base R (no JSON dep), the path is NEVER joined to the filesystem, and the happy path returns 204 (or 200 with a bare text body for GET reads like `/overlays`).

```r
# transport.R — extend dyn_suffixes and add branches (mirror /overlays for GETs)
dyn_suffixes <- c("close","pick","anchor","curve","delete","undo","specimen",
                  "overlays","downsample","gpa","export","save",
                  "files","open","savepath","tabstate","status")  # NEW
# ... in .gmw_digitize_handler:
if (grepl("/files$", path)) {           # D-03 directory listing
  dir <- .gmw_session_get(token)$browse_dir %||% getwd()
  entries <- list.files(dir, pattern="\\.(dgt|ply)$", ignore.case=TRUE)
  return(list(status=200L, headers=list("Content-Type"="text/plain"),
              body=paste(entries, collapse="\n")))   # bare, JSON-free
}
```

### Pattern 2: D-03 file picker — R owns enumeration AND the chosen path
The browser sends only a *selected basename/index* over `/open`; R joins it to the server-owned browse directory and reads it. This preserves the Phase 5 invariant (`/save` carries no path, R owns the path) and the path-traversal guard (validate the selection against the enumerated list; never `file.path(dir, untrusted_path)` with `..`). Confirm the chosen basename is a member of the just-listed set before opening.

### Anti-Patterns to Avoid
- **Deleting `rtkogl.R` before relocating `GUImorphWeb()`/`dbg()`/`.plot_show()`/`.onAttach()`** — breaks the entry point and in-package logging (Landmine 1).
- **Joining an untrusted request path to the filesystem** in the new `/open`/`/files` routes — every existing route deliberately only `grepl`s the suffix (T-2-02). The file picker must validate the selection against R's own enumerated list, not trust a browser-supplied path.
- **Overflowing the 8192-byte `sprintf` HEAD cap** when adding tabs/menu markup to `GMW_VIEW3D_TEMPLATE`. All parameter-free markup goes in the BODY (after the `MESH_URL = "%s";` split marker); only true `%s` slots stay in the HEAD (see Landmine 3).
- **Forgetting RE-SERVE on specimen switch (A4)** when wiring the new specimen combo/prev/next to `/specimen` — the browser must reload the returned mesh URL and `redraw()` overlays, exactly as `switchSpecimen()`/`loadSpecimen()` already do.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| File open/save chooser | A bespoke JS filesystem browser with directory traversal | R-served `list.files()` over one route + a plain browser list (D-03) | R already owns the filesystem and the path; keep server-owns-state; avoids path-traversal surface |
| Color picker | Custom HSV wheel | `<input type="color">` | Native browser widget returns `#rrggbb` directly |
| Message box / warning | New modal framework | A single reusable DOM modal + the existing route/redraw plumbing | Parity only needs title+message+OK; the toolbar/HUD pattern already exists in `view3d.R` |
| Per-token state | Any client-side store | Existing `.gmw_session` server-owned env | Browser is a pure view layer (REFERENCE-ARCHITECTURE) |
| Route dispatch | A second server / router lib | Extend `.gmw_digitize_handler` with more `grepl` branches | The mixed static+dynamic pattern is proven (Phase 3/4/5) |

**Key insight:** Every "dialog" the Tk chrome offered maps onto machinery that already exists — R owns the data/paths, the browser owns presentation, and the transport is one dispatch handler. Phase 6 is wiring, deletion, and packaging, not new subsystems.

## Tk Removal Surface (enumeration for the planner)

All paths under `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/R/`. Line numbers are current-source anchors, not exhaustive; treat them as "where to look."

### (a) File / message / color dialogs — reimplement as browser UI (D-03)
| Call | File : lines |
|------|--------------|
| `tkgetOpenFile` | `3dDigitize.digitize.r`:902 · `3dDigitize.main.r`:1509, 2887, 3271, 3549 |
| `tkgetSaveFile` | `3dDigitize.geomorph.r`:314, 368 · `3dDigitize.main.r`:1961, 2088, 3567 |
| `tkmessageBox` | `3dDigitize.geomorph.r`:199, 226, 254, 303, 408, 414, 429, 615, 627 · `3dDigitize.main.r`:892, 1951, 2004, 2915, 2947, 3075, 3265, 3285, 3312, 3374, 3562, 3579, 3581 · `3dDigitize.surface.r`:327, 507, 562 |
| `tcl('tk_chooseColor')` | `3dDigitize.digitize.r`:481, 500 |

There is **no `file.choose()`** in the source (verified) — good; only the `tk*` choosers exist.

### (b) Main window chrome — `3dDigitize.main.r`
| Element | Anchor | Replace with |
|---------|--------|--------------|
| `tktoplevel` + `tktitle` + `tkwm.minsize` + `.center_toplevel` | 660–674, 51 | The browser page (already the window); drop entirely |
| `ttknotebook` + 5 `tkadd` tabs + tab enable/disable + `<Button-1>` tab switch | 678, 720–729, 709 | DOM tab strip in `GMW_VIEW3D_TEMPLATE` BODY; gating state stays server-owned |
| `tkmenu` topMenu/fileMenu/devMenu/helpMenu + all `tkadd` command entries | 907–1024 | DOM menu bar; each command → existing R route/function |
| Status bar: `statusFrame`/`sepStatus`/`statusLabel`/`ttkprogressbar` | 731–745; `setStatus` 268; `busyStart`/`busyStop` 273/283 | HUD status region (the `#h`/`#m` pattern already in `view3d.R`) |
| Nav: `createNavFrame`, `refreshNavButtons`, `populateSpecimenCombo`, `jumpToSpecimen` | 1031, 294, 309, 327 | DOM prev/next + specimen `<select>` wired to `/specimen` (RE-SERVE A4) |
| `showShortcutsDialog` toplevel | 833–838 | DOM help modal / static HUD legend |
| `.warnUnexpectedExtension` (uses `tkmessageBox`) | 887 | Browser warning modal |

### (c) Tab builders (Tk widget code) — strip the UI, keep the logic
| Function | File : line |
|----------|-------------|
| `ui.main` | `3dDigitize.main.r`:657 |
| `ui.digitize`, `ui.anchor` | `3dDigitize.digitize.r`:168, 312 |
| `ui.surface` (+ "Set Number of Surface Sliders" toplevel :160) | `3dDigitize.surface.r`:35 |
| `ui.curve` | `3dDigitize.curve.r`:29 |
| `ui.geomorph` (all `tk2label`/`tk2entry`/`tk2spinbox`/`tk2checkbutton`) | `3dDigitize.geomorph.r`:25, 52–110 |
| "Set Landmark Number" / "Set Anchor Number" toplevels | `3dDigitize.digitize.r`:779, 840 |

The GPA options currently live as `tclVar`-backed `tk2checkbutton`s (geomorph.r 52–110). Phase 5 already reads GPA options into the geomorph env via `.gmw_session_to_geomorph_env` + gpagen option `tclVars`; the browser GPA tab must set those same options over a route (or the GPA button posts option flags) so `.build_geomorph_data`/`compute` stay untouched.

### (d) S3 `ui`/`init`/`bind`/`updateWidgets` generics
`3dDigitize.main.r`:75–89 define S3 generics dispatched on `class(e) <- "main"`. `GUImorphWeb()` calls `ui(e)` then `init(e)`. After rewire, the `main`-method Tk implementations are removed; the entry no longer needs `UseMethod` dispatch. Audit `.geomorph.r`/`.surface.r`/`.digitize.r`/`.curve.r` for `*.main` method definitions before removing the generics.

**Widget-call magnitude (for effort sizing):** grep counts of `tk*`/`ttk*`/`tcl*` calls — `3dDigitize.geomorph.r` ~131, `3dDigitize.main.r` ~102, `3dDigitize.digitize.r` ~104, `rtkogl.R` ~80, `3dDigitize.surface.r` ~79, `3dDigitize.curve.r` ~12. Most are `tkgrid`/`tkpack`/`tkconfigure` layout calls that vanish with their widgets.

## Native Engine Removal Surface (D-02, UI-02)

### In-package engine binding — `R/rtkogl.R` (944 lines)
| Symbol | Line | Disposition |
|--------|------|-------------|
| `.gmw_engine` env + `$ok`/`$msg` | 498–500 | DELETE |
| `.gmw_require_engine` | 505 | DELETE (and remove its call in `GUImorphWeb()` at 410) |
| `.onLoad` (tcl `load` of `tkogl2`) | 513–592 | DELETE |
| `add` / `del` / `set` / `shows` (tcl_if → C engine verbs) | 8, 338, 675, 601 | DELETE + remove all call sites (see below) |
| `get_rtkogl_date` | 2 | DELETE |
| `loadDgt` (tcl `loadDgt`, exported placeholder) | 444 | DELETE + drop `export(loadDgt)` from NAMESPACE |
| `bindPlatformAccelerator` / `bindDeleteGesture` (Tk bindings) | 894, 901 | DELETE (Tk-only) |

### Engine-verb call sites (the `add`/`set`/`del`/`shows` bridge into C)
These native-draw/pick calls are scattered through `3dDigitize.main.r` (e.g. `result <- add("getCompileInformation", …)` :760, `set("window","id",canvasFrame)` :783, `set("window","size",…)` :788/799, canvas `<Configure>` size pushes :795–813), plus the digitize/surface/curve tabs. **Every call to `add`/`set`/`del`/`shows` must be removed** — the browser now renders and picks. The Phase 5 session/route layer is already the replacement for the state these calls maintained.

### Compiled binaries shipped in the package — DELETE (this is what UI-02 verifies)
- `inst/libs/tkogl2.dylib`
- `inst/libs/x64/tkogl2.dll`
- `inst/libs/x64/glut64.dll`
Removing these + the `.onLoad` load path is what makes "engine uninstalled and absent from the library path" literally true.

### Survivors that MUST be relocated out of `rtkogl.R` before deletion (Landmine 1)
| Symbol | Line | Why it survives | Suggested home |
|--------|------|-----------------|----------------|
| `GUImorphWeb` (exported entry) | 409 | THE user entry point; must be rewired to boot the browser shell | `shell.R` (new) or `transport.R` |
| `dbg` | 844 | `transport.R` depends on the package-level `dbg` (its own def is only a source-alone fallback) | `shell.R`/`transport.R` |
| `.plot_show` | 923 | result-plot delivery (used by geomorph plots) | `view3d.R` (beside `.gmw_view3d`) |
| `.onAttach` | 936 | startup banner | `shell.R`/`transport.R` |
| `.pkg_version`, `.module_banner`, `.isMacOS`, `normalizeWheelDelta`, `shortcutLabel` | 855–894 | general helpers (audit each caller) | wherever their callers land |

## tkogl2 Build-Tree Removal (D-02)

Delete the entire sibling directory `integrated-guimorph-development_EOC/Project/tkogl2/`. Top-level contents:
- `CMakeLists.txt`, `cmake/`, `tkogl2.sln`, `tkogl2.vcxproj`, `tkogl2.vcxproj.user` (MSVC/Rtools build)
- `src/` — the C/ObjC engine: `ogl_ZARF9.c`, `ogl_model_*_ZARF_9.c`, `curve_ZARF_9.c`, `marker.c`, `tcl_dispatch.c`, `tcl_init.c`, `tcl_state.c`, `tcl_window.c`, `gfx_backend.h` (the backend seam), `gfx_backend_wgl.c` (Windows WGL), `gfx_backend_nsgl.m` (macOS NSGL), `tcl_stub_bootstrap.c`, `StatisticsFunction_ZARF_9.*`
- `include/` — bundled Tcl/Tk headers (~280 files) + `glut.h`
- `third_party/glut_shim/`
- `test/gate/` — **CMP-01 gate machinery:** `gate_check.R`, `gate_ext.c`, `CMakeLists.txt`; `test/fixtures/regression.ply`
- `R/` — **stale sibling copies** of `3dDigitize.*.r`, `geomorph.support.code.r`, `rtkogl.R` (not the package's R/; delete with the tree)
- `BUILD.md`, `docs/`, `lib/`, `deltas.txt`

## Test Removal / Rewrite Surface (D-02, D-04)

| Test file | Action | Reason |
|-----------|--------|--------|
| `test-picking-parity.R` | RETIRE | PICK-03 oracle (tkogl2) deleted → won't-verify (D-04) |
| `test-retina-picking-parity.R` | RETIRE | same oracle gone |
| `test-dgt-cross-platform.R` | REWRITE | keep the reader-accepts-both-dialects assertions; drop/skip the `-rewrite` byte gate that needs a Windows `tkogl2` capture (D-04) |
| `test-transport.R` :121–133 | **REWRITE (will FAIL otherwise)** | It asserts `rtkogl.R` still contains `.onLoad` + `Tkogl2` (proving the engine untouched). After deletion those assertions invert — rewrite to assert the engine is *gone* (no `inst/libs/tkogl2*`, no `.gmw_engine`, no `.onLoad` tcl-load) |
| `test-offline-smoke.R`, `test-rgl-fallback-macos.R`, `test-picking-transport.R`, `test-digitizing-session.R` | AUDIT | they grep for `tkogl2`/`.gmw_engine`/`.gmw_serve_mesh`; update expectations to the engine-absent world |
| Tk-stubbing tests (`assignInNamespace` on tcltk) | RETIRE/REWRITE | STATE notes 4 tests stub `tcltk` via `assignInNamespace`, which R 4.6 forbids; with `tcltk` gone they are moot |

STATE also records the suite has been "6-red for a month" (2 call deleted functions, 4 stub tcltk). Phase 6 removes the root cause for the 4 tcltk ones; the planner should fold a green-the-suite task in.

## DESCRIPTION / NAMESPACE Mechanics (D-01, D-05, UI-03)

**`DESCRIPTION`** (`integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION`):
- `Imports:` currently `geomorph (>= 4.1.1), Rvcg, tcltk, tcltk2, httpuv` → remove `tcltk`, `tcltk2` → leaves `geomorph, Rvcg, httpuv`.
- `Suggests:` currently `rgl, htmlwidgets, testthat` → remove `rgl` → leaves `htmlwidgets, testthat`. (Verify no guarded `rgl::` call sites remain first; STATE says PLT-01 left "zero `rgl::` calls in geomorph.r".)
- `Version:` `0.10.0` → `1.0.0`; consider bumping `Date:`.
- `Description:` text says "based on OpenGL and Tk widgets" — update to the browser architecture.

**`NAMESPACE`** (roxygen-generated — edit the roxygen tags, then re-`document()`, don't hand-edit):
- Current: `export(GUImorphWeb)`, `export(gmw_close)`, `export(gmw_picks)`, `export(gmw_session)`, `export(loadDgt)`, `import(Rvcg)`, `import(geomorph)`, `import(tcltk)`, `import(tcltk2)`.
- Remove `import(tcltk)`, `import(tcltk2)` (delete the `@import tcltk`/`@import tcltk2` roxygen directives — find them near the package doc or in `rtkogl.R`).
- Remove `export(loadDgt)` (function deleted).
- Keep `import(Rvcg)`, `import(geomorph)`, `export(GUImorphWeb/gmw_close/gmw_picks/gmw_session)`.
- **Roxygen debt (STATE):** 22 S3 methods need `@exportS3Method`; `@docType "package"` is deprecated. Whether to clear this here is builder's discretion, but re-running `roxygen2` will surface it as `R CMD check` noise.

## NEWS.md Migration Note (D-05, D-06, D-07)

`NEWS.md` **does not exist yet** in the package root — it must be created at `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/NEWS.md`. Content per decisions:
- Header `# GUImorphWeb 1.0.0` — browser migration complete; breaking: native OpenGL/Tk engine and `rgl` removed.
- Migration guidance for native-path users: **primary** → GUImorph (`dreoc/GUImorph`, the `upstream` remote, separately maintained native OpenGL/Tk project); **fallback** → pin `GUImorphWeb 0.10.0` (last version bundling the engine), e.g. `remotes::install_version("GUImorphWeb", "0.10.0")` or the equivalent git-tag pin.
- Note that PICK-03 / DAT-02 `-rewrite` gates are formally closed as won't-verify (D-04) — the harness is complete and drop-in-ready; the gap is Windows-host availability.

Use R `NEWS.md` conventions (top-level `#` version headers, `##` subsections). Config has `create_tag: true` — a `1.0.0` tag should accompany the release.

## Runtime State Inventory

> Rename/refactor/removal phase — all categories answered explicitly.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| **Stored data** | No datastore keys embed "tkogl2"/"tcltk". Session state is in-memory (`.gmw_session`/`.gmw_picks`, per-token, non-persistent). `.dgt` file format is engine-independent (R owns reader/writer). Sample `inst/extdata/folsom3d.dgt` is data only. | None — verified: no persisted state references the engine. |
| **Live service config** | The only "service" is the ephemeral loopback `httpuv` listener, created per session, torn down at exit (Phase 3 teardown). No external service holds the engine name. | None — verified. |
| **OS-registered state** | No launchd/systemd/Task Scheduler/pm2 registration. `.onLoad` (auto engine load) and `.onAttach` (banner) are package hooks, not OS registrations. `browseURL()` uses the OS default browser at call time only. | Remove `.onLoad` (D-02); keep/relocate `.onAttach`. |
| **Secrets / env vars** | None. Per-session token is random, in-memory (`.gmw_token`). `getOption("browser")`/`R_BROWSER` consulted at launch (unaffected). `options(guimorph.debug)` set by `GUImorphWeb(debug=)`. | None. |
| **Build artifacts / installed packages** | `inst/libs/tkogl2.dylib`, `inst/libs/x64/tkogl2.dll`, `inst/libs/x64/glut64.dll` ship inside the package. Sibling `tkogl2/` build tree produces them. A prior *installed* GUImorphWeb 0.10.0 in a user's library still contains the engine — reinstall of 1.0.0 replaces it, but a stale hand-copied `libs/` could linger. `renv/` + `renv.lock` in the package root (STATE notes a workspace-local `renv` side effect that hangs bare R; unrelated to this deletion but present). | Delete `inst/libs/*` and the `tkogl2/` tree. UI-02 verification = fresh install/load with no engine present. |

**Canonical question — after every repo file is updated, what still has the old thing?** Only a previously *installed* copy of the package (0.10.0) in a user library, which the 1.0.0 reinstall overwrites. That is exactly what D-06/D-07's pin guidance addresses. No hidden runtime state survives a clean reinstall.

## Common Pitfalls

### Pitfall 1: Deleting `rtkogl.R` decapitates the package
**What goes wrong:** `GUImorphWeb()`, `dbg()`, `.plot_show()`, `.onAttach()` disappear; entry point and logging break.
**How to avoid:** Relocate survivors as an explicit early task; delete `rtkogl.R` last. Verify `GUImorphWeb()` boots the browser shell *before* the delete.
**Warning signs:** `could not find function "GUImorphWeb"`; `transport.R` `dbg` errors under `guimorph.debug=TRUE`.

### Pitfall 2: The engine-absent workflow isn't actually engine-absent
**What goes wrong:** A lingering `add`/`set`/`del`/`shows` call, or `.gmw_require_engine()` still in `GUImorphWeb()`, stops the browser path on an engine-less host.
**How to avoid:** Remove `.gmw_require_engine()` from the entry FIRST; grep for `add(`/`set(`/`del(`/`shows(` call sites and remove each. Test with `inst/libs/` already deleted (UI-02 order).
**Warning signs:** `stop("… needs the native tkogl2 engine …")` or `tcl` errors on load.

### Pitfall 3: 8192-byte `sprintf` HEAD cap overflow
**What goes wrong:** Adding tab/menu/status markup as `%s`-parameterised HEAD content pushes the `head_fmt` past base-R's 8192-byte single-`fmt` limit; `sprintf` errors.
**How to avoid:** Put all parameter-free shell markup in the BODY (after the `MESH_URL = "%s";` marker at `view3d.R`:88). Only genuine injection slots (`title`, `background`, clouds, mesh, mesh_url) stay in HEAD. This split is already the file's design.
**Warning signs:** `sprintf` "too long" / "unsupported format" errors when the template grows.

### Pitfall 4: Specimen switch without RE-SERVE (A4)
**What goes wrong:** New prev/next/combo controls change the index but the browser keeps the old mesh/BVH → picks land on the wrong geometry.
**How to avoid:** Wire nav to the existing `switchSpecimen(n)` → POST `/specimen` → `loadSpecimen(url)` (rebuild BVH) → `redraw()` overlays. Reuse `view3d.R`:587–597, don't reinvent.
**Warning signs:** Stale mesh after switching; overlays from the previous specimen.

### Pitfall 5: File picker path-traversal (D-03)
**What goes wrong:** `/open` joins a browser-supplied path to the filesystem → `..` escape.
**How to avoid:** R enumerates the directory (`/files`), the browser returns only a selection from that set, R validates membership before opening. Never `file.path(dir, untrusted)` with unchecked input. Mirror the existing "grepl the suffix only, never join req path" invariant.
**Warning signs:** Any `normalizePath`/`file.path` fed directly from `req$rook.input`.

### Pitfall 6: `test-transport.R` inversion
**What goes wrong:** The "engine untouched" test asserts `rtkogl.R` still has `.onLoad`/`Tkogl2`; deleting the file makes it fail, not pass.
**How to avoid:** Rewrite it to assert engine-absence as part of the same commit that deletes the engine.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Native tkogl2 OpenGL viewport in a Tk canvas | three.js browser viewport over httpuv | Phases 2–5 (this phase completes it) | Removes XQuartz/Homebrew/Tcl-Tk from the render path |
| Tk chrome (notebook/menu/statusbar) as control surface | Browser DOM shell | Phase 6 | UI-01 |
| `rgl` for 3-D result plots | three.js widget (`.gmw_view3d`) | Phase 1 (PLT-01) | `rgl` demotable then removable |
| Morpho `fastKmeans` | Rvcg reimplementation (`template_kmeans.R`) | Phase 1 (PLT-02) | Dropped Morpho→rgl hard dep |

**Deprecated/outdated:** `@docType "package"` roxygen tag (deprecated); `assignInNamespace`-based tcltk stubbing in tests (R 4.6 forbids) — both removed/mooted here.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `GUImorphWeb()` should be *rewired* to boot the browser shell (serve mesh + open URL), replacing the Tk `ui.main` path, rather than kept as a Tk launcher | Summary / Removal Surface | If the intended UX is "print a URL, no auto-launch" vs "open browser", the entry differs; both honor REFERENCE-ARCHITECTURE (print-first, try-open). Low risk — matches `.gmw_serve_mesh` behavior. |
| A2 | Relocating survivors into a new `shell.R` (vs folding into `transport.R`/`view3d.R`) is acceptable file organization | Project Structure | Cosmetic; any surviving-file home works. |
| A3 | No production datastore/service embeds the engine or Tk name (state is in-memory + `.dgt` files) | Runtime State Inventory | Verified by source read; low risk. |
| A4 | `rgl` has no remaining guarded call sites (Phase 1 removed them) | DESCRIPTION Mechanics | If a guarded `rgl::` remains, removing `rgl` from Suggests breaks it — planner must grep `rgl::` before the DESCRIPTION edit. |
| A5 | The new file-open/save picker replaces the Tk choosers in-place at every `tkgetOpenFile`/`tkgetSaveFile` site; some sites (merge, add-PLY) need multi-select/save-name UX | Tk Removal Surface (a) | Multi-select merge (`multiple = TRUE`, main.r:3549) and save-name entry need richer browser UI than a single-pick list. Medium — flag as its own task. |

## Open Questions

> **All three RESOLVED at planning (2026-08-13).** The plans below settle each
> question; none is left dangling. The recommendations were adopted verbatim.

1. **Entry-point UX after rewire. — RESOLVED (Plan 06-03, Task 2).**
   - What we know: `.gmw_serve_mesh` prints the URL then tries `browseURL`; REFERENCE-ARCHITECTURE says print-first, auto-open as convenience.
   - What's unclear: whether `GUImorphWeb()` should take a starting directory / PLY argument (the Tk path started empty and used Load PLY).
   - Recommendation: `GUImorphWeb(dir = getwd(), open = TRUE)` — boot the shell, set the server-owned browse dir for the D-03 picker, print+open the URL. Builder's discretion per CONTEXT.
   - **Resolution:** Adopted. Plan 06-03 rewires the signature to `GUImorphWeb(dir = getwd(), open = TRUE, debug = FALSE)`, seeding the session `browse_dir` (Plan 06-01) and delegating print+open to `.gmw_serve_mesh`. No longer open.

2. **GPA options transport. — RESOLVED (Plan 06-06, Task 2).**
   - What we know: options were `tclVar`-backed checkbuttons; Phase 5 feeds gpagen option `tclVars` via `.gmw_session_to_geomorph_env`.
   - What's unclear: whether the browser GPA tab posts each option flag over a route or the `/gpa` body carries them.
   - Recommendation: extend the `/gpa` (or a `/gpaopts`) route to carry the boolean flags as a bare CSV; keep `.build_geomorph_data`/`compute` untouched.
   - **Resolution:** Adopted. Plan 06-06 carries the boolean GPA flags as a bare CSV over the `/gpa` (or new `/gpaopts`) branch into the gpagen option tclVars via `.gmw_session_to_geomorph_env`, leaving `.build_geomorph_data`/`compute` byte-unchanged. No longer open.

3. **Merge / Add-PLY multi-file UX (A5). — RESOLVED (Plan 06-02, Task 2).**
   - What we know: Tk used `multiple = TRUE` open + a save-name dialog.
   - Recommendation: model as a checkbox list (multi-select) + a save-name text field in the browser picker modal; own its own task.
   - **Resolution:** Adopted. Plan 06-02 Task 2 renders Add PLY / Merge through the same picker modal with a checkbox multi-select list plus a save-name field posting to `/savepath` (Plan 06-01). No longer open.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| R (with `httpuv`, `geomorph`, `Rvcg`) | whole package | ✓ (assumed, prior phases) | — | — |
| A web browser | browser shell | ✓ | — | Print URL (REFERENCE-ARCHITECTURE); degrades legibly |
| `roxygen2` / `devtools` | NAMESPACE regen, tests | ✓ (dev only) | 8.0.0 (Config/roxygen2/version) | hand-verify NAMESPACE |
| CMake / MSVC / Rtools | **NOT needed after this phase** | n/a | — | Build tree deleted (D-02) |
| Tcl/Tk | **removed** | n/a | — | none — that's the point |

**Missing dependencies with no fallback:** none. This phase reduces the dependency surface; it adds nothing that could be missing. (The Windows `tkogl2` host that would close PICK-03/DAT-02 is unavailable — explicitly closed won't-verify per D-04, not a blocker.)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `testthat` (3e); `tests/testthat.R` + `tests/testthat/*` |
| Config file | `DESCRIPTION` `Suggests: testthat`; `tests/testthat/helper-*.R` |
| Quick run command | `devtools::test(filter = "<name>")` (e.g. `filter = "transport"`) |
| Full suite command | `devtools::test()` (or `R CMD check`) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| UI-01 | New shell routes (files/open/tabstate/status) parse + dispatch; picker validates selection | unit | `devtools::test(filter="transport")` (extend) | ⚠️ extend `test-transport.R` |
| UI-01 | Template still splits at the `MESH_URL` marker under the 8192 cap after tabs/menu added | unit | `devtools::test(filter="view3d")` | ✅ `test-*-view3d.R` (extend) |
| UI-01 | Specimen nav RE-SERVE unchanged | unit | `devtools::test(filter="digitizing-session")` | ✅ (audit) |
| UI-02 | Package loads + digitize→GPA→save workflow runs with `inst/libs/` and `.onLoad` gone | integration | new test: assert no `.gmw_engine`/`.onLoad` tcl-load; workflow via routes | ❌ Wave 0 (rewrite `test-transport.R` :121–133) |
| UI-02 | No `add`/`set`/`del`/`shows` engine-verb call sites remain | source-scan | grep-style source test | ❌ Wave 0 |
| UI-03 | `DESCRIPTION` has no `tcltk`/`tcltk2`/`rgl`; `NAMESPACE` has no tcltk imports/`loadDgt`; `inst/libs` empty of `tkogl2*` | source-scan | new test reading DESCRIPTION/NAMESPACE/inst | ❌ Wave 0 |
| UI-03 | `NEWS.md` exists with 1.0.0 header + pin 0.10.0 + GUImorph link | source-scan | new test | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `devtools::test(filter = "<touched area>")`
- **Per wave merge:** full `devtools::test()`
- **Phase gate:** full suite green + `R CMD check` clean of tcltk/rgl before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] Rewrite `test-transport.R` :121–133 to assert engine ABSENCE (was: presence).
- [ ] New source-scan test: DESCRIPTION/NAMESPACE free of `tcltk`/`tcltk2`/`rgl`/`loadDgt`; no `inst/libs/tkogl2*`.
- [ ] New source-scan test: no `add(`/`set(`/`del(`/`shows(` engine-verb call sites; no `.gmw_engine`/`.gmw_require_engine`.
- [ ] New test: `NEWS.md` present with required migration content.
- [ ] Extend `test-transport.R` for new shell routes (`/files`, `/open`, path-traversal rejection).
- [ ] Retire `test-picking-parity.R`, `test-retina-picking-parity.R`; skip/rewrite the `-rewrite` gate in `test-dgt-cross-platform.R` (D-04) with a documented won't-verify note.

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1`.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Loopback-only, single local user; per-session token is an enumeration guard, not auth (documented in `transport.R` header) |
| V3 Session Management | partial | Per-token server-owned session; ephemeral; torn down at exit |
| V4 Access Control | yes | Bind `127.0.0.1` only (never wildcard); token-guarded path; new `/files`/`/open` must not expose arbitrary dirs |
| V5 Input Validation | **yes (primary risk here)** | Base-R parse of bare CSV bodies; the NEW file-open route is the main new attack surface |
| V6 Cryptography | no | Token is a non-CSPRNG enumeration guard (accepted residual risk, Phase 2 header); no new crypto |
| V12 Files & Resources | **yes** | D-03 picker: validate selection against R-enumerated list; never join untrusted request path to filesystem |

### Known Threat Patterns for this stack
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via `/open` file selection | Tampering / Info-disclosure | R enumerates dir; browser returns index/basename from that set; validate membership; no `file.path(dir, untrusted)` with `..` |
| Directory over-exposure via `/files` | Info-disclosure | Scope listing to a server-owned browse dir; filter to `.dgt`/`.ply`; don't recurse into arbitrary parents |
| LAN exposure of the listener | Info-disclosure | Keep `host = "127.0.0.1"` (inherited T-2-03); never wildcard |
| Injection via request body | Tampering | Bare CSV, base-R `as.numeric`/`as.integer`, arity+finiteness checks, no `eval`, no JSON (inherited T-4-02/T-5-04) |
| Malformed `.dgt` on open | DoS/Tampering | Wrap reader in `tryCatch`; surface a browser error modal, don't crash the server |

## Project Constraints (from .cursor/rules / .cursorrules)
- **`.cursorrules` (RTK):** prefix shell commands with `rtk` for token savings; it is a passthrough when no filter applies. (Note: `rtk` was not found on this machine during research; commands still run raw.) This is a tooling convenience, not a code constraint.
- **`.planning/config.json`:** `security_enforcement` on (ASVS L1, block on high), `nyquist_validation` on (Validation Architecture required), `code_review` on (standard), `commit_docs: false` (docs not auto-committed), `create_tag: true` (tag the 1.0.0 release), `branching_strategy: none`.
- **REFERENCE-ARCHITECTURE (binding):** server owns state; browser is a pure view/input layer; assets vendored offline (no CDN, no runtime network); print the URL (don't rely on auto-open). The new shell + picker MUST obey these.

## Sources

### Primary (HIGH confidence) — direct source reads this session
- `R/view3d.R` (679 lines) — full browser page template, HUD/toolbar, modes, routes wiring, 8192-byte split.
- `R/transport.R` (861 lines) — `.gmw_digitize_handler` dispatch, `.gmw_session` model, routes, teardown.
- `R/rtkogl.R` (§490–592 `.onLoad`/`.gmw_engine`; §400–474 `GUImorphWeb`/`loadDgt`; symbol map) — engine binding + survivors.
- `R/3dDigitize.main.r` (§75–89 generics, §255–360 status/nav, §640–1025 window/notebook/menu/status) — Tk chrome.
- `DESCRIPTION`, `NAMESPACE` — dependency + export edits.
- `tests/testthat/test-transport.R` :121–133 — the will-invert engine-presence test.
- Directory listings: `inst/libs/` (engine binaries), `tkogl2/` tree (build surface, CMP-01 gate).
- grep enumerations of `tk*`/`tk2*`/`tcl*` dialog + widget call sites across the four digitizing files.
- `.planning/`: `CONTEXT.md`, `REQUIREMENTS.md`, `STATE.md`, `ROADMAP` context, `REFERENCE-ARCHITECTURE.md`, `05-WINDOWS-REVIEW.md`, `config.json`.

### Secondary / Tertiary
- None needed — no external documentation lookup required for a removal/refactor phase within a known codebase.

## Metadata

**Confidence breakdown:**
- Removal surface (Tk + engine + tests + build tree): HIGH — enumerated directly from source with line anchors.
- Browser shell attach points: HIGH — `view3d.R`/`transport.R` read in full; the patterns to extend are explicit.
- Entry-point rewire: MEDIUM-HIGH — mechanism clear; exact UX (args, auto-open) is builder's discretion (Open Q1).
- Multi-file picker UX + GPA-options transport: MEDIUM — flagged as their own tasks (A5, Open Q2/Q3).

**Research date:** 2026-08-13
**Valid until:** ~2026-09-12 (stable internal codebase; re-verify if Phase 5 tail work lands more routes/tests before planning)
