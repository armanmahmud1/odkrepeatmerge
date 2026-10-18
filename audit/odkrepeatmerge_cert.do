/*----------------------------------------------------------------------
   audit/odkrepeatmerge_cert.do
   Certification / regression tests for odkrepeatmerge v1.3.0

   Covers:
     T01  Basic single-level repeat group
     T02  Nested repeat groups (2 levels)
     T03  Prefix-collision variable names (q1 vs q10)
     T04  formloc omitted (uses cwd)
     T05  Data in memory preserved after command
     T06  Error: missing formid option
     T07  Error: missing xlsform()/formtitle() option
     T08  Error: non-existent form file
     T09  Global macros not leaked after command
     T10  No orphan intermediate .dta files
----------------------------------------------------------------------*/

capture log close _all
log using "audit/odkrepeatmerge_cert.log", replace text name(cert)

version 14

local startdir "`c(pwd)'"

* ======================================================================
* T01: Basic single-level repeat group
* ======================================================================
display as input _n "=== T01: Basic single-level repeat group ==="

capture mkdir "audit/tmp_t01"
quietly cd "audit/tmp_t01"

clear
input str20 type str20 name
"text" "respondent"
"begin_repeat" "items"
"text" "item_name"
"integer" "item_qty"
"end_repeat" "items_end"
"text" "enumerator"
end
export excel using "form.xlsx", firstrow(variables) replace

clear
input str10 key str20 respondent str10 enumerator
"uuid1" "Alice" "Bob"
"uuid2" "Carol" "Dave"
end
export delimited using "survey.csv", replace

clear
input str20 key str10 parent_key str10 item_name byte item_qty
"uuid1/items[1]" "uuid1" "rice" 5
"uuid1/items[2]" "uuid1" "beans" 3
"uuid2/items[1]" "uuid2" "flour" 10
end
export delimited using "survey-items.csv", replace

odkrepeatmerge, formid("survey") formtitle("form.xlsx") replace

confirm file "survey.dta"
use "survey.dta", clear
confirm variable key respondent enumerator
confirm variable item_name1 item_qty1
display as result "T01 PASS: basic single-level repeat"

erase "survey.dta"
erase "form.xlsx"
erase "survey.csv"
erase "survey-items.csv"
quietly cd "`startdir'"
capture shell rmdir "audit/tmp_t01"


* ======================================================================
* T02: Nested repeat groups (2 levels)
* ======================================================================
display as input _n "=== T02: Nested repeat groups (2 levels) ==="

capture mkdir "audit/tmp_t02"
quietly cd "audit/tmp_t02"

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
export excel using "testform.xlsx", firstrow(variables) replace

clear
input str10 key str10 submissiondate str5 main1 str5 main2
"uuid1" "2024-01-01" "A" "Z"
end
export delimited using "testform.csv", replace

clear
input str20 key str10 parent_key str5 hh_q1 str5 hh_q2
"uuid1/hh[1]" "uuid1" "h1a" "h1b"
"uuid1/hh[2]" "uuid1" "h2a" "h2b"
end
export delimited using "testform-hh.csv", replace

clear
input str30 key str20 parent_key str5 p_q1 str5 p_q2
"uuid1/hh[1]/person[1]" "uuid1/hh[1]" "p11a" "p11b"
"uuid1/hh[1]/person[2]" "uuid1/hh[1]" "p12a" "p12b"
"uuid1/hh[2]/person[1]" "uuid1/hh[2]" "p21a" "p21b"
end
export delimited using "testform-person.csv", replace

odkrepeatmerge, formid("testform") formtitle("testform.xlsx") replace

use "testform.dta", clear
confirm variable key submissiondate main1 main2
describe, short
display as result "T02 PASS: nested repeat groups processed"

erase "testform.dta"
erase "testform.xlsx"
erase "testform.csv"
erase "testform-hh.csv"
erase "testform-person.csv"
quietly cd "`startdir'"
capture shell rmdir "audit/tmp_t02"


* ======================================================================
* T03: Prefix collision (q1 vs q10)
* ======================================================================
display as input _n "=== T03: Prefix collision ==="

capture mkdir "audit/tmp_t03"
quietly cd "audit/tmp_t03"

clear
input str20 type str20 name
"begin_repeat" "rep"
"text" "q1"
"text" "q10"
"end_repeat" "rep_end"
"text" "after_rep"
end
export excel using "testform.xlsx", firstrow(variables) replace

clear
input str10 key str5 after_rep
"uuid1" "done"
end
export delimited using "testform.csv", replace

clear
input str20 key str10 parent_key str5 q1 str5 q10
"uuid1/rep[1]" "uuid1" "a1" "b1"
"uuid1/rep[2]" "uuid1" "a2" "b2"
end
export delimited using "testform-rep.csv", replace

odkrepeatmerge, formid("testform") formtitle("testform.xlsx") replace

use "testform.dta", clear
unab allvars : _all
local expected "key q11 q101 q12 q102 after_rep"
assert "`allvars'" == "`expected'"
display as result "T03 PASS: prefix collision handled correctly"

erase "testform.dta"
erase "testform.xlsx"
erase "testform.csv"
erase "testform-rep.csv"
quietly cd "`startdir'"
capture shell rmdir "audit/tmp_t03"


* ======================================================================
* T04: formloc omitted (use cwd)
* ======================================================================
display as input _n "=== T04: formloc omitted ==="

capture mkdir "audit/tmp_t04"
quietly cd "audit/tmp_t04"

