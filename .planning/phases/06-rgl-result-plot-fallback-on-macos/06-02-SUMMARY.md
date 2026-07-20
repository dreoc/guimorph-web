---
phase: 06-rgl-result-plot-fallback-on-macos
plan: 02
subsystem: testing
tags: [rgl, rglwidget, macos, quartz, verification, anl-02, cmp-01]
requires:
  - phase: 06-01
    provides: .rgl_show()/.plot_show() platform-guarded result-plot display + macOS rgl.useNULL startup
provides:
  - Live macOS confirmation that all three result plots render (aligned specimens + mean shape as WebGL widgets, PCA as browser PNG) with no segfault.
  - Gap-closure fix for a PCA close crash discovered during verification (routed PCA off the native quartz window).
affects: [milestone-closeout]
tech-stack:
  added: []
  patterns: [browser-artifact display for all macOS result plots (no in-process AppKit window)]
key-files:
  created: []
  modified: []
key-decisions:
  - "PCA on macOS renders as a static browser PNG (consistent with the rgl widgets); interactive/zoomable PCA is a possible future htmlwidget follow-up, out of Phase 6 parity scope."
  - "Windows CMP-01 recorded as owner-accepted pending off-box maintainer confirmation (Phase 6 is R-only; Windows branches are byte-identical)."
requirements-completed: [ANL-02, CMP-01]
coverage:
  - id: D1
    description: "On macOS, Plot Aligned Specimens renders an interactive WebGL widget in the browser (no crash, no 'no OpenGL functions')."
    requirement: ANL-02
    verification:
      - kind: manual_procedural
        ref: "Live macOS session 2026-07-20: widget opened in browser, rotate/zoom confirmed (user-approved)"
        status: pass
    human_judgment: true
    rationale: "WebGL widget render/rotate has no headless oracle; confirmed live by the project owner."
  - id: D2
    description: "On macOS, Plot Mean Shape renders an interactive WebGL widget in the browser."
    requirement: ANL-02
    verification:
      - kind: manual_procedural
        ref: "Live macOS session 2026-07-20: mesh + red mean landmarks widget opened, rotate confirmed (user-approved)"
        status: pass
    human_judgment: true
    rationale: "Same as D1 — live-only oracle."
  - id: D3
    description: "On macOS, PCA (morphospace) renders without crashing (browser PNG) and can be dismissed without the quartz close crash."
    requirement: ANL-02
    verification:
      - kind: manual_procedural
        ref: "Live macOS session 2026-07-20 after fix 488a626: PCA opens as browser PNG, no EXC_BAD_ACCESS on close (user-approved)"
        status: pass
    human_judgment: true
    rationale: "The original crash was on window close; the fix removes the native window. Confirmed live by the owner."
  - id: D4
    description: "Engine viewport still renders/picks after plotting (129b42a per-frame make-current holds with rgl in-process)."
    requirement: ANL-02
    verification:
      - kind: manual_procedural
        ref: "Live macOS session 2026-07-20: canvas survived post-plot interaction (user-approved)"
        status: pass
    human_judgment: true
    rationale: "Cross-subsystem live behavior; no headless oracle."
  - id: D5
    description: "Windows result plots render unchanged (native interactive rgl windows + base-graphics PCA)."
    requirement: CMP-01
    verification:
      - kind: manual_procedural
        ref: "Off-box Windows maintainer confirmation — PENDING (owner-accepted at closeout; Phase 6 is R-only, Windows branches byte-identical)"
        status: unknown
    human_judgment: true
    rationale: "Off-box Windows host; delegated to the maintainer (D-16 recurring pattern). Tracked in .planning/todos/pending/cmp-01-phase6-windows-plots.md."
duration: n/a (verification plan; live checkpoints 2026-07-20)
completed: 2026-07-20
status: complete
---

# Phase 06 Plan 02: macOS Result-Plot Live Verification Summary

**All three result plots confirmed rendering on macOS with no segfault — a PCA window-close crash surfaced during verification and was fixed by routing PCA off the native quartz window.**

## Accomplishments
- **Checkpoint 1 (ANL-02) — APPROVED live on macOS 2026-07-20:** Plot Aligned Specimens and Plot Mean Shape open as interactive WebGL widgets in the browser; PCA opens as a browser PNG; the engine viewport survives post-plot interaction.
- **Gap found + fixed during verification:** closing the PCA plot crashed R with `EXC_BAD_ACCESS` — the native quartz (Cocoa) window's close animation over-released a Core Animation object on Tk's Aqua run loop (crash stack pure AppKit/QuartzCore, no GUImorph frames). Fixed in `488a626` by adding `.plot_show()` (macOS: temp PNG + `browseURL`, no in-process AppKit window; Windows: unchanged `dev.new()`), then re-verified and approved.
- **Checkpoint 2 (CMP-01) — owner-accepted, off-box confirmation pending:** Phase 6 is R-only and the Windows branches of `.rgl_show()`/`.plot_show()` are byte-identical (`rgl.bringtotop`/`dev.new`, `rgl.useNULL` only under `.isMacOS()`), so Windows behavior is unchanged in source. Live Windows confirmation is delegated to the maintainer and tracked as a pending todo.

## Task Commits
1. **Checkpoint 1: live macOS render** — human-verify (no code commit); surfaced the PCA crash.
2. **PCA close-crash gap fix** — `488a626` (fix): `.plot_show()` helper + `plotPCA` reroute + tests (28/0).
3. **Checkpoint 2: Windows regression** — human-verify, off-box (owner-accepted pending).

## Decisions Made
- PCA renders as a static browser PNG on macOS (consistent with the rgl widgets). Interactive/zoomable macOS PCA (e.g. plotly htmlwidget) is a possible future enhancement, out of Phase 6 parity scope.
- Windows CMP-01 recorded as owner-accepted pending off-box confirmation (same pattern as Phase 5 DAT-03 return leg).

## Deviations from Plan
- One gap-closure beyond the verification-only plan: the PCA close crash required a code fix (`488a626`) before Checkpoint 1 could pass. Scope-appropriate — it is one of the three result plots this phase is responsible for.

## Known Residuals (tracked, non-blocking)
- **CMP-01 Windows confirmation** — off-box, pending maintainer. Tracked in `.planning/todos/pending/cmp-01-phase6-windows-plots.md`.
- **Separate pre-existing native defect (out of Phase 6 scope):** `tkogl2.dylib simpleLogWriteModelToFile` `sprintf` buffer overflow (Jul 17 crash, `__chk_fail_overflow`). Filed for follow-up.

## Next Phase Readiness
- Phase 6 goal met: all three macOS result plots render via the fallback with no crash. This is the last milestone phase — ready for milestone closeout (open items: BLD-03 universal2/signing decision; the sprintf-overflow native defect).

## Self-Check: PASSED
- `.plot_show()` present in rtkogl.R; `plotPCA` routed through it; tests 28/0.
- Fix commit `488a626` on record.
