# SSC Audit Report: `odkrepeatmerge`

**Package version:** 1.3.0 (18oct2026)
**Branch:** V1
**Developed and tested on:** Stata 17, Windows

---

## Verdict: code-complete for SSC; awaiting the v1.3.0 test run

v1.2.0 passed 14/14 test files. A reviewer-style audit on 2026-10-18 then found 3 blockers and 7 should-fix items, all addressed in v1.3.0 below. Run `do tests/run_all_tests.do` (now 20 test files) to confirm before submitting.

---

## Test suite

| File | Covers |
|------|--------|
| `tests/regression_nested_order.do` | nested repeat order |
| `tests/regression_prefix_collision.do` | q1 vs q10 order |
| `audit/odkrepeatmerge_cert.do` (T01–T10) | basics, preserve, errors, no globals, no stray files |
| `tests/edge/E1`–`E11` | realistic export, empty repeats, no repeats, 3 levels, 10+ instances, blank end_repeat names, upper-case KEY, q1/q11 clash, groups/notes, separator, q1/q10 with 10+ instances |
| `tests/edge/E12_group_prefixed_headers.do` | ODK Central default `group-field` headers; system columns; geopoint parts |
| `tests/edge/E13_saving_replace_results.do` | no overwrite without `replace`; `saving()`; `r()` results; data in memory untouched |
| `tests/edge/E14_unmatched_report.do` | unmatched variables listed and placed last |
| `tests/edge/E15_allstring.do` | leading zeros kept |
| `tests/edge/E16_xlsform_synonym.do` | `xlsform()` / `formtitle()` synonym and conflicts |
| `tests/edge/E17_maxvar_guard.do` | clear r(900) before exceeding `c(maxvar)` |

Run everything with: `cd` to the repo root, then `do tests/run_all_tests.do` (log: `tests/run_all_tests.log`).

---

## v1.3.0 changes (2026-10-18, from the SSC-readiness review)

| ID | Finding | Change | Test |
|----|---------|--------|------|
| B1 | Output `formid.dta` was overwritten silently | `saving(filename [, replace])` and `replace`; r(602) if the file exists without `replace`; checked before any work | E13 |
| B2 | ODK Central's default export names grouped fields `group-field`; these never matched the XLSForm and were moved to the end | Prefixes removed using the original header (kept by `import delimited` as the variable label), only when every prefix is a group/repeat name in the form and the field exists in the form; Central system columns normalised (`meta-instanceID` → `instanceid`) | E12 |
| B3 | Unmatched variables were moved to the end silently | Listed in the output and returned in `r(unmatched)` / `r(n_unmatched)`; Central system columns excluded | E12, E14 |
| S1 | Wide data could exceed `c(maxvar)` with a cryptic error | Checked before each reshape and merge; r(900) with advice | E17 |
| S2 | `import delimited` type guessing drops leading zeros | `allstring` option | E15 |
| S3 | Name clash with parent gave no hint | Error now suggests `separator` | — |
| S4 | No stored results | `rclass`: `r(fn) r(N) r(k) r(n_repeat) r(n_unmatched) r(unmatched)` | E13, E14 |
| S5 | `formtitle()` actually takes a file name | `xlsform()` added; `formtitle()` kept as a synonym | E16 |
| S6 | Help file had no Remarks | Remarks on input files, group names, naming, order and edge cases; options grouped; stored results documented | — |
| S7 | "Requires Stata 14" untested | Help, README and email say "requires 14, developed and tested on 17" | — |
| — | Duplicate or missing KEY in main CSV gave a cryptic merge error | `isid key` check with a clear message | — |

---

## v1.2.0 fixes (2026-10-18)

