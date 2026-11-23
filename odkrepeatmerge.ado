*! version 1.5.0 23nov2026 Arman Mahmud

program define odkrepeatmerge, rclass
	version 14
	syntax using/ [, XLSform(string) FORMTitle(string) ///
		SAVing(string asis) REPLACE SEParator ALLstring]

	* --- XLSForm: xlsform() is the preferred name; formtitle() a synonym ---
	if `"`xlsform'"' == "" {
		local xlsform `"`formtitle'"'
	}
	else if `"`formtitle'"' != "" & `"`formtitle'"' != `"`xlsform'"' {
		display as error "specify xlsform() or formtitle(), not both"
		exit 198
	}
	if `"`xlsform'"' == "" {
		display as error "option xlsform() required"
		exit 198
	}

	* separator: put "_" between a question name and its instance number
	local sep = cond("`separator'" != "", "_", "")
	* allstring: import every CSV column as string (keeps leading zeros);
	* otherwise store decimals as double so GPS coordinates keep full precision
	local strimport = cond("`allstring'" != "", "stringcols(_all)", "asdouble")
	local overwrite `replace'

	* --- Locate the data -------------------------------------------------
	* form_id  = folder/stem of the CSV files: main is form_id.csv,
	*            repeat group g is form_id-g.csv
	local __p : subinstr local using "\" "/", all
	if regexm(lower(`"`__p'"'), "\.csv$") {
		local mainfile `"`__p'"'
		local form_id = substr(`"`__p'"', 1, length(`"`__p'"') - 4)
	}
	else {
		local mainfile `"`__p'.csv"'
		local form_id `"`__p'"'
	}
	* stem = file name part of form_id (used for the default output)
	if regexm(`"`form_id'"', "([^/]*)$") {
		local stem = regexs(1)
	}
	local form_name `"`xlsform'"'

	confirm file `"`form_name'"'
	confirm file `"`mainfile'"'

	* --- Output file: saving(filename [, replace]) or stem.dta in the cwd ---
	if `"`saving'"' != "" {
		local 0 `"using `saving'"'
		capture syntax using/ [, replace]
		if _rc {
			display as error "saving() must be {it:filename} [, replace]"
			exit 198
		}
		local savefile `"`using'"'
		if "`replace'" != "" local overwrite replace
	}
	else {
		local savefile `"`stem'.dta"'
	}
	mata: st_local("__ext", pathsuffix(st_local("savefile")))
	if `"`__ext'"' == "" local savefile `"`savefile'.dta"'
	else if lower(`"`__ext'"') != ".dta" {
		display as error `"saving(): the output must be a .dta file, not `__ext'"'
		exit 198
	}
	if "`overwrite'" == "" {
		capture confirm new file `"`savefile'"'
		local rc = _rc
		if `rc' == 602 {
			display as error `"file `savefile' already exists; specify replace"'
			exit 602
		}
		else if `rc' {
			display as error `"cannot write `savefile'"'
			exit `rc'
		}
	}

	preserve

qui {

	* ==================================================================
	* 1. Read the XLSForm: repeat structure + question order
	* ==================================================================
	noisily display as input _n "Reading the XLSForm..."

	import excel using `"`form_name'"', describe
	local __nsheet = r(N_worksheet)
	local __sheet
	forvalues s = 1/`__nsheet' {
		if lower(`"`r(worksheet_`s')'"') == "survey" local __sheet `"`r(worksheet_`s')'"'
	}
	if `"`__sheet'"' == "" {
		local __sheet `"`r(worksheet_1)'"'
		noisily display as text `"  note: no sheet named survey; reading the first sheet (`__sheet')"'
	}
	import excel using `"`form_name'"', sheet(`"`__sheet'"') firstrow case(lower) allstring clear
	capture confirm variable type name
	if _rc {
		noisily display as error "The XLSForm survey sheet must have columns named type and name"
		exit 111
	}
	* question label: first column whose name starts with "label"
	local __labvar
	foreach v of varlist _all {
		if "`__labvar'" == "" & substr("`v'", 1, 5) == "label" local __labvar `v'
	}
	if "`__labvar'" != "" {
		keep type name `__labvar'
		rename `__labvar' _orm_label
	}
	else {
		keep type name
		generate _orm_label = ""
	}
	replace _orm_label = trim(ustrregexra(_orm_label, "[\r\n\t]+", " "))
	replace type = lower(trim(itrim(type)))
	replace name = trim(itrim(name))
	drop if type == ""
	* keep end_repeat / end_group rows even when their name cell is blank
	drop if name == "" & !inlist(type, "end_repeat", "end repeat", "end_group", "end group")

	tempfile question_meta variable_order main expect
	tempname qh
	postfile `qh' str128 qname str244 qlabel str244 qtemplate int qdepth ///
		long qseq byte qgeo int qgroup using "`question_meta'", replace

	local depth = 0
	local pos0 = 0
	local templ0 ""
	local gcur0 = 0
	local qseq = 0
	local G = 0
	local maxgdepth = 0
	local qnamelist
	local grpnames meta
	* ODK Central system columns: expected to be absent from the XLSForm
	local __sys submissiondate submitterid submittername attachmentspresent ///
		attachmentsexpected status reviewstate deviceid edits formversion ///
		instanceid instancename metainstanceid meta_instanceid ///
		metainstancename meta_instancename

	forvalues x = 1/`=_N' {
		local __type = type[`x']
		local __oname = name[`x']

		if inlist("`__type'", "begin_group", "begin group", "begin_repeat", "begin repeat") {
			local grpnames `grpnames' `=lower(name[`x'])'
		}

		if inlist("`__type'", "begin_repeat", "begin repeat") {
			local pos`depth' = `pos`depth'' + 1
			local __templ = trim("`templ`depth'' `pos`depth''")
			local ++G
			local gname`G' "`__oname'"
			local gpidx`G' = `gcur`depth''
			local gactive`G' 0
			local gdone`G' 0
			local depth = `depth' + 1
			local gdepth`G' = `depth'
			if `depth' > `maxgdepth' local maxgdepth = `depth'
			local templ`depth' "`__templ'"
			local gcur`depth' = `G'
			local pos`depth' = 0
		}
		else if inlist("`__type'", "end_repeat", "end repeat") {
			if `depth' > 0 local depth = `depth' - 1
		}
		else if !inlist("`__type'", "begin_group", "begin group", "end_group", "end group") {
			* notes are kept: ODK Central exports them as (empty) columns
			local pos`depth' = `pos`depth'' + 1
			local ++qseq
			local __templ = trim("`templ`depth'' `pos`depth''")
			* geopoint columns are split into -Latitude/-Longitude/...
			local __geo = inlist("`__type'", "geopoint", "start-geopoint", "start_geopoint")
			* the variable name import delimited makes from this column:
			* "-" and "." dropped, at most 32 characters
			local __vname = lower(usubstr(ustrregexra(name[`x'], "[^\p{L}\p{N}_]", ""), 1, 32))
			post `qh' ("`__vname'") (usubstr(_orm_label[`x'], 1, 80)) ("`__templ'") ///
				(`depth') (`qseq') (`__geo') (`gcur`depth'')
			local qnamelist `qnamelist' `__vname'
		}
	}
	postclose `qh'

	* the same question name twice makes the output ambiguous
	use "`question_meta'", clear
	bysort qname (qseq): generate byte _dup = _N > 1 & _n == 1
	levelsof qname if _dup, local(__dups) clean
	if `"`__dups'"' != "" {
		noisily display as text "  note: these names appear more than once in the XLSForm: `__dups'"
	}

	noisily display as result "Found `G' repeat group(s)"

	* ==================================================================
	* 2. Load the main CSV and every repeat-group CSV
	* ==================================================================
	noisily display as input _n "Loading CSV files..."

	import delimited using `"`mainfile'"', clear varnames(1) case(lower) bindquote(strict) encoding("utf-8") `strimport'
	if _N == 0 {
		noisily display as error `"`mainfile' has no data rows"'
		exit 2000
	}
	_orm_ungroup using `"`mainfile'"', names(`qnamelist' `__sys') groups(`grpnames')
	capture confirm variable key
	if _rc {
		noisily display as error `"`mainfile' has no KEY column"'
		exit 111
	}
	capture isid key
	if _rc {
		noisily display as error `"`mainfile': KEY is missing or duplicated in some rows"'
		exit 459
	}
	save "`main'"

	forvalues g = 1/`G' {
		local fn "`form_id'-`gname`g''.csv"
		capture confirm file "`fn'"
		if _rc {
			noisily display as error `"Repeat-group file not found: `fn'"'
			exit 601
		}
		import delimited using "`fn'", clear varnames(1) case(lower) bindquote(strict) encoding("utf-8") `strimport'
		if _N == 0 {
			noisily display as text "  note: `gname`g'' has no rows - skipped"
			continue
		}
		capture confirm variable key parent_key
		if _rc {
			noisily display as error `"`fn' must have KEY and PARENT_KEY columns"'
			exit 111
		}
		_orm_ungroup using `"`fn'"', names(`qnamelist' `__sys') groups(`grpnames')
		local gactive`g' 1
		ds key parent_key, not
		local own`g' `r(varlist)'
		tempfile tf`g'
		save "`tf`g''"
	}

	noisily display as result "CSV files loaded"

	* ==================================================================
	* 3. Reshape + merge, deepest groups first
	* ==================================================================
	noisily display as input _n "Merging repeat groups (deepest first)..."

	if `maxgdepth' > 0 {
	forvalues dd = `maxgdepth'(-1)1 {
		forvalues g = 1/`G' {
			if `gdepth`g'' != `dd' continue
			if !`gactive`g'' continue

			use "`tf`g''", clear

			* instance number = the [n] at the end of KEY (not row order)
			generate long _orm_j = real(regexs(1)) if regexm(key, "\[([0-9]+)\]$")
			count if missing(_orm_j)
			if r(N) > 0 {
				noisily display as error "`gname`g'': could not read the instance number [n] from KEY"
				exit 459
			}
			drop key
			rename parent_key key
			capture isid key _orm_j
			if _rc {
				noisily display as error "`gname`g'': the same KEY appears more than once in the repeat-group CSV"
				exit 459
			}

			if "`sep'" != "" {
				foreach v of local own`g' {
					if length("`v'`sep'") > 32 {
						noisily display as error "`v'`sep' would exceed 32 characters; shorten question `v'"
						exit 198
					}
					capture confirm new variable `v'`sep'
					if _rc {
						noisily display as error "`v' (repeat group `gname`g'') becomes `v'`sep', which is already used by a nested repeat question; rename one of them"
						exit 110
					}
					rename `v' `v'`sep'
				}
			}

			ds key _orm_j, not
			local stubs `r(varlist)'
			if "`stubs'" == "" continue

			* name-length check (nested names get one more "_" later)
			levelsof _orm_j, local(jvals)
			local maxlen = cond(`gpidx`g'' > 0, 31, 32)
			foreach s of local stubs {
				foreach j of local jvals {
					if length("`s'`j'") > `maxlen' {
						noisily display as error "`s'`j' (repeat group `gname`g'') would exceed Stata's 32-character name limit; shorten the question name"
						exit 198
					}
				}
			}

			* variable-limit check: reshape wide multiplies variables
			local __ns : word count `stubs'
			local __nj : word count `jvals'
			local __newk = c(k) - `__ns' - 1 + `__ns' * `__nj'
			if `__newk' > c(maxvar) {
				noisily display as error "Repeat group `gname`g'' needs `__newk' variables in wide form; the limit is `c(maxvar)'."
				noisily display as error "Raise it with {cmd:set maxvar} (Stata SE/MP) or drop unneeded questions."
				exit 900
			}

			capture reshape wide `stubs', i(key) j(_orm_j)
			if _rc {
				local rc = _rc
				noisily display as error "reshape wide failed for repeat group `gname`g'' (r(`rc'))."
				if "`sep'" == "" {
					noisily display as error "If two questions differ only by trailing digits (e.g. q1 and q11), or select_multiple"
					noisily display as error "choices are exported as separate columns (food/1, food/11), re-run with the separator option."
				}
				exit `rc'
			}

			if `gpidx`g'' > 0 {
				rename * *_
				rename key_ key
			}
			ds key, not
			local childvars `r(varlist)'
			tempfile child
			save "`child'"

			local p = `gpidx`g''
			if `p' > 0 {
				if !`gactive`p'' {
					noisily display as text "  note: `gname`g'' has rows but parent `gname`p'' has none - dropped"
					continue
				}
				use "`tf`p''", clear
			}
			else {
				use "`main'", clear
			}

			foreach v of local childvars {
				capture confirm variable `v', exact
				if !_rc {
					noisily display as error "Variable `v' (from repeat group `gname`g'') already exists in the parent data."
					noisily display as error "Check that no two questions in the XLSForm share the same name."
					if "`sep'" == "" {
						noisily display as error "If names differ only by trailing digits (e.g. q1 and q11), re-run with the separator option."
					}
					exit 110
				}
			}
			local __nc : word count `childvars'
			if c(k) + `__nc' + 1 > c(maxvar) {
				noisily display as error "Merging repeat group `gname`g'' needs more than `c(maxvar)' variables."
				noisily display as error "Raise the limit with {cmd:set maxvar} (Stata SE/MP) or drop unneeded questions."
				exit 900
			}

			merge 1:1 key using "`child'", generate(_orm_m)
			count if _orm_m == 2
			if r(N) > 0 {
				noisily display as text "  note: `r(N)' `gname`g'' row(s) had no matching parent and were dropped"
			}
			drop if _orm_m == 2
			drop _orm_m

			if `p' > 0 save "`tf`p''", replace
			else save "`main'", replace

			* instance numbers of this group, used to name its variables
			local jv`g' `jvals'
			local gdone`g' 1
		}
	}
	}   // maxgdepth > 0

	noisily display as result "Merge done"

	* ==================================================================
	* 4. Order variables to follow the questionnaire
	* ==================================================================
	* Every variable the merge created is known exactly: question q of
	* repeat group g gets q[sep]<inner>_..._<outer> for every combination
	* of instance numbers of g and its ancestors. Build that list and look
	* each variable up by name (no guessing from name prefixes).
	noisily display as input _n "Ordering variables..."

	use "`main'", clear
	unab allvars : _all
	* Central system columns renamed on import because their name clashes
	* with a form field (e.g. DeviceID vs deviceid becomes v30)
	local __syslab
	foreach x of local allvars {
		local __l : variable label `x'
		local __l = lower(subinstr(`"`__l'"', "-", "", .))
		local __in : list posof `"`__l'"' in __sys
		if `__in' local __syslab `__syslab' `x'
	}

	* instance tuples of each merged group: j1 (outermost) .. jd
	forvalues g = 1/`G' {
		if !`gdone`g'' continue
		* the group and its ancestors, outermost first (all were merged,
		* otherwise this group could not have been merged into its parent)
		local chain `g'
		local h = `gpidx`g''
		while `h' > 0 {
			local chain `h' `chain'
			local h = `gpidx`h''
		}
		tempfile tup`g'
		local lvl 0
		foreach h of local chain {
			local ++lvl
			clear
			local __jl `jv`h''
			set obs `: word count `__jl''
			generate long j`lvl' = .
			mata: st_store(., "j`lvl'", strtoreal(tokens(st_local("__jl")))')
			if `lvl' > 1 cross using "`tup`g''"
			save "`tup`g''", replace
		}
	}

	* expected variable names, with their sort keys and labels
	local maxkey = 2 * `maxgdepth' + 1
	local nexp 0
	forvalues g = 0/`G' {
		if `g' > 0 {
			if !`gdone`g'' continue
		}
		use "`question_meta'", clear
		keep if qgroup == `g'
		if _N == 0 continue
		local d 0
		if `g' > 0 local d = `gdepth`g''
		generate str244 _sfx = ""
		if `g' > 0 {
			cross using "`tup`g''"
			forvalues m = `d'(-1)1 {
				replace _sfx = _sfx + cond(_sfx == "", "", "_") + string(j`m')
			}
		}
		* geopoint: one variable per part
		expand cond(qgeo, 5, 1)
		bysort qseq _sfx: generate byte _part = _n - 1
		generate str10 _pn = ""
		replace _pn = word("latitude longitude altitude accuracy", _part) if _part > 0
		generate str244 actual = qname + _pn + cond(`g' > 0, "`sep'" + _sfx, "")
		generate str244 vlab = cond(qlabel != "", qlabel, qname)
		replace vlab = vlab + " (" + _pn + ")" if _part > 0
		if `g' > 0 replace vlab = "[" + _sfx + "] " + vlab
		replace vlab = usubstr(vlab, 1, 80)
		forvalues m = 1/`=`d' + 1' {
			generate long k`=2 * `m' - 1' = real(word(qtemplate, `m'))
		}
		forvalues m = 1/`d' {
			generate long k`=2 * `m'' = j`m'
		}
		keep actual vlab qseq k*
		if `nexp' append using "`expect'"
		save "`expect'", replace
		local ++nexp
	}
	if `nexp' {
		* a name can only be created once (a clash stops the merge above)
		bysort actual (qseq): keep if _n == 1
		save "`expect'", replace
	}

	* the variables in the data, in their current order
	clear
	local nv : word count `allvars'
	set obs `nv'
	generate str128 actual = ""
	mata: st_sstore(., "actual", tokens(st_local("allvars"))')
	generate long origseq = _n
	if `nexp' {
		merge 1:1 actual using "`expect'", keep(master match) generate(_orm_m)
	}
	else {
		generate byte _orm_m = 1
		generate long qseq = .
		generate str1 vlab = ""
	}
	local klist
	forvalues i = 1/`maxkey' {
		capture generate long k`i' = .
		local klist `klist' k`i'
	}
	generate byte grp = cond(actual == "key", 0, cond(_orm_m == 3, 1, 2))
	sort grp `klist' qseq origseq

	* not in the XLSForm (and not an ODK Central system column)
	local unmatched
	forvalues i = 1/`=_N' {
		if grp[`i'] != 2 continue
		local x = actual[`i']
		local __issys : list posof "`x'" in __sys
		local __issys2 : list posof "`x'" in __syslab
		if !`__issys' & !`__issys2' local unmatched `unmatched' `x'
	}

	mata: st_local("ordered_varlist", invtokens(st_sdata(., "actual")'))
	* labels for the variables found in the XLSForm (grp 1)
	mata: __orm_s = st_data(., "grp") :== 1
	mata: __orm_n = select(st_sdata(., "actual"), __orm_s); __orm_l = select(st_sdata(., "vlab"), __orm_s)

	use "`main'", clear
	order `ordered_varlist'
	mata: for (__i = 1; __i <= rows(__orm_n); __i++) st_varlabel(__orm_n[__i], __orm_l[__i])
	mata: mata drop __orm_n __orm_l __orm_s __i
	save `"`savefile'"', replace
	local N = _N
	local K = c(k)

	noisily display as result "Ordering done"

	local n_unmatched : word count `unmatched'
	if `n_unmatched' > 0 {
		local __show
		forvalues i = 1/`=min(`n_unmatched', 20)' {
			local __w : word `i' of `unmatched'
			local __show `__show' `__w'
		}
		if `n_unmatched' > 20 local __show `__show' ...
		noisily display as text _n "Note: `n_unmatched' variable(s) not found in the XLSForm were placed at the end:"
		noisily display as text "  `__show'"
		noisily display as text "  If unexpected, check that the XLSForm version matches the data."
	}

	noisily display as result _n `"Saved `savefile' (`N' obs, `K' vars)"'

}   // qui closing

	return local fn `"`savefile'"'
	return local unmatched `"`unmatched'"'
	return scalar N = `N'
	return scalar k = `K'
	return scalar n_repeat = `G'
	return scalar n_unmatched = `n_unmatched'
