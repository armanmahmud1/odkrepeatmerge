/*----------------------------------------------------------------------
   E19_four_level_nesting.do
   Tests 4-level nesting (a > b > c > d). The existing test suite only
   goes to 3 levels. Verifies variable names, order, and values.
   Run from the repo root (or via tests/run_all_tests.do).
   Promoted from the independent audit probe P01_four_level_nesting.do.
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
local d "`repo'/tests/tmp_edge/E19"
capture mkdir "`repo'/tests/tmp_edge"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "a"
"text"         "aq"
"begin_repeat" "b"
"text"         "bq"
"begin_repeat" "c"
"text"         "cq"
"begin_repeat" "d"
"text"         "dq"
"end_repeat"   ""
"end_repeat"   ""
"end_repeat"   ""
"end_repeat"   ""
"text"         "m2"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1,m2" _n "u1,M1,M2" _n
file close `fh'
file open `fh' using "`d'/f-a.csv", write replace text
file write `fh' "key,parent_key,aq" _n "u1/a[1],u1,A1" _n "u1/a[2],u1,A2" _n
file close `fh'
file open `fh' using "`d'/f-b.csv", write replace text
file write `fh' "key,parent_key,bq" _n
file write `fh' "u1/a[1]/b[1],u1/a[1],B11" _n
file write `fh' "u1/a[2]/b[1],u1/a[2],B21" _n
file close `fh'
file open `fh' using "`d'/f-c.csv", write replace text
file write `fh' "key,parent_key,cq" _n
file write `fh' "u1/a[1]/b[1]/c[1],u1/a[1]/b[1],C111" _n
file write `fh' "u1/a[2]/b[1]/c[1],u1/a[2]/b[1],C211" _n
file close `fh'
file open `fh' using "`d'/f-d.csv", write replace text
file write `fh' "key,parent_key,dq" _n
file write `fh' "u1/a[1]/b[1]/c[1]/d[1],u1/a[1]/b[1]/c[1],D1111" _n
file write `fh' "u1/a[1]/b[1]/c[1]/d[2],u1/a[1]/b[1]/c[1],D2111" _n
file close `fh'

odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta", replace)

use "`d'/f.dta", clear
* Verify values
assert aq1 == "A1" & aq2 == "A2"
assert bq1_1 == "B11" & bq1_2 == "B21"
assert cq1_1_1 == "C111" & cq1_1_2 == "C211"
assert dq1_1_1_1 == "D1111" & dq2_1_1_1 == "D2111"
* Verify order: m1 before aq1 before bq before cq before dq before m2
unab got : _all
local pm1 : list posof "m1" in got
local paq : list posof "aq1" in got
local pbq : list posof "bq1_1" in got
local pcq : list posof "cq1_1_1" in got
local pdq : list posof "dq1_1_1_1" in got
local pm2 : list posof "m2" in got
assert `pm1' < `paq' & `paq' < `pbq' & `pbq' < `pcq' & `pcq' < `pdq' & `pdq' < `pm2'
* exact order: instances kept together, innermost numbers first
local want "key m1 aq1 bq1_1 cq1_1_1 dq1_1_1_1 dq2_1_1_1 aq2 bq1_2 cq1_1_2 dq1_1_1_2 dq2_1_1_2 m2"
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
assert dq1_1_1_2 == "" & dq2_1_1_2 == ""
display as result "E19 PASS: 4-level nesting, values and order correct"
