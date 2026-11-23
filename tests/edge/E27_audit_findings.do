/*----------------------------------------------------------------------
   E27_audit_findings.do
   Regression tests for the issues found in the independent audit of
   v1.4.0 (fixed in 1.5.0):
     a  q (instances 1, 12) and q1 (instance 1) in two repeats: q12 must
        stay with q, not be credited to q1 instance 2
     b  a column not in the form (q15) is reported, not filed as q1 #5
     c  separator: outer hh_1 vs nested hh gives a clear r(110)
     d  question names longer than 32 characters are matched
     e  main CSV with no rows: clear r(2000)
     f  saving() to a non-.dta file is refused (r(198))
     g  stem containing a dot, .csv omitted
     h  duplicate KEY in a repeat CSV: r(459)
     i  variables get the XLSForm label, repeat instance in brackets
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/output"
capture mkdir "`repo'/tests/output/edge"
local d "`repo'/tests/output/edge/E27"
capture mkdir "`d'"
tempname fh

* --- a, b, i: q / q1 in two repeats, extra column q15, labels ------------
clear
input str20 type str40 name str40 label
"text"         "m1"   "First main question"
"begin_repeat" "r1"   ""
"text"         "q"    "Question q"
"end_repeat"   ""     ""
"begin_repeat" "r2"   ""
"text"         "q1"   "Question q-one"
"end_repeat"   ""     ""
end
export excel using "`d'/a.xlsx", firstrow(variables) sheet("survey") replace
file open `fh' using "`d'/a.csv", write replace text
file write `fh' "m1,q15,KEY" _n "x,extra,u1" _n
file close `fh'
file open `fh' using "`d'/a-r1.csv", write replace text
file write `fh' "q,PARENT_KEY,KEY" _n "A1,u1,u1/r1[1]" _n "A12,u1,u1/r1[12]" _n
file close `fh'
file open `fh' using "`d'/a-r2.csv", write replace text
file write `fh' "q1,PARENT_KEY,KEY" _n "B1,u1,u1/r2[1]" _n
file close `fh'
odkrepeatmerge using "`d'/a.csv", xlsform("`d'/a.xlsx") saving("`d'/a.dta", replace) allstring
assert r(n_unmatched) == 1 & "`r(unmatched)'" == "q15"
use "`d'/a.dta", clear
unab got : _all
local want "key m1 q1 q12 q11 q15"
if "`got'" != "`want'" {
	display as error "a: order want `want', got `got'"
	exit 9
}
assert q1 == "A1" & q12 == "A12" & q11 == "B1"
assert "`: variable label q12'" == "[12] Question q"
assert "`: variable label m1'" == "First main question"

* --- c: separator clash hh_1 (outer) vs hh (nested) ---------------------
clear
input str20 type str20 name
"begin_repeat" "o"
"text"         "hh_1"
"begin_repeat" "n"
"text"         "hh"
"end_repeat"   ""
"end_repeat"   ""
end
export excel using "`d'/c.xlsx", firstrow(variables) replace
file open `fh' using "`d'/c.csv", write replace text
file write `fh' "KEY" _n "u1" _n
file close `fh'
file open `fh' using "`d'/c-o.csv", write replace text
file write `fh' "hh_1,PARENT_KEY,KEY" _n "x,u1,u1/o[1]" _n
file close `fh'
file open `fh' using "`d'/c-n.csv", write replace text
file write `fh' "hh,PARENT_KEY,KEY" _n "y,u1/o[1],u1/o[1]/n[1]" _n
file close `fh'
capture noisily odkrepeatmerge using "`d'/c.csv", xlsform("`d'/c.xlsx") saving("`d'/c.dta", replace) separator
assert _rc == 110

* --- d: question name longer than 32 characters --------------------------
clear
input str20 type str60 name
"text" "a_very_long_question_name_exceeding_32_chars"
"text" "m2"
end
export excel using "`d'/dd.xlsx", firstrow(variables) replace
file open `fh' using "`d'/dd.csv", write replace text
file write `fh' "a_very_long_question_name_exceeding_32_chars,m2,KEY" _n "x,y,u1" _n
file close `fh'
odkrepeatmerge using "`d'/dd.csv", xlsform("`d'/dd.xlsx") saving("`d'/dd.dta", replace)
assert r(n_unmatched) == 0

* --- e: main CSV with a header but no rows -------------------------------
file open `fh' using "`d'/e.csv", write replace text
file write `fh' "m1,KEY" _n
file close `fh'
capture noisily odkrepeatmerge using "`d'/e.csv", xlsform("`d'/dd.xlsx") saving("`d'/e.dta", replace)
assert _rc == 2000

* --- f: refuse to write a non-.dta output --------------------------------
capture noisily odkrepeatmerge using "`d'/dd.csv", xlsform("`d'/dd.xlsx") saving("`d'/dd.csv", replace)
assert _rc == 198
confirm file "`d'/dd.csv"

* --- g: stem with a dot, .csv omitted ------------------------------------
copy "`d'/dd.csv" "`d'/survey.v2.csv", replace
odkrepeatmerge using "`d'/survey.v2", xlsform("`d'/dd.xlsx") saving("`d'/g.dta", replace)
assert r(N) == 1

* --- h: duplicate KEY in a repeat CSV -------------------------------------
file open `fh' using "`d'/a-r2.csv", write replace text
file write `fh' "q1,PARENT_KEY,KEY" _n "B1,u1,u1/r2[1]" _n "B1b,u1,u1/r2[1]" _n
file close `fh'
capture noisily odkrepeatmerge using "`d'/a.csv", xlsform("`d'/a.xlsx") saving("`d'/h.dta", replace)
assert _rc == 459

display as result "E27 PASS: audit findings fixed"
