---
phase: 09-c-engine-cleanup-validation
verified: 2026-06-22T22:00:00Z
status: passed
score: 12/12 must-haves verified
overrides_applied: 0
re_verification: false
---

# Phase 9: C Engine Cleanup & Validation Verification Report

**Phase Goal:** C engine cleanup & validation — numbered globals array-ified, debug cruft removed, full UAT passes  
**Verified:** 2026-06-22T22:00:00Z  
**Status:** passed  
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `GBL_PTR_MODEL` / `GBL_PTR_CONTEXT` / `GBL_PTR_CURVE` are fixed-capacity arrays with capacity `#define`s in `tcl_state.h` (CENG-03, D-01) | ✓ VERIFIED | `tcl_state.h:11-17` defines `GBL_MODEL_SLOTS 5`, `GBL_CONTEXT_SLOTS 5`, `GBL_CURVE_SLOTS 6`, `GBL_LANDMARK_SET_CAPACITY 25`, `GBL_CURVE_SET_CAPACITY 10`, `GBL_DELTAS_CAPACITY 1000`; `tcl_state.c:45-46,73` defines `GBL_PTR_MODEL[]`, `GBL_PTR_CONTEXT[]`, `GBL_PTR_CURVE[]` |
| 2 | No numbered `GBL_PTR_*_N` globals remain in phase-edited sources | ✓ VERIFIED | `rg 'GBL_PTR_[A-Z]+_[0-9]' tkogl2/src/` — zero matches |
| 3 | Pre-Phase-9 deployed DLL backed up for rollback (D-15) | ✓ VERIFIED | `inst/libs/x64/tkogl2.dll.pre-phase9.bak` exists on disk (binary; read tool confirms presence); referenced in `smoke-test-findings.md:628` and `BUILD.md:211-212` |
| 4 | Array wiring preserved — `snapshot()` reads `GBL_PTR_MODEL[0]`; curve cluster uses `GBL_PTR_CURVE[]` with D-02 bug comment | ✓ VERIFIED | `tcl_state.c:393` `simpleLogWriteModelToFile(GBL_PTR_MODEL[0])`; `tcl_dispatch.c:2099-2129` curve array assignments + D-02 preservation comment |
| 5 | Bare `printf` trace removed from loader / state / dispatch (`CODE_FOR_LIBRARY` path, D-04) | ✓ VERIFIED | `rg '^\s*printf\(' tkogl2/src/` — zero live matches; `tcl_dispatch.c` only has commented `//printf`; `tcl_state.c` `printf` confined to `#ifdef STAND_ALONE_TOOL` alloc wrappers (out of scope per 09-03/RESEARCH A4); loader uses `sprintf` + `simpleLog` (100 `simpleLog` calls in `ogl_model_ply_ZARF_9.c`) |
| 6 | `D`/`D1`/`D2`/`D3` debug macros removed from `def_ZARF_9.h`; no call sites remain | ✓ VERIFIED | No `#define D`/`D1`/`D2`/`D3` in `def_ZARF_9.h`; `rg '\bD\(|D1\(|D2\(|D3\(' tkogl2/src/` — zero matches |
| 7 | `MAKE_INERT` docs pruned; `if(0)` debug toggles removed (CENG-04) | ✓ VERIFIED | `RunTime_Defines_ZARF_9.h` retains `#define CODE_FOR_LIBRARY` only — no `MAKE_INERT`; `rg 'MAKE_INERT|if\s*\(\s*0\s*\)' tkogl2/src/` — zero matches |
| 8 | D-05 `.dgt` parse guards intact (`FLAG_READ_SURFACES` / `sscanf` path) | ✓ VERIFIED | `ogl_model_ply_ZARF_9.c:1051-1242` — `FLAG_READ_SURFACES` guard chain preserved |
| 9 | Dead debug-dump functions removed from `tcl_state.c` / `tcl_state.h` | ✓ VERIFIED | `rg 'showPoint|show_GBL_LANDMARK|ut_show_Model|showStatistics' tkogl2/src/` — zero matches; prototypes absent from `tcl_state.h` |
| 10 | `BUILD.md` reflects final module-layout table; god file not in CMake build (D-14) | ✓ VERIFIED | `BUILD.md:190-212` lists `tcl_init.c`, `tcl_dispatch.c`, `tcl_window.c`, `tcl_state.c`, `tcl_log.c`, `marker.c`, curve/ogl modules; `CMakeLists.txt` includes `tcl_dispatch.c`, `tcl_state.c`, `marker.c` — no `tcl_if_ZARF_9.c` |
| 11 | Fixture A full round-trip UAT passed — Phase 4-5 baseline parity (CENG-05, D-09) | ✓ VERIFIED | `smoke-test-findings.md:630-646` — all steps ✅; "user approved 2026-06-22"; `Surface=0` reload confirmed |
| 12 | Fixture B anchors + curves UAT passed — Phase 8 baseline parity (CENG-05, D-10) | ✓ VERIFIED | `smoke-test-findings.md:648-659` — all steps ✅; "user approved 2026-06-22" |

