# Backlog: GPA plot window opens but nothing rendered

**Captured:** 2026-06-19  
**Phase:** 999.1  
**Origin:** Phase 5 GPA UAT (`05-02`)

## Report

- Compute succeeds (`gpagen` on 3 LM × 2 specimens from `test_fresh.dgt`)
- Save CSV works (`gpa_test.csv` non-empty)
- Plot Aligned Specimens opens an rgl window but **nothing is rendered** (empty canvas)

## Likely areas

- `3dDigitize.geomorph.r` — `plotspecs()`, `plotAllSpecimens`, `plot_param`
- rgl + Tcl/Tk co-existence on Windows R
- geomorph 4.x 3D plotting backend vs legacy `plot3d` expectations

## Not in scope until promoted

Fix is deferred from Phase 5 closure (ANAL-01 satisfied by Compute + export).
