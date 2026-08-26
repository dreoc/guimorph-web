---
status: testing
phase: 06-shell-and-native-retirement
source: [06-VERIFICATION.md]
started: 2026-08-14T16:25:00Z
updated: 2026-08-14T16:25:00Z
---

## Current Test

number: 1
name: Live browser feature-parity walkthrough of the reimplemented shell
expected: |
  Every control behaves at feature parity with the retired Tk chrome — the five
  tabs (digitize/anchor/surface/curve/GPA) gate correctly, specimen prev/next
  re-serves the mesh, the file-picker modal lists and opens .dgt/.ply, the
  message-box and color picker and save-name field round-trip through R. No
  native window and no Tk dialog appears anywhere in the flow.
awaiting: user response

## Tests

### 1. Live browser feature-parity walkthrough of the reimplemented shell
expected: |
  Boot GUImorphWeb() and exercise the reimplemented shell: five tabs
  (digitize/anchor/surface/curve/GPA), the File/Help menu bar, the status bar
  (specimen index + landmark/anchor/surface counts), the file-picker modal, the
  message-box modal, the color picker, and the save-name field. Every control
  behaves at feature parity with the retired Tk chrome — tabs gate correctly,
  specimen prev/next re-serves the mesh, the picker lists/opens .dgt/.ply,
  color/save-name round-trip through R. No native window, no Tk dialog.
result: [pending]

## Summary

total: 1
passed: 0
issues: 0
pending: 1
skipped: 0
blocked: 0

## Gaps
