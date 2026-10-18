/*----------------------------------------------------------------------
   E15_allstring.do
   Codes with leading zeros survive with allstring.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E15"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "hhid"
"begin_repeat" "r"
"text"         "pid"
"end_repeat"   ""
end
export excel using "`d'/f.xlsx", firstrow(variables) replace
file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,hhid" _n "u1,007" _n
file close `fh'
file open `fh' using "`d'/f-r.csv", write replace text
file write `fh' "key,parent_key,pid" _n "u1/r[1],u1,0101" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace allstring
use "`d'/f.dta", clear
confirm string variable hhid pid1
assert hhid == "007" & pid1 == "0101"
display as result "E15 PASS: allstring keeps leading zeros"