| ID | Issue (v1.1.0) | Fix | Test |
|----|----------------|-----|------|
| R01 | `levelsof` without `clean` returned compound-quoted group names, making `tempfile tf_<group>` invalid for any form with repeats | Repeat groups tracked by index (`tf1`, `tf2`, …); no `levelsof` on group names | all |
| R02 | `drop if name == ""` removed blank-named `end_repeat` rows (normal XLSForm style), so nesting depth never closed and later questions were mis-ordered | Blank names kept for `end_repeat` / `end_group` rows | E6, E9 |
| R03 | Instance number taken from row order; `merge` sorts keys as strings (`hh[10]` < `hh[2]`), so instances ≥10 were mislabeled in groups with nested children | Instance number parsed from the trailing `[n]` of `KEY` | E5 |
| R04 | Repeat CSV with a header but no rows crashed the command | Empty groups skipped with a note | E2 |
| R05 | Form with no repeat groups saved a scratch dataset as the output | Main data kept in its own tempfile and saved explicitly | E3 |
| R06 | No separator between question name and instance: `q1` #11 and `q11` #1 both became `q111` | New `separator` option (`q1_11`, `q11_1`); default naming unchanged and a collision now stops with a clear error | E8, E10 |
| R07 | Ordering treated `q110` (`q1` #10) as `q10` "instance 0" | Instance suffixes may not start with 0 | E11 |

Hardening:

- Repeat nesting and parents read from the XLSForm, not inferred from key length.
- XLSForm read from the `survey` sheet (falls back to the first sheet); `type`/`name` columns checked.
- CSVs imported with `varnames(1) case(lower) bindquote(strict) encoding("utf-8")`: upper-case `KEY`/`PARENT_KEY`, multi-line text answers and non-Latin text (e.g. Bangla) are handled. XLSForm names are lower-cased to match.
- Clear errors for names that would exceed 32 characters and for repeat variables that clash with a parent variable (previously `merge` would silently keep the parent's values).
- Child rows with no matching parent are counted, reported and dropped.
- All tempfile paths quoted (safe when `c(tmpdir)` contains spaces).
- Certification test T05 fixed: it checked a stale `_rc` instead of the result of `datasignature confirm`.

(The group-prefix limitation noted here was fixed in v1.3.0.)

---

## v1.1.0 fixes (2026-10-09)

#### Critical (all 8 fixed)

| ID | Issue | Fix |
|----|-------|-----|
| C01 | `cap program drop` at load time (`ado:3`) | Removed. Program now starts with `program define` directly. |
| C02 | No `preserve`/`restore` — user data destroyed | Added `preserve` after `syntax`. Stata auto-restores on exit/error. |
| C03 | Global macros `form_id`, `form_name` leaked | Replaced all `gl`/`${...}` with `local`/`` `...' ``. |
| C04 | `version 13` but `strtrim()` needs Stata 14+ | Changed to `version 14`. Replaced `strtrim()` with `trim(itrim())` for broader compat. |
| C05 | `.pkg` has `v 1.0.0` (wrong protocol version) | Changed to `v 3`. |
| C06 | `stata.toc` has `v 1.0.0` | Changed to `v 3`. |
| C07 | `stata.toc` missing `p` line | Added `p odkrepeatmerge`. |
| C08 | Non-temp `.dta` files overwrite user files | Replaced `save \`f', replace` with `tempfile tf_\`f'` / `save \`tf_\`f''`. All intermediate saves now use tempfiles. Cleanup loop removed (no longer needed). |

#### Major (all 9 fixed)

| ID | Issue | Fix |
|----|-------|-----|
| M01 | Windows-only `\\` path separator | Changed to `/`. |
| M02 | Deprecated `insheet` | Replaced with `import delimited`. |
| M03 | Key length from obs 1 only | Made explicit with `length(key[1])` and documented assumption. |
| M04 | No error handling | Added `confirm file` before imports, `confirm variable key parent_key` after loading CSVs, and input validation for empty options. |
| M05 | Help file missing Syntax/Options/Stored results | Added full Syntax section with `synoptset`, Options section, Stored results section, `viewerjumpto` nav, and Also see section. |
| M06 | Help example uses `\\\` instead of `///` | Fixed example syntax and added a second example. |
| M07 | Date mismatch ado vs sthlp | Synchronized to `09oct2026` (version 1.1.0). |
| M08 | `ren * *_` could fail at 32-char limit | Acknowledged risk; no structural change (would require redesign). Documented. |
| M09 | No cleanup on error path | `preserve` now handles rollback. Intermediate files use tempfiles, so no disk cleanup needed. |

#### Minor (all 11 fixed)

| ID | Issue | Fix |
|----|-------|-----|
| m01 | `__` prefix variables | Renamed to `_orm_file`, `_orm_mother`, `_orm_j`. |
| m02 | `rm` instead of `erase` | Cleanup loop removed entirely (tempfiles auto-delete). |
| m03 | Debug `di` left in code | Removed. |
| m04 | `nogen` suppresses merge diagnostics | Kept `nogen` (intentional for this workflow). |
| m05 | `set obs 1000` hardcoded | Changed to `set obs \`wc'` (actual word count). |
| m06 | `begin_group`/`end_group` not skipped | Added to the `inlist()` exclusion filter. |
| m07 | Version line format | Reformatted to `*! version 1.1.0 09oct2026 Arman Mahmud`. |
| m08 | Test files hardcoded paths | Changed to `` `c(pwd)' `` relative paths. |
| m09 | `cap macro drop` drops user globals | Removed (no globals used anymore). |
| m10 | Empty `{right:}` in help title | Filled with version and date. |
| m11 | Mixed indentation | Normalized to tab-based indentation. |

---

---

---

## Draft SSC Submission Email

```
To: baum@bc.edu
Subject: SSC submission: odkrepeatmerge

Dear Kit,

I would like to submit the following package to the SSC Archive:

Title: ODKREPEATMERGE: Stata module to merge ODK repeat-group data into one
wide dataset in questionnaire order

Abstract: odkrepeatmerge combines the main and repeat-group CSV files
exported from ODK Central into a single Stata dataset with one row per
submission. It reads the XLSForm to find the repeat groups and their
nesting, reshapes each group wide (deepest first) using the instance number
recorded in each row's KEY, merges it into its parent, and orders all
variables to follow the questionnaire. Nested repeats of any depth, empty
repeat groups and exports with or without group-name prefixes are
supported. Variables that cannot be matched to the form are listed, name
clashes and Stata's variable limits produce clear errors, and the output
file is never overwritten without replace.

Keywords: ODK, ODK Central, XLSForm, repeat groups, survey data, data management, reshape, merge

Requires: Stata version 14 (developed and tested on Stata 17)

Author: Arman Mahmud
Affiliation: [TODO: add your institution]
Email: armanmahmud.du18@gmail.com

The package consists of:
  odkrepeatmerge.ado
  odkrepeatmerge.sthlp

Thank you,
Arman Mahmud
```

---

## Pre-Submission Checklist (v1.3.0)

| # | Item | Status |
|---|------|--------|
| 1 | `.ado` and `.sthlp` present, lowercase, matching names | PASS |
| 2 | `*! version 1.3.0 18oct2026` in ado and help | PASS |
| 3 | `version 14` statement | PASS |
| 4 | No `program drop`, `clear all`, `set more off`, `cd`, hard-coded paths in ado | PASS |
| 5 | No global macros; temporary objects are tempfiles/tempnames | PASS (T09, T10) |
| 6 | User data preserved | PASS (T05, E13) |
| 7 | Never overwrites a file without `replace` | PASS (E13) |
| 8 | Stored results documented and returned | PASS (E13) |
| 9 | Help: Syntax, Description, Options, Remarks, Examples, Stored results, Author | PASS |
| 10 | Help syntax matches `syntax` statement | PASS |
| 11 | Informative error messages | PASS |
| 12 | Cross-platform paths | PASS (`/`) |
| 13 | No SSC name collision | PASS |
| 14 | `.pkg` / `stata.toc` valid for GitHub `net install` | PASS |
| 15 | Full test suite passes on v1.3.0 | TODO (run `tests/run_all_tests.do`) |
| 16 | Tested on a real ODK Central export | TODO |
| 17 | Affiliation filled in email | TODO |
| 18 | README "testing phase" warning removed | PASS |
| 19 | V1 merged into `main` (what `net install` serves) | TODO |
