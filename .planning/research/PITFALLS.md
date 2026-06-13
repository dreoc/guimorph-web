# Pitfalls Research: GUImorph Modernization

**Date:** 2026-06-13

## Domain-Specific Pitfalls

### 1. Refactoring C before GUI works

| | |
|---|---|
| **Warning signs** | Spending weeks splitting `tcl_if` while `tcl("load")` still fails |
| **Prevention** | Phases 1–6 must complete before Phase 7 C modularization |
| **Phase** | 7+ |

### 2. geomorph API migration without inventory

| | |
|---|---|
| **Warning signs** | Fixing errors one-at-a-time in `.geomorph.r` without knowing full call surface |
| **Prevention** | Phase 5 starts with grep inventory of all `geomorph::` / `Morpho::` calls |
| **Phase** | 5 |

**Known breaking changes (2020 → 4.1.0):**
- `advanced.procD.lm` → `procD.lm` + RRPP
- `procD.allometry` → `procD.lm` + `plotAllometry`
- `nested.update` → RRPP `anova`
- `trajectory.analysis` → RRPP package
- `plotTangentSpace` → `gm.prcomp` + separate plot functions
- `gpagen` default `ProcD=FALSE` (was different in older versions)

### 3. Dot/anchor dedup breaks subtle behavior differences

| | |
|---|---|
| **Warning signs** | Landmarks work but anchors fail (or vice versa) after unification |
| **Prevention** | Characterize behavioral diff before merge; add regression test with saved `.dgt` |
| **Phase** | 8 |

### 4. Tcl stub ABI fragility

| | |
|---|---|
| **Warning signs** | `loading tkogl2 failed` immediately on `tcl("load", ...)` |
| **Prevention** | Minimal load test before full GUI; validate `Tcl_InitStubs` return |
| **Phase** | 1 |

### 5. WSL UNC path I/O

| | |
|---|---|
| **Warning signs** | Slow `load_all`, intermittent file-not-found |
| **Prevention** | Copy repo to `C:\dev\GUImorph` if UNC fails |
| **Phase** | 2 |

### 6. Fixed-function GL on remote desktop

| | |
|---|---|
| **Warning signs** | GUI opens but 3D viewer is black |
| **Prevention** | Test on local Windows desktop with discrete GPU first |
| **Phase** | 3 |

### 7. GLUT DLL not on PATH

| | |
|---|---|
| **Warning signs** | Crash on first OpenGL call after successful Tcl load |
| **Prevention** | Copy `glut64.dll` beside `tkogl2.dll` in `inst/libs/x64/` |
| **Phase** | 1–2 |

### 8. C refactor changes DLL export surface

| | |
|---|---|
| **Warning signs** | R loads old DLL fine; new build fails `Tkogl2_Init` lookup |
| **Prevention** | Verify export after every C build; keep `Tkogl2_Init` symbol stable |
| **Phase** | 7–9 |

### 9. Scope creep toward Option B mid-milestone

| | |
|---|---|
| **Warning signs** | "Let's just use rgl" discussions during C rehab |
| **Prevention** | Option A locked in Key Decisions; cross-platform explicitly out of scope |
| **Phase** | All |

---
*Pitfalls research: 2026-06-13*
