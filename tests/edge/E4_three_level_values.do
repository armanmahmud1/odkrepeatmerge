/*----------------------------------------------------------------------
   E4_three_level_values.do
   Three nested levels (a > b > c). Checks exact variable order AND that
   every value lands in the right variable.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E4"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "a"
"text"         "a_q"
"begin_repeat" "b"
"text"         "b_q"
"begin_repeat" "c"
"text"         "c_q"
"end_repeat"   "c_end"
"end_repeat"   "b_end"
"end_repeat"   "a_end"
"text"         "m2"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1,m2" _n "u1,M1,M2" _n
file close `fh'
file open `fh' using "`d'/f-a.csv", write replace text
file write `fh' "key,parent_key,a_q" _n "u1/a[1],u1,A1" _n "u1/a[2],u1,A2" _n
file close `fh'
file open `fh' using "`d'/f-b.csv", write replace text
file write `fh' "key,parent_key,b_q" _n
file write `fh' "u1/a[1]/b[1],u1/a[1],B11" _n "u1/a[1]/b[2],u1/a[1],B12" _n "u1/a[2]/b[1],u1/a[2],B21" _n
file close `fh'
file open `fh' using "`d'/f-c.csv", write replace text
file write `fh' "key,parent_key,c_q" _n
file write `fh' "u1/a[1]/b[1]/c[1],u1/a[1]/b[1],C111" _n
file write `fh' "u1/a[1]/b[1]/c[2],u1/a[1]/b[1],C112" _n
file write `fh' "u1/a[2]/b[1]/c[1],u1/a[2]/b[1],C211" _n
file close `fh'

odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta", replace)

use "`d'/f.dta", clear
* naming: c_q<c>_<b>_<a>, b_q<b>_<a>, a_q<a>
local want "key m1 a_q1 b_q1_1 c_q1_1_1 c_q2_1_1 b_q2_1 c_q1_2_1 c_q2_2_1"
local want "`want' a_q2 b_q1_2 c_q1_1_2 c_q2_1_2 b_q2_2 c_q1_2_2 c_q2_2_2 m2"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
assert a_q1 == "A1" & a_q2 == "A2"
assert b_q1_1 == "B11" & b_q2_1 == "B12" & b_q1_2 == "B21" & b_q2_2 == ""
assert c_q1_1_1 == "C111" & c_q2_1_1 == "C112" & c_q1_1_2 == "C211"
assert c_q1_2_1 == "" & c_q2_2_2 == ""
display as result "E4 PASS: three-level nesting, order and values"
