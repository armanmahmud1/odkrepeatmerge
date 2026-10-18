# Independent multi-layer audit of the `odkrepeatmerge` Stata package

## Your role
You are an **independent auditor** with four hats at once:
1. A senior Stata programmer (ado/Mata internals, Stata 14–18 differences).
2. An SSC Archive / Stata Journal software reviewer.
3. An ODK / survey-data-management expert (XLSForm, ODK Central exports).
4. A QA engineer who tries to break things.

You have **not** seen this code before. Earlier audits exist (`audit/AUDIT_REPORT.md`) and the test suite claims everything passes. **Do not trust either.** Verify every claim yourself. Your value is in finding what others missed and confirming, with evidence, what really works.

## The package
- **Purpose:** merge the main CSV and the repeat-group CSVs exported from ODK Central into one wide Stata dataset (one row per submission), with variables ordered as in the XLSForm.
- **Current syntax (v1.4.0):**
  `odkrepeatmerge using maincsv, xlsform(filename) [saving(filename [, replace]) replace separator allstring]`
  The older syntax `odkrepeatmerge, formid() xlsform()|formtitle() [formloc() ...]` must still work.
- **Child CSVs** are expected next to the main CSV, named `stem-groupname.csv`.
- **Target:** Stata 14+. Developed and tested only on Stata 17 (Windows).
- **Goal:** submission to the SSC Archive (Kit Baum).
- **Main files:**
  - Package: `odkrepeatmerge.ado`, `odkrepeatmerge.sthlp`, `odkrepeatmerge.pkg`, `stata.toc`
  - Docs and repo files: `README.md`, `LICENSE`, `.gitignore`
  - Tests: `tests/run_all_tests.do` (runner), `tests/regression_*.do`, `tests/edge/E1–E18`
  - Audit folder: `audit/odkrepeatmerge_cert.do`, `audit/examples.do`, `audit/install_test.do`, `audit/AUDIT_REPORT.md`

## Ground rules
1. **Do not modify any existing file** (ado, sthlp, pkg, toc, README, tests, audit files). This is an audit, not a fix.
2. You **may create**:
   - probe do-files in `audit/vscode_probes/` (one self-contained file per probe, each with a header comment saying what it tests);
   - scratch data only under `audit/tmp_vscode/` (already git-ignored);
   - the final report (see "Deliverable").
3. **Check whether Stata is available** (e.g. `stata-mp`, `stata-se`, `stata`, `StataMP-64.exe`, `StataSE-64.exe` in PATH or `C:\Program Files\Stata*`).
   - If it is available, run `do tests/run_all_tests.do` from the repo root and run every probe you write in batch mode. Use the real output as evidence.
   - If it is not available, audit statically, write the probes anyway so the author can run them, and label every finding by confidence (below).
4. **Never present a guess as a result.** Every finding needs evidence: file and line, a code excerpt, and either real output or a clearly marked static argument.
5. **Confidence labels** for each finding:
   - `CONFIRMED`: reproduced by running Stata.
   - `STATIC-HIGH`: certain from reading the code or the Stata documentation.
   - `STATIC-PLAUSIBLE`: likely, needs a run to confirm.
6. **Severity labels:**
   - `BLOCKER`: wrong or lost data, a crash on common input, or something SSC would reject.
   - `MAJOR`: wrong results in realistic edge cases, misleading docs, a broken convention.
   - `MINOR`: robustness or clarity issues with a workaround.
   - `NIT`: style or wording.
7. Also record what you checked and found **correct**. A list of verified-good items is as valuable as the list of bugs.

## Method
1. **Inventory.** List every file. Run `git log --oneline -10`, `git status` and `git rev-parse HEAD`, and note branches (`V1`, `main`) and whether they differ.
2. **Read everything in full:** the ado (every line), help, README, pkg/toc and all tests. Build a written model of the algorithm:
   1. XLSForm parse
   2. repeat tree
   3. CSV discovery
   4. group-prefix rename (`_orm_ungroup`)
   5. reshape / merge, deepest first
   6. variable ordering
   7. save / return
