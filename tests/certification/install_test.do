/*----------------------------------------------------------------------
   tests/certification/install_test.do
   Installs the package with -net install- from the repository root
   (the same stata.toc / odkrepeatmerge.pkg that SSC and GitHub users
   get) into a throw-away PLUS folder, checks that the ado and help
   files arrive, then uninstalls.

   Run from the repository root:  do "tests/certification/install_test.do"
----------------------------------------------------------------------*/

version 14
local repo "`c(pwd)'"
capture mkdir "`repo'/tests/output"
local tmpplus "`repo'/tests/output/tmp_plus"
capture mkdir "`tmpplus'"

local oldplus  "`c(sysdir_plus)'"
local oldpath  "`c(adopath)'"
sysdir set PLUS "`tmpplus'"
* look only in the throw-away PLUS folder (and Stata's own folders)
capture adopath - "`repo'"

local fail 0
capture noisily net install odkrepeatmerge, from("`repo'") replace
if _rc local fail 1

if !`fail' {
	capture confirm file "`tmpplus'/o/odkrepeatmerge.ado"
	if _rc local fail 2
	capture confirm file "`tmpplus'/o/odkrepeatmerge.sthlp"
	if _rc local fail 3
}
if !`fail' {
	capture noisily ado uninstall odkrepeatmerge
	if _rc local fail 4
	capture confirm file "`tmpplus'/o/odkrepeatmerge.ado"
	if !_rc local fail 5
}

* restore the session
sysdir set PLUS "`oldplus'"
adopath ++ "`repo'"
if c(os) == "Windows" capture shell rmdir /s /q "`tmpplus'"
else capture shell rm -rf "`tmpplus'"

if `fail' {
	display as error "FAIL (step `fail'): net install / uninstall from the repository"
	exit 9
}
display as result "PASS: net install, files present, ado uninstall"
