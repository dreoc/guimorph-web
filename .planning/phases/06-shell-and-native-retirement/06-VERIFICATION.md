---
phase: 06-shell-and-native-retirement
verified: 2026-08-14T16:20:00Z
status: human_needed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Boot GUImorphWeb() in a browser and walk the reimplemented shell: five tabs (digitize/anchor/surface/curve/GPA), the File/Help menu bar, the status bar (specimen index + landmark/anchor/surface counts), the file-picker modal, the message-box modal, the color picker, and the save-name field."
    expected: "Every control behaves at feature parity with the retired Tk chrome — tabs gate correctly, specimen prev/next re-serves the mesh, the picker lists/opens .dgt/.ply, color/save-name round-trip through R. No native window, no Tk dialog."
    why_human: "grep confirms the shell markup, route wiring, and RE-SERVE path exist, but 'feature parity with the Tk chrome' is a live UX/visual judgment that cannot be verified statically."
---

# Phase 6: Shell and Native Retirement Verification Report

**Phase Goal:** Replace the Tk chrome, then remove the native engine and its entire build surface.
**Verified:** 2026-08-14T16:20:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth (ROADMAP success criterion) | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Tabs, dialogs, specimen navigation, and status bar reimplemented in the browser shell at parity with the Tk chrome (UI-01) | ✓ VERIFIED (structure) | `view3d.R`: `#menubar` (L633/676), tab strip/status bar/modal layer (L623 header, `#modal` + picker/message-box/save-name L655–726); `transport.R` server routes `/files /open /savepath /status /tabstate /msgack /color` (L471–567). Live visual *parity* routed to human verification. |
| 2 | The complete workflow runs with the native engine uninstalled and absent from the library path (UI-02) | ✓ VERIFIED | `R/rtkogl.R`, `inst/libs/`, and the `tkogl2/` tree are physically gone (disk + `git ls-files`=0). `GUImorphWeb()` (`shell.R` L33–44) boots `.gmw_serve_mesh()` with no `.gmw_require_engine`/`ui(e)`/`init(e)`. No `.gmw_engine`/`.onLoad`/engine-verb definition survives in `R/` (comments only). `test-engine-absent.R` + `test-shell-entry.R` workflow drives reported green. |
| 3 | `tkogl2` deleted from the package and `rgl` removed from dependencies entirely (UI-03); CMP-01 retired here | ✓ VERIFIED | `tkogl2/` build tree + `inst/libs/*` binaries deleted. `DESCRIPTION`: Version 1.0.0, Imports = geomorph/Rvcg/httpuv (no tcltk/tcltk2), Suggests = htmlwidgets/testthat (no rgl). `NAMESPACE`: 4 exports + import(Rvcg)/import(geomorph) only — no `import(tcltk)`/`export(loadDgt)`. No `rgl::`/`tcltk::` call site in `R/`. |
| 4 | A migration note ships in `NEWS.md` for native-path users, with a documented version to pin | ✓ VERIFIED | `NEWS.md`: `# GUImorphWeb 1.0.0`, breaking-change list, PRIMARY→`dreoc/GUImorph`, FALLBACK→pin `0.10.0` (`remotes::install_version(...,"0.10.0")`), D-04 PICK-03/DAT-02 won't-verify closure citing `05-WINDOWS-REVIEW.md`. |

