/*----------------------------------------------------------------------
   E1_odk_central_realistic.do
   Realistic ODK Central export: uuid: keys, upper-case KEY/PARENT_KEY,
   meta-instanceID + SubmissionDate columns, blank end_repeat name,
   form filename with a space, unequal repeat counts per submission.
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E1"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"start"        "starttime"
"text"         "resp_name"
"begin_repeat" "hh"
"text"         "hh_name"
"integer"      "hh_age"
"end_repeat"   ""
"text"         "comment"
end
export excel using "`d'/Central Form.xlsx", firstrow(variables) sheet("survey") replace

local u1 "uuid:3f2a9c1e-0b7d-4c55-9e61-1a2b3c4d5e01"
local u2 "uuid:3f2a9c1e-0b7d-4c55-9e61-1a2b3c4d5e02"
file open `fh' using "`d'/central.csv", write replace text
file write `fh' "SubmissionDate,starttime,resp_name,comment,meta-instanceID,KEY" _n
file write `fh' "2026-01-05T10:00:00.000Z,2026-01-05T09:50:00.000+06:00,Arif,ok,`u1',`u1'" _n
file write `fh' "2026-01-06T11:00:00.000Z,2026-01-06T10:40:00.000+06:00,Chand,fine,`u2',`u2'" _n
file close `fh'
file open `fh' using "`d'/central-hh.csv", write replace text
file write `fh' "hh_name,hh_age,PARENT_KEY,KEY" _n
file write `fh' "Arif,40,`u1',`u1'/hh[1]" _n
file write `fh' "Bina,35,`u1',`u1'/hh[2]" _n
file write `fh' "Chand,60,`u2',`u2'/hh[1]" _n
file close `fh'

odkrepeatmerge using "`d'/central.csv", xlsform("`d'/Central Form.xlsx") saving("`d'/central.dta", replace)

use "`d'/central.dta", clear
describe, short
confirm variable key resp_name comment hh_name1 hh_name2 hh_age1 hh_age2
assert _N == 2
sort resp_name
assert hh_name1[1] == "Arif"  & hh_name2[1] == "Bina" & hh_age2[1] == 35
assert hh_name1[2] == "Chand" & hh_name2[2] == ""     & missing(hh_age2[2])

unab got : _all
foreach pair in "resp_name hh_name1" "hh_name1 hh_age1" "hh_age1 hh_name2" "hh_name2 comment" {
	local a : word 1 of `pair'
	local b : word 2 of `pair'
	local pa : list posof "`a'" in got
	local pb : list posof "`b'" in got
	if !(`pa' < `pb') {
		display as error "`a' should come before `b'.  Order: `got'"
		exit 9
	}
}
display as result "E1 PASS: realistic ODK Central export"
