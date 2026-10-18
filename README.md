# odkrepeatmerge
Merge ODK repeat-group data into one wide Stata dataset, with variables in questionnaire order.

ODK Central exports one CSV for the main form (parent) and one CSV per repeat group (child). `odkrepeatmerge` reads the XLSForm to learn the repeat structure, reshapes every repeat group to wide form, merges it into its parent, and orders all variables to follow the questionnaire. You get one row per submission.

Requires Stata 14 or newer (developed and tested on Stata 17).

## Installation
```stata
net install odkrepeatmerge, from("https://raw.githubusercontent.com/armanmahmud1/odkrepeatmerge/main/") replace
help odkrepeatmerge
```

## Before you run
Put all input files in **one folder** (the data folder):

```
D:/survey/data/
    hh_survey.csv            main (parent) CSV:  formid.csv
    hh_survey-member.csv     child CSV per repeat group:  formid-groupname.csv
    hh_survey-illness.csv
    HH Survey.xlsx           the XLSForm used to collect the data
```

`odkrepeatmerge` looks for these files in the `formloc()` folder. **If you don't give `formloc()`, it looks in the current working directory, so that directory must be the data folder.** Use one of these:

```stata
* Option 1: change to the data folder first
cd "D:/survey/data"
odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx")

* Option 2: point to the data folder with formloc()
odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data")
```

Either way, the result is saved in the data folder as `formid.dta` (`hh_survey.dta` here), unless you use `saving()`.

## Syntax
```stata
odkrepeatmerge, formid(string) xlsform(filename) [formloc(path) saving(filename [, replace]) replace separator allstring]
```

### Required options
| Option | What to give |
|---|---|
| `formid()` | The form ID: the main CSV's name without `.csv` (also `form_id` on the XLSForm's settings sheet). Child files must be named `formid-groupname.csv` |
| `xlsform()` | The XLSForm file name, e.g. `"HH Survey.xlsx"`. Only the file name; the folder comes from `formloc()` or the current directory. (`formtitle()` is the older name and still works) |

### Optional options
| Option | What it does |
|---|---|
| `formloc()` | Data folder holding the XLSForm and CSVs. Default: current working directory. Use forward slashes, e.g. `formloc("D:/My drive/survey")` |
| `saving(file [, replace])` | Save the result under another name. A name without a folder is saved in the current working directory. Add `, replace` inside to overwrite |
| `replace` | Overwrite the output file if it exists. The command never overwrites without it, so add it when you run again |
| `separator` | Name variables `q1_11` instead of `q111`. Use it when two questions differ only by trailing digits (`q1`, `q11`); otherwise their names clash and the command stops with an error |
| `allstring` | Import all columns as strings, so codes like `007` don't become `7`. Use `destring` afterwards where needed |

## Examples
```stata
* data folder is the current working directory
cd "D:/survey/data"
odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx")

* data folder given with formloc()
odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data")

* run again and overwrite the previous output
odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data") replace

* save under another name, keep codes as strings, use underscore names
odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data") saving("D:/survey/hh_wide.dta", replace) allstring separator
use "D:/survey/hh_wide.dta", clear
```

## Output
- One row per submission; variables follow the order of the XLSForm's survey sheet.
- Repeat questions get the instance number added: `age2` is `age` for member 2. For a nested repeat the numbers are innermost first: `ill_type2_1` is illness 2 of member 1 (`ill_type_2_1` with `separator`).
- Columns not in the XLSForm are placed at the end and listed on screen.
- ODK Central exports with or without "Remove group names" both work.
- `r(fn)`, `r(N)`, `r(k)`, `r(n_repeat)`, `r(n_unmatched)` and `r(unmatched)` describe the result.

## Testing
```stata
cd "path/to/odkrepeatmerge"
do tests/run_all_tests.do
```

## Issues
Report problems at https://github.com/armanmahmud1/odkrepeatmerge/issues

## Author
Arman Mahmud </br>
Web: [arman-mahmud.com](https://www.arman-mahmud.com)
