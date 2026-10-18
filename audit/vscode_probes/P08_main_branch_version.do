/*----------------------------------------------------------------------
   P08_main_branch_version.do
   Verifies that net install from the main branch would install v1.4.0.
   This is a documentation/packaging check, not a code test.
   Run from the repo root.

   EXPECTED: This probe will FAIL if the main branch still has v1.0.0.
   The fix is to merge V1 into main before SSC submission.
----------------------------------------------------------------------*/
version 14
clear all
set more off

* This probe cannot be run as a do-file; it is a static check.
* The finding is: git show main:odkrepeatmerge.ado shows v1.0.0,
* while V1 (the current branch) has v1.4.0.
* net install from https://raw.githubusercontent.com/.../main/
* would install the old, broken version.

display as error "STATIC CHECK - see audit report VS-001"
display as text "main branch ado version line:"
display as text "  *! version 1.0.0 Arman Mahmud, 17Oct2025"
display as text "V1 branch ado version line:"
display as text "  *! version 1.4.0 18oct2026 Arman Mahmud"
display as text ""
display as text "net install URL in README points to main."
display as text "Merge V1 into main before SSC submission."
