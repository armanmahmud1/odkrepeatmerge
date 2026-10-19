/*----------------------------------------------------------------------
   tests/run_all_tests.do  --  one-shot test runner for odkrepeatmerge

   Usage (Stata):
     cd "H:/My Drive/00_Workspace/Repositories/odkrepeatmerge"
     do tests/run_all_tests.do

   Works from the repo root or from tests/. Forces Stata to run the
   REPO copy of odkrepeatmerge.ado (not an older net-installed copy),
   runs every test, and prints a PASS/FAIL summary.
   Full output: tests/run_all_tests.log
----------------------------------------------------------------------*/

version 14
clear all
set more off
capture log close _all

* --- Locate repo root ---------------------------------------------------
local repo "`c(pwd)'"
capture confirm file "`repo'/odkrepeatmerge.ado"
if _rc {
	capture confirm file "`repo'/../odkrepeatmerge.ado"
	if _rc {
		display as error "Cannot find odkrepeatmerge.ado - cd to the repository root first."
		exit 601
	}
	quietly cd ..
	local repo "`c(pwd)'"
}
quietly cd "`repo'"
local runlog "`repo'/tests/run_all_tests.log"
log using "`runlog'", replace text name(runner)

* --- Make sure the REPO copy is what runs -------------------------------
discard
adopath ++ "`repo'"
display as text "Stata version : " as result c(stata_version)
display as text "Repo          : " as result `"`repo'"'
display as text "Loaded from   :"
which odkrepeatmerge
quietly findfile odkrepeatmerge.ado
local loaded = subinstr(lower(`"`r(fn)'"'), "\", "/", .)
local want   = subinstr(lower(`"`repo'/odkrepeatmerge.ado"'), "\", "/", .)
if `"`loaded'"' != `"`want'"' {
	display as error "WARNING: Stata resolves odkrepeatmerge to"
	display as error `"  `r(fn)'"'
	display as error "  which is NOT the repo copy. Results below may test the wrong version."
}

* --- Test list ------------------------------------------------------------
local tests `""tests/regression_nested_order.do" "tests/regression_prefix_collision.do" "audit/odkrepeatmerge_cert.do" "audit/examples.do""'
local edge : dir "tests/edge" files "E*.do"
local edge : list sort edge
foreach f of local edge {
	local tests `"`tests' "tests/edge/`f'""'
}

* --- Run ----------------------------------------------------------------
local npass 0
local nfail 0
local results
foreach t of local tests {
	quietly cd "`repo'"
	discard
	display as text _n "{hline 70}" _n "RUNNING `t'" _n "{hline 70}"
	capture noisily do "`t'"
	local rc = _rc
	* some tests close all logs / cd away - restore runner state
	capture log close _all
	quietly cd "`repo'"
	log using "`runlog'", append text name(runner)
	adopath ++ "`repo'"
	if `rc' == 0 {
		local ++npass
		local results `"`results' "PASS        `t'""'
	}
	else {
		local ++nfail
		local results `"`results' "FAIL (r`rc')  `t'""'
	}
}

* --- Summary ------------------------------------------------------------
display as text _n "{hline 70}" _n "SUMMARY" _n "{hline 70}"
foreach r of local results {
	if substr(`"`r'"', 1, 4) == "PASS" display as result `"`r'"'
	else display as error `"`r'"'
}
display as text "{hline 70}"
display as result "Passed: `npass'" as text "   " as error "Failed: `nfail'"
log close runner
