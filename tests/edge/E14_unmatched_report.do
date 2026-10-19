/*----------------------------------------------------------------------
   E14_unmatched_report.do
   A CSV column that is not in the XLSForm goes to the end and is
   reported in r(unmatched).
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E14"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "r"
"text"         "a"
"end_repeat"   ""
"text"         "m2"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace
file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,old_q,m1,m2" _n "u1,z,x,y" _n
file close `fh'
file open `fh' using "`d'/f-r.csv", write replace text
file write `fh' "key,parent_key,a,extra" _n "u1/r[1],u1,a1,e1" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace
assert r(n_unmatched) == 2
local um `"`r(unmatched)'"'
local ok1 : list posof "old_q" in um
local ok2 : list posof "extra1" in um
assert `ok1' & `ok2'

use "`d'/f.dta", clear
local want "key m1 a1 m2 old_q extra1"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
display as result "E14 PASS: unmatched variables reported and placed last"
