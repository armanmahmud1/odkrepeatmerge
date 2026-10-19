/*----------------------------------------------------------------------
   E12_group_prefixed_headers.do
   ODK Central default export: fields inside groups are named group-field
   (main and repeat files). Prefixes must be removed so order is correct,
   Central system columns must not be reported as unmatched, and geopoint
   parts (gps-Latitude) must not steal the name of a real field "latitude".
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E12"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"begin_group"  "g1"
"text"         "m1"
"end_group"    ""
"geopoint"     "gps"
"text"         "latitude"
"begin_repeat" "hh"
"begin_group"  "hg"
"text"         "hh_q"
"end_group"    ""
"integer"      "hh_n"
"end_repeat"   ""
"text"         "m2"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

file open `fh' using "`d'/f.csv", write replace text
file write `fh' "SubmissionDate,g1-m1,gps-Latitude,gps-Longitude,latitude,m2,meta-instanceID,KEY,ReviewState" _n
file write `fh' "2026-01-01T00:00:00Z,x,23.7,90.4,L,y,uuid:a1,uuid:a1,approved" _n
file close `fh'
file open `fh' using "`d'/f-hh.csv", write replace text
file write `fh' "hg-hh_q,hh_n,PARENT_KEY,KEY" _n
file write `fh' "h1,5,uuid:a1,uuid:a1/hh[1]" _n
file write `fh' "h2,6,uuid:a1,uuid:a1/hh[2]" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace
local nu = r(n_unmatched)
local um `"`r(unmatched)'"'

use "`d'/f.dta", clear
confirm variable m1 m2 latitude hh_q1 hh_q2 hh_n1 hh_n2
unab got : _all
local head
forvalues i = 1/8 {
	local w : word `i' of `got'
	local head `head' `w'
}
local want "key m1 latitude hh_q1 hh_n1 hh_q2 hh_n2 m2"
if "`head'" != "`want'" {
	display as error "Order mismatch"
	display as error "  want (first 8): `want'"
	display as error "  got           : `got'"
	exit 9
}
assert hh_q2 == "h2" & hh_n1 == 5 & m1 == "x" & latitude == "L"
* only the two geopoint parts are unmatched (system columns are not listed)
if `nu' != 2 {
	display as error `"expected 2 unmatched (geopoint parts), got `nu': `um'"'
	exit 9
}
display as result "E12 PASS: group-prefixed headers handled"