3. **Audit layer by layer** (next section). For each layer, write probes for anything not already covered by a test that asserts **values**, not just names.
4. **Run** the suite and the probes if Stata is available; re-check suspected issues against real output.
5. **Write the report.**

## Audit layers (cover every one; mark anything you could not check as NOT CHECKED, with the reason)

### L1. Repository and packaging
- `.pkg` and `stata.toc` format (`v 3`, `d`, `p`, `f` lines). Does `net install` from `https://raw.githubusercontent.com/armanmahmud1/odkrepeatmerge/main/` work, and does `main` actually contain v1.4.0?
- Version consistency: `*!` line in the ado, the sthlp header, `Distribution-Date`, README, audit report.
- `.gitignore` coverage; tracked junk (e.g. `.claude/settings.local.json`, logs, `.dta`); LICENSE present.

### L2. Syntax and API design
- `syntax` statement vs help vs README: every option, every abbreviation, required vs optional.
- The `using` syntax and the older `formid()/formloc()` syntax: how they interact, rejected combinations, defaults (output location in each syntax).
- Stata conventions: `replace`/`saving()`, never overwriting silently, `rclass` results, exit codes (198, 601, 602, 110, 111, 459, 900), and whether error messages tell the user what to do.

### L3. Core correctness: XLSForm parsing
- Type variants: `begin_repeat` / `begin repeat`, `end_repeat` / `end repeat`, groups, mixed case, extra spaces, blank `name` on end rows.
- Field types: `note`, `calculate`, `select_one` / `select_multiple` (`or_other`), `geopoint` / `geotrace` / `geoshape`, `start` / `end` / `deviceid` metadata, `field-list` groups, `repeat_count`.
- Workbook structure: nested groups inside repeats, the `survey` sheet not being first, `.xls` vs `.xlsx`, a `type` / `name` header in different case, duplicate column headers.

### L4. Core correctness: CSV discovery, reshape, merge
- Child-file naming and discovery from `using`: dots in folder or file names, `.CSV` in uppercase, no extension, relative paths, Windows backslashes and spaces, UNC paths.
- KEY / PARENT_KEY handling: case, `uuid:` prefixes, `[n]` parsing, instance numbers ≥ 10 and ≥ 100, gaps in instance numbers (deleted repeats), rows out of order.
- Reshape naming: default and `separator`, nested innermost-first order, digit-suffix collisions (`q1` / `q11`, `q1` / `q10`), the 32-character limit, `c(maxvar)` limits.
- Merges: orphan children, a parent with no rows, empty child files, a repeat with no own questions, 4+ levels of nesting, sibling repeats at the same level.

### L5. Core correctness: variable ordering and unmatched handling
- The template / sort-key algorithm: verify its logic on paper and with probes, including the longest-prefix matching rule.
- Repeat names that are prefixes of each other; a main question named like a repeat stub plus digits.
- Unmatched reporting: what is listed, what is excluded (ODK Central system columns), and whether `r(unmatched)` is correct.
- `_orm_ungroup`: renaming only when every prefix segment is a group or repeat name; geopoint parts (`gps-Latitude`); split select-multiple columns; collisions with existing names.

### L6. Data integrity (value level)
- No rows lost, no values attached to the wrong instance or submission, on randomized multi-level data. Write a probe that generates random nested data, runs the command, and checks every value against the source CSVs.
- Types: missing vs empty string, leading zeros (with and without `allstring`), long numeric IDs and precision, dates and times as text.
- Text content: UTF-8 (e.g. Bangla text), text with commas, quotes and embedded newlines.

### L7. Stata programming quality
- Stata 14 compatibility of every command, option and function used: list each one with the version it was introduced. Examples:
  - `import delimited` with `varnames()`, `case()`, `bindquote()`, `encoding()`, `stringcols(_all)`
  - `import excel ..., case() allstring`
  - `strtoname()`, `regexm()`/`regexs()`
  - `confirm variable ..., exact`, `confirm new file`
  - Mata `pathsuffix()`
  - `isid`, `levelsof`, `rename` with wildcards