**Score:** 12/12 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `tkogl2/src/tcl_state.h` | Capacity `#define`s + array externs | ✓ VERIFIED | Substantive (96 lines); wired via `tcl_state.c` definitions |
| `tkogl2/src/tcl_state.c` | Array definitions + cleaned state | ✓ VERIFIED | `GBL_PTR_*[]` arrays at lines 45-46, 73; `COMPILE_INFORMATION` freshness banner |
| `tkogl2/src/tcl_dispatch.c` | Array-ified curve cluster, no trace printf | ✓ VERIFIED | `GBL_PTR_CURVE[]` wired; diagnostics via `simpleLog` |
| `tkogl2/src/def_ZARF_9.h` | D-macro defs removed; types frozen | ✓ VERIFIED | Only debug macros removed; `dot_t`/struct layout intact |
| `tkogl2/src/ogl_model_ply_ZARF_9.c` | Loader trace removed; TAG_* → `simpleLog` | ✓ VERIFIED | No live bare `printf`; D-05 guards present |
| `inst/libs/x64/tkogl2.dll.pre-phase9.bak` | D-15 rollback artifact | ✓ VERIFIED | Binary file present on disk |
| `inst/libs/x64/tkogl2.dll` | Deployed MSVC cleaned build | ✓ VERIFIED | Binary file present on disk |
| `.planning/smoke-test-findings.md` | Phase 9 UAT section | ✓ VERIFIED | Lines 623-668 — both fixtures documented |
| `BUILD.md` | Final module-layout table | ✓ VERIFIED | Section "C source layout (Phase 9)" with 10-module table |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `tcl_state.c` `snapshot()` | `GBL_PTR_MODEL[0]` | `simpleLogWriteModelToFile` | ✓ WIRED | `tcl_state.c:393` |
| `tcl_dispatch.c` add("curve") | `GBL_PTR_CURVE[]` | curve-logging cluster | ✓ WIRED | `tcl_dispatch.c:2102-2129` |
| `ogl_loadDgtModel` TAG_* errors | `simpleLog()` | ported diagnostics | ✓ WIRED | `ogl_model_ply_ZARF_9.c` — `simpleLog` after `sprintf` |
| `ogl_loadDgtModel` SURF parse | `FLAG_READ_SURFACES` | preserved guards | ✓ WIRED | Lines 1166-1242 |
| Deployed `tkogl2.dll` | `tkogl2.dll.pre-phase9.bak` | documented rollback | ✓ WIRED | `BUILD.md:211-212`, `smoke-test-findings.md:628` |
| `tcl_init.c` | Tcl runtime | `Tkogl2_Init` export | ✓ WIRED | `tcl_init.c:14` `int DLLEXPORT Tkogl2_Init(...)`; in `CMakeLists.txt` source list |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `tcl_state.c` globals | `GBL_PTR_MODEL[]` | `get_curveAtIndex` / model load paths | Real model pointers from engine | ✓ FLOWING |
| `ogl_model_ply_ZARF_9.c` loader | `FLAG_READ_SURFACES` | `.dgt` TAG_SURF parse (`sscanf`) | Dynamic per file content | ✓ FLOWING |
| `tcl_dispatch.c` diagnostics | `buffer` | `sprintf` from live state (`models`, dots, curves) | Runtime coordinates/counts | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No numbered globals in src | `rg 'GBL_PTR_[A-Z]+_[0-9]' tkogl2/src/` | 0 matches | ✓ PASS |
| No live bare printf in src | `rg '^\s*printf\(' tkogl2/src/` | 0 matches | ✓ PASS |
| No D-macro call sites | `rg '\bD\(|D1\(|D2\(|D3\(' tkogl2/src/` | 0 matches | ✓ PASS |
| No if(0) toggles | `rg 'if\s*\(\s*0\s*\)' tkogl2/src/` | 0 matches | ✓ PASS |
| Rollback backup exists | Read `tkogl2.dll.pre-phase9.bak` | Binary file present | ✓ PASS |
| `Tkogl2_Init` in source | Grep `tcl_init.c` | `DLLEXPORT Tkogl2_Init` found | ✓ PASS |

