# Backlog: openDgt shows second specimen first on load

**Captured:** 2026-06-19  
**Phase:** 999.2  
**Origin:** Phase 5 GPA UAT (`05-02`)

## Report

- Load `test_fresh.dgt` (2 specimens: C13.1.ply, C8.1.ply)
- Viewer initially shows **specimen 2** despite `e$currImgId == 1`
- Workaround: Next → Previous to see specimen 1
- Not client-breaking but confusing UX

## Likely areas

- `3dDigitize.main.r` — `openDgt`, `drawElements`, `showPicture`, `set("specimen", "id", ...)`
- C layer retains last-loaded specimen as active display after multi-specimen load loop

## Attempted fix (insufficient)

Post-openDgt `e$currImgId <- 1` + `showPicture(e)` — user retest still shows specimen 2 first.
