/*----------------------------------------------------------------------
   E10_separator_nested.do
   separator option with nested repeats: hh > person.
   Names: hh_q_<hh>, p_q_<person>_<hh>. Checks order and values.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E10"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "hh"
"text"         "hh_q"
"begin_repeat" "person"
"text"         "p_q"
"end_repeat"   ""
"end_repeat"   ""
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1" _n "u1,M" _n
file close `fh'
file open `fh' using "`d'/f-hh.csv", write replace text
file write `fh' "key,parent_key,hh_q" _n "u1/hh[1],u1,H1" _n "u1/hh[2],u1,H2" _n
file close `fh'
file open `fh' using "`d'/f-person.csv", write replace text
file write `fh' "key,parent_key,p_q" _n
file write `fh' "u1/hh[1]/person[1],u1/hh[1],P11" _n
file write `fh' "u1/hh[1]/person[2],u1/hh[1],P12" _n
file write `fh' "u1/hh[2]/person[1],u1/hh[2],P21" _n
file close `fh'

odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta", replace) separator

use "`d'/f.dta", clear
local want "key m1 hh_q_1 p_q_1_1 p_q_2_1 hh_q_2 p_q_1_2 p_q_2_2"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
assert hh_q_1 == "H1" & hh_q_2 == "H2"
assert p_q_1_1 == "P11" & p_q_2_1 == "P12" & p_q_1_2 == "P21" & p_q_2_2 == ""
display as result "E10 PASS: separator with nested repeats"
