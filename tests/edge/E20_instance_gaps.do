/*----------------------------------------------------------------------
   E20_instance_gaps.do
   Tests gaps in instance numbers (e.g., instances [1], [3], [5] from
   deleted repeats). Verifies that variables are named correctly and
   that values land in the right columns.
   Run from the repo root (or via tests/run_all_tests.do).
   Promoted from the independent audit probe P02_instance_gaps.do.
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
local d "`repo'/tests/tmp_edge/E20"
capture mkdir "`repo'/tests/tmp_edge"
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
file write `fh' "key,m1" _n "u1,x" _n "u2,y" _n
file close `fh'
* Gaps: submission u1 has instances [1],[3],[5]; u2 has [2],[4]
file open `fh' using "`d'/f-r.csv", write replace text
file write `fh' "key,parent_key,q" _n
file write `fh' "u1/r[1],u1,A1" _n
file write `fh' "u1/r[3],u1,A3" _n
file write `fh' "u1/r[5],u1,A5" _n
file write `fh' "u2/r[2],u2,B2" _n
file write `fh' "u2/r[4],u2,B4" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace

use "`d'/f.dta", clear
sort m1
* u1 (m1="x") should have q1=A1, q2=., q3=A3, q4=., q5=A5
* u2 (m1="y") should have q1=., q2=B2, q3=., q4=B4, q5=.
assert q1[1] == "A1" & q3[1] == "A3" & q5[1] == "A5"
assert q2[2] == "B2" & q4[2] == "B4"
* Missing values for missing instances
assert q2[1] == "" & q4[1] == ""
assert q1[2] == "" & q3[2] == "" & q5[2] == ""

display as result "E20 PASS: instance gaps handled correctly"