- Quoting and macros:
  - compound quotes;
  - backslashes before backticks;
  - local macro name length (≤ 31);
  - `c(macrolen)` limits on very long varlists (Stata BE / IC);
  - string-expression limits (244 characters in older versions).
- Side effects:
  - `preserve` / `restore`, `tempfile` / `tempname`;
  - no global or Mata pollution;
  - the working directory and settings are unchanged after the command, including on error;
  - output under `quietly` / `noisily`.
- Error paths: does every exit leave the user's data and environment intact?

### L8. Performance and scalability
- Complexity of the ordering loop (variables × questions in ado code) and of the reshapes.
- If Stata is available, time a synthetic large case: e.g. 500 questions, a roster of 30 members × 40 questions, a nested repeat, 5,000 submissions. Report the time per phase if possible.
- Memory, macro-length and `c(maxvar)` behaviour on Stata BE (2,048 variables).

### L9. Help file and README
- SMCL validity: render the help, e.g. `translate odkrepeatmerge.sthlp tmp.txt, translator(smcl2txt)`, and inspect the layout of the column-aligned blocks.
- Every statement in the help and README is true of the code; every example runs as written (apart from the example paths).
- Sections SSC readers expect (Title, Syntax, Description, Options, Remarks, Examples, Stored results, Author); consistency between help and README; clarity for a non-expert ODK user; typos.

### L10. Test suite quality
- Coverage map: which code paths and branches are tested, and which are not.
- Tests that could pass for the wrong reason, e.g. asserting only names, or `capture` hiding the real error code.
- Isolation and cleanup, the robustness of the runner (log handling, cwd restore, picking the repo copy of the ado), and cross-platform issues in the tests themselves.

### L11. SSC submission readiness
- Name not already on SSC; description format (title line `MODULE: Stata module to ...`, abstract, keywords, `Requires:`, author, contact).
- No hard-coded paths in the ado; cross-platform; no undeclared dependencies.
- Review the draft email in `audit/AUDIT_REPORT.md`.

### L12. Safety and UX
- File writes only where the user asked, no shell commands, no deletion of user files.
- The messages printed during a run: helpful and not noisy.
- The defaults are sensible for a typical project layout (raw / instrument / clean folders).

## Deliverable
Write **one file: `audit/README_REPORT_FROM_VSCODE.md`** with exactly these sections:

1. **Header:** date, auditor (you), branch and commit audited (`git rev-parse HEAD`), Stata version used or "Stata not available — static audit", scope.
2. **Executive summary:** verdict (`READY FOR SSC` / `READY AFTER MINOR FIXES` / `NOT READY`), counts by severity, and the top 5 issues in one line each.
3. **Method and environment:** what you ran and what was static only.
4. **Findings table:** `ID (VS-001…) | Layer | Severity | Confidence | File:line | Title`.
5. **Detailed findings.** For each finding:
   - description;
   - evidence (code excerpt with line numbers);
   - reproduction (path to the probe do-file, or inline code);
   - expected vs actual;
   - impact;
   - recommended fix (a concrete code snippet or diff);
   - the test that should be added.
6. **Layer checklist:** L1–L12, each `PASS / ISSUES / NOT CHECKED` with short notes.
7. **Test coverage map:** code path → covering test(s) → gaps.
8. **Verified correct:** everything you checked that works, with how you checked it.
9. **Disagreements with `audit/AUDIT_REPORT.md`:** claims you could not confirm or found wrong.
10. **SSC submission checklist:** item → status.
11. **Open questions and assumptions.**
12. **Appendix:** commands run with summarized output, and the list of probe files with one line each.

Write in clear English. Be specific and concise; no padding. Prefer fewer, well-evidenced findings over many speculative ones, but do not skip a layer.
