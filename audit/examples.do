/*----------------------------------------------------------------------
   audit/examples.do
   The examples from odkrepeatmerge.sthlp (v1.4.0). Checks that
   each one is accepted by the parser.

   The example files do not exist, so each call should stop with
   r(601) "file not found". A syntax error (r(197)/r(198)) means the
   help-file example is wrong.
----------------------------------------------------------------------*/

capture log close _all
log using "audit/examples.log", replace text name(examples)

version 14

local bad 0

* Example 1: data and XLSForm in different folders (the "cd" line is not run)
capture noisily odkrepeatmerge using "D:/survey/raw/hh_survey.csv", xlsform("D:/survey/instrument/HH Survey.xlsx")
if inlist(_rc, 197, 198) local bad = `bad' + 1

* Example 2: run again and overwrite
capture noisily odkrepeatmerge using "D:/survey/raw/hh_survey.csv", xlsform("D:/survey/instrument/HH Survey.xlsx") replace
if inlist(_rc, 197, 198) local bad = `bad' + 1

* Example 3: relative paths, saving()
capture noisily odkrepeatmerge using "raw/hh_survey.csv", xlsform("instrument/HH Survey.xlsx") saving("clean/hh_wide.dta", replace)
if inlist(_rc, 197, 198) local bad = `bad' + 1

* Example 4: allstring, separator
capture noisily odkrepeatmerge using "raw/hh_survey.csv", xlsform("instrument/HH Survey.xlsx") allstring separator replace
if inlist(_rc, 197, 198) local bad = `bad' + 1

* Older syntax (documented under "Older syntax")
capture noisily odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/raw")
if inlist(_rc, 197, 198) local bad = `bad' + 1

if `bad' {
	display as error "FAIL: `bad' help-file example(s) have a syntax error"
	log close examples
	exit 198
}
display as result "PASS: all help-file examples parse (file-not-found is expected)"
log close examples
