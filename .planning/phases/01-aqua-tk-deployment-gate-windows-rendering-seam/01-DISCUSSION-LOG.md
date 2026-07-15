# Phase 1: Aqua-Tk Deployment Gate + Windows Rendering Seam - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-12
**Phase:** 1-Aqua-Tk Deployment Gate + Windows Rendering Seam
**Areas discussed:** Aqua-Tk distribution, Gate proof artifact, Seam API shape, Windows regression rigor

---

## Aqua-Tk Distribution (GATE-02)

| Option | Description | Selected |
|--------|-------------|----------|
| Homebrew tcl-tk | Cocoa/Aqua build + document how R's tcltk points at it — reproducible, no vendoring | |
| Bundle framework | Ship a prebuilt Aqua Tcl/Tk framework inside the package — zero researcher setup, heavier to build/sign/maintain | ✓ |
| Don't lock (spike) | Let the planning research spike pick among brew/bundle/ActiveTcl | |

**User's choice:** Bundle a prebuilt Aqua Tcl/Tk framework.
**Notes:** Goal is zero manual Tcl/Tk setup for researchers. Bundling mechanics + feasibility vs CRAN R's default X11 Tk still go through a planning research spike; Homebrew-Aqua path retained as fallback. Bundling adds sign/notarize + universal2 weight (ties into Phase 4 BLD-03).

**Pre-discussion clarification:** User asked why Aqua Tk is considered and whether it regresses Windows. Established: X11/XQuartz GLX is broken on current macOS, so only Aqua (Cocoa) Tk exposes an `NSView` for NSOpenGL embedding; Aqua is macOS-only and the seam is compile-time split, so the Windows WGL path is untouched.

---

## Gate Proof Artifact (GATE-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Commit smoke test | Throwaway trivial Aqua-Tk C extension committed as a repeatable smoke test / load-path regression guard | ✓ |
| Manual only | Verify manually once + document steps, nothing committed | |

**User's choice:** Commit a throwaway trivial Aqua-Tk C extension as a repeatable smoke test.
**Notes:** Doubles as a regression guard for the `.onLoad`/`tcl("load", ...)` path.

---

## Seam API Shape (RND-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Exact 5 | create / make_current / swap / resize / destroy — matches roadmap | ✓ |
| Add extras | Also query drawable size + explicit present/clear now | |

**User's choice:** Exact 5 functions.
**Notes:** Add extras only when the macOS backend (Phase 4) actually needs them.

---

## Windows Regression Rigor (CMP-01)

| Option | Description | Selected |
|--------|-------------|----------|
| Eyeball | Build + load + manual eyeball render of a known PLY | ✓ |
| Pixel compare | Screenshot / pixel-compare against a baseline image | |

**User's choice:** Build + load + manual eyeball render of a known PLY.
**Notes:** No baseline capture/compare infra this phase; MSVC build only (MinGW renders blank).

---

## Claude's Discretion

- Seam file naming/layout beyond `gfx_backend.h` + `gfx_backend_wgl.c`.
- Which PLY fixture serves as the regression mesh.
- Form/location of the GATE-02 setup doc and the trivial-extension test directory.

## Deferred Ideas

- Homebrew tcl-tk + R-reconfigure path — documented fallback if bundling spike shows infeasibility.
- Screenshot/pixel-compare regression baseline — revisit if eyeball checks prove insufficient.
- Seam extras (drawable-size query, present/clear) — add when Phase 4 needs them.
