/*----------------------------------------------------------------------
   E7_uppercase_key_columns.do
   ODK Central writes KEY / PARENT_KEY in upper case. Isolated check.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E7"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "r"
"text"         "a"
"end_repeat"   "r_end"
"text"         "m2"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "m1,m2,KEY" _n "x,y,u1" _n
file close `fh'
file open `fh' using "`d'/f-r.csv", write replace text
file write `fh' "a,PARENT_KEY,KEY" _n "a1,u1,u1/r[1]" _n "a2,u1,u1/r[2]" _n
file close `fh'

odkrepeatmerge, formid("f") formtitle("f.xlsx") formloc("`d'") replace

use "`d'/f.dta", clear
local want "key m1 a1 a2 m2"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
assert a1 == "a1" & a2 == "a2"
display as result "E7 PASS: upper-case KEY/PARENT_KEY"
