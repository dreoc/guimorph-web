# Milestones

## v1.0 — GUImorph Modernization

**Shipped:** 2026-06-23  
**Phases:** 9 (28 plans)  
**Requirements:** 22/22 validated  
**Tag:** `v1.0`

### Delivered

Restored GUImorph on Windows R 4.6+ with full digitize → analyze workflow and modular C/OpenGL engine rehabilitation (Option A).

### Key Accomplishments

1. **Runtime restored** — `tkogl2.dll` builds, deploys, and loads via `load_all` on Windows R
2. **Digitize workflow** — landmarks (double-click), curves, multi-specimen `.dgt` save/reload
3. **Analysis round-trip** — landmarks-only GPA (`gpagen`) + CSV on geomorph 4.x APIs
4. **Contributor onboarding** — `BUILD.md`, `renv.lock`, `deploy-dll.ps1` (MSVC-primary)
5. **C engine rehabilitation** — five `tcl_*` modules + unified `marker.c`; god file removed
6. **Regression validated** — Phase 9 Fixtures A+B full workflow UAT passed

### Archives

- [Roadmap](milestones/v1.0-ROADMAP.md)
- [Requirements](milestones/v1.0-REQUIREMENTS.md)
- [Audit](milestones/v1.0-MILESTONE-AUDIT.md)

### Known Deferred Items at Close

4 items acknowledged in STATE.md Deferred Items (see STATE.md)

### Timeline

2026-06-13 → 2026-06-22 (execution); archived 2026-06-23
