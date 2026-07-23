---
title: "DAT parity gate skips; the two platforms do not write identical bytes"
status: open
kind: defect
priority: high
blocks: [DAT-01, DAT-02]
phase: 5
discovered: 2026-07-23
discovered_during: repo inspection after the GUImorph split
owner: eoc
---

## What is wrong

`test-dgt-cross-platform.R::"DAT-03 bidirectional fixture gate is enforceable"`
looks for four files in `tests/fixtures/parity/` and calls `skip()` when any is
missing. Only `reference-export.csv` was ever committed, so the gate has never
run. It reports green as a skip.

GUImorph's REQUIREMENTS.md marks DAT-03 complete on the strength of that suite.

## What the evidence on disk actually shows

Two authored `.dgt` files were sitting untracked-by-tests at the repo root:
`testdgt_6_phase5test.DGT` (Windows) and `macos_dgt_byte_test.dgt` (macOS). Same
6-specimen session, 6140 lines each. They are **not** byte-identical.

**1. Line endings differ on every line.** The Windows file is CRLF, the macOS
file is LF, as committed. `.dgt_normalize_lines()` strips CR before comparing, so
the round-trip assertions never see this. `.byte_signature()` is a raw md5 and
would.

**2. Ten coordinate lines differ by exactly 1e-6.** That is one unit in the last
place of the six-decimal `formatC` output:

```
line 1032   mac: 4.432138 -38.764957 -14.300832
            win: 4.432137 -38.764957 -14.300832
line 1038   mac: -6.177391 -4.745280 -12.725644
            win: -6.177391 -4.745281 -12.725644
```

Maximum absolute difference across all differing lines: 1.0e-6. This is
float-to-decimal tie-breaking in the platform C library, not digitizing
variation. Human re-digitizing would differ in the first or second decimal
everywhere, not the sixth in ten places out of six thousand.

**3. The macOS fixture was being corrupted on checkout.** With
`core.autocrlf=true` on Windows, git rewrote the LF macOS file to CRLF in the
working tree. The evidence was mangled before any test could read it. Fixed by
`.gitattributes` marking `*.dgt` as `-text`.

## What this means for the requirements

"Byte-identical" is the wrong contract, and it is currently false between the two
native builds. Any requirement holding a third path (the browser) to
byte-identity with the native path inherits a standard the native paths do not
meet between themselves.

Pick one before Phase 5 plans:

- **(a) Make it true.** Round explicitly in R before formatting
  (`formatC(round(x, 6), format = "f", digits = 6)`) so R's rounding, not libc's,
  decides the last digit, and pin the line terminator in the writer. Then
  byte-identity is a real and testable contract.
- **(b) Change the contract.** Assert numeric agreement within 1e-6 after parsing,
  plus structural identity of the block layout. Weaker, but honest, and it does
  not make the writer's formatting a compatibility surface.

(a) is preferable. It keeps a byte-level gate, which is much harder to fool than
a tolerance comparison, and the fix is small and local to
`.dgt_write_matrix_block`.

## What is now in place

- `windows-authored-roundtrip.dgt` and `mac-authored-roundtrip.dgt` moved into
  `tests/fixtures/parity/` under the names the test expects
- `.gitattributes` protects their bytes across checkout on either platform

## What is still needed to un-skip the gate

Two `-rewrite` halves. The test asserts that opening an authored file and
re-saving it reproduces the original bytes:

```r
expect_identical(.byte_signature(windows_authored), .byte_signature(windows_rewritten))
expect_identical(.byte_signature(mac_authored),     .byte_signature(mac_rewritten))
```

Both can be produced on Windows alone. Austin's Mac is not required, because the
macOS-authored *file* already exists; only the re-save is needed.

1. Open `tests/fixtures/parity/windows-authored-roundtrip.dgt` in GUImorphWeb.
2. File > Save to DGT, as
   `tests/fixtures/parity/windows-authored-roundtrip-rewrite.dgt`.
3. Repeat with `mac-authored-roundtrip.dgt` >
   `mac-authored-roundtrip-rewrite.dgt`.
4. Run the suite. Commit the two new fixtures.

**Expect step 3 to fail on the first attempt.** Re-saving a LF file on Windows
will almost certainly emit CRLF, so the md5s will not match. That failure is the
finding, not a broken test. It is item (a) or (b) above, arriving as a red test
instead of a silent skip, which is the entire point of committing these fixtures.

## Related

Do not confuse this with the `folsom3d.dgt` fixture in `inst/extdata/`, which
backs a different test and is fine.
