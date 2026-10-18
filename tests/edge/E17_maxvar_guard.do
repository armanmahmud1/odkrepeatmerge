/*----------------------------------------------------------------------
   E17_maxvar_guard.do
   A repeat whose wide form exceeds c(maxvar) must stop with r(900)
   and a clear message, before reshape.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E17"
capture mkdir "`d'"
tempname fh

local nq 50
local ni = ceil(c(maxvar) / `nq') + 1

clear
set obs `=`nq' + 2'
generate str20 type = "text"
generate str20 name = "q" + string(_n - 1)
replace type = "begin_repeat" in 1
replace name = "r" in 1
replace type = "end_repeat" in `=`nq' + 2'
replace name = "" in `=`nq' + 2'
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key" _n "u1" _n
file close `fh'

clear
set obs `ni'
generate key        = "u1/r[" + string(_n) + "]"
generate parent_key = "u1"
forvalues i = 1/`nq' {
	generate byte q`i' = 1
}
export delimited using "`d'/f-r.csv", replace

capture noisily odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace
if _rc != 900 {
	display as error "expected r(900) from the maxvar guard; got r(`=_rc')"
	exit 9
}
display as result "E17 PASS: variable-limit guard"
