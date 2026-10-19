/*----------------------------------------------------------------------
   E22_sibling_repeats_values.do
   Two sibling repeats at the same level, verifying data values (not
   just variable order). Tests E6 and E9 verify order but not values.
   Run from the repo root (or via tests/run_all_tests.do).
   Promoted from the independent audit probe P04_sibling_repeats_values.do.
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
local d "`repo'/tests/tmp_edge/E22"
capture mkdir "`repo'/tests/tmp_edge"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "roster"
"text"         "name"
"end_repeat"   ""
"text"         "m2"
"begin_repeat" "asset"
"text"         "item"
"end_repeat"   ""
"text"         "m3"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1,m2,m3" _n "u1,before,between,after" _n
file close `fh'
file open `fh' using "`d'/f-roster.csv", write replace text
file write `fh' "key,parent_key,name" _n
file write `fh' "u1/roster[1],u1,Alice" _n "u1/roster[2],u1,Bob" _n
file close `fh'
file open `fh' using "`d'/f-asset.csv", write replace text
file write `fh' "key,parent_key,item" _n
file write `fh' "u1/asset[1],u1,Radio" _n "u1/asset[2],u1,Phone" _n "u1/asset[3],u1,Bike" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace

use "`d'/f.dta", clear
* Check values
assert m1 == "before" & m2 == "between" & m3 == "after"
assert name1 == "Alice" & name2 == "Bob"
assert item1 == "Radio" & item2 == "Phone" & item3 == "Bike"
* Check order
local want "key m1 name1 name2 m2 item1 item2 item3 m3"
unab got : _all
if "`got'" != "`want'" {
	display as error "Variable order mismatch"
	display as error "  want: `want'"
	display as error "  got : `got'"
	exit 9
}

display as result "E22 PASS: sibling repeats with correct values and order"
