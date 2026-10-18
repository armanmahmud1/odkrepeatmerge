*! version 1.4.0 18oct2026 Arman Mahmud

program define odkrepeatmerge, rclass
	version 14
	syntax [using/] [, XLSform(string) FORMTitle(string) formid(string) formloc(string) ///
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
	* allstring: import every CSV column as string (keeps leading zeros)
	local strimport = cond("`allstring'" != "", "stringcols(_all)", "")
	local overwrite `replace'

	* --- Locate the data -------------------------------------------------
	* form_id  = folder/stem of the CSV files: main is form_id.csv (or the
	*            using file), repeat group g is form_id-g.csv
	* form_name = the XLSForm file
	if `"`using'"' != "" {
		* new syntax: odkrepeatmerge using main.csv, xlsform(path)
		if `"`formid'"' != "" | `"`formloc'"' != "" {
			display as error "with {bf:using}, do not specify formid() or formloc()"
			exit 198
		}
		local mainfile `"`using'"'
		local __p : subinstr local mainfile "\" "/", all
		* form_id = the main CSV path without its extension
		if regexm(`"`__p'"', "^(.*)\.[^./]*$") {
			local form_id = regexs(1)
		}
		else {
			local form_id `"`__p'"'
			local mainfile `"`mainfile'.csv"'
		}
		* stem = file name part of form_id (used for the default output)
		if regexm(`"`form_id'"', "([^/]*)$") {
			local stem = regexs(1)
		}
		local form_name `"`xlsform'"'
		* default output: stem.dta in the current working directory
		local defsave `"`stem'.dta"'
	}
	else {
		* older syntax: odkrepeatmerge, formid() xlsform() [formloc()]
		if `"`formid'"' == "" {
			display as error "specify the main CSV file with {bf:using} (or the older formid() option)"
			exit 198
		}
		local form_id "`formid'"
		local form_name "`xlsform'"
		if `"`formloc'"' != "" {
			local form_id "`formloc'/`formid'"
			* join formloc() only when xlsform() is a bare file name
			local __x : subinstr local xlsform "\" "/", all
			if !strpos(`"`__x'"', "/") & !strpos(`"`__x'"', ":") {
				local form_name "`formloc'/`xlsform'"
			}
		}
		local mainfile `"`form_id'.csv"'
		* default output: formid.dta next to the data (as in earlier versions)
		local defsave `"`form_id'.dta"'
	}

	confirm file `"`form_name'"'
	confirm file `"`mainfile'"'

	* --- Output file: saving(filename [, replace]) or the default ---
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
		local savefile `"`defsave'"'
	}
	mata: st_local("__ext", pathsuffix(st_local("savefile")))
	if `"`__ext'"' == "" local savefile `"`savefile'.dta"'
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

	capture import excel using "`form_name'", sheet("survey") firstrow case(lower) allstring clear
	if _rc {
		import excel using "`form_name'", firstrow case(lower) allstring clear
	}
	capture confirm variable type name
	if _rc {
		noisily display as error "The XLSForm survey sheet must have columns named type and name"
		exit 111
	}
	keep type name
	replace type = lower(trim(itrim(type)))
	replace name = trim(itrim(name))
	drop if type == ""
	* keep end_repeat / end_group rows even when their name cell is blank
	drop if name == "" & !inlist(type, "end_repeat", "end repeat", "end_group", "end group")

	tempfile question_meta variable_order main
	tempname qh oh
	postfile `qh' str244 qname str244 qtemplate int qdepth long qseq using "`question_meta'", replace

	local depth = 0
	local pos0 = 0
	local templ0 ""
	local rstack0 ""
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
		local __name = lower(name[`x'])

		if inlist("`__type'", "begin_group", "begin group", "begin_repeat", "begin repeat") {
			local grpnames `grpnames' `__name'
		}

		if inlist("`__type'", "begin_repeat", "begin repeat") {
			local pos`depth' = `pos`depth'' + 1
			local __templ = trim("`templ`depth'' `pos`depth''")
			local ++G
			local gname`G' "`__oname'"
			local gparent`G' "`rstack`depth''"
			local gactive`G' 0
			local depth = `depth' + 1
			local gdepth`G' = `depth'
			if `depth' > `maxgdepth' local maxgdepth = `depth'
			local templ`depth' "`__templ'"
			local rstack`depth' "`__oname'"
			local pos`depth' = 0
		}
		else if inlist("`__type'", "end_repeat", "end repeat") {
			if `depth' > 0 local depth = `depth' - 1
		}
		else if !inlist("`__type'", "note", "begin_group", "begin group", "end_group", "end group") {
			local pos`depth' = `pos`depth'' + 1
			local ++qseq
			local __templ = trim("`templ`depth'' `pos`depth''")
			post `qh' ("`__name'") ("`__templ'") (`depth') (`qseq')
			local qnamelist `qnamelist' `__name'
		}
	}
	postclose `qh'

	* parent index of each repeat group (0 = top level)
	forvalues g = 1/`G' {
		local gpidx`g' 0
		forvalues h = 1/`G' {
			if "`gparent`g''" != "" & "`gname`h''" == "`gparent`g''" local gpidx`g' `h'
		}
	}

	noisily display as result "Found `G' repeat group(s)"

	* ==================================================================
	* 2. Load the main CSV and every repeat-group CSV
	* ==================================================================
	noisily display as input _n "Loading CSV files..."

	import delimited using `"`mainfile'"', clear varnames(1) case(lower) bindquote(strict) encoding("utf-8") `strimport'
	_orm_ungroup, names(`qnamelist' `__sys') groups(`grpnames')
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
		_orm_ungroup, names(`qnamelist' `__sys') groups(`grpnames')
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

			if "`sep'" != "" {
				foreach v of local own`g' {
					if length("`v'`sep'") > 32 {
						noisily display as error "`v'`sep' would exceed 32 characters; shorten question `v'"
						exit 198
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
					noisily display as error "If two questions differ only by trailing digits (e.g. q1 and q11), re-run with the separator option."
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
					if "`sep'" == "" {
						noisily display as error "Re-run with the separator option to keep repeat names distinct (e.g. q_1)."
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
		}
	}
	}   // maxgdepth > 0

	noisily display as result "Merge done"

	* ==================================================================
	* 4. Order variables to follow the questionnaire
	* ==================================================================
	noisily display as input _n "Ordering variables..."

	use "`main'", clear
	unab allvars : _all

	use "`question_meta'", clear
	local qcount = _N
	local maxdepth = 0
	forvalues x = 1/`qcount' {
		local qname`x' = qname[`x']
		local qtemplate`x' = qtemplate[`x']
		local qdepth`x' = qdepth[`x']
		local qseq`x' = qseq[`x']
		if `qdepth`x'' > `maxdepth' local maxdepth = `qdepth`x''
	}

	local maxkey = 2 * `maxdepth' + 1
	local keydefs
	forvalues x = 1/`maxkey' {
		local keydefs `keydefs' long k`x'
	}
	postfile `oh' str128 actual byte grp byte matched long origseq long qseq `keydefs' using "`variable_order'", replace

	local unmatched
	local origseq = 0
	foreach x of local allvars {
		local ++origseq

		if "`x'" == "key" {
			local __postkeys
			forvalues j = 1/`maxkey' {
				local __postkeys `__postkeys' (.)
			}
			post `oh' ("`x'") (0) (0) (`origseq') (.) `__postkeys'
			continue
		}

		local besttempl
		local bestdepth = .
		local bestqseq = .
		local besttuple
		local bestlen = -1

		forvalues i = 1/`qcount' {
			local __qname "`qname`i''"
			if strpos("`x'", "`__qname'") != 1 continue
			local __qdepth = `qdepth`i''
			local __suffix = substr("`x'", length("`__qname'") + 1, .)

			if `__qdepth' == 0 {
				if "`__suffix'" == "" & length("`__qname'") > `bestlen' {
					local besttempl "`qtemplate`i''"
					local bestdepth = 0
					local bestqseq = `qseq`i''
					local besttuple
					local bestlen = length("`__qname'")
				}
				continue
			}

			if "`sep'" != "" {
				if substr("`__suffix'", 1, 1) != "`sep'" continue
				local __suffix = substr("`__suffix'", 2, .)
			}
			* instance numbers never start with 0 (keeps q1#10 = q110 apart from q10)
			if !regexm("`__suffix'", "^[1-9][0-9]*(_[1-9][0-9]*)*$") continue

			local __suffix_words : subinstr local __suffix "_" " ", all
			local __word_count : word count `__suffix_words'
			if `__word_count' == `__qdepth' & length("`__qname'") > `bestlen' {
				* suffix is innermost-first; reverse to outermost-first
				local __tuple
				forvalues j = `__word_count'(-1)1 {
					local __piece : word `j' of `__suffix_words'
					local __tuple `__tuple' `__piece'
				}
				local besttempl "`qtemplate`i''"
				local bestdepth = `__qdepth'
				local bestqseq = `qseq`i''
				local besttuple "`__tuple'"
				local bestlen = length("`__qname'")
			}
		}

		local __postkeys
		if `bestlen' >= 0 {
			forvalues j = 1/`maxkey' {
				local kval`j' .
			}
			if `bestdepth' == 0 {
				local kval1 : word 1 of `besttempl'
			}
			else {
				forvalues j = 1/`bestdepth' {
					local __k1 = 2 * `j' - 1
					local __k2 = 2 * `j'
					local kval`__k1' : word `j' of `besttempl'
					local kval`__k2' : word `j' of `besttuple'
				}
				local __lastindex = `bestdepth' + 1
				local __kfinal = 2 * `bestdepth' + 1
				local kval`__kfinal' : word `__lastindex' of `besttempl'
			}
			forvalues j = 1/`maxkey' {
				local __postkeys `__postkeys' (`kval`j'')
			}
			post `oh' ("`x'") (1) (1) (`origseq') (`bestqseq') `__postkeys'
		}
		else {
			forvalues j = 1/`maxkey' {
				local __postkeys `__postkeys' (.)
			}
			post `oh' ("`x'") (2) (0) (`origseq') (.) `__postkeys'
			local __issys : list posof "`x'" in __sys
			if !`__issys' local unmatched `unmatched' `x'
		}
	}
	postclose `oh'

	use "`variable_order'", clear
	sort grp k1-k`maxkey' qseq origseq
	local ordered_varlist
	forvalues x = 1/`=_N' {
		local ordered_varlist `ordered_varlist' `=actual[`x']'
	}

	use "`main'", clear
	order `ordered_varlist'
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
* back to the XLSForm field name. import delimited keeps the original
* header in the variable label; rename only when the last "-" segment is a
* field in the form (or a Central system column such as meta-instanceID),
* every earlier segment is a group/repeat name from the form (so geopoint
* parts such as gps-Latitude are left alone), and the new name is free.
program define _orm_ungroup
	version 14
	syntax [, names(string) groups(string)]
	foreach v of varlist _all {
		local lab : variable label `v'
		if !regexm(`"`lab'"', "^(.+)-([^-]+)$") continue
		local prefix = lower(regexs(1))
		local new = lower(strtoname(regexs(2)))
		if "`new'" == "`v'" continue
		local prefix : subinstr local prefix "-" " ", all
		local okprefix 1
		foreach p of local prefix {
			local isgrp : list posof "`p'" in groups
			if !`isgrp' local okprefix 0
		}
		if !`okprefix' continue
		local inform : list posof "`new'" in names
		if !`inform' continue
		capture confirm new variable `new'
		if _rc continue
		rename `v' `new'
	}
end
