*! version 1.1.0 09oct2026 Arman Mahmud

program define odkrepeatmerge
	version 14
	syntax, formid(string) formtitle(string) [formloc(string)]

	* --- Input validation (M04) ---
	if `"`formid'"' == "" {
		display as error "formid() must not be empty"
		exit 198
	}
	if `"`formtitle'"' == "" {
		display as error "formtitle() must not be empty"
		exit 198
	}

	* --- Build paths using forward slash for cross-platform (M01, C03) ---
	local form_id "`formid'"
	local form_name "`formtitle'"
	if `"`formloc'"' != "" {
		local form_id "`formloc'/`formid'"
		local form_name "`formloc'/`formtitle'"
	}

	* --- Validate that input files exist (M04) ---
	confirm file "`form_name'"
	confirm file "`form_id'.csv"

	* --- Preserve user data (C02) ---
	preserve

qui {

	* form load
	noisily display as input _n "Form loading and repeat group splitting initiated..."

	tempfile survey_rows
	import excel using "`form_name'", firstrow clear
	save `survey_rows'
	keep if type == "begin_repeat" | type == "begin repeat"
	levelsof name, local(rep_group)

	noisily display as result "Form loading and repeat group splitting done"


	* All file load
	noisily display as input _n "All repeat group data loading initiated..."

	local key_len = ""

	foreach x of local rep_group {
		confirm file "`form_id'-`x'.csv"
		import delimited using "`form_id'-`x'.csv", clear
		confirm variable key parent_key
		local l_key_`x' = length(key[1])
		local key_length = length(key[1])
		local key_len `key_len' `key_length'
		tempfile r_`x'
		save `r_`x''
	}

	* save main data as dta
	import delimited using "`form_id'.csv", clear
	save "`form_id'.dta", replace

	noisily display as result "All repeat group data loading done"

	* Sort the key length
	clear
	tempfile blank_file
	save `blank_file', emptyok replace
	use `blank_file', clear
	local wc : word count `key_len'
	if `wc' > 0 {
		set obs `wc'
	}
	else {
		set obs 1
	}
	generate num = ""

	forvalues i = 1/`wc' {
		replace num = word("`key_len'", `i') in `i'
	}

	duplicates drop num, force
	destring num, replace
	drop if num == .
	gsort -num

	* descending order sort
	generate N = _N
	generate n = _n
	local sorted_key_len

	forvalues i = 1/`=_N' {
		local sorted_key_len `sorted_key_len' `=num[`i']'
	}

	* identify most child dataset and rename — use tempfiles (C08)
	local i = 1

	foreach len of local sorted_key_len {
		foreach x of local rep_group {
			if `l_key_`x'' == `len' {
				use `r_`x'', clear
				generate _orm_file = regexs(1) if regexm(key, "/([a-zA-Z0-9_]+)\[[0-9]+\]$")
				generate _orm_mother = regexs(1) if regexm(parent_key, "/([a-zA-Z0-9_]+)\[[0-9]+\]$")
				levelsof _orm_file, local(f)
				drop _orm_file
				tempfile tf_`f'
				save `tf_`f'', replace
				local ++i
			}
		}
	}

	* merge all nested child dataset
	noisily display as input _n "All nested group data merge initiated..."

	foreach len of local sorted_key_len {
		foreach x of local rep_group {
			if `l_key_`x'' == `len' {
				use `tf_`x'', clear
				drop key
				rename parent_key key

				if _orm_mother != "" {
					levelsof _orm_mother, local(mother)

					drop _orm_mother
					sort key, stable
					** reshape
					bysort key: generate _orm_j = _n
					ds key _orm_j, not
					reshape wide `r(varlist)', i(key) j(_orm_j)

					rename * *_
					rename key_ key
					tempfile child
					save `child'

					foreach y of local mother {
						use `tf_`y'', clear
						merge 1:1 key using `child', nogen
						save `tf_`y'', replace
					}
				}
			}
		}
	}

	noisily display as result "All nested group data merge done"

	* merge all child dataset with main data
	noisily display as input _n "Nested group data merge with main data initiated..."

	foreach len of local sorted_key_len {
		foreach x of local rep_group {
			if `l_key_`x'' == `len' {
				use `tf_`x'', clear
				drop key
				rename parent_key key

				if _orm_mother == "" {
					drop _orm_mother
					sort key, stable
					** reshape
					bysort key: generate _orm_j = _n
					ds key _orm_j, not
					reshape wide `r(varlist)', i(key) j(_orm_j)

					tempfile child
					save `child'

					use "`form_id'.dta", clear
					merge 1:1 key using `child', nogen
					save "`form_id'.dta", replace
				}
			}
		}
	}

	tempfile without_order_merged
	save `without_order_merged'


	* order all variables
	tempfile question_meta variable_order
	tempname qh oh
	use `survey_rows', clear
	keep type name
	replace type = lower(trim(itrim(type)))
	replace name = trim(itrim(name))
	drop if name == ""

	postfile `qh' str128 qname str244 qtemplate int qdepth long qseq using `question_meta', replace
	local depth = 0
	local pos0 = 0
	local path0 ""
	local templ0 ""
	local qseq = 0

	forvalues x = 1/`=_N' {
		local __type "`=type[`x']'"
		local __name "`=name[`x']'"

		if inlist("`__type'", "begin_repeat", "begin repeat") {
			local pos`depth' = `pos`depth'' + 1
			local __nextdepth = `depth' + 1
			local __templ = cond("`templ`depth''" == "", "`pos`depth''", "`templ`depth'' `pos`depth''")
			local depth = `__nextdepth'
			local templ`depth' "`__templ'"
			local path`depth' "`__name'"
			local pos`depth' = 0
		}
		else if inlist("`__type'", "end_repeat", "end repeat") {
			local pos`depth' = 0
			local templ`depth' ""
			local path`depth' ""
			local depth = `depth' - 1
		}
		else if !inlist("`__type'", "note", "begin_group", "begin group", "end_group", "end group") {
			local pos`depth' = `pos`depth'' + 1
			local ++qseq
			local __templ = cond("`templ`depth''" == "", "`pos`depth''", "`templ`depth'' `pos`depth''")
			post `qh' ("`__name'") ("`__templ'") (`depth') (`qseq')
		}
	}
	postclose `qh'

	noisily display as result "Nested group data merge with main data done"

	* ordering
	noisily display as input _n "Data ordering initiated..."

	use `without_order_merged', clear
	unab allvars : _all
	local allvars `allvars'

	use `question_meta', clear
	local qcount = _N
	local maxdepth = 0
	forvalues x = 1/`qcount' {
		local qname`x' "`=qname[`x']'"
		local qtemplate`x' "`=qtemplate[`x']'"
		local qdepth`x' = qdepth[`x']
		local qseq`x' = qseq[`x']
		if `qdepth`x'' > `maxdepth' {
			local maxdepth = `qdepth`x''
		}
	}

	local maxkey = 2 * `maxdepth' + 1
	local keydefs
	forvalues x = 1/`maxkey' {
		local keydefs `keydefs' long k`x'
	}
	postfile `oh' str128 actual byte grp byte matched int origseq long qseq `keydefs' using `variable_order', replace

	local origseq = 0
	foreach x of local allvars {
		local ++origseq

		if "`x'" == "key" {
			local __postkeys
			forvalues j = 1/`maxkey' {
				local __postkeys `__postkeys' (.)
			}
			post `oh' ("`x'") (0) (0) (`origseq') (.) `__postkeys'
		}
		else {
			local bestname
			local besttempl
			local bestdepth = .
			local bestqseq = .
			local besttuple
			local bestlen = -1

			forvalues i = 1/`qcount' {
				local __qname "`qname`i''"
				local __qdepth = `qdepth`i''
				local __suffix = substr("`x'", `=length("`__qname'") + 1', .)

				if strpos("`x'", "`__qname'") == 1 {
					if `__qdepth' == 0 {
						if "`__suffix'" == "" & length("`__qname'") > `bestlen' {
							local bestname "`__qname'"
							local besttempl "`qtemplate`i''"
							local bestdepth = `__qdepth'
							local bestqseq = `qseq`i''
							local besttuple
							local bestlen = length("`__qname'")
						}
					}
					else if regexm("`__suffix'", "^[0-9]+(_[0-9]+)*$") {
						local __suffix_words : subinstr local __suffix "_" " ", all
						local __word_count : word count `__suffix_words'

						if `__word_count' == `__qdepth' & length("`__qname'") > `bestlen' {
							local __tuple
							forvalues j = `__word_count'(-1)1 {
								local __piece : word `j' of `__suffix_words'
								local __tuple `__tuple' `__piece'
							}

							local bestname "`__qname'"
							local besttempl "`qtemplate`i''"
							local bestdepth = `__qdepth'
							local bestqseq = `qseq`i''
							local besttuple "`__tuple'"
							local bestlen = length("`__qname'")
						}
					}
				}
			}

			local __postkeys
			if `bestlen' >= 0 {
				forvalues j = 1/`maxkey' {
					local kval`j' .
				}

				if `bestdepth' == 0 {
					local __lastpos : word 1 of `besttempl'
					local kval1 = `__lastpos'
				}
				else {
					forvalues j = 1/`bestdepth' {
						local __posword : word `j' of `besttempl'
						local __instword : word `j' of `besttuple'
						local __k1 = 2 * `j' - 1
						local __k2 = 2 * `j'
						local kval`__k1' = `__posword'
						local kval`__k2' = `__instword'
					}
					local __lastindex = `bestdepth' + 1
					local __lastpos : word `__lastindex' of `besttempl'
					local __kfinal = 2 * `bestdepth' + 1
					local kval`__kfinal' = `__lastpos'
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
			}
		}
	}
	postclose `oh'

	use `variable_order', clear
	sort grp k1-k`maxkey' qseq origseq
	local ordered_varlist
	forvalues x = 1/`=_N' {
		local ordered_varlist `ordered_varlist' `=actual[`x']'
	}

	use `without_order_merged', clear
	order `ordered_varlist'
	save "`form_id'.dta", replace

	noisily display as result "Data ordering done"

}   // qui closing
end
