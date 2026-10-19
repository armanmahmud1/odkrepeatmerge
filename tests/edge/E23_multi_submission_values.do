/*----------------------------------------------------------------------
   E23_multi_submission_values.do
   Multiple submissions with varying repeat counts. Comprehensive
   value checking to verify no row/value misattribution.
   Run from the repo root (or via tests/run_all_tests.do).
   Promoted from the independent audit probe P05_multi_submission_values.do.
----------------------------------------------------------------------*/
version 14
clear all
set more off
local repo "`c(pwd)'"
adopath ++ "`repo'"
local d "`repo'/tests/tmp_edge/E23"
capture mkdir "`repo'/tests/tmp_edge"
capture mkdir "`d'"
tempname fh

clear
input str20 type str20 name
"text"         "village"
"begin_repeat" "hh"
"text"         "head"
"integer"      "size"
"end_repeat"   ""
"text"         "enum"
end
export excel using "`d'/f.xlsx", firstrow(variables) replace

* 3 submissions with different repeat counts
file open `fh' using "`d'/f.csv", write replace text
file write `fh' "key,village,enum" _n
file write `fh' "uuid:001,Dhaka,E1" _n
file write `fh' "uuid:002,Comilla,E2" _n
file write `fh' "uuid:003,Sylhet,E3" _n
file close `fh'

* uuid:001 has 3 HH members, uuid:002 has 1, uuid:003 has 2
file open `fh' using "`d'/f-hh.csv", write replace text
file write `fh' "KEY,PARENT_KEY,head,size" _n
file write `fh' "uuid:001/hh[1],uuid:001,Ali,5" _n
file write `fh' "uuid:001/hh[2],uuid:001,Fatima,3" _n
file write `fh' "uuid:001/hh[3],uuid:001,Karim,4" _n
file write `fh' "uuid:002/hh[1],uuid:002,Rahim,6" _n
file write `fh' "uuid:003/hh[1],uuid:003,Nadia,2" _n
file write `fh' "uuid:003/hh[2],uuid:003,Jamal,7" _n
file close `fh'

odkrepeatmerge, formid("f") xlsform("f.xlsx") formloc("`d'") replace

use "`d'/f.dta", clear
sort village

* Comilla (uuid:002): 1 HH member
assert village[1] == "Comilla" & enum[1] == "E2"
assert head1[1] == "Rahim" & size1[1] == 6
assert head2[1] == "" & missing(size2[1])
assert head3[1] == "" & missing(size3[1])

* Dhaka (uuid:001): 3 HH members
assert village[2] == "Dhaka" & enum[2] == "E1"
assert head1[2] == "Ali" & size1[2] == 5
assert head2[2] == "Fatima" & size2[2] == 3
assert head3[2] == "Karim" & size3[2] == 4

* Sylhet (uuid:003): 2 HH members
assert village[3] == "Sylhet" & enum[3] == "E3"
assert head1[3] == "Nadia" & size1[3] == 2
assert head2[3] == "Jamal" & size2[3] == 7
assert head3[3] == "" & missing(size3[3])

display as result "E23 PASS: multi-submission values correctly attributed"
