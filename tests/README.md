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
| `edge/` | `E1`–`E27`: one edge case per file, built from synthetic data: nesting up to 4 levels, instance gaps and rows out of order, sibling repeats, empty repeat CSVs, forms without repeats, ≥ 10 instances, group-prefixed headers, `separator`, `allstring`, `saving()`/`replace`, variable limits, paths with spaces, error messages, and the findings of the independent audit (`E27`) |
| `certification/` | Core behaviour (data in memory preserved, no global macros or stray files left), every help-file example parses, and `net install` / `ado uninstall` from the repository's `stata.toc` and `.pkg` |
| `realdata/` | Real ODK Central exports, checked cell by cell (see below) |

## Real data (`realdata/`)

Exports from real test forms. Names, phone numbers, addresses, device IDs and GPS coordinates were replaced by placeholders; the structure, `KEY`s and codes are unchanged.

| Data set | What it tests |
|---|---|
| `nested_5level` | Five nested repeats (classes > students > attendance > subjects > resources) |
| `sample_form` | Repeats inside groups, a 3-level and a 2-level nest, notes, a hyphenated question name (`start-geopoint`), numeric import precision, `separator` |
| `select_multiple` | Split select_multiple columns (`food/1`, `food/10`) inside a nested repeat: stops without `separator`, correct with it |
| `rmg_survey` | Large real form: 5 repeats, groups nested 5 deep, group-prefixed headers longer than 80 characters |
| `duplicate_names` | Two sibling repeats that both contain a question `resource`: must stop with r(110) |

`realdata_tests.do` checks that every value in every repeat-group CSV appears in the output under the expected wide name, in the row of its submission.
