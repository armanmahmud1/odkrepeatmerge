/*----------------------------------------------------------------------
   E24_survey_not_first_sheet.do
   XLSForm where the "survey" sheet is not the first sheet. The code
   tries sheet("survey") first and falls back to the first sheet.
   Run from the repo root (or via tests/run_all_tests.do).
   Promoted from the independent audit probe P06_survey_not_first_sheet.do.
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
local d "`repo'/tests/tmp_edge/E24"
capture mkdir "`repo'/tests/tmp_edge"
capture mkdir "`d'"
tempname fh

* Create an Excel file with "choices" as sheet 1 and "survey" as sheet 2
clear
input str20 list_name str20 name str20 label
"yn" "1" "Yes"
"yn" "0" "No"
end
export excel using "`d'/f.xlsx", firstrow(variables) sheet("choices") replace

clear
input str20 type str20 name
"text"         "q1"
"begin_repeat" "r"
"text"         "q2"
"end_repeat"   ""
end
export excel using "`d'/f.xlsx", firstrow(variables) sheet("survey") sheetmodify

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,q1" _n "u1,A" _n
file close `fh'
file open `fh' using "`d'/f-r.csv", write replace text
file write `fh' "key,parent_key,q2" _n "u1/r[1],u1,B" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace

use "`d'/f.dta", clear
assert q1 == "A" & q21 == "B"
display as result "E24 PASS: survey sheet not first - handled correctly"
