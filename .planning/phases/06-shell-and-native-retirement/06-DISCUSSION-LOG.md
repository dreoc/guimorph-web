# Phase 6: Shell and Native Retirement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-13
**Phase:** 6-Shell and Native Retirement
**Areas discussed:** Retirement scope, Migration note

---

## Gray-area selection

Presented five candidate gray areas: shell layout & fidelity, file & message
dialogs, retirement scope, migration note, shortcuts & status-bar content.

**User selected:** Retirement scope, Migration note.
Left as builder's discretion: shell layout, dialog styling, shortcuts/status-bar.

---

## Retirement Scope — toolkit severance

| Option | Description | Selected |
|--------|-------------|----------|
| Full severance | Drop tcltk AND tcltk2 from Imports too; no Tk window; everything browser-rendered | ✓ |
| Keep tcltk shim | Remove chrome but retain tcltk for native file pickers | |
| Literal UI-03 only | Delete tkogl2 + rgl but leave Tk chrome/tcltk as-is | |

**User's choice:** Full severance.
**Notes:** Cleanest end state; matches "no external application" positioning and
makes UI-01 real. Forces browser reimplementation of file-open/save + message
dialogs.

## Retirement Scope — engine deletion boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Binding + build surface | Delete R/rtkogl.R, engine load in transport.R/onLoad, sibling tkogl2/ tree; retire CMP-01 tests | ✓ |
| Binding only | Delete R/rtkogl.R + load path but keep tkogl2/ archived in-tree | |
| You decide | Pick a boundary that satisfies "absent from library path" | |

**User's choice:** Binding + build surface (full removal, nothing archived in-tree).

## Retirement Scope — file-open mechanism (after tcltk removal)

| Option | Description | Selected |
|--------|-------------|----------|
| Browser-served picker | R serves a directory listing over httpuv; user selects in the browser; R opens the path | ✓ |
| R-side file.choose() | Trigger R's built-in native chooser (no tcltk) | |
| You decide | Pick the most reliable offline cross-platform selection | |

**User's choice:** Browser-served file picker.
**Notes:** Fully self-contained, no native toolkit, consistent with
server-owns-state and the Phase 5 "R owns the path" rule.

## Retirement Scope — PICK-03 / DAT-02 gate fate

| Option | Description | Selected |
|--------|-------------|----------|
| Capture-before-delete | Sequence a Windows PICK-03/DAT-02 capture before deleting the engine | |
| Close as won't-verify | Accept gates unverified, document limitation, delete, retire todos | ✓ |
| You decide | Choose based on Windows-host availability | |

**User's choice:** Close as won't-verify.
**Notes:** No Windows tkogl2 host available across Phases 4–6; harness was
drop-in-ready, so the gap is host availability, not code. Retires the two pending
todos.

---

## Migration Note — version bump

| Option | Description | Selected |
|--------|-------------|----------|
| 1.0.0 | Signals completed browser migration; native removal is the natural 1.0 line | ✓ |
| 0.11.0 | Stay in 0.x, treat as one more minor step | |
| You decide | Pick the version reflecting a completed migration | |

**User's choice:** 1.0.0. Pin target for native users = 0.10.0 (last
engine-bundling version).

## Migration Note — destination for native-path users

| Option | Description | Selected |
|--------|-------------|----------|
| GUImorph repo + pin fallback | Primary: GUImorph (dreoc/GUImorph, upstream). Fallback: pin GUImorphWeb 0.10.0 | ✓ |
| Pin only | Just tell them to pin 0.10.0 | |
| GUImorph only | Direct all native users to GUImorph, no pin fallback | |

**User's choice:** GUImorph repo + pin fallback.

---

## Claude's Discretion

- Shell layout & fidelity (faithful Tk mirror vs browser-native redesign).
- Dialog/menu/message-box styling.
- Which keyboard shortcuts and status-bar readouts carry over (parity preserved,
  exact set builder's discretion).

## Deferred Ideas

None — discussion stayed within phase scope.
