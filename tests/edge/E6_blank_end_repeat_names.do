/*----------------------------------------------------------------------
   E6_blank_end_repeat_names.do
   end_repeat rows with a blank name column - the normal XLSForm style.
   Questions after the repeat must still be ordered correctly.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E6"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "r1"
"text"         "a"
"end_repeat"   ""
"text"         "m2"
"begin_repeat" "r2"
"text"         "b"
"end_repeat"   ""
"text"         "m3"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1,m2,m3" _n "u1,x,y,z" _n
file close `fh'
file open `fh' using "`d'/f-r1.csv", write replace text
file write `fh' "key,parent_key,a" _n "u1/r1[1],u1,a1" _n "u1/r1[2],u1,a2" _n
file close `fh'
file open `fh' using "`d'/f-r2.csv", write replace text
file write `fh' "key,parent_key,b" _n "u1/r2[1],u1,b1" _n "u1/r2[2],u1,b2" _n
file close `fh'

odkrepeatmerge, formid("f") formtitle("f.xlsx") formloc("`d'") replace

use "`d'/f.dta", clear
local want "key m1 a1 a2 m2 b1 b2 m3"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}
display as result "E6 PASS: blank end_repeat names"
