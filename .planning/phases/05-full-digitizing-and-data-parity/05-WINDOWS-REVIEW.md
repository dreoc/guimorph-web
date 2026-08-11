# Phase 5 — Windows Reviewer Guide (Items 5 & 6)

Two Phase 5 UAT items need a **Windows host with the built `tkogl2` engine**.
Everything else in Phase 5 is already approved. Please run both checks below and
report the results.

## Setup

Start R in the package root:

```
integrated-guimorph-development_EOC/Project/GUImorphDevelopment
```

```r
library(GUImorphWeb)
```

---

## Item 6 — CMP-01: native oracle loads at runtime (~2 min)

Right after `library(GUImorphWeb)`, check the engine status:

```r
GUImorphWeb:::.gmw_engine$ok     # expect: TRUE
GUImorphWeb:::.gmw_engine$msg    # expect: "" (empty string)
```

**PASS** = `ok` is `TRUE`. If it is `FALSE`, paste the `$msg` string.

---

## Item 5 — DAT-02: `-rewrite` byte gate + cross-open

The gate compares each authored `.dgt` against a **Windows re-save of itself**.
Two re-save fixtures don't exist yet — produce them, then run the gate.

Parity dir: `tests/fixtures/parity/`

| have (authored)                   | produce (re-save)                          |
|-----------------------------------|--------------------------------------------|
| `windows-authored-roundtrip.dgt`  | `windows-authored-roundtrip-rewrite.dgt`   |
| `mac-authored-roundtrip.dgt`      | `mac-authored-roundtrip-rewrite.dgt`       |

### 1. Produce the two re-saves (in the GUI)

```r
GUImorphWeb()
```

For **each** authored file, in the app:
1. Open it (File menu) — e.g. `tests/fixtures/parity/windows-authored-roundtrip.dgt`
2. Save it (File menu / Ctrl+S) to the matching `-rewrite` name in the **same** dir
   — e.g. `tests/fixtures/parity/windows-authored-roundtrip-rewrite.dgt`

Repeat for `mac-authored-roundtrip.dgt` → `mac-authored-roundtrip-rewrite.dgt`.

### 2. Run the byte gate

```r
devtools::test(filter = "dgt-cross-platform")
# fallback if devtools isn't installed:
# testthat::test_file("tests/testthat/test-dgt-cross-platform.R")
```

**PASS** = the *"DAT-03 bidirectional fixture gate is enforceable"* test passes
(authored bytes == re-saved bytes, both files). It **skips** until the two
`-rewrite` files exist; after step 1 it must **pass**.

### 3. Cross-open (reader accepts both dialects)

Open a GUImorphWeb-authored `.dgt` in the **native GUImorph** and confirm it
loads correctly (landmarks / curves / anchors intact).

---

## Report back

- **Item 6:** the value of `.gmw_engine$ok`.
- **Item 5:** the gate result (pass / skip / fail), commit the two `-rewrite`
  fixtures, and note whether the cross-open in step 3 worked.
