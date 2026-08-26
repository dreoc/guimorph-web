# Phase 6: Shell and Native Retirement - Context

**Gathered:** 2026-08-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Replace the Tk chrome (tabs, dialogs, specimen navigation, status bar) with a
browser shell at feature parity, then remove the native engine and its entire
build surface: delete `tkogl2`, drop `rgl`, and — decided here — also drop
`tcltk`/`tcltk2`. Ship a `NEWS.md` migration note for users on the native path.

Delivers UI-01 (browser shell at Tk parity), UI-02 (workflow runs with the
native engine absent from the library path), UI-03 (`tkogl2` deleted, `rgl`
removed, migration note shipped). CMP-01 is deliberately retired here.

**Not in scope:** the deferred macOS→Windows `.dgt` upstream leg (GUImorph's own
cross-platform parity), Linux support, WebGPU as a first-class target, and the
Phase 5 live-surface COMPUTE stub — all belong to other phases/projects.

</domain>

<decisions>
## Implementation Decisions

### Retirement Scope
- **D-01 (full toolkit severance):** Phase 6 drops **`tcltk` AND `tcltk2`** from
  `Imports` in addition to `tkogl2` and `rgl`. No Tk window survives. Every
  dialog, menu, tab, and status readout becomes browser-rendered. This goes
  beyond the literal wording of UI-03 (which names only `tkogl2` + `rgl`) and is
  the intended end state — it matches the "no external application" positioning
  and is what makes UI-01 real rather than leaving Tk as the control surface.
- **D-02 (engine deletion boundary):** Delete `R/rtkogl.R` (the in-package engine
  binding), remove the engine load/guard from `transport.R`/onLoad, AND drop the
  sibling `tkogl2/` project tree (CMake, MSVC/Rtools, WGL/NSGL backends,
  `gfx_backend.h` seam). Retire the CMP-01 test machinery. Full removal from the
  package and repo build surface — nothing archived in-tree.

### File & Message Dialogs (forced by full severance)
- **D-03 (file opening = browser-served picker):** With `tcltk` gone,
  `tkgetOpenFile`/`tkgetSaveFile` are removed. Opening files (choosing which
  `.dgt`/`.ply` to load) is done via an **R-served directory listing/picker over
  `httpuv`**, selected inside the same browser shell; R opens the chosen path.
  No native OS chooser, no `file.choose()`. Consistent with server-owns-state and
  the Phase 5 rule that R owns the path (`/save` carries no path).
