/*----------------------------------------------------------------------
   E16_xlsform_synonym.do
   xlsform() and formtitle() are synonyms; conflicting or missing
   values are rejected.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E16"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text" "q1"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace
file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,q1" _n "u1,a" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace
odkrepeatmerge, formid("f") formtitle("f.xlsx") formloc("`d'") replace
odkrepeatmerge, formid("f") xlsform("f.xlsx") formtitle("f.xlsx") formloc("`d'") replace

capture odkrepeatmerge, formid("f") xlsform("f.xlsx") formtitle("g.xlsx") formloc("`d'") replace
assert _rc == 198
capture odkrepeatmerge, formid("f") formloc("`d'") replace
assert _rc == 198
display as result "E16 PASS: xlsform()/formtitle() synonym"