**Score:** 4/4 truths verified (0 present, behavior-unverified). 1 human-verification item (live UI-01 feature parity).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `R/shell.R` | Rewired engine-free `GUImorphWeb` + relocated survivors | ✓ VERIFIED | `GUImorphWeb(dir, open, debug)` boots `.gmw_serve_mesh`; `dbg`/`.plot_show`/`.onAttach` survive here. |
| `R/view3d.R` | Tab strip / menu bar / status bar / modal + wiring | ✓ VERIFIED | Shell chrome + picker/message-box/color/save-name below the `MESH_URL` marker; `switchSpecimen`/`loadSpecimen` RE-SERVE preserved. |
| `R/transport.R` | 7 shell routes + `/gpa` options branch | ✓ VERIFIED | All routes present; `/open` membership-checked, `/savepath` rejects `/`,`\`,`..`. |
| `R/rtkogl.R` | Deleted | ✓ VERIFIED | Absent on disk. |
| `inst/libs/*`, `tkogl2/` tree | Deleted | ✓ VERIFIED | Absent on disk; 0 files tracked in git. |
| `DESCRIPTION` / `NAMESPACE` | Severed + regenerated | ✓ VERIFIED | tcltk/tcltk2/rgl gone; Version 1.0.0; NAMESPACE clean. |
| `NEWS.md` | Migration note | ✓ VERIFIED | Present with required content. |
| Source-scan / absent tests | Guard tests present | ✓ VERIFIED | `test-main-chrome-stripped.R`, `test-digitize-curve-stripped.R`, `test-surface-geomorph-stripped.R`, `test-engine-absent.R`, `test-deps-clean.R`, `test-news-migration.R`, `test-shell-entry.R` all present. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `GUImorphWeb()` | `.gmw_serve_mesh(dir=)` | boot seed | ✓ WIRED | `shell.R` L43. |
| `/open` body | filesystem | membership check then `file.path` | ✓ WIRED | Join only after `sel %in% entries` (`transport.R` L488–503). |
| GPA option flags | `compute()`/`.build_geomorph_data` | tclVar/tclvalue in-package shim | ✓ WIRED | Parity-pinned forwarding textually unchanged; shim defined `geomorph.r` L47–59. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| — | — | No `TBD`/`FIXME`/`XXX` in phase-modified R files; `tk*`/engine tokens appear only in explanatory comments and the internal `tclVar`/`tclvalue` shim | ℹ️ Info | None — no blocking debt markers. |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| UI-01 | 06-01, 06-02, 06-04, 06-05, 06-06 | Browser shell at Tk parity | ✓ SATISFIED (struct.) / ? human | Routes + shell chrome present; live parity → human. |
| UI-02 | 06-03, 06-04, 06-05, 06-06, 06-07 | Workflow runs engine-absent | ✓ SATISFIED | Engine physically gone; entry engine-free; workflow tests green. |
| UI-03 | 06-08 | Deps severed + NEWS migration note | ✓ SATISFIED | DESCRIPTION/NAMESPACE clean, NEWS.md shipped. |

All three declared requirement IDs (UI-01, UI-02, UI-03) are claimed by ≥1 PLAN frontmatter and satisfied in the codebase. No orphaned IDs for Phase 6.

### Human Verification Required

1. **Live browser shell feature-parity walkthrough** — Boot `GUImorphWeb()` and exercise the five tabs, File/Help menu, status bar, file-picker/message-box/color/save-name modals, and specimen prev/next.
   - Expected: behaves at feature parity with the retired Tk chrome; no native window or Tk dialog appears.
   - Why human: markup/wiring is statically confirmed, but "feature parity" is a live UX judgment.

### Gaps Summary

No gaps. Every physically checkable truth is confirmed against the codebase: the native engine (`rtkogl.R`, `inst/libs/*` binaries, and the sibling `tkogl2/` build tree) is deleted; no `tk*`/`tcltk`/`tcltk2`/`rgl`/engine-verb call site survives in `R/` (only explanatory comments and the in-package `tclVar`/`tclvalue` compat shim); `DESCRIPTION` is 1.0.0 with tcltk/tcltk2/rgl removed; `NAMESPACE` is clean; and `NEWS.md` ships the migration note with a pinnable `0.10.0`. Test execution could not be re-run in this environment (`Rscript` absent, documented `renv` hang), so the reported green suite (675 pass / 6 documented skips) is taken as the orchestrator-provided behavioral evidence. The single outstanding item is a live UI-01 feature-parity confirmation, which is inherently human.

---

_Verified: 2026-08-14T16:20:00Z_
_Verifier: Claude (gsd-verifier)_
