/*----------------------------------------------------------------------
   E5_ten_plus_instances.do
   Repeat with 11 instances that also has a nested child group.
   Instance 10 must land in *10, not *2 (string sort of hh[10] < hh[2]).
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E5"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "hh"
"text"         "hh_q"
"begin_repeat" "person"
"text"         "p_q"
"end_repeat"   "person_end"
"end_repeat"   "hh_end"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1" _n "u1,M" _n
file close `fh'

clear
set obs 11
generate key        = "u1/hh[" + string(_n) + "]"
generate parent_key = "u1"
generate hh_q       = "h" + string(_n)
export delimited using "`d'/f-hh.csv", replace

clear
set obs 11
generate key        = "u1/hh[" + string(_n) + "]/person[1]"
generate parent_key = "u1/hh[" + string(_n) + "]"
generate p_q        = "p" + string(_n)
export delimited using "`d'/f-person.csv", replace

odkrepeatmerge, formid("f") formtitle("f.xlsx") formloc("`d'") replace

use "`d'/f.dta", clear
confirm variable hh_q1 hh_q2 hh_q10 hh_q11 p_q1_1 p_q1_2 p_q1_10
foreach i of numlist 1/11 {
	if hh_q`i'[1] != "h`i'" {
		display as error "hh_q`i' = " hh_q`i'[1] "  (expected h`i')"
		exit 9
	}
	if p_q1_`i'[1] != "p`i'" {
		display as error "p_q1_`i' = " p_q1_`i'[1] "  (expected p`i')"
		exit 9
	}
}
display as result "E5 PASS: 10+ instances keep their instance numbers"
