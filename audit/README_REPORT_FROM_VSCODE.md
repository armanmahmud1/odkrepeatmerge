# Independent Audit Report: `odkrepeatmerge` v1.4.0

**Date:** 2026-10-18
**Auditor:** Claude Opus 4.6 (VS Code independent audit)
**Branch audited:** V1
**Commit:** `e6ed58c61adef45bbf9ac4e94e0b1cdf5d4b7ded`
**Stata version used:** Stata 17 MP (StataMP-64.exe available at `C:\Program Files\Stata17\`; batch mode from CLI not operational — audit is static with prior log evidence)
**Scope:** Full 12-layer audit of the `odkrepeatmerge` Stata package for SSC Archive readiness.

---

## Executive Summary

**Verdict: READY AFTER MINOR FIXES**

| Severity | Count |
|----------|-------|
| BLOCKER  | 1     |
| MAJOR    | 0     |
| MINOR    | 7     |
| NIT      | 4     |

**Top 5 issues:**

1. **VS-001 (BLOCKER):** `main` branch still has v1.0.0 — `net install` from the documented URL installs the old, broken code.
2. **VS-002 (MINOR):** `.claude/settings.local.json` is tracked in git on V1; will pollute the repo when merged.
3. **VS-003 (MINOR):** `confirm file` on ado lines 76–77 uses simple quotes instead of compound quotes for file paths.
4. **VS-004 (MINOR):** No test for 4+ levels of nesting (code supports it; untested beyond 3).
5. **VS-005 (MINOR):** No test for gaps in instance numbers (deleted repeats).

The single BLOCKER is a repository management task (merge V1 → main), not a code defect. The code itself is solid, well-structured, and handles an impressive range of edge cases correctly. Once V1 is merged to main and the two TODOs in the SSC email are filled in, the package is ready for SSC submission.

---

## Method and Environment

### What was examined
- Every line of `odkrepeatmerge.ado` (559 lines), `odkrepeatmerge.sthlp` (232 lines), `odkrepeatmerge.pkg`, `stata.toc`, `README.md`, `.gitignore`, `LICENSE`.
- All 22 test files: 2 regression tests, certification tests T01–T10, help examples, edge tests E1–E18.
- The test runner `tests/run_all_tests.do`.
- Audit files: `audit/AUDIT_REPORT.md`, `audit/odkrepeatmerge_cert.do`, `audit/examples.do`, `audit/install_test.do`.
- Git history (`git log --oneline -10`), branch state, and diff between `main` and `V1`.

### What was run vs static
- **Prior run evidence:** The test runner log (`tests/run_all_tests.log`) and certification log (`audit/odkrepeatmerge_cert.log`) from 18 Oct 2026, 23:10, show 22/22 PASS on Stata 17 MP. I verified these logs in full.
- **Batch mode:** Stata 17 MP is installed at `C:\Program Files\Stata17\StataMP-64.exe`, but the GUI `/e` batch mode did not produce output when invoked from the MSYS2/Git Bash shell. Probes were written but not executed; all findings are labeled STATIC-HIGH or STATIC-PLAUSIBLE.
- **Algorithm tracing:** The XLSForm parsing, reshape/merge, and ordering algorithms were traced by hand through the E4 three-level-nesting example. All values and sort keys verified correct.

---

## Findings Table

| ID     | Layer | Severity | Confidence      | File:line         | Title |
|--------|-------|----------|-----------------|-------------------|-------|
| VS-001 | L1    | BLOCKER  | STATIC-HIGH     | (repo branches)   | `main` branch has v1.0.0; `net install` broken |
| VS-002 | L1    | MINOR    | STATIC-HIGH     | .claude/settings.local.json | Dev tool config tracked in git |
| VS-003 | L7    | MINOR    | STATIC-PLAUSIBLE| ado:76–77         | `confirm file` uses simple quotes, not compound |
| VS-004 | L10   | MINOR    | STATIC-HIGH     | (tests)           | No test for 4+ levels of nesting |
| VS-005 | L10   | MINOR    | STATIC-HIGH     | (tests)           | No test for instance number gaps |
| VS-006 | L10   | MINOR    | STATIC-HIGH     | (tests)           | No test for out-of-order child rows |
| VS-007 | L10   | MINOR    | STATIC-HIGH     | E6, E9            | Two tests check order only, not values |
| VS-008 | L4    | MINOR    | STATIC-PLAUSIBLE| ado:258, 351      | Internal names `_orm_j`/`_orm_m` could collide with user fields |
| VS-009 | L1    | NIT      | STATIC-HIGH     | LICENSE:3          | Copyright year says 2025 |
| VS-010 | L10   | NIT      | STATIC-HIGH     | install_test.do:48 | Windows-only cleanup command |
| VS-011 | L9    | NIT      | STATIC-HIGH     | AUDIT_REPORT.md:183| Pre-submission checklist header says "v1.3.0" |
| VS-012 | L11   | NIT      | STATIC-HIGH     | AUDIT_REPORT.md:170| SSC email has `[TODO: add your institution]` |

---

## Detailed Findings

### VS-001: `main` branch has v1.0.0; `net install` from documented URL is broken

- **Severity:** BLOCKER | **Confidence:** STATIC-HIGH | **Layer:** L1

**Description:**
The `main` branch still contains the original v1.0.0 code (`*! version 1.0.0 Arman Mahmud, 17Oct2025`), including every critical bug fixed in v1.1.0–v1.4.0 (e.g., `cap program drop` at load time, global macro leakage, no preserve/restore, wrong `version 13`). The README and help file document `net install` from `https://raw.githubusercontent.com/armanmahmud1/odkrepeatmerge/main/`, which serves the `main` branch.

**Evidence:**
```
$ git show main:odkrepeatmerge.ado | head -5
*! version 1.0.0 Arman Mahmud, 17Oct2025

	cap program drop odkrepeatmerge
	program define odkrepeatmerge
		version 13
```

```
$ git log main --oneline -3
90b6a42 Remove email address from author section in README
4a1a166 Merge pull request #2 from armanmahmud1/V1
bacc2d5 Update author website link in README
```

The last merge from V1 to main was PR #2, which merged v1.0.0 changes. The v1.1.0–v1.4.0 changes on V1 have not been merged.

**Impact:**
Any user following the installation instructions gets a non-functional, bug-ridden version. SSC submission would be from the same GitHub source.

**Recommended fix:**
```bash
git checkout main
git merge V1
git push origin main
```

**Test to add:** The `audit/install_test.do` already tests local install; extend it or add a CI check that `which odkrepeatmerge` reports v1.4.0.

---

### VS-002: `.claude/settings.local.json` tracked in git

- **Severity:** MINOR | **Confidence:** STATIC-HIGH | **Layer:** L1

**Description:**
The file `.claude/settings.local.json` is tracked on the V1 branch (it appears in `git diff main..V1 --name-only`). Although `.gitignore` lists it, git does not ignore already-tracked files. When V1 is merged to main, this file will be in the repository.

**Evidence:**
```json
// .claude/settings.local.json
{
  "permissions": {
    "allow": [
      "WebSearch"
    ]
  }
}
```

**Impact:**
Cosmetic — this file won't be installed by SSC (the `.pkg` only lists `.ado` and `.sthlp`). But it's a development tool artifact that shouldn't be in the repository.

**Recommended fix:**
```bash
git rm --cached .claude/settings.local.json
git commit -m "Untrack .claude/settings.local.json"
```

---

### VS-003: `confirm file` uses simple quotes for file paths

- **Severity:** MINOR | **Confidence:** STATIC-PLAUSIBLE | **Layer:** L7

**Description:**
Lines 76–77 use simple double quotes around file path macros:
```stata
confirm file "`form_name'"      // line 76
confirm file "`mainfile'"       // line 77
```

The rest of the code consistently uses compound quotes (`` `"..."' ``) for paths that may contain spaces or special characters. While simple quotes work for paths with spaces (since the local expansion inserts the full string), they would fail if a path contained a literal double-quote character.

**Evidence:**
Compare with line 203 which correctly uses compound quotes:
```stata
import delimited using `"`mainfile'"', clear ...   // line 203
```

**Impact:**
Extremely unlikely to cause a real problem (file paths with literal `"` are rare), but inconsistent with the rest of the code.

**Recommended fix:**
```stata
confirm file `"`form_name'"'
confirm file `"`mainfile'"'
```

---

### VS-004: No test for 4+ levels of nesting

- **Severity:** MINOR | **Confidence:** STATIC-HIGH | **Layer:** L10

**Description:**
Test E4 covers 3 levels of nesting (a > b > c). The code logic (nested `forvalues dd = maxgdepth(-1)1` loop with `rename * *_` at each intermediate level) supports arbitrary depth, but this is unverified beyond 3 levels.

**Reproduction:** See `audit/vscode_probes/P01_four_level_nesting.do`.

**Impact:** Low — the algorithm generalizes naturally. But 4+ level nesting is used in some health surveys (e.g., household > member > visit > symptom).

---

### VS-005: No test for instance number gaps

- **Severity:** MINOR | **Confidence:** STATIC-HIGH | **Layer:** L10

**Description:**
When a repeat instance is deleted in ODK Central, the remaining rows may have gaps (e.g., instances [1], [3], [5]). The code parses instance numbers from KEY and uses `reshape wide` with `j(_orm_j)`, which should handle gaps correctly. But no test verifies this.

**Reproduction:** See `audit/vscode_probes/P02_instance_gaps.do`.

---

### VS-006: No test for out-of-order child rows

- **Severity:** MINOR | **Confidence:** STATIC-HIGH | **Layer:** L10

**Description:**
Child CSV rows may not arrive in instance-number order (e.g., instance [3] before [1]). The code uses `_orm_j` from the KEY's `[n]` suffix, so `reshape wide` should assign values correctly regardless of row order. No test verifies this.

**Reproduction:** See `audit/vscode_probes/P03_rows_out_of_order.do`.

---

### VS-007: Tests E6 and E9 check order only, not values

- **Severity:** MINOR | **Confidence:** STATIC-HIGH | **Layer:** L10

**Description:**
E6 (`blank end_repeat names`) and E9 (`groups and spaced types`) assert only variable order (`unab got : _all` / `if "\`got'" != "\`want'"`) without checking any data values. A bug that produces correct variable names but wrong values would pass these tests.

**Reproduction:** See `audit/vscode_probes/P04_sibling_repeats_values.do` (covers the E6/E9 scenario with value checks).

---

### VS-008: Internal variable names could collide with user fields

- **Severity:** MINOR | **Confidence:** STATIC-PLAUSIBLE | **Layer:** L4

**Description:**
The code creates `_orm_j` (ado:258) and uses `_orm_m` in `merge ... generate(_orm_m)` (ado:351). If a user's XLSForm contains a question named `_orm_j` or `_orm_m`, these would collide. After `import delimited` with `case(lower)`, the variable name would be `_orm_j` or `_orm_m`, causing the `generate _orm_j` to fail or the `merge generate(_orm_m)` to error.

**Impact:** Extremely unlikely in practice — no ODK form would use `_orm_` prefixed field names. But a defensive check would improve robustness.

**Recommended fix:** Before creating `_orm_j`, check for collision:
```stata
capture confirm new variable _orm_j
if _rc {
    noisily display as error "variable _orm_j already exists (name collision)"
    exit 110
}
```

---

### VS-009: LICENSE copyright year says 2025

- **Severity:** NIT | **Confidence:** STATIC-HIGH | **Layer:** L1

**Description:** `LICENSE:3` says `Copyright (c) 2025 Arman Mahmud`. The package dates are 2026.

---

### VS-010: `install_test.do` uses Windows-only cleanup

- **Severity:** NIT | **Confidence:** STATIC-HIGH | **Layer:** L10

**Description:** Line 48 of `audit/install_test.do` uses `capture shell rmdir /s /q`, which is Windows-specific. A comment on line 49 mentions the Mac/Linux alternative but the code doesn't auto-detect. This is in an audit helper, not the main package, so impact is minimal.

---

### VS-011: Audit report checklist header says "v1.3.0"

- **Severity:** NIT | **Confidence:** STATIC-HIGH | **Layer:** L9

**Description:** `audit/AUDIT_REPORT.md:183` says `## Pre-Submission Checklist (v1.3.0)` but the checklist items reference v1.4.0.

---

### VS-012: SSC email has unfilled TODO

- **Severity:** NIT | **Confidence:** STATIC-HIGH | **Layer:** L11

**Description:** The draft SSC email in `audit/AUDIT_REPORT.md:170` still contains `[TODO: add your institution]` under Affiliation.

---

## Layer Checklist

### L1. Repository and packaging — ISSUES

- **`.pkg`:** Valid format. `v 3`, `d` line, `f odkrepeatmerge.ado`, `f odkrepeatmerge.sthlp`. Correct.
- **`stata.toc`:** Valid. `v 3`, `d Arman Mahmud`, `p odkrepeatmerge`. Correct.
- **`net install` from `main`:** BROKEN. Main has v1.0.0. See VS-001.
- **Version consistency:** On V1: ado line 1 (`*! version 1.4.0 18oct2026`), sthlp line 2/13 (`version 1.4.0 18oct2026`), pkg Distribution-Date `20261018`, README says v1.4.0 syntax and examples. All consistent.
- **`.gitignore`:** Covers `tests/tmp_*/`, `tests/tests/`, `audit/tmp_*/`, `audit/*.log`, `*.dta`, `tests/run_all_tests.log`, `.claude/settings.local.json`. Good coverage.
- **Tracked junk:** `.claude/settings.local.json` (VS-002). No `.dta`, `.log`, `.csv`, or `.xlsx` files are tracked (verified via `git ls-files`).
- **LICENSE:** Present, MIT. Copyright year says 2025 (VS-009).

### L2. Syntax and API design — PASS

- **`syntax` statement (ado:5–6):**
  ```stata
  syntax [using/] [, XLSform(string) FORMTitle(string) formid(string) formloc(string) ///
      SAVing(string asis) REPLACE SEParator ALLstring]
  ```
  Abbreviations: `xls` → `xlsform`, `form` → `formtitle` (but conflicts with `formid` — Stata resolves by requiring 5+ chars for `formtitle`; `formt` works, `form` is ambiguous). Actually: `FORMTitle` requires `formt`, `formid` requires `formi`. No ambiguity.
- **Help file syntax:** Matches the `syntax` statement. `{opt xls:form()}`, `{opt sep:arator}`, `{opt all:string}` match the capital-letter abbreviation markers.
- **README syntax:** Matches help and ado.
- **`using` + `formid()`/`formloc()`:** Correctly rejected with r(198) (ado:33–36). Tested in E18.
- **`replace` / `saving(, replace)`:** Both work. Without replace, r(602) if file exists. Tested in E13.
- **`rclass` results:** `r(fn)`, `r(N)`, `r(k)`, `r(n_repeat)`, `r(n_unmatched)`, `r(unmatched)`. All documented in help. Tested in E13, E14.
- **Exit codes:** 198 (syntax), 601 (file not found), 602 (file exists), 111 (missing column), 459 (KEY issues), 110 (name collision), 900 (variable limit). All produce clear, actionable error messages.

### L3. Core correctness: XLSForm parsing — PASS

- **Type variants:** `begin_repeat`/`begin repeat`/`end_repeat`/`end repeat` handled via `inlist()` on ado:157, 161, 175. Tested in E9.
- **Groups:** `begin_group`/`begin group`/`end_group`/`end group` correctly skipped for question posting but tracked in `grpnames` for `_orm_ungroup`. Tested in E9, E12.
- **`note` type:** Correctly skipped (ado:178). Tested in E9.
- **Case and whitespace:** `type` is lowercased and trimmed with `itrim()` (ado:127). `name` is trimmed (ado:128). Handles mixed case and extra spaces.
- **Blank `name` on end rows:** Kept for `end_repeat`/`end_group`, dropped otherwise (ado:131). Tested in E1, E6.
- **`survey` sheet:** Tried first; falls back to first sheet (ado:117–119). Probe P06 covers the fallback case.
- **`.xls` vs `.xlsx`:** Both handled by `import excel`. No extension restriction.
- **`type`/`name` columns:** Confirmed with `confirm variable type name` (ado:121–125).
- **Compound types:** `select_one choicelist`, `select_multiple options` — not in the exclusion list, so treated as regular questions. Correct. The `_other` auto-generated field would be unmatched, which is acceptable.
- **`geopoint`/`geotrace`/`geoshape`:** Listed as regular questions. Their split columns (e.g., `gps-Latitude`) are not in the form and would be unmatched. The `_orm_ungroup` function correctly does NOT rename `gps-Latitude` because `gps` (as a geopoint field) is not added to `grpnames`. Tested in E12.
- **Metadata fields:** `start`, `end`, `deviceid` — treated as regular questions if present in the XLSForm. If present only in the CSV, they're unmatched. Correct.

### L4. Core correctness: CSV discovery, reshape, merge — PASS

- **Child-file naming:** `form_id-groupname.csv` (ado:218). Matches ODK Central convention.
- **Path handling with `using`:** Backslashes converted to forward slashes (ado:38). Extension stripped via regex (ado:40). Stem extracted (ado:48). Tested in E18.
- **KEY/PARENT_KEY handling:** `case(lower)` lowercases headers (ado:203, 224). `confirm variable key parent_key` (ado:205–209, 229–233). `uuid:` prefixes work transparently since KEY matching is exact string comparison. Tested in E1, E7.
- **Instance number parsing:** `regexm(key, "\[([0-9]+)\]$")` (ado:258). Extracts trailing `[n]`. Works for any positive integer. Missing `_orm_j` checked (ado:259–263). Tested in E5 (11 instances).
- **Reshape:** `reshape wide stubs, i(key) j(_orm_j)` (ado:303). Uses instance number, not row order. Collision error caught and reported with helpful message (ado:304–310).
- **Nested reshapes:** Innermost first via `forvalues dd = maxgdepth(-1)1`. `rename * *_` adds trailing underscore for intermediate levels (ado:314–316). Name-length check (ado:282–291) uses `maxlen=31` for nested, `32` for top-level. Correct. Tested in E4 (3 levels), E5, E10.
- **Merges:** `merge 1:1 key` (ado:351). Orphan children (`_orm_m==2`) dropped with a note. Tested in E1 (unequal repeat counts), E2 (empty repeat).
- **Empty child files:** Skipped with `_N==0` check (ado:225–228). Tested in E2.
- **`c(maxvar)` guard:** Checked before reshape (ado:294–301) and before merge (ado:344–349). r(900) with advice. Tested in E17.

### L5. Core correctness: variable ordering — PASS

- **Template/sort-key algorithm:** Verified by hand-tracing through 3-level nesting (E4). The template encodes position-within-parent at each nesting level. The sort key interleaves template positions with instance numbers, reversed from innermost-first to outermost-first. Sorting on `(grp, k1, k2, ..., kN, qseq, origseq)` produces correct questionnaire order.
- **Longest-prefix match:** `length(qname) > bestlen` (ado:420, 439) ensures that `q10` is preferred over `q1` when both are prefixes of `q101`. Instance suffix `0` is rejected by `^[1-9]...` pattern (ado:435). Tested in E8, E11.
- **Repeat names as prefixes of each other:** Not explicitly tested but handled by the longest-match rule. A question in repeat `r` and repeat `r1` would have different names.
- **Unmatched reporting:** ODK Central system columns (ado:147–150) are excluded from the unmatched list (ado:483–484). Non-system unmatched variables are reported and placed at the end. `r(unmatched)` and `r(n_unmatched)` returned. Tested in E12, E14.
- **`_orm_ungroup`:** Renames group-prefixed variables (ado:536–558). Uses the original header from the variable label. Only renames when every prefix segment is a known group/repeat name AND the target name is in the form AND the target name is free. Tested in E12 (including geopoint protection).

### L6. Data integrity (value level) — PASS

Value assertions verified in the following tests:
- **E1:** `hh_name1[1]=="Arif"`, `hh_age2[1]==35`, etc. Multiple submissions with unequal counts.
- **E4:** All 3-level nested values verified against source CSV data (14 assertions).
- **E5:** All 11 instances × 2 variables verified.
- **E7:** `a1=="a1"`, `a2=="a2"`.
- **E8:** `q1_11=="a11"`, `q11_1=="b1"`.
- **E10:** Nested separator values: `p_q_1_1=="P11"`, `p_q_2_1=="P12"`.
- **E11:** `q110=="a10"`, `q101=="b1"`, `q1010=="b10"`.
- **E12:** `hh_q2=="h2"`, `hh_n1==5`, `latitude=="L"`.
- **E15:** Leading zeros: `hhid=="007"`, `pid1=="0101"`.
- **E18:** `name1=="A"`, `name2=="B"`, `ill_type2_1=="fever"`.

Gap: No randomized multi-submission stress test. Probes P02 (instance gaps), P03 (out-of-order rows), P05 (multi-submission values) cover additional scenarios statically.

### L7. Stata programming quality — PASS (with one minor)

**Stata 14 compatibility:**
Every command, option, and function used in the ado was checked against Stata 14 availability:

| Feature | Used on line | Introduced in |
|---------|-------------|---------------|
| `import delimited ... varnames(1) case(lower) bindquote(strict) encoding("utf-8")` | 203, 224 | Stata 14 |
| `import delimited ... stringcols(_all)` | 203, 224 (via `strimport`) | Stata 13 |
| `import excel ... case(lower) allstring` | 117, 119 | Stata 14 |
| `strtoname()` | 543 | Stata 13 |
| `regexm()` / `regexs()` | 40, 258, 435, 541 | Stata 9 |
| `confirm variable ... , exact` | 335 | Stata 5+ |
| `confirm new file` | 96 | Stata 5+ |
| Mata `pathsuffix()` | 93 | Stata 10+ |
| `isid` | 210 | Stata 10 |
| `levelsof` | 282 | Stata 12 |
| `postfile` with `str244` | 135 | Stata 6+ |
| `ds ... , not` | 236, 277, 317 | Stata 6+ |
| `trim()` / `itrim()` | 127, 128 | Stata 6+ |
| `unab` | 373 | Stata 5+ |

All features are available in Stata 14.

**Quoting and macros:**
- Compound quotes used consistently for file paths in `import`, `save`, `display`, `use`, `merge` (ado:203, 224, 498, etc.).
- **VS-003:** `confirm file` on lines 76–77 uses simple quotes. See finding.
- Local macro names: longest is `__suffix_words` (15 chars), well within the 31-char limit.
- `c(macrolen)` limits: The `qnamelist` local accumulates all question names. For a 500-question form, this would be ~5,000 chars. Stata 14 IC/BE `c(macrolen)` is 645,200 chars. No issue.

**Side effects:**
- `preserve` (ado:108): Data in memory restored on exit or error. Tested in T05, E13.
- All intermediate data uses `tempfile` (ado:133, 238, 319). No disk pollution. Tested in T10.
- No global macros. Tested in T09.
- No Mata globals or pollution (only one `mata:` call on line 93, which is stateless).
- Working directory: The ado never calls `cd`. Unchanged after the command.
- `quietly` block (ado:110–519) with `noisily display` breakouts. Appropriate output level.
- `set more off` is NOT called in the ado (good — it would change user settings). It's only in test files.

**Error paths:**
- Before `preserve`: lines 9–19 (option validation), 76–77 (file existence), 80–106 (output file check). These exit without touching data.
- After `preserve`: Any error triggers automatic restore. `exit` codes used throughout.

### L8. Performance and scalability — PASS (not benchmarked)

**Complexity analysis:**
- XLSForm parsing: O(N) where N = rows in survey sheet. Single pass.
- CSV loading: O(G) file reads where G = number of repeat groups.
- Reshape: O(R × V) per group where R = rows, V = variables. Stata-native.
- Ordering loop: O(A × Q) where A = total variables in output, Q = questions in XLSForm. For a large survey (500 questions, 30-member roster × 40 questions = 1,700 variables), this is ~850,000 string operations. Manageable.
- The `rename * *_` operation is O(V), called once per nested repeat group.

**Variable limits:**
- Stata BE: 2,048 variables. A 40-question roster with 30 members produces 1,200 variables. Feasible but tight. The `c(maxvar)` guard (ado:294–301, 344–349) catches overflows.
- Stata SE/MP: 32,767 or 120,000 variables. No practical concern.

**Macro length:**
- The `ordered_varlist` local (ado:491–494) contains all variable names space-separated. For 2,000 variables averaging 10 chars, this is ~22,000 chars. Well within `c(macrolen)`.

**Not benchmarked:** Stata batch mode was not operational. For a concrete estimate, the author should time a synthetic large case.

### L9. Help file and README — PASS (with one NIT)

**SMCL validity:**
- The help file was rendered successfully during the test run (visible in `audit/examples.log`).
- All SMCL tags are syntactically correct: `{synoptset}`, `{synopt}`, `{synoptline}`, `{viewerjumpto}`, `{dlgtab}`, `{phang}`, `{pstd}`, `{marker}`, `{cmd}`, `{opt}`, `{it}`, `{bf}`, `{helpb}`, `{browse}`, `{col}`.
- The column-aligned file layout table (sthlp:74–77) uses `{col 52}` for alignment.

**Content accuracy:**
- Every statement in the help file and README is consistent with the code.
- The four help-file examples all parse correctly (tested in `audit/examples.do`; all return file-not-found, not syntax errors).
- The older syntax documentation is accurate and matches the code's `formid()`/`formloc()` handling.

**SSC-expected sections:** Title, Syntax, Description, Options, Remarks, Examples, Stored results, Author, Also see — all present.

**README:** Consistent with help. Clear for a non-expert ODK user. The installation section, syntax table, file-layout diagram, and examples are all correct.

**VS-011 (NIT):** Audit report checklist header says "v1.3.0".

### L10. Test suite quality — ISSUES (minor gaps)

**Coverage map:** See the Test Coverage Map section below.

**Strengths:**
- 22 test files covering syntax, errors, data preservation, variable order, data values, edge cases.
- Tests that verify values (E1, E4, E5, E7, E8, E10, E11, E12, E15, E18) are thorough.
- The test runner (`run_all_tests.do`) handles cwd restoration, log management, and adopath correctly.
- Error tests (T06–T08, E8, E13, E16–E18) check specific return codes.

**Gaps (VS-004 through VS-007):**
- No 4+ level nesting test (P01 written).
- No instance gap test (P02 written).
- No out-of-order row test (P03 written).
- E6 and E9 check only order, not values (P04 written).

**Tests that could pass for the wrong reason:**
- T01, T02, T04: Use `confirm variable` (existence check) without value assertions. A bug that creates wrong variable names would be caught, but one that assigns wrong values would not. However, the same scenarios are covered with value assertions in E1 and the regression tests.
- T06 and T07: Check `if _rc != 0` without asserting the specific error code. The test would pass even if the command failed for an unrelated reason. However, the `capture noisily` shows the error message in the log, which was manually verified.

**Isolation and cleanup:**
- Each test creates and cleans up its own temporary directory.
- The runner restores cwd, re-opens the log, and re-sets adopath after each test (run_all_tests.do:64–73).
- `clear all` at the start of each edge test provides clean state.

### L11. SSC submission readiness — ISSUES (blocker + TODOs)

| Item | Status |
|------|--------|
| Name not on SSC | PASS (searched IDEAS/RePEc, not found) |
| `.ado` and `.sthlp` present, lowercase, matching names | PASS |
| Version line in ado and sthlp | PASS (`*! version 1.4.0 18oct2026`) |
| `version 14` statement | PASS |
| No `program drop`, `clear all`, `set more off`, `cd`, hard-coded paths in ado | PASS |
| No global macros; tempfiles/tempnames used | PASS |
| `preserve`/`restore` | PASS |
| Never overwrites without `replace` | PASS |
| Stored results documented | PASS |
| Help file complete (all SSC sections) | PASS |
| Error messages are actionable | PASS |
| Cross-platform paths (`/`) | PASS |
| `.pkg` / `stata.toc` valid | PASS |
| Full test suite passes | PASS (22/22 on Stata 17) |
| `main` branch has current version | **FAIL** (VS-001) |
| Email affiliation filled | **TODO** (VS-012) |
| Tested on real ODK Central export | TODO (per audit report) |

**SSC email format:** Title uses `MODULE: Stata module to ...` convention. Abstract is well-written. Keywords appropriate. `Requires:` line present. Format matches [SSC submission guidelines](http://repec.org/bocode/s/sscsubmit.html).

### L12. Safety and UX — PASS

- **File writes:** Only to the specified output file (or default `stem.dta`). No writes to the raw data folder with `using` syntax. Tested in E18.
- **No shell commands:** The ado contains no `shell`, `winexec`, or `!` commands.
- **No file deletion:** The ado never erases user files.
- **Messages:** Informative phase markers ("Reading the XLSForm...", "Loading CSV files...", etc.). Not noisy — all under `quietly` except the phase messages. Unmatched variables listed with actionable advice.
- **Defaults:** With `using`, output goes to cwd (safe — doesn't pollute raw data). With `formid()`/`formloc()`, output goes next to the data (matching pre-v1.4.0 behavior).

---

## Test Coverage Map

| Code path / branch | Covering test(s) | Gap? |
|---------------------|-------------------|------|
| **XLSForm parsing** | | |
| `begin_repeat` / `begin repeat` | E9 | |
| `end_repeat` / `end repeat` (blank name) | E1, E6 | |
| `begin_group` / `end_group` skipped | E9, E12 | |
| `note` type skipped | E9 | |
| `survey` sheet preferred; fallback to first | E1 (survey sheet), T01–T04 (no sheet specified) | No test for survey-not-first-sheet (P06 written) |
| `type`/`name` columns required | T08 (implicitly) | |
| Mixed case / extra spaces in type | E9 | |
| **CSV loading** | | |
| `using` syntax | E18 | |
| `formid()` / `formloc()` syntax | T01–T04, E1–E17 | |
| `formid()` + `formloc()` + full `xlsform()` path | E18 (step 5) | |
| `using` + `formid()` conflict | E18 (step 4) | |
| Missing `using` and `formid()` | E18 (step 4), T06 | |
| Upper-case KEY/PARENT_KEY | E1, E7, E18 | |
| `uuid:` prefix in keys | E1 | |
| `bindquote(strict)` / `encoding("utf-8")` | All CSV tests | |
| `allstring` option | E15 | |
| **Reshape / merge** | | |
| Single-level repeat | T01, T04, E2, E6, E7, E13–E15 | |
| 2-level nesting | T02, E5, E10, E18 | |
| 3-level nesting | E4 | |
| 4+ level nesting | — | **Gap** (P01) |
| Sibling repeats | E6, E9 | Values not checked (P04) |
| 10+ instances | E5, E8, E11 | |
| Empty child CSV (0 rows) | E2 | |
| Orphan children (no parent) | E1 (implicit — unequal counts) | |
| Instance gaps | — | **Gap** (P02) |
| Out-of-order rows | — | **Gap** (P03) |
| Name-length check (32/31 chars) | E8 (implicit) | |
| `c(maxvar)` guard | E17 | |
| `separator` option | E8, E10 | |
| `reshape` collision error | E8 | |
| Parent variable collision | — | Not tested explicitly; error path exists (ado:334–343) |
| **Ordering** | | |
| Questionnaire order verified | T03, E3, E4, E6, E7, E8, E9, E10, E11, E12, E14, E18 | |
| Prefix collision (q1/q10) | T03, E11, regression_prefix_collision | |
| Unmatched at end | E12, E14 | |
| System columns excluded from unmatched | E12 | |
| **`_orm_ungroup`** | | |
| Group-prefixed headers renamed | E12 | |
| Geopoint parts NOT renamed | E12 | |
| System column `meta-instanceID` | E12 | |
| **Output / save** | | |
| Default output name | T01–T04, E1–E17 | |
| `saving()` | E13, E18 | |
| `replace` / no overwrite | E13, E18 | |
| `.dta` extension added if missing | E13 | |
| **Error handling** | | |
| Missing `xlsform()` / `formtitle()` | T07, E16 | |
| Missing `formid()` or `using` | T06, E18 | |
| Conflicting `xlsform()` and `formtitle()` | E16 | |
| File not found | T08, E18 | |
| Missing KEY column | — | Not tested (error path exists ado:206–209) |
| Duplicate KEYs | — | Not tested (error path exists ado:210–214) |
| **Side effects** | | |
| `preserve`/`restore` | T05, E13 | |
| No global macros | T09 | |
| No intermediate files | T10 | |
| `r()` results | E13, E14 | |

---

## Verified Correct

The following aspects were checked and found to work correctly:

1. **Algorithm correctness (by hand-tracing E4):** The template-based sort-key algorithm produces the correct questionnaire order for 3-level nested repeats. Each variable gets a sort key that interleaves template positions (encoding questionnaire position) with instance numbers (reversed from innermost-first to outermost-first). The `sort grp k1-kN qseq origseq` produces the expected output order. All 14 value assertions in E4 are consistent with the algorithm's output.

2. **Instance number parsing from KEY:** The regex `\[([0-9]+)\]$` correctly extracts the trailing instance number regardless of the KEY format (plain `u1/r[1]`, uuid `uuid:xxx/r[1]`, nested `uuid:xxx/a[1]/b[2]/c[3]`). Instance numbers ≥10 are handled correctly because `real()` produces the numeric value. Verified by E5 (11 instances) and E11 (10 instances).

3. **Longest-prefix matching rule:** When `q1` and `q10` are both in a repeat, the variable `q101` (q10 instance 1) is correctly matched to `q10` (not `q1` with suffix `01`, which is rejected by the `^[1-9]...` pattern) because `length("q10") > length("q1")`. Verified by T03 and E11.

4. **`_orm_ungroup` geopoint protection:** For a header `gps-Latitude`, the prefix `gps` is correctly NOT in `grpnames` (because `geopoint` is not `begin_group`/`begin_repeat`), so the rename is skipped. A real question `latitude` coexists without collision. Verified by E12.

5. **`preserve`/`restore` data integrity:** After running `odkrepeatmerge`, `datasignature confirm` passes, proving the data in memory is unchanged. Verified by T05 and E13 (step 4).

6. **No global macro leakage:** After the command, `$form_id` and `$form_name` are empty. Verified by T09.

7. **No intermediate file pollution:** After the command, no `grp.dta` or similar files are left in the working directory. All intermediates use `tempfile`. Verified by T10.

8. **`saving()` with and without `.dta` extension:** `saving("out")` correctly adds `.dta`, producing `out.dta`. `saving("out.dta")` works as-is. Verified by E13.

9. **Older syntax backward compatibility:** `formid("f") formtitle("f.xlsx") formloc("dir")` still works. A full `xlsform()` path is not joined with `formloc()`. Verified by E18 (step 5) and all T01–T10 / E1–E17 tests.

10. **`xlsform()` / `formtitle()` synonym:** Both accepted. Same value for both is accepted. Different values rejected with r(198). Missing both rejected. Verified by E16.

11. **22/22 test pass on Stata 17:** Confirmed from `tests/run_all_tests.log` dated 18 Oct 2026, 23:10. All PASS messages present; `Passed: 22   Failed: 0`.

---

## Disagreements with `audit/AUDIT_REPORT.md`

| Audit report claim | This audit's finding |
|--------------------|---------------------|
| "Pre-Submission Checklist (v1.3.0)" heading | Should say v1.4.0 (VS-011). |
| Item 14: "`.pkg` / `stata.toc` valid for GitHub `net install`" → PASS | Technically correct for the V1 branch, but `net install` serves from `main`, which has v1.0.0 (VS-001). The check should be "main branch serves the current version." |
| Item 15: "Full test suite passes on v1.4.0" → PASS | Confirmed. 22/22. |
| Item 16: "Tested on a real ODK Central export" → TODO | Still TODO. Not something this audit can verify. |
| Item 18: "README 'testing phase' warning removed" → PASS | Confirmed. No such warning in the current README. |
| Item 19: "V1 merged into main" → TODO | Confirmed still TODO. This is the BLOCKER (VS-001). |

No claims in the audit report were found to be factually wrong. The report accurately describes the changes and their tests. The only gaps are the unfilled TODOs.

---

## SSC Submission Checklist

| # | Item | Status |
|---|------|--------|
| 1 | Package name not on SSC | PASS (searched IDEAS/RePEc) |
| 2 | `.ado` and `.sthlp` present, lowercase | PASS |
| 3 | Version line consistent across files | PASS (v1.4.0 18oct2026) |
| 4 | `version 14` in ado | PASS |
| 5 | No `program drop`, `clear all`, `cd`, hard-coded paths | PASS |
| 6 | No global macros; uses tempfiles | PASS |
| 7 | `preserve`/`restore` protects user data | PASS |
| 8 | Never overwrites without `replace` | PASS |
| 9 | Stored results documented and returned | PASS |
| 10 | Help has all required sections | PASS |
| 11 | Help syntax matches `syntax` statement | PASS |
| 12 | Error messages are clear and actionable | PASS |
| 13 | Cross-platform (no `\`, no `shell`, no Windows-specific) | PASS |
| 14 | `.pkg` and `stata.toc` format correct | PASS |
| 15 | Test suite passes | PASS (22/22) |
| 16 | Email: title line `MODULE: Stata module to ...` | PASS |
| 17 | Email: abstract, keywords, Requires, author | PASS |
| 18 | Email: affiliation filled in | **TODO** |
| 19 | `main` branch has current version for `net install` | **FAIL** (VS-001) |
| 20 | Tested on a real ODK Central export | **TODO** (per audit report) |

---

## Open Questions and Assumptions

1. **Stata 14 runtime verification:** All Stata-14 compatibility checks are based on documentation and web sources. The tests ran on Stata 17. Running on actual Stata 14 would provide definitive confirmation.

2. **`or_other` and split select-multiple columns:** ODK Central auto-generates `question_other` for `or_other` questions and can split `select_multiple` into binary columns. These auto-generated columns would not be in the XLSForm and would appear as unmatched. This is acceptable behavior, but the help file could mention it in Remarks.

3. **Real ODK Central export:** The test suite uses synthetic data. A test on a real ODK Central export (with group-prefixed headers, UUID keys, system columns, etc.) would increase confidence. E1 simulates this well, but a real export test is still listed as TODO.

4. **Stata IC/BE variable limits:** The `c(maxvar)` guard catches the limit, but no test verifies behavior on Stata IC/BE (which has a 2,048 variable limit). The guard logic is sound, but untested on those editions.

5. **UNC paths (e.g., `\\server\share\data.csv`):** Not tested. The backslash-to-forward-slash conversion (ado:38) would convert `\\` to `//`, which may not resolve correctly. This is an edge case on Windows network drives.

---

## Appendix

### Commands run (summarized output)

```
git rev-parse HEAD
  → e6ed58c61adef45bbf9ac4e94e0b1cdf5d4b7ded

git log --oneline -10
  → e6ed58c Update `odkrepeatmerge` to version 1.4.0 ...
    c007d43 Add edge case tests ...
    (8 more commits back to bd7ecf3 v1)

git status
  → On branch V1, clean

git branch -a
  → * V1, main, remotes/origin/HEAD -> origin/main, remotes/origin/V1, remotes/origin/main

git diff main..V1 --stat
  → 35 files changed, 2833 insertions(+), 383 deletions(-)

git show main:odkrepeatmerge.ado | head -5
  → *! version 1.0.0 Arman Mahmud, 17Oct2025 (old code with critical bugs)

git log main --oneline -3
  → 90b6a42 Remove email address ...
    4a1a166 Merge pull request #2 ...
    bacc2d5 Update author website link ...

git ls-files | grep -E '\.(dta|log|tmp|csv|xlsx)$'
  → (empty — no data files tracked)

Stata batch mode (/e flag):
  → StataMP-64.exe found at C:\Program Files\Stata17\
  → GUI launches but does not produce log output from MSYS2/Git Bash
  → All findings are static; prior test logs used as evidence

SSC name search (web):
  → "odkrepeatmerge" not found on IDEAS/RePEc SSC archive

Existing test run log (tests/run_all_tests.log):
  → 22/22 PASS on Stata 17, 18 Oct 2026 23:10
```

### Probe files

| File | What it tests |
|------|---------------|
| `audit/vscode_probes/P01_four_level_nesting.do` | 4-level nesting (a>b>c>d): values and order |
| `audit/vscode_probes/P02_instance_gaps.do` | Instance number gaps [1],[3],[5] from deleted repeats |
| `audit/vscode_probes/P03_rows_out_of_order.do` | Child CSV rows in non-sequential order |
| `audit/vscode_probes/P04_sibling_repeats_values.do` | Two sibling repeats: values + order (extends E6/E9) |
| `audit/vscode_probes/P05_multi_submission_values.do` | 3 submissions with varying repeat counts: all values checked |
| `audit/vscode_probes/P06_survey_not_first_sheet.do` | XLSForm with "choices" as first sheet, "survey" second |
| `audit/vscode_probes/P07_confirm_file_quoting.do` | Paths with spaces in folder and file names |
| `audit/vscode_probes/P08_main_branch_version.do` | Static check: main branch version mismatch documentation |

Run from the repo root: `cd odkrepeatmerge && do audit/vscode_probes/P01_four_level_nesting.do` (etc.)
