/*----------------------------------------------------------------------
   E25_paths_with_spaces.do
   using syntax with spaces in the folder, the main CSV name and the
   XLSForm name. Child file "main data-r.csv" must be found.
   Run from the repo root (or via tests/run_all_tests.do).
   Promoted from the independent audit probe P07_confirm_file_quoting.do
   (fixed: the probe asserted before opening the output, and wrote the
   output into the repo root).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E25 folder with spaces"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "q1"
"begin_repeat" "r"
"text"         "q2"
"end_repeat"   ""
end
export excel using "`d'/My Form.xlsx", firstrow(variables) replace

file open `fh' using "`d'/main data.csv", write replace text
file write `fh' "key,q1" _n "u1,hello" _n
file close `fh'
file open `fh' using "`d'/main data-r.csv", write replace text
file write `fh' "key,parent_key,q2" _n "u1/r[1],u1,world" _n
file close `fh'

* run from inside the folder so the default output (main data.dta) lands there
quietly cd "`d'"
odkrepeatmerge using "`d'/main data.csv", xlsform("`d'/My Form.xlsx") replace
assert `"`r(fn)'"' == "main data.dta"
use "`d'/main data.dta", clear
assert q1 == "hello" & q21 == "world"
quietly cd "`repo'"
display as result "E25 PASS: paths with spaces handled correctly"
