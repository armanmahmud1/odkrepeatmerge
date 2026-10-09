/*----------------------------------------------------------------------
   audit/examples.do
   Extracted from odkrepeatmerge.sthlp — tests that the help-file
   example at least parses without syntax errors.

   NOTE: This cannot run to completion without real ODK data files.
         It will confirm the syntax is accepted by Stata's parser.
----------------------------------------------------------------------*/

capture log close _all
log using "audit/examples.log", replace text name(examples)

version 14

* --- Syntax check only (will error on missing files, which is expected) ---
capture noisily {
    odkrepeatmerge, formid("rmg_environmental_survey") ///
        formtitle("RMG Environmental Survey ODK.xlsx") ///
        formloc("D:/My drive/test")
}

* We expect r(601) or similar file-not-found error.
* What we do NOT want is a syntax error (r(197) / r(198)).
if _rc == 197 | _rc == 198 {
    display as error "FAIL: syntax error in odkrepeatmerge invocation"
    exit _rc
}
else {
    display as result "OK: command syntax accepted (file-not-found is expected)"
}

log close examples
