/*----------------------------------------------------------------------
   E13_saving_replace_results.do
   Output is never overwritten without replace; saving() works;
   r() results are returned.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E13"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "r"
"text"         "a"
"end_repeat"   ""
end
export excel using "`d'/f.xlsx", firstrow(variables) replace
file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1" _n "u1,x" _n "u2,y" _n
file close `fh'
file open `fh' using "`d'/f-r.csv", write replace text
file write `fh' "key,parent_key,a" _n "u1/r[1],u1,a1" _n "u1/r[2],u1,a2" _n
file close `fh'

capture erase "`d'/f.dta"
capture erase "`d'/out.dta"

* 1. first run creates the default file without replace
odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta")
assert r(N) == 2
assert r(k) == 4
assert r(n_repeat) == 1
assert r(n_unmatched) == 0
local fn `"`r(fn)'"'
confirm file `"`fn'"'

* 2. second run without replace must refuse
capture odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta")
if _rc != 602 {
	display as error "expected r(602) when output exists without replace; got r(`=_rc')"
	exit 9
}

* 3. saving() without extension adds .dta; then needs replace
odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/out")
confirm file "`d'/out.dta"
capture odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/out.dta")
if _rc != 602 {
	display as error "expected r(602) for existing saving() file; got r(`=_rc')"
	exit 9
}
odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/out.dta", replace)
assert `"`r(fn)'"' == "`d'/out.dta"

* 4. data in memory untouched
sysuse auto, clear
odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta", replace)
assert _N == 74
confirm variable make

display as result "E13 PASS: replace/saving()/stored results"
