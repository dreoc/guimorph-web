---
phase: 06-rgl-result-plot-fallback-on-macos
verified: 2026-07-20T15:45:00Z
status: passed
score: 8/8 must-haves verified
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "On Windows, all three result plots render unchanged (interactive rgl window for the two 3-D plots; base-graphics window for PCA) — CMP-01."
    reason: "Phase 6 is R-only; the Windows branches of .rgl_show() (rgl.bringtotop(stay = TRUE)) and .plot_show() (dev.new() + draw()) are byte-identical to the pre-phase path, and options(rgl.useNULL = TRUE) is set ONLY under .isMacOS(). No Windows-observable behavior changed in source. Live off-box Windows confirmation is delegated to a Windows maintainer per the established D-16 recurring pattern (same disposition as Phase 5 DAT-03) and is tracked in .planning/todos/pending/cmp-01-phase6-windows-plots.md. Owner accepted closure on the off-box leg at milestone closeout."
    accepted_by: "project owner"
    accepted_at: "2026-07-20T00:00:00Z"
deferred: []
human_verification: []
---

# Phase 6: rgl Result-Plot Fallback on macOS — Verification Report

**Phase Goal:** Make GPA/PCA/mean-shape result plots render on macOS via an rgl NULL/`rglwidget` fallback, since interactive XQuartz rgl is broken on current macOS.
**Verified:** 2026-07-20T15:45:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| #   | Truth | Status | Evidence |
| --- | ----- | ------ | -------- |
| 1 | On macOS, Plot Aligned Specimens renders a WebGL widget in the browser (NULL device → rglwidget), no OpenGL failure, no crash. | ✓ VERIFIED | `plotspecs` (`3dDigitize.geomorph.r:388-392`) builds the scene then calls `.rgl_show()`; macOS branch (`rtkogl.R:841-852`) = `rglwidget()` → `saveWidget(selfcontained = FALSE)` → `browseURL()` → `close3d()`. Live macOS render owner-approved 2026-07-20 (06-02 coverage D1). |
| 2 | On macOS, Plot Mean Shape renders a WebGL widget in the browser. | ✓ VERIFIED | `plotMeanShape` (`3dDigitize.geomorph.r:480-484`) → `.rgl_show()` (same macOS widget path). Live render owner-approved 2026-07-20 (D2). |
| 3 | On macOS, PCA (morphospace) renders and can be dismissed without the quartz close crash. | ✓ VERIFIED | `plotPCA` (`3dDigitize.geomorph.r:395-456`) routes through `.plot_show(draw)`; macOS branch (`rtkogl.R:868-873`) = temp `png()` → `browseURL()` (no in-process AppKit window). Crash (`EXC_BAD_ACCESS` on quartz close) found during verify and fixed in `488a626`; re-verified live, owner-approved (D3). The macOS PNG+browser branch is exercised by a passing test on this Darwin host. |
| 4 | `options(rgl.useNULL = TRUE)` is `.isMacOS()`-guarded and set before any `open3d()`. | ✓ VERIFIED | `rtkogl.R:404` — `if (.isMacOS()) options(rgl.useNULL = TRUE)` inside `GUImorph()`, before `ui(e)`. Audit test asserts guard + startup placement (passing). |
| 5 | Neither 3-D plot function calls `select3d`, `rgl.snapshot`, or `snapshot3d` (ANL-02 criterion 2). | ✓ VERIFIED | Source grep: 0 hits in `3dDigitize.geomorph.r`. Audit test "3-D plot file uses no interactive-selection / snapshot rgl calls (ANL-02)" passing. |
| 6 | Windows interactive path is byte-identical in source (`.rgl_show()` else = `rgl.bringtotop(stay = TRUE)`; `.plot_show()` else = `dev.new()` + `draw()`; `rgl.useNULL` macOS-only). | ✓ VERIFIED | `rtkogl.R:854` (rgl else), `875-876` (plot else), `404` (macOS-only guard). No Windows-observable source change. |
| 7 | `plotPCA` stays base-graphics — no `rgl::` calls. | ✓ VERIFIED | Source grep: 0 `rgl::` in `plotPCA` body. Test "plotPCA stays base-graphics" passing. |
| 8 | Engine viewport still renders/picks after plotting (129b42a per-frame make-current holds with rgl in-process). | ✓ VERIFIED | Live macOS session 2026-07-20: canvas survived post-plot interaction, owner-approved (D4). |

