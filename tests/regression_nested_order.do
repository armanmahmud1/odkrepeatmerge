clear all
set more off
capture log close

local repo "D:/odkrepeatmerge"
local testdir "`repo'/tests/tmp_nested_order"

capture mkdir "`repo'/tests"
capture mkdir "`testdir'"
log using "`testdir'/regression.log", replace text

adopath ++ "`repo'"

clear
input str20 type str20 name
"text" "submissiondate"
"text" "main1"
"begin_repeat" "hh"
"text" "hh_q1"
"begin_repeat" "person"
"text" "p_q1"
"text" "p_q2"
"end_repeat" "person_end"
"text" "hh_q2"
"end_repeat" "hh_end"
"text" "main2"
end
export excel using "`testdir'/testform.xlsx", firstrow(variables) replace

clear
input str10 key str10 submissiondate str5 main1 str5 main2
"uuid1" "2024-01-01" "A" "Z"
end
export delimited using "`testdir'/testform.csv", replace

clear
input str20 key str10 parent_key str5 hh_q1 str5 hh_q2
"uuid1/hh[1]" "uuid1" "h1a" "h1b"
"uuid1/hh[2]" "uuid1" "h2a" "h2b"
end
export delimited using "`testdir'/testform-hh.csv", replace

clear
input str30 key str20 parent_key str5 p_q1 str5 p_q2
"uuid1/hh[1]/person[1]" "uuid1/hh[1]" "p11a" "p11b"
"uuid1/hh[1]/person[2]" "uuid1/hh[1]" "p12a" "p12b"
"uuid1/hh[2]/person[1]" "uuid1/hh[2]" "p21a" "p21b"
end
export delimited using "`testdir'/testform-person.csv", replace

odkrepeatmerge, formid("testform") formtitle("testform.xlsx") formloc("`testdir'")

use "`testdir'/testform.dta", clear
unab allvars : _all

local expected ///
    "key submissiondate main1 " + ///
    "hh_q11 p_q11_1 p_q21_1 p_q12_1 p_q22_1 hh_q21 " + ///
    "hh_q12 p_q11_2 p_q21_2 p_q12_2 p_q22_2 hh_q22 main2"

assert "`allvars'" == "`expected'"

display "PASS: nested repeat variables follow questionnaire order"
log close
exit 0