- Message boxes (`tkmessageBox`) and color pickers (`tk_chooseColor`) scattered
  across `3dDigitize.main.r`/`.geomorph.r`/`.surface.r`/`.digitize.r` must also
  be reimplemented as browser-rendered UI. (Exact styling = builder's discretion.)

### PICK-03 / DAT-02 Gate Fate
- **D-04 (close as won't-verify):** Deleting `tkogl2` destroys the only oracle for
  the still-DEFERRED PICK-03 milestone gate and the DAT-02 `-rewrite` byte gate,
  both of which awaited a Windows `tkogl2` capture. No Windows host has been
  available across Phases 4–6. Decision: **do not** block Phase 6 on a capture.
  Formally close both as won't-verify, document the limitation (harness is
  complete and was drop-in-ready — the gap is host availability, not code),
  delete the engine, and retire the two pending todos. The parity reader
  (accepts both dialects) and the automated primary gates remain in place.

### Migration Note (NEWS.md)
- **D-05 (version bump to 1.0.0):** Removing the native engine + `rgl` + Tk chrome
  is breaking; bump GUImorphWeb to **1.0.0**, signalling the browser migration is
  complete and the architecture stabilized.
- **D-06 (pin target = 0.10.0):** The pinnable "last version that still bundled
  the native engine" is **0.10.0** (current `DESCRIPTION` version, pre-Phase-6).
- **D-07 (migration destination):** The `NEWS.md` note points native-path users
  **primarily to GUImorph** (`dreoc/GUImorph`, the `upstream` remote) — the
  separately-maintained native OpenGL/Tk project — with **pin `GUImorphWeb 0.10.0`**
  as the frozen-package fallback for anyone who must stay on this package as-is.

### Claude's Discretion
- **Shell layout & fidelity** — faithful mirror of the Tk arrangement (center
  viewport + tabbed control panel + menu + status bar) vs a browser-native
  redesign. Resolve against the existing `view3d.R` HUD/toolbar patterns; feature
  parity (UI-01) is the only hard constraint.
- **Dialog/menu styling** — how browser-rendered dialogs, menus, and message
  boxes look and behave.
- **Shortcuts & status-bar content** — which accelerators (`[`/`]` prev-next,
  Ctrl+S, etc.) and status readouts (specimen index, mode, counts) carry over.
  Preserve parity; exact set is builder's discretion.

### Folded Todos
- **`pick03-windows-parity-capture-owed.md`** — "PICK-03 milestone gate + CMP-01
  load owed a Windows capture." Folded via D-04: closed as won't-verify and
  retired in Phase 6, since the oracle it depends on is deleted here.
- **`dat-parity-gate-is-a-skip.md`** — "DAT parity gate skips; the two platforms
  do not write identical bytes." Folded via D-04: the DAT-02 `-rewrite` byte gate
  closes as won't-verify alongside PICK-03; documented as a limitation.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase requirements & scope
- `.planning/REQUIREMENTS.md` §"Shell and Retirement" — UI-01, UI-02, UI-03
  definitions (and CMP-01 retirement wording).
- `.planning/ROADMAP.md` §"Phase 6: Shell and Native Retirement" + §"What
  Disappears at Phase 6" / §"What Survives Untouched" — the authoritative list of
  what is removed vs preserved.

### Architecture (binding)
- `.planning/research/REFERENCE-ARCHITECTURE.md` — server-owns-state, browser is a
  pure view/input layer, assets vendored offline, URL printed not auto-opened.
  Governs how the new browser shell and the file picker (D-03) are built.

### Gate closure evidence
- `.planning/phases/05-full-digitizing-and-data-parity/05-WINDOWS-REVIEW.md` —
  the exact deferred Windows reviewer steps for PICK-03/DAT-02; cite when
  documenting the D-04 won't-verify closure.
- `.planning/todos/pending/pick03-windows-parity-capture-owed.md` — retired by D-04.
- `.planning/todos/pending/dat-parity-gate-is-a-skip.md` — retired by D-04.

### Migration
- `NEWS.md` — where the D-05/D-06/D-07 migration note ships.
- `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/DESCRIPTION` —
  `Imports`/`Suggests`/`Version` edited by D-01, D-05.

</canonical_refs>

<code_context>
## Existing Code Insights

Package root: `integrated-guimorph-development_EOC/Project/GUImorphDevelopment/`.

### Reusable Assets
- `R/view3d.R` (679 lines): already carries a HUD + mode-toolbar + keyboard
  shortcuts from Phase 5. This is the foundation the browser shell grows from —
  the tabs/menu/status bar attach here, not to a fresh page.
- `R/transport.R` (861 lines): the mixed `httpuv` app with per-route
  `excludeStaticPath` + one `call` handler and server-owned `.gmw_session`. New
  shell routes (tab state, file listing/open, dialog actions) follow the same
  per-route pattern; the file-open picker (D-03) is served here.
- `.gmw_session` server-owned state model + `/save` (path chosen R-side) — the
  contract the browser shell reads/writes through.

### Established Patterns
- Server-owns-state; browser never writes files directly; R chooses all paths.
- Per-route `excludeStaticPath` entries + a single dispatch handler (Phase 5 A5).
- RE-SERVE mesh bytes on specimen switch (Phase 5 A4) — specimen nav in the new
  shell reuses this.
- Template HEAD stays under the 8192-byte R `sprintf` cap; parameter-free content
  goes in the BODY (Phase 4/5 view3d split).

### Integration Points (removal surface)
- `DESCRIPTION` `Imports`: remove `tcltk`, `tcltk2` (D-01) — leaving
  `geomorph`, `Rvcg`, `httpuv`; remove `rgl` from `Suggests`; bump `Version` to
  1.0.0.
- `NAMESPACE`: drop tcltk/rgl/engine imports and any exported engine accessors.
- `R/rtkogl.R` (944 lines): deleted (D-02).
- `R/transport.R` onLoad / `.gmw_engine` guard: engine load path removed (D-02).
- All `tk*` call sites — `tknotebook`/`ttknotebook`, `tkmenu`, `tkframe`,
  status-bar frame, `tkgetOpenFile`/`tkgetSaveFile`/`tkmessageBox`/`tk_chooseColor`
  across `R/3dDigitize.main.r` (3,586 lines), `.geomorph.r`, `.surface.r`,
  `.digitize.r` — reimplemented in the browser or removed.
- Sibling `integrated-guimorph-development_EOC/Project/tkogl2/` build tree:
  deleted (D-02).
- CMP-01 tests (e.g. `test-transport.R` engine-load assertions,
  `test-picking-parity.R`, `test-retina-picking-parity.R`, `test-dgt-cross-platform.R`
  `-rewrite` gate): retired/rewritten per D-02/D-04.

</code_context>

<specifics>
## Specific Ideas

- The browser shell is an *extension of the existing Phase 5 HUD/toolbar*, not a
  green-field UI — build the tabs/menu/status bar onto `view3d.R`'s current page.
- File opening should feel self-contained: user never leaves the browser to pick
  a file (D-03).

</specifics>

<deferred>
## Deferred Ideas

None raised — discussion stayed within phase scope. (Shell layout, dialog
styling, and shortcut/status-bar specifics were consciously left as builder's
discretion, not deferred to another phase.)

</deferred>

---

*Phase: 6-Shell and Native Retirement*
*Context gathered: 2026-08-13*
