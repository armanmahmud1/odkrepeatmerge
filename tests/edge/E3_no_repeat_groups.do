/*----------------------------------------------------------------------
   E3_no_repeat_groups.do
   Form with no repeat groups. Output .dta must equal the main CSV.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E3"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text" "q1"
"text" "q2"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,q1,q2" _n "u1,a,b" _n "u2,c,d" _n
file close `fh'

odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta", replace)

use "`d'/f.dta", clear
local want "key q1 q2"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
assert _N == 2
sort key
assert q1[1] == "a" & q2[2] == "d"
display as result "E3 PASS: form without repeat groups"