clear
input str20 type str20 name
"begin_repeat" "grp"
"text" "val"
"end_repeat" "grp_end"
end
export excel using "myform.xlsx", firstrow(variables) replace

clear
input str10 key
"uuid1"
end
export delimited using "mysurvey.csv", replace

clear
input str20 key str10 parent_key str5 val
"uuid1/grp[1]" "uuid1" "v1"
end
export delimited using "mysurvey-grp.csv", replace

odkrepeatmerge, formid("mysurvey") formtitle("myform.xlsx") replace
confirm file "mysurvey.dta"
display as result "T04 PASS: formloc omitted, cwd used"

erase "mysurvey.dta"
erase "myform.xlsx"
erase "mysurvey.csv"
erase "mysurvey-grp.csv"
quietly cd "`startdir'"
capture shell rmdir "audit/tmp_t04"


* ======================================================================
* T05: Data in memory preserved after command
* ======================================================================
display as input _n "=== T05: Data preservation ==="

capture mkdir "audit/tmp_t05"
quietly cd "audit/tmp_t05"

clear
input str20 type str20 name
"begin_repeat" "grp"
"text" "val"
"end_repeat" "grp_end"
end
export excel using "f.xlsx", firstrow(variables) replace

clear
input str10 key
"uuid1"
end
export delimited using "f.csv", replace

clear
input str20 key str10 parent_key str5 val
"uuid1/grp[1]" "uuid1" "v1"
end
export delimited using "f-grp.csv", replace

sysuse auto, clear
datasignature set
local orig_sig "`r(datasignature)'"

odkrepeatmerge, formid("f") formtitle("f.xlsx") replace

capture noisily datasignature confirm
if _rc == 0 {
	display as result "T05 PASS: data in memory preserved"
}
else {
	display as error "T05 FAIL: data in memory was destroyed"
	exit 9
}

capture erase "f.dta"
capture erase "f.xlsx"
capture erase "f.csv"
capture erase "f-grp.csv"
quietly cd "`startdir'"
capture shell rmdir "audit/tmp_t05"


* ======================================================================
* T06: Missing formid option
* ======================================================================
display as input _n "=== T06: Missing formid ==="

capture noisily odkrepeatmerge, formtitle("x.xlsx")
if _rc != 0 {
	display as result "T06 PASS: missing formid correctly rejected (rc=`=_rc')"
}
else {
	display as error "T06 FAIL: command should have errored"
}


* ======================================================================
* T07: Missing formtitle option
* ======================================================================
display as input _n "=== T07: Missing formtitle ==="

capture noisily odkrepeatmerge, formid("x") replace
if _rc != 0 {
	display as result "T07 PASS: missing formtitle correctly rejected (rc=`=_rc')"
}
else {
	display as error "T07 FAIL: command should have errored"
}


* ======================================================================
* T08: Non-existent form file
* ======================================================================
display as input _n "=== T08: Non-existent form file ==="

capture noisily odkrepeatmerge, formid("noexist") formtitle("noexist.xlsx") replace
if _rc != 0 {
	display as result "T08 PASS: non-existent file correctly rejected (rc=`=_rc')"
}
else {
	display as error "T08 FAIL: command should have errored"
}


* ======================================================================
* T09: Global macros not leaked
* ======================================================================
display as input _n "=== T09: Global macro leakage ==="

capture mkdir "audit/tmp_t09"
quietly cd "audit/tmp_t09"

clear
input str20 type str20 name
"begin_repeat" "grp"
"text" "val"
"end_repeat" "grp_end"
end
export excel using "f.xlsx", firstrow(variables) replace

clear
input str10 key
"uuid1"
end
export delimited using "f.csv", replace

clear
input str20 key str10 parent_key str5 val
"uuid1/grp[1]" "uuid1" "v1"
end
export delimited using "f-grp.csv", replace

capture macro drop form_id form_name

odkrepeatmerge, formid("f") formtitle("f.xlsx") replace

if "$form_id" == "" & "$form_name" == "" {
	display as result "T09 PASS: no global macros leaked"
}
else {
	display as error "T09 FAIL: globals leaked: form_id='$form_id' form_name='$form_name'"
	exit 9
}

capture erase "f.dta"
capture erase "f.xlsx"
capture erase "f.csv"
capture erase "f-grp.csv"
quietly cd "`startdir'"
capture shell rmdir "audit/tmp_t09"


* ======================================================================
* T10: Intermediate .dta files cleaned up
* ======================================================================
display as input _n "=== T10: Intermediate file cleanup ==="

capture mkdir "audit/tmp_t10"
quietly cd "audit/tmp_t10"

clear
input str20 type str20 name
"begin_repeat" "grp"
"text" "val"
"end_repeat" "grp_end"
end
export excel using "f.xlsx", firstrow(variables) replace

clear
input str10 key
"uuid1"
end
export delimited using "f.csv", replace

clear
input str20 key str10 parent_key str5 val
"uuid1/grp[1]" "uuid1" "v1"
end
export delimited using "f-grp.csv", replace

odkrepeatmerge, formid("f") formtitle("f.xlsx") replace

capture confirm file "grp.dta"
if _rc != 0 {
	display as result "T10 PASS: no orphan intermediate files"
}
else {
	display as error "T10 FAIL: orphan grp.dta left in working directory"
	erase "grp.dta"
}

capture erase "f.dta"
capture erase "f.xlsx"
capture erase "f.csv"
capture erase "f-grp.csv"
quietly cd "`startdir'"
capture shell rmdir "audit/tmp_t10"


* ======================================================================
display as result _n "=== Certification tests complete ==="
log close cert
