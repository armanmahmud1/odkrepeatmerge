/*----------------------------------------------------------------------
   E2_empty_repeat_csv.do
   A repeat group nobody answered: its CSV has a header but no rows.
   Command should still succeed and merge the other groups.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E2"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "q0"
"begin_repeat" "hh"
"text"         "hh_q"
"end_repeat"   "hh_end"
"begin_repeat" "asset"
"text"         "asset_q"
"end_repeat"   "asset_end"
"text"         "q9"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,q0,q9" _n "u1,a,z" _n
file close `fh'
file open `fh' using "`d'/f-hh.csv", write replace text
file write `fh' "key,parent_key,hh_q" _n "u1/hh[1],u1,h1" _n
file close `fh'
file open `fh' using "`d'/f-asset.csv", write replace text
file write `fh' "key,parent_key,asset_q" _n
file close `fh'

odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta", replace)

use "`d'/f.dta", clear
confirm variable key q0 hh_q1 q9
assert hh_q1[1] == "h1" & q0[1] == "a" & q9[1] == "z"
unab got : _all
local p0 : list posof "q0" in got
local ph : list posof "hh_q1" in got
local p9 : list posof "q9" in got
assert `p0' < `ph' & `ph' < `p9'
display as result "E2 PASS: empty repeat-group CSV handled"
