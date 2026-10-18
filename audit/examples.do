/*----------------------------------------------------------------------
   audit/examples.do
   The four examples from odkrepeatmerge.sthlp (v1.3.0). Checks that
   each one is accepted by the parser.

   The example files do not exist, so each call should stop with
   r(601) "file not found". A syntax error (r(197)/r(198)) means the
   help-file example is wrong.
----------------------------------------------------------------------*/

capture log close _all
log using "audit/examples.log", replace text name(examples)

version 14

local bad 0

* Example 1: data folder is the current working directory
* (the "cd" line is not run here; the repo root has no such files)
capture noisily odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx")
if inlist(_rc, 197, 198) local bad = `bad' + 1

* Example 2: data folder given with formloc()
capture noisily odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data")
if inlist(_rc, 197, 198) local bad = `bad' + 1

* Example 3: run again and overwrite
capture noisily odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data") replace
if inlist(_rc, 197, 198) local bad = `bad' + 1

* Example 4: saving(), allstring, separator
capture noisily odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data") saving("D:/survey/hh_wide.dta", replace) allstring separator
if inlist(_rc, 197, 198) local bad = `bad' + 1

if `bad' {
	display as error "FAIL: `bad' help-file example(s) have a syntax error"
	log close examples
	exit 198
}
display as result "PASS: all help-file examples parse (file-not-found is expected)"
log close examples
