# odkrepeatmerge
Merge ODK repeat-group data into one wide Stata dataset, with variables in questionnaire order.

ODK Central exports one CSV for the main form (parent) and one CSV per repeat group (child). `odkrepeatmerge` reads the XLSForm to learn the repeat structure, reshapes every repeat group to wide form, merges it into its parent, and orders all variables to follow the questionnaire. You get one row per submission.

- Nested repeats of any depth
- Data, XLSForm and output can be in different folders
- Works with ODK Central exports with or without "Remove group names"
- Never overwrites a file unless you say `replace`
- Clear error messages instead of silent data loss

Requires Stata 14 or newer (developed and tested on Stata 17).

## Installation
```stata
net install odkrepeatmerge, from("https://raw.githubusercontent.com/armanmahmud1/odkrepeatmerge/main/") replace
help odkrepeatmerge
```

## Syntax
```stata
odkrepeatmerge using maincsv, xlsform(filename) [saving(filename [, replace]) replace separator allstring]
```

### Required
| Item | What to give |
|---|---|
| `using` *maincsv* | The main (parent) CSV with its folder, e.g. `"D:/survey/raw/hh_survey.csv"` (`.csv` may be omitted) |
| `xlsform()` | The XLSForm with its folder, e.g. `"D:/survey/instrument/HH Survey.xlsx"` (`formtitle()` is the older name and still works) |

### Optional
| Option | What it does |
|---|---|
| `saving(file [, replace])` | Save the result under another name or folder. Add `, replace` inside to overwrite |
| `replace` | Overwrite the output file if it exists. The command never overwrites without it, so add it when you run again |
| `separator` | Name variables `q1_11` instead of `q111`. Use it when two questions differ only by trailing digits (`q1`, `q11`); otherwise their names clash and the command stops with an error |
| `allstring` | Import all columns as strings, so codes like `007` don't become `7`. Use `destring` afterwards where needed |

## Files and folders
The data and the XLSForm can be in different folders:
```
D:/survey/raw/hh_survey.csv            main (parent) CSV
D:/survey/raw/hh_survey-member.csv     child CSV, repeat "member"
D:/survey/raw/hh_survey-illness.csv    child CSV, repeat "illness"
D:/survey/instrument/HH Survey.xlsx    XLSForm
```

- **Child CSVs must be in the same folder as the main CSV**, named `stem-groupname.csv`, where `stem` is the main CSV's name without `.csv` (`hh_survey`) and `groupname` is the repeat group's name in the XLSForm. This is how ODK Central names them.
- **The output is saved as `stem.dta` (`hh_survey.dta`) in the current working directory**, so nothing is written to the raw data folder. Use `cd` to choose the folder first, or give the output file with `saving()`.
- Paths can be full paths or relative to the current working directory. Use forward slashes.
- Use the files as downloaded from ODK Central: the main CSV needs a `KEY` column, and each child CSV needs `KEY` and `PARENT_KEY`. Use the XLSForm version that collected the data.

## Examples
```stata
* data and XLSForm in different folders; output in the current directory
cd "D:/survey/clean"
odkrepeatmerge using "D:/survey/raw/hh_survey.csv", xlsform("D:/survey/instrument/HH Survey.xlsx")

* run again and overwrite the previous output
odkrepeatmerge using "D:/survey/raw/hh_survey.csv", xlsform("D:/survey/instrument/HH Survey.xlsx") replace

* paths relative to a project folder; save under another name
cd "D:/survey"
odkrepeatmerge using "raw/hh_survey.csv", xlsform("instrument/HH Survey.xlsx") saving("clean/hh_wide.dta", replace)

* keep codes as strings and use underscore names
odkrepeatmerge using "raw/hh_survey.csv", xlsform("instrument/HH Survey.xlsx") allstring separator replace
```

## Output
- One row per submission; variables follow the order of the XLSForm's survey sheet, with each repeat instance kept together.
- Repeat questions get the instance number added: `name2` is `name` for member 2. For a nested repeat the numbers are innermost first: `ill_type2_1` is illness 2 of member 1 (`ill_type_2_1` with `separator`).
- Instance numbers come from ODK's `KEY` (`member[3]` is always instance 3), so deleted instances or rows out of order do not shift data.
- Columns not in the XLSForm (e.g. from an older form version, or split select-multiple columns) are placed at the end and listed on screen. ODK Central system columns such as `SubmissionDate` go to the end without being listed.
- Child CSVs with no rows are skipped; child rows whose parent is not in the data are dropped and counted on screen.
- `r(fn)`, `r(N)`, `r(k)`, `r(n_repeat)`, `r(n_unmatched)` and `r(unmatched)` describe the result.

## Version history
| Version | Changes |
|---|---|
| 1.4.0 | New `using` syntax: data, XLSForm and output can be in different folders; output defaults to the current directory |
| 1.3.0 | `saving()` / `replace` (no silent overwrite); ODK Central group-name prefixes handled; unmatched variables reported; variable-limit check; `allstring`; stored results; `xlsform()` |
| 1.2.0 | Fixed blank `end_repeat` names, instance numbers ≥ 10, empty repeat files, forms without repeats; `separator` option |
| 1.1.0 | Code clean-up for SSC: `preserve`, tempfiles, no global macros, help file |

## Testing
The `tests/` and `audit/` folders hold 30 test files covering nesting up to four levels, instance numbering, group prefixes, name clashes, error codes, file and folder handling, and the help-file examples. Run them all from the repository root:
```stata
cd "path/to/odkrepeatmerge"
do tests/run_all_tests.do
```

## Issues
Report problems at https://github.com/armanmahmud1/odkrepeatmerge/issues

## Author
Arman Mahmud </br>
Web: [arman-mahmud.com](https://www.arman-mahmud.com)
