clear all
set more off
capture log close

local repo "D:/odkrepeatmerge"
local testdir "`repo'/tests/tmp_prefix_collision"

capture mkdir "`repo'/tests"
capture mkdir "`testdir'"
log using "`testdir'/regression.log", replace text

adopath ++ "`repo'"

clear
input str20 type str20 name
"begin_repeat" "rep"
"text" "q1"
"text" "q10"
"end_repeat" "rep_end"
"text" "after_rep"
end
export excel using "`testdir'/testform.xlsx", firstrow(variables) replace

clear
input str10 key str5 after_rep
"uuid1" "done"
end
export delimited using "`testdir'/testform.csv", replace

clear
input str20 key str10 parent_key str5 q1 str5 q10
"uuid1/rep[1]" "uuid1" "a1" "b1"
"uuid1/rep[2]" "uuid1" "a2" "b2"
end
export delimited using "`testdir'/testform-rep.csv", replace

odkrepeatmerge, formid("testform") formtitle("testform.xlsx") formloc("`testdir'")

use "`testdir'/testform.dta", clear
unab allvars : _all

local expected "key q11 q101 q12 q102 after_rep"
assert "`allvars'" == "`expected'"

display "PASS: repeat stems with shared prefixes stay in questionnaire order"
log close
exit 0