**Note:** `dumpbin /exports` on deployed DLL not re-run in this verification session; export claim verified at source level only.

### Probe Execution

Step 7c: SKIPPED — no phase-declared probes or `scripts/*/tests/probe-*.sh` for Phase 9.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CENG-03 | 09-01 | Numbered globals → arrays; capacity documented | ✓ SATISFIED | `tcl_state.h` capacity `#define`s + `GBL_PTR_*[]` arrays |
| CENG-04 | 09-02, 09-03 | Debug cruft removed (`MAKE_INERT`, `if(0)`, `printf` tracing) | ✓ SATISFIED | No `MAKE_INERT`/`if(0)`/live bare `printf`; D macros removed; `simpleLog` sole channel |
| CENG-05 | 09-04 | Post-rehab DLL passes full digitize smoke test | ✓ SATISFIED | Both fixtures ✅ in `smoke-test-findings.md` Phase 9 section with user approval |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `def_ZARF_9.h` | 50 | `// TBD ??` on `model_t.count` | ℹ️ Info | Pre-existing struct comment in frozen layout (D-03); not introduced by Phase 9; phase only removed D-macro lines |

No `FIXME`/`XXX` markers in phase-modified files. No stub handlers or hollow props detected.

### Human Verification Required

None pending. Fixture A and Fixture B UAT were completed and recorded with user approval dates in `.planning/smoke-test-findings.md` (2026-06-22). Automated checks confirm code deliverables; GUI behavioral acceptance is documented in the audit trail.

### Gaps Summary

No gaps found. Phase 9 goal achieved:

- **CENG-03:** Three numbered pointer families replaced with documented fixed-capacity arrays in `tcl_state.h`/`tcl_state.c`; no `GBL_PTR_*_N` remnants.
- **CENG-04:** Debug facility removed — `MAKE_INERT` pruned, `if(0)` blocks deleted, bare `printf` trace eliminated from `CODE_FOR_LIBRARY` paths, `D/D1/D2/D3` macros removed from `def_ZARF_9.h` with types byte-unchanged; `simpleLog` is the surviving diagnostic channel.
- **CENG-05:** Both UAT fixtures passed per `smoke-test-findings.md`; `BUILD.md` module table updated; rollback backup `tkogl2.dll.pre-phase9.bak` on disk.

---

_Verified: 2026-06-22T22:00:00Z_  
_Verifier: Claude (gsd-verifier)_
