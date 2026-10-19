/*----------------------------------------------------------------------
   E11_prefix_ten_plus.do
   Questions q1 and q10 in a repeat with 10 instances (default naming).
   q1#10 -> q110 must be ordered as q1 instance 10, not q10 "instance 0".
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E11"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"begin_repeat" "r"
"text"         "q1"
"text"         "q10"
"end_repeat"   ""
"text"         "after"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,after" _n "u1,done" _n
file close `fh'
clear
set obs 10
generate key        = "u1/r[" + string(_n) + "]"
generate parent_key = "u1"
generate q1         = "a" + string(_n)
generate q10        = "b" + string(_n)
export delimited using "`d'/f-r.csv", replace

odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta", replace)

use "`d'/f.dta", clear
local want "key"
forvalues i = 1/10 {
	local want "`want' q1`i' q10`i'"
}
local want "`want' after"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
assert q110 == "a10" & q101 == "b1" & q1010 == "b10"
display as result "E11 PASS: q1/q10 prefix with 10+ instances"
