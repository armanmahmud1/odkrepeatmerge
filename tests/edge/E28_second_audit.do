/*----------------------------------------------------------------------
   E28_second_audit.do
   Regression tests for the issues found in the second independent audit
   (fixed before the 1.5.0 release):
     a  q31 listed before q3, instances 1 and 11 (both q311): r(110),
        no value silently lost
     b  main q1 has no column, repeat q instance 1 is q1: q1 gets the
        repeat question's label and place
     c  group prefixes: a question named latitude in a group, a group name
        containing "-", and hh-size next to a question hhsize
     d  the same question name in two groups: r(110) if both are
        exported; if only one is, it gets that question's label and place
     e  Unicode: a 19-character Cyrillic repeat question; an upper-case
        non-ASCII name at main level
     f  no reshape globals or characteristics left behind
     g  empty PARENT_KEY and duplicate KEY in a repeat CSV: r(459)
     h  output folder that does not exist (with replace): error before work
     i  separator with questions a and a_ in one repeat, in either order
   Run from the repo root (or via tests/run_all_tests.do).
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
capture mkdir "`repo'/tests/output"
capture mkdir "`repo'/tests/output/edge"
local d "`repo'/tests/output/edge/E28"
capture mkdir "`d'"
tempname fh

capture program drop _w
program define _w
	* _w "file" `"line1"' `"line2"' ...   (UTF-8 written byte for byte)
	gettoken fn 0 : 0
	capture erase `"`fn'"'
	mata: __w_fh = fopen(st_local("fn"), "w")
	foreach l of local 0 {
		mata: fput(__w_fh, st_local("l"))
	}
	mata: fclose(__w_fh)
	mata: mata drop __w_fh
end

* --- a: q31 before q3, instances 1 and 11 -------------------------------
clear
input str20 type str20 name
"begin_repeat" "r"
"text"         "q31"
"text"         "q3"
"end_repeat"   ""
end
export excel using "`d'/a.xlsx", firstrow(variables) sheet("survey") replace
_w "`d'/a.csv" "KEY" "u1" "u2"
_w "`d'/a-r.csv" "q31,q3,PARENT_KEY,KEY" "A1,B1,u1,u1/r[1]" "A11,B11,u2,u2/r[11]"
capture noisily odkrepeatmerge using "`d'/a.csv", xlsform("`d'/a.xlsx") saving("`d'/a.dta", replace) allstring
assert _rc == 110
odkrepeatmerge using "`d'/a.csv", xlsform("`d'/a.xlsx") saving("`d'/a.dta", replace) allstring separator
use "`d'/a.dta", clear
assert q31_1 == "A1" in 1
assert q3_11 == "B11" in 2

* --- b: main q1 without a column, repeat q instance 1 --------------------
clear
input str20 type str20 name str20 label
"text"         "m0" "Main m0"
"text"         "q1" "Main q1"
"begin_repeat" "r"  ""
"text"         "q"  "Repeat q"
"end_repeat"   ""   ""
"text"         "m2" "Main m2"
end
export excel using "`d'/b.xlsx", firstrow(variables) sheet("survey") replace
_w "`d'/b.csv" "m0,m2,KEY" "x,y,u1"
_w "`d'/b-r.csv" "q,PARENT_KEY,KEY" "R1,u1,u1/r[1]" "R2,u1,u1/r[2]"
odkrepeatmerge using "`d'/b.csv", xlsform("`d'/b.xlsx") saving("`d'/b.dta", replace) allstring
use "`d'/b.dta", clear
unab got : _all
if "`got'" != "key m0 q1 q2 m2" {
	display as error "b: order key m0 q1 q2 m2 expected, got `got'"
	exit 9
}
assert q1 == "R1"
assert "`: variable label q1'" == "[1] Repeat q"

* --- c: group prefixes ----------------------------------------------------
clear
input str20 type str20 name
"begin_group"  "grp"
"geopoint"     "gps"
"decimal"      "latitude"
"end_group"    ""
"begin_group"  "hh-info"
"integer"      "age"
"end_group"    ""
"begin_group"  "hh"
"integer"      "size"
"end_group"    ""
"integer"      "hhsize"
"begin_repeat" "r"
"begin_group"  "g"
"decimal"      "latitude"
"end_group"    ""
"end_repeat"   ""
end
* latitude in grp and in r/g: different datasets after the merge would
* still clash, so the repeat one is named lat
replace name = "lat" in 14
export excel using "`d'/c.xlsx", firstrow(variables) sheet("survey") replace
_w "`d'/c.csv" "grp-gps-Latitude,grp-gps-Longitude,grp-gps-Altitude,grp-gps-Accuracy,grp-latitude,hh-info-age,hh-size,hhsize,KEY" ///
	"23.5,90.4,10,5,1.5,40,5,7,u1"
_w "`d'/c-r.csv" "g-lat,PARENT_KEY,KEY" "2.5,u1,u1/r[1]" "3.5,u1,u1/r[2]"
odkrepeatmerge using "`d'/c.csv", xlsform("`d'/c.xlsx") saving("`d'/c.dta", replace)
assert r(n_unmatched) == 0
use "`d'/c.dta", clear
unab got : _all
local want "key gpslatitude gpslongitude gpsaltitude gpsaccuracy latitude age size hhsize lat1 lat2"
if "`got'" != "`want'" {
	display as error "c: order `want' expected, got `got'"
	exit 9
}
assert latitude == 1.5 & age == 40 & size == 5 & hhsize == 7 & lat2 == 3.5

* --- d: the same name in two groups --------------------------------------
clear
input str20 type str20 name
"begin_group" "a"
"integer"     "age"
"end_group"   ""
"begin_group" "b"
"integer"     "age"
"end_group"   ""
end
export excel using "`d'/dd.xlsx", firstrow(variables) sheet("survey") replace
_w "`d'/dd.csv" "a-age,b-age,KEY" "1,2,u1"
capture noisily odkrepeatmerge using "`d'/dd.csv", xlsform("`d'/dd.xlsx") saving("`d'/dd.dta", replace)
assert _rc == 110
_w "`d'/dd.csv" "age,age,KEY" "1,2,u1"
capture noisily odkrepeatmerge using "`d'/dd.csv", xlsform("`d'/dd.xlsx") saving("`d'/dd.dta", replace)
assert _rc == 110
* only b-age exported: age must be labelled and placed as question b/age
clear
input str20 type str20 name str20 label
"text"        "m1"  "M one"
"begin_group" "a"   ""
"integer"     "age" "Age A"
"end_group"   ""    ""
"text"        "m2"  "M two"
"begin_group" "b"   ""
"integer"     "age" "Age B"
"end_group"   ""    ""
end
export excel using "`d'/dd.xlsx", firstrow(variables) sheet("survey") replace
_w "`d'/dd.csv" "m1,m2,b-age,KEY" "x,y,7,u1"
odkrepeatmerge using "`d'/dd.csv", xlsform("`d'/dd.xlsx") saving("`d'/dd.dta", replace)
use "`d'/dd.dta", clear
unab got : _all
if "`got'" != "key m1 m2 age" {
	display as error "d: order key m1 m2 age expected, got `got'"
	exit 9
}
assert age == 7
assert "`: variable label age'" == "Age B"

* --- e: Unicode names -----------------------------------------------------
local cyr = ustrunescape("\u0432\u043e\u0437\u0440\u0430\u0441\u0442_\u0447\u043b\u0435\u043d\u0430_\u0441\u0435\u043c\u044c\u0438")
local Ae  = ustrunescape("\u00c4rzte")
local ae  = ustrlower("`Ae'")
clear
set obs 4
generate str40 type = ""
generate str80 name = ""
replace type = "text" in 1
replace name = "`Ae'" in 1
replace type = "begin_repeat" in 2
replace name = "r" in 2
replace type = "integer" in 3
replace name = "`cyr'" in 3
replace type = "end_repeat" in 4
export excel using "`d'/e.xlsx", firstrow(variables) sheet("survey") replace
_w "`d'/e.csv" "`Ae',KEY" "x,u1"
_w "`d'/e-r.csv" "`cyr',PARENT_KEY,KEY" "30,u1,u1/r[1]" "31,u1,u1/r[2]"
odkrepeatmerge using "`d'/e.csv", xlsform("`d'/e.xlsx") saving("`d'/e.dta", replace)
assert r(n_unmatched) == 0
use "`d'/e.dta", clear
unab got : _all
if "`got'" != "key `ae' `cyr'1 `cyr'2" {
	display as error "e: unexpected variables `got'"
	exit 9
}
assert `cyr'2 == 31

* --- f: no reshape globals or characteristics ----------------------------
local g : all globals "ReS_*"
assert "`g'" == ""
use "`d'/b.dta", clear
local c : char _dta[]
foreach x of local c {
	assert substr("`x'", 1, 4) != "ReS_"
}

* --- g: empty PARENT_KEY, duplicate KEY in a repeat CSV -------------------
_w "`d'/b-r.csv" "q,PARENT_KEY,KEY" "R1,u1,u1/r[1]" "R2,,u1/r[2]"
capture noisily odkrepeatmerge using "`d'/b.csv", xlsform("`d'/b.xlsx") saving("`d'/g.dta", replace) allstring
assert _rc == 459
_w "`d'/b-r.csv" "q,PARENT_KEY,KEY" "R1,u1,u1/r[1]" "R2,u1,u1/r[1]"
capture noisily odkrepeatmerge using "`d'/b.csv", xlsform("`d'/b.xlsx") saving("`d'/g.dta", replace) allstring
assert _rc == 459

* --- h: output folder that does not exist ---------------------------------
capture noisily odkrepeatmerge using "`d'/a.csv", xlsform("`d'/a.xlsx") saving("`d'/nosuchdir/h.dta", replace) separator
assert _rc != 0
capture confirm file "`d'/nosuchdir/h.dta"
assert _rc

* --- i: separator, a and a_ in one repeat, both orders --------------------
foreach ord in "a a_" "a_ a" {
	local n1 : word 1 of `ord'
	local n2 : word 2 of `ord'
	clear
	set obs 4
	generate str20 type = cond(_n == 1, "begin_repeat", cond(_n == 4, "end_repeat", "text"))
	generate str20 name = cond(_n == 1, "r", cond(_n == 2, "`n1'", cond(_n == 3, "`n2'", "")))
	export excel using "`d'/i.xlsx", firstrow(variables) sheet("survey") replace
	_w "`d'/i.csv" "KEY" "u1"
	_w "`d'/i-r.csv" "`n1',`n2',PARENT_KEY,KEY" "v_`n1',v_`n2',u1,u1/r[1]"
	odkrepeatmerge using "`d'/i.csv", xlsform("`d'/i.xlsx") saving("`d'/i.dta", replace) allstring separator
	use "`d'/i.dta", clear
	assert a_1 == "v_a" & a__1 == "v_a_"
}

display as result "E28 PASS: second-audit regressions"
