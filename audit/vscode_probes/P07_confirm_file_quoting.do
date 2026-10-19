/*----------------------------------------------------------------------
   P07_confirm_file_quoting.do
   Paths with spaces: verify confirm file works correctly.
   Run from the repo root.
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
local d "`repo'/audit/tmp_vscode/P07 folder with spaces"
capture mkdir "`repo'/audit/tmp_vscode"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "q1"
"begin_repeat" "r"
"text"         "q2"
"end_repeat"   ""
end
export excel using "`d'/My Form.xlsx", firstrow(variables) replace

file open `fh' using "`d'/main data.csv", write replace text
file write `fh' "key,q1" _n "u1,hello" _n
file close `fh'
file open `fh' using "`d'/main data-r.csv", write replace text
file write `fh' "key,parent_key,q2" _n "u1/r[1],u1,world" _n
file close `fh'

* Test with using syntax (paths with spaces)
capture erase "`d'/main data.dta"
odkrepeatmerge using "`d'/main data.csv", xlsform("`d'/My Form.xlsx") replace

assert q1 == "hello" & q21 == "world"
display as result "P07 PASS: paths with spaces handled correctly"
