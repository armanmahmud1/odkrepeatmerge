/*----------------------------------------------------------------------
   E9_groups_and_spaced_types.do
   'begin repeat' (space form), begin/end group rows, note rows,
   and two top-level repeats interleaved with main questions.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E9"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin group"  "g1"
"text"         "m2"
"end group"    ""
"begin repeat" "r"
"note"         "n1"
"text"         "r_q"
"end repeat"   ""
"text"         "m3"
"begin_repeat" "s"
"text"         "s_q"
"end_repeat"   ""
"text"         "m4"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1,m2,m3,m4" _n "u1,w,x,y,z" _n
file close `fh'
file open `fh' using "`d'/f-r.csv", write replace text
file write `fh' "key,parent_key,r_q" _n "u1/r[1],u1,r1" _n "u1/r[2],u1,r2" _n
file close `fh'
file open `fh' using "`d'/f-s.csv", write replace text
file write `fh' "key,parent_key,s_q" _n "u1/s[1],u1,s1" _n "u1/s[2],u1,s2" _n
file close `fh'

odkrepeatmerge using "`d'/f.csv", xlsform("`d'/f.xlsx") saving("`d'/f.dta", replace)

use "`d'/f.dta", clear
local want "key m1 m2 r_q1 r_q2 m3 s_q1 s_q2 m4"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
display as result "E9 PASS: groups, notes, spaced types, two top-level repeats"
