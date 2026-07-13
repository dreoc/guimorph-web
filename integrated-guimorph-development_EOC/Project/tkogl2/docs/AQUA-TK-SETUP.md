# Aqua Tk Setup (macOS)

This document defines the reproducible macOS setup for GUImorph's Aqua Tk gate.

## Distribution Decision

- **Selected option:** `d01-bundled`
- **Rationale (spike-grounded):** Plan 02 recorded that package-local Aqua binding is currently infeasible in the tested host due mixed Tk runtime collisions, but this plan intentionally locks the bundled path as the shipped target because it remains the lowest-friction researcher experience. Treat this as the target contract and carry the sign/notarize + universal2 hardening into Phase 4 (`BLD-03`).

## What Ships

- Shipped Tcl/Tk flavor target: **Aqua (Cocoa) Tk**
- Distribution target: **bundled prebuilt Aqua Tcl/Tk framework**
- Verification artifact: committed `test/gate/gate_check.R`

## Required Base Toolchain

Run once on macOS:

```bash
xcode-select --install
brew install tcl-tk
brew install cmake
```

Use **command-line R only** for this flow. Do **not** use R.app (Aqua Tk gate is validated in terminal R).

## Reproducible Aqua Gate Procedure

From `integrated-guimorph-development_EOC/Project/tkogl2`:

1. Verify the Tcl/Tk runtime is Aqua and not X11-linked:

```bash
echo 'puts [tk windowingsystem]' | "$(brew --prefix tcl-tk)/bin/wish"
otool -L "$(brew --prefix tcl-tk)/lib/libtk8.6.dylib" | grep libX11
```

Expected behavior:
- `wish` prints `aqua`
- `grep libX11` prints nothing

2. Build the committed gate extension:

```bash
cmake -S test/gate -B build-gate
cmake --build build-gate
```

3. Run the automated Aqua gate check with command-line R:

```bash
Rscript test/gate/gate_check.R build-gate/gateext.dylib
```

Expected output:

```text
gate_check: PASS
```

## Verify Your Setup

Run the same committed automated proof command any time you need to validate the machine:

```bash
Rscript test/gate/gate_check.R build-gate/gateext.dylib
```

Pass criteria:
- `tk windowingsystem == aqua` inside `gate_check.R`
- Tcl `load` succeeds for `Gateext`
- `gate_winsys == aqua`

## Notes for Phase 4

Because `d01-bundled` is locked, Phase 4 (`BLD-03`) must include:
- signing/notarization treatment for the bundled frameworks and native artifacts
- universal2 compatibility validation
- clean-machine + quarantine survivability checks
