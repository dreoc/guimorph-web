# Features Research: GUImorph Modernization

**Date:** 2026-06-13

## Table Stakes (must have — users leave without these)

| Feature | Complexity | Notes |
|---------|------------|-------|
| Native DLL loads in Windows R | Medium | `Tkogl2_Init` + Tcl stubs |
| GUI opens ("3D GUImorph") | Low | Tk window from `GUImorph()` |
| Load PLY specimen mesh | Medium | `ogl_model_ply_*` pipeline |
| 3D mesh rendering | High | WGL + fixed-function GL — fragile on RDP/VM |
| Place landmarks (dots) | Medium | String dispatch `"dot"` |
| Place anchors | Medium | Duplicated dot implementation |
| Define curves (semi-landmarks) | High | Spline logic in `curve_*` |
| Save/load `.dgt` files | Medium | R-side data + C `loadDgt` |
| Run geomorph analysis on export | Medium–High | API migration required |
| Reproducible dev environment | Low | renv + BUILD.md |

## Differentiators (competitive but not v1 blockers)

| Feature | Complexity | Defer to |
|---------|------------|----------|
| Cross-platform (Linux/macOS) | Very High | Requires Option B/C, not Option A |
| Modern OpenGL / shader pipeline | Very High | Out of scope for rehabilitation |
| Automated test suite | Medium | Phase 10+ |
| CI for MinGW builds | Medium | Phase 10+ |
| Tcl/Tk 9.0 support | High | Post-milestone evaluation |

## Anti-Features (deliberately NOT building)

| Feature | Reason |
|---------|--------|
| rgl renderer swap | User chose Option A — keep custom C engine |
| Shiny/WebGL rebuild | Option C rejected for this milestone |
| Full geomorph gmShiny parity | GUImorph is a specialized digitizer, not a general gmShiny clone |
| Rewrite stringly-typed R↔C protocol to typed API | Too risky for rehabilitation; keep protocol stable |

## C Engine Rehabilitation Features (Option A — in scope)

| Feature | Complexity | Dependency |
|---------|------------|------------|
| Split `tcl_if_ZARF_9.c` into modules | High | GUI must work first (Phases 1–6) |
| Unify dot/anchor implementations | Medium | Split or parallel with modularization |
| Replace numbered globals with arrays | Medium | Document capacity limits explicitly |
| Remove debug cruft (`MAKE_INERT`, `if(0)`) | Low | After modularization |
| Safe macro → function conversion | Low | `ANGLE_REDUCE`, `FREE`/`D`/`D1` |

## Feature Dependencies

```
BUILD/RUN (Phase 1)
  └─► PKG/GUI launch (Phase 2)
        └─► PLY render (Phase 3)
              └─► Digitize (Phase 4)
                    └─► geomorph analyze (Phase 5)
                          └─► renv/docs (Phase 6)
                                └─► C modularize (Phase 7)
                                      └─► C dedup (Phase 8)
                                            └─► C cleanup (Phase 9)
```

---
*Features research: 2026-06-13*
