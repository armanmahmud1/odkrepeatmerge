/*----------------------------------------------------------------------
   audit/install_test.do
   Tests local net-install / ado-uninstall round-trip.

   Instructions:
   1. Open Stata
   2. cd to the repository root
   3. do "audit/install_test.do"
----------------------------------------------------------------------*/

capture log close _all
log using "audit/install_test.log", replace text name(install)

version 14

* --- Set up an isolated PLUS directory ---
local tmpplus "`c(pwd)'/audit/tmp_plus"
capture mkdir "`tmpplus'"
sysdir set PLUS "`tmpplus'"

* --- Install from the audit/ local package files ---
display as input "Installing odkrepeatmerge from local audit/ package..."
net install odkrepeatmerge, from("`c(pwd)'/audit")
display as result "net install succeeded"

* --- Verify installation ---
which odkrepeatmerge
display as result "`r(fn)'"

* --- Verify help renders without error ---
capture noisily help odkrepeatmerge
display as result "help file rendered"

* --- Uninstall ---
ado uninstall odkrepeatmerge
display as result "ado uninstall succeeded"

* --- Verify removal ---
capture which odkrepeatmerge
if _rc != 0 {
    display as result "PASS: odkrepeatmerge correctly removed"
}
else {
    display as error "FAIL: odkrepeatmerge still found after uninstall"
}

* --- Clean up ---
capture shell rmdir /s /q "`tmpplus'"
* On Mac/Linux use: capture shell rm -rf "`tmpplus'"

log close install
