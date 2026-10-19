/*----------------------------------------------------------------------
   E26_error_paths.do
   Error paths that had no test (gap noted by the independent audit):
     A. main CSV without KEY             -> r(111)
     B. duplicate KEY in main CSV        -> r(459)
     C. repeat CSV without PARENT_KEY    -> r(111)
     D. repeat KEY without trailing [n]  -> r(459)
     E. repeat variable clashes with a main variable (q a1 vs repeat
        question a, instance 1)          -> r(110); works with separator
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/tmp_edge"
local d "`repo'/tests/tmp_edge/E26"
capture mkdir "`d'"
tempname fh

* form 1: no repeats
clear
input str20 type str20 name
"text" "q1"
end
export excel using "`d'/form1.xlsx", firstrow(variables) replace

* form 2: one repeat r with question a
clear
input str20 type str20 name
"text"         "q1"
"begin_repeat" "r"
"text"         "a"
"end_repeat"   ""
end
export excel using "`d'/form2.xlsx", firstrow(variables) replace

* form 3: main question a1 + repeat r with question a
clear
input str20 type str20 name
"text"         "a1"
"begin_repeat" "r"
"text"         "a"
"end_repeat"   ""
end
export excel using "`d'/form3.xlsx", firstrow(variables) replace

* A. no KEY column in main CSV
file open `fh' using "`d'/nokey.csv", write replace text
file write `fh' "q1" _n "x" _n
file close `fh'
capture odkrepeatmerge using "`d'/nokey.csv", xlsform("`d'/form1.xlsx") saving("`d'/out.dta", replace)
if _rc != 111 {
	display as error "A: expected r(111) for missing KEY; got r(`=_rc')"
	exit 9
}

* B. duplicate KEY in main CSV
file open `fh' using "`d'/dupkey.csv", write replace text
file write `fh' "key,q1" _n "u1,a" _n "u1,b" _n
file close `fh'
capture odkrepeatmerge using "`d'/dupkey.csv", xlsform("`d'/form1.xlsx") saving("`d'/out.dta", replace)
if _rc != 459 {
	display as error "B: expected r(459) for duplicate KEY; got r(`=_rc')"
	exit 9
}

* C. repeat CSV without PARENT_KEY
file open `fh' using "`d'/noparent.csv", write replace text
file write `fh' "key,q1" _n "u1,a" _n
file close `fh'
file open `fh' using "`d'/noparent-r.csv", write replace text
file write `fh' "key,a" _n "u1/r[1],x" _n
file close `fh'
capture odkrepeatmerge using "`d'/noparent.csv", xlsform("`d'/form2.xlsx") saving("`d'/out.dta", replace)
if _rc != 111 {
	display as error "C: expected r(111) for missing PARENT_KEY; got r(`=_rc')"
	exit 9
}

* D. repeat KEY without trailing [n]
file open `fh' using "`d'/badkey.csv", write replace text
file write `fh' "key,q1" _n "u1,a" _n
file close `fh'
file open `fh' using "`d'/badkey-r.csv", write replace text
file write `fh' "key,parent_key,a" _n "u1/r1,u1,x" _n
file close `fh'
capture odkrepeatmerge using "`d'/badkey.csv", xlsform("`d'/form2.xlsx") saving("`d'/out.dta", replace)
if _rc != 459 {
	display as error "D: expected r(459) for KEY without [n]; got r(`=_rc')"
	exit 9
}

* E. clash between main a1 and repeat a instance 1
file open `fh' using "`d'/clash.csv", write replace text
file write `fh' "key,a1" _n "u1,main" _n
file close `fh'
file open `fh' using "`d'/clash-r.csv", write replace text
file write `fh' "key,parent_key,a" _n "u1/r[1],u1,rep1" _n "u1/r[2],u1,rep2" _n
file close `fh'
capture odkrepeatmerge using "`d'/clash.csv", xlsform("`d'/form3.xlsx") saving("`d'/out.dta", replace)
if _rc != 110 {
	display as error "E: expected r(110) for name clash; got r(`=_rc')"
	exit 9
}
odkrepeatmerge using "`d'/clash.csv", xlsform("`d'/form3.xlsx") saving("`d'/out.dta", replace) separator
use "`d'/out.dta", clear
assert a1 == "main" & a_1 == "rep1" & a_2 == "rep2"

display as result "E26 PASS: error paths return the documented codes"
