# Tests for odkrepeatmerge

Run everything from the repository root in Stata:

```stata
do tests/run_all_tests.do
```

The runner puts the repository copy of `odkrepeatmerge.ado` first on the adopath (so an older installed copy is not tested), runs every `.do` file in the folders below, and ends with a PASS/FAIL summary. Each test can also be run on its own from the repository root.

All generated files (CSVs, XLSForms, `.dta` output, logs) go to `tests/output/`, which is git-ignored and recreated on every run. The full log is `tests/output/run_all_tests.log`.

| Folder | What it covers |
|---|---|
| `regression/` | Variable order for nested repeats; names that share a prefix (`q1`, `q10`) |
| `edge/` | `E1`–`E28`: one edge case per file, built from synthetic data: nesting up to 4 levels, instance gaps and rows out of order, sibling repeats, empty repeat CSVs, forms without repeats, ≥ 10 instances, group-prefixed headers, `separator`, `allstring`, `saving()`/`replace`, variable limits, paths with spaces, error messages, and the findings of the two independent audits (`E27`, `E28`) |
| `certification/` | Core behaviour (data in memory preserved, no global macros or stray files left), every help-file example parses, and `net install` / `ado uninstall` from the repository's `stata.toc` and `.pkg` |