**Score:** 8/8 truths verified (0 present, behavior-unverified; 1 owner-accepted override applied for the CMP-01 off-box leg).

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `R/rtkogl.R` | `.rgl_show()` + `.plot_show()` helpers + guarded `rgl.useNULL` startup | ✓ VERIFIED | `.rgl_show` (840-856), `.plot_show` (867-878), startup guard (404). Both helpers substantive and platform-branched. |
| `R/3dDigitize.geomorph.r` | `plotspecs`/`plotMeanShape` → `.rgl_show()`; `plotPCA` → `.plot_show()` | ✓ VERIFIED | Wired at 392, 484, 455. No stray `rgl.bringtotop`/`dev.new` in plot bodies. |
| `DESCRIPTION` | `htmlwidgets` in `Imports:` | ✓ VERIFIED | Present at Imports line 11. |
| `tests/testthat/test-rgl-fallback-macos.R` | source-scan audit + headless smoke + `.plot_show` macOS branch | ✓ VERIFIED | 9 `test_that` blocks; all assertions pass. |

### Key Link Verification

| From | To | Via | Status |
| ---- | -- | --- | ------ |
| `plotspecs` / `plotMeanShape` | `.rgl_show()` | trailing call replacing `rgl.bringtotop` | ✓ WIRED |
| `plotPCA` | `.plot_show(draw)` | closure passed to platform helper | ✓ WIRED |
| `GUImorph()` startup | `options(rgl.useNULL=TRUE)` | `.isMacOS()` guard before `ui(e)` | ✓ WIRED |
| `.rgl_show()` macOS | browser | `rglwidget → saveWidget(selfcontained=FALSE) → browseURL → close3d` | ✓ WIRED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Full phase test file | `R_LIBS_USER=.r-lib R -e "testthat::test_file('.../test-rgl-fallback-macos.R', reporter='summary')"` | 28 assertions, 0 failures/errors | ✓ PASS |
| `.plot_show()` macOS PNG+browser branch (crash-fix path) | (covered by the run above, executes live on this Darwin host) | writes non-empty `.png`, opens via captured browser, no native window | ✓ PASS |
| NULL-mode `rglwidget → saveWidget` smoke | (covered by the run above) | non-empty `.html` written | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| ANL-02 | 06-01, 06-02 | Result visualization on macOS via rgl fallback | ✓ SATISFIED | Fallback implemented, wired, audit test green, all three plots live-verified on macOS (D1-D4). |
| CMP-01 | 06-02 | Windows build still works (result plots unchanged) | ⚠ OWNER-ACCEPTED (off-box) | Windows branches byte-identical in source (T6); live off-box confirmation pending maintainer, owner-accepted at closeout. Tracked in `.planning/todos/pending/cmp-01-phase6-windows-plots.md`. |

### Anti-Patterns Found

None. No `TODO`/`FIXME`/`XXX`/`HACK`/`PLACEHOLDER` or stub patterns in the modified R files. Comments present are explanatory (rationale for `selfcontained = FALSE`, the quartz-close crash cause), not debt markers.

### Human Verification Required

None outstanding. The three live macOS render confirmations and the engine-viewport-survival check were completed and owner-approved on 2026-07-20 (06-02 D1-D4). The only remaining real-world action is the off-box Windows CMP-01 render, which the owner has explicitly accepted as closed-pending under the established off-box maintainer pattern (recorded as an override above and tracked as a pending todo).

### Gaps Summary

No blocking gaps. The phase goal — macOS result-plot rendering via an rgl NULL/`rglwidget` fallback (ANL-02) — is fully implemented in the codebase, unit-audited, and confirmed live on macOS for all three result plots (aligned specimens + mean shape as WebGL widgets; PCA as a browser PNG after the `488a626` close-crash fix). The ROADMAP's literal "PCA via `rglwidget` / `rgl.printRglwidget = TRUE`" wording is an intentional, documented divergence: PCA is base-graphics via a temp-PNG+browser path (not a WebGL widget) and autoprint is a no-op inside a Tk callback, so the explicit `saveWidget`+`browseURL` mechanism is used instead — both changes are correct and better serve the goal. The sole outstanding item is the recurring CMP-01 "Windows still works" checkpoint, which is off-box (no Windows host available), byte-identical in source, and owner-accepted for closure.

---

_Verified: 2026-07-20T15:45:00Z_
_Verifier: Claude (gsd-verifier)_
