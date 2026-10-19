/*----------------------------------------------------------------------
   E18_using_separate_folders.do
   New syntax (v1.4.0): odkrepeatmerge using main.csv, xlsform(path)
   - data in raw/, XLSForm in instrument/, output in the current
     working directory (out/); nothing is written to raw/
   - using without .csv, relative paths, saving()
   - conflicts: using + formid()/formloc(); neither using nor formid()
   - older syntax with a full xlsform() path plus formloc()
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E18"
capture mkdir "`d'"
capture mkdir "`d'/raw"
capture mkdir "`d'/instrument"
capture mkdir "`d'/out"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "member"
"text"         "name"
"begin_repeat" "illness"
"text"         "ill_type"
"end_repeat"   ""
"end_repeat"   ""
"text"         "m2"
end
export excel using "`d'/instrument/HH Survey.xlsx", firstrow(variables) sheet("survey") replace

file open `fh' using "`d'/raw/hh_survey.csv", write replace text
file write `fh' "m1,m2,KEY" _n "x,y,u1" _n
file close `fh'
file open `fh' using "`d'/raw/hh_survey-member.csv", write replace text
file write `fh' "name,PARENT_KEY,KEY" _n "A,u1,u1/member[1]" _n "B,u1,u1/member[2]" _n
file close `fh'
file open `fh' using "`d'/raw/hh_survey-illness.csv", write replace text
file write `fh' "ill_type,PARENT_KEY,KEY" _n
file write `fh' "flu,u1/member[1],u1/member[1]/illness[1]" _n
file write `fh' "fever,u1/member[1],u1/member[1]/illness[2]" _n
file close `fh'

capture erase "`d'/out/hh_survey.dta"
capture erase "`d'/raw/hh_survey.dta"

* 1. absolute paths; output goes to the current working directory
quietly cd "`d'/out"
odkrepeatmerge using "`d'/raw/hh_survey.csv", xlsform("`d'/instrument/HH Survey.xlsx")
assert `"`r(fn)'"' == "hh_survey.dta"
assert r(N) == 1
confirm file "`d'/out/hh_survey.dta"
capture confirm file "`d'/raw/hh_survey.dta"
if !_rc {
	display as error "output was written to the raw data folder"
	exit 9
}
use "`d'/out/hh_survey.dta", clear
local want "key m1 name1 ill_type1_1 ill_type2_1 name2 ill_type1_2 ill_type2_2 m2"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
assert name1 == "A" & name2 == "B" & ill_type2_1 == "fever" & ill_type1_2 == ""

* 2. run again without replace must refuse; with replace works
capture odkrepeatmerge using "`d'/raw/hh_survey.csv", xlsform("`d'/instrument/HH Survey.xlsx")
assert _rc == 602
odkrepeatmerge using "`d'/raw/hh_survey.csv", xlsform("`d'/instrument/HH Survey.xlsx") replace

* 3. relative paths, no .csv extension, saving()
quietly cd "`d'"
odkrepeatmerge using "raw/hh_survey", xlsform("instrument/HH Survey.xlsx") saving("out/wide.dta", replace)
confirm file "`d'/out/wide.dta"

* 4. conflicts and missing input
capture odkrepeatmerge using "raw/hh_survey.csv", xlsform("instrument/HH Survey.xlsx") formid("hh_survey") replace
assert _rc == 198
capture odkrepeatmerge using "raw/hh_survey.csv", xlsform("instrument/HH Survey.xlsx") formloc("raw") replace
assert _rc == 198
capture odkrepeatmerge, xlsform("instrument/HH Survey.xlsx") replace
assert _rc == 198
capture odkrepeatmerge using "raw/nofile.csv", xlsform("instrument/HH Survey.xlsx") replace
assert _rc == 601

* 5. older syntax: full xlsform() path is not joined with formloc()
odkrepeatmerge, formid("hh_survey") formloc("`d'/raw") xlsform("`d'/instrument/HH Survey.xlsx") saving("`d'/out/old.dta", replace)
confirm file "`d'/out/old.dta"

quietly cd "`repo'"
display as result "E18 PASS: using syntax with separate data/instrument/output folders"
