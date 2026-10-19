/*----------------------------------------------------------------------
   P03_rows_out_of_order.do
   Child CSV rows arrive in non-sequential order (e.g., instance [3]
   before [1]). Verifies that the instance number from KEY, not row
   order, determines the column assignment.
   Run from the repo root.
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
local d "`repo'/audit/tmp_vscode/P03"
capture mkdir "`repo'/audit/tmp_vscode"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "m1"
"begin_repeat" "r"
"text"         "q"
"end_repeat"   ""
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,m1" _n "u1,x" _n
file close `fh'
* Rows deliberately out of order: [3] first, then [1], then [2]
file open `fh' using "`d'/f-r.csv", write replace text
file write `fh' "key,parent_key,q" _n
file write `fh' "u1/r[3],u1,THIRD" _n
file write `fh' "u1/r[1],u1,FIRST" _n
file write `fh' "u1/r[2],u1,SECOND" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace

use "`d'/f.dta", clear
* Instance numbers from KEY, not row order
assert q1 == "FIRST"
assert q2 == "SECOND"
assert q3 == "THIRD"

display as result "P03 PASS: row order does not affect column assignment"
