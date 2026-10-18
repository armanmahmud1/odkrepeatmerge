/*----------------------------------------------------------------------
   E8_digit_suffix_collision.do
   Questions q1 and q11 in a repeat with 11 instances.
   Default naming gives q1 #11 -> q111 and q11 #1 -> q111 (same name):
   must error clearly. With separator: q1_11 vs q11_1.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E8"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"begin_repeat" "r"
"text"         "q1"
"text"         "q11"
"end_repeat"   "r_end"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key" _n "u1" _n
file close `fh'
clear
set obs 11
generate key        = "u1/r[" + string(_n) + "]"
generate parent_key = "u1"
generate q1         = "a" + string(_n)
generate q11        = "b" + string(_n)
export delimited using "`d'/f-r.csv", replace

* default naming: must stop with an error, not lose data silently
capture odkrepeatmerge, formid("f") formtitle("f.xlsx") formloc("`d'") replace
if _rc == 0 {
	display as error "Default naming should have stopped on the q1#11 / q11#1 collision"
	exit 9
}
display as text "default naming correctly refused (r`=_rc')"

* separator option: q1_11 and q11_1 are distinct
odkrepeatmerge, formid("f") formtitle("f.xlsx") formloc("`d'") separator replace
use "`d'/f.dta", clear
local want "key"
forvalues i = 1/11 {
	local want "`want' q1_`i' q11_`i'"
}
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
assert q1_11 == "a11" & q11_1 == "b1" & q1_1 == "a1" & q11_11 == "b11"
display as result "E8 PASS: collision refused by default, resolved by separator"