end


* Rename group-prefixed CSV columns (ODK Central default: group-question)
* back to the XLSForm field name. The original headers are read from the
* CSV's first row (variable labels are cut at 80 characters, too short for
* deeply nested groups); rename only when the last "-" segment is a
* field in the form (or a Central system column such as meta-instanceID),
* every earlier segment is a group/repeat name from the form, and the new
* name is free. Geopoint parts keep their part name: grp-gps-Latitude
* becomes gpslatitude (as gps-Latitude does without group names).
program define _orm_ungroup
	version 14
	syntax using/ [, names(string) groups(string)]
	unab __vars : _all
	local K : word count `__vars'
	preserve
	quietly import delimited using `"`using'"', clear varnames(nonames) ///
		rowrange(1:1) stringcols(_all) bindquote(strict) encoding("utf-8")
	local useraw = (c(k) == `K' & _N >= 1)
	if `useraw' {
		forvalues j = 1/`K' {
			local h`j' = trim(v`j'[1])
		}
	}
	restore
	local j 0
	foreach v of local __vars {
		local ++j
		if `useraw' local lab `"`h`j''"'
		else local lab : variable label `v'
		local geo
		if regexm(lower(`"`lab'"'), "^(.+)-(latitude|longitude|altitude|accuracy)$") {
			local geo = regexs(2)
			local lab = regexs(1)
		}
		if !regexm(`"`lab'"', "^(.+)-([^-]+)$") continue
		local prefix = lower(regexs(1))
		local field = regexs(2)
		local field = lower(usubstr(ustrregexra(`"`field'"', "[^\p{L}\p{N}_]", ""), 1, 32))
		local new `field'`geo'
		if "`new'" == "`v'" | length("`new'") > 32 continue
		local prefix : subinstr local prefix "-" " ", all
		local okprefix 1
		foreach p of local prefix {
			local isgrp : list posof "`p'" in groups
			if !`isgrp' local okprefix 0
		}
		if !`okprefix' continue
		local inform : list posof "`field'" in names
		if !`inform' continue
		capture confirm new variable `new'
		if _rc continue
		rename `v' `new'
	}
end
