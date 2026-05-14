*! version 1.0.0 Arman Mahmud, 17Oct2025

	cap program drop odkrepeatmerge	
	program define odkrepeatmerge
		version 13
		syntax, formid(string) formtitle(string) [formloc(string)]
	
qui{
	
	cap macro drop form_id form_name
	if "`formloc'" != ""{
		
		gl form_id "`formloc'\\`formid'"
		gl form_name "`formloc'\\`formtitle'"
	} 	
	
	if "`formloc'" == ""{
		
		gl form_id "`formid'"
		gl form_name "`formtitle'"
	}
	
	* form load 
	
	n di as input _n "Form loading and repeat group splitting initiated..."
	
	tempfile survey_rows
	import excel using "${form_name}", firstrow clear
	save `survey_rows'
	keep if type == "begin_repeat" | type == "begin repeat"
	levelsof name, loc(rep_group)
	
	n di as result "Form loading and repeat group splitting done"
	
	
	*All file load
	n di as input _n "All repeat group data loading initiated..."
	
	loc key_len = ""
		
	foreach x of loc rep_group{
		insheet using "${form_id}-`x'.csv", names clear
		loc l_key_`x' = length(key)
		loc key_length = length(key)
		loc key_len `key_len' `key_length'
		tempfile r_`x'
		save `r_`x''
	}	
	
	*save main data as dta
	insheet using "${form_id}.csv", names clear
	save "${form_id}.dta", replace

	n di as result "All repeat group data loading done"
		
	*Sort the key length
	clear
	tempfile blank_file
	save `blank_file', emptyok replace
	u `blank_file', clear 
	set obs 1000
	g num = ""
	
	loc wc : word count `key_len'
	forvalues i = 1/`wc' {
		replace num = word("`key_len'", `i') in `i'
	}
	
	duplicates drop num, force
	destring num, replace
	drop if num == .
	gsort -num
	
	*descending order sort
	gen N = _N
	gen n = _n
	loc sorted_key_len

	forval i = 1/`=N'{
		preserve
			keep if n == `i'
			levelsof num, loc(a)
			loc sorted_key_len `sorted_key_len' `a' 
		restore
	}
	di `sorted_key_len'
	
	*identify most child dataset and rename
	loc i = 1
	loc forderchild = ""
	
	foreach len of loc sorted_key_len{
		foreach x of loc rep_group{
			if `l_key_`x'' == `len'{
			use `r_`x'', clear
			*g child_status = `i'
			g __file = regexs(1) if regexm(key, "/([a-zA-Z0-9_]+)\[[0-9]+\]$")
			g __mother = regexs(1) if regexm(parent_key, "/([a-zA-Z0-9_]+)\[[0-9]+\]$")
			levelsof __file, loc(f)
			drop __file
			save `f', replace
			loc ++i
			}
		}
	}
	
	*merge all nested child dataset
	n di as input _n "All nested group data merge initiated..."
	
	foreach len of loc sorted_key_len{
			foreach x of loc rep_group{
				if `l_key_`x'' == `len'{
					u `x'.dta, clear	
					drop key
					ren parent_key key
					
					if __mother!=""{
						levelsof __mother, loc(mother)
						
						drop __mother
						sort key, stable
						** reshape
						bysort key: gen __j = _n
						ds key __j, not
						reshape wide `r(varlist)', i(key) j(__j)
						
						ren * *_
						ren key_ key
						tempfile child
						save `child'
						
						foreach y of local mother{
							u `y'.dta, clear
						
						merge 1:1 key using `child', nogen
						save `y', replace
						}
					}
				}
			}
		}	
				
	n di as result "All nested group data merge done"
	
	*merge all child dataset wth main data
	
	n di as input _n "Nested group data merge with main data initiated..."
	
	foreach len of loc sorted_key_len{
			foreach x of loc rep_group{
				if `l_key_`x'' == `len'{
					u `x'.dta, clear	
					drop key
					ren parent_key key
				
					if __mother == ""{
							drop __mother
							sort key, stable
							**reshape
							bysort key: gen __j = _n
							ds key __j, not
							reshape wide `r(varlist)', i(key) j(__j)
						
							tempfile child
							save `child'
							
							u "${form_id}.dta", clear
							merge 1:1 key using `child', nogen
							save "${form_id}.dta",replace
						}
					}
				}
			}

	tempfile without_order_merged
	save `without_order_merged'

	
	*order all variables
	tempfile question_meta variable_order
	tempname qh oh
	use `survey_rows', clear
	keep type name
	replace type = lower(strtrim(type))
	replace name = strtrim(name)
	drop if name == ""
	
	postfile `qh' str128 qname str244 qtemplate int qdepth long qseq using `question_meta', replace
	local depth = 0
	local pos0 = 0
	local path0 ""
	local templ0 ""
	local qseq = 0
	
	forvalues x = 1/`=_N'{
		local __type "`=type[`x']'"
		local __name "`=name[`x']'"
		
		if inlist("`__type'", "begin_repeat", "begin repeat"){
			local pos`depth' = `pos`depth'' + 1
			local __nextdepth = `depth' + 1
			local __templ = cond("`templ`depth''" == "", "`pos`depth''", "`templ`depth'' `pos`depth''")
			local depth = `__nextdepth'
			local templ`depth' "`__templ'"
			local path`depth' "`__name'"
			local pos`depth' = 0
		}
		else if inlist("`__type'", "end_repeat", "end repeat"){
			local pos`depth' = 0
			local templ`depth' ""
			local path`depth' ""
			local depth = `depth' - 1
		}
		else if "`__type'" != "note"{
			local pos`depth' = `pos`depth'' + 1
			local ++qseq
			local __templ = cond("`templ`depth''" == "", "`pos`depth''", "`templ`depth'' `pos`depth''")
			post `qh' ("`__name'") ("`__templ'") (`depth') (`qseq')
		}
	}
	postclose `qh'
	
	n di as result "Nested group data merge with main data done"
	
	*ordering
	
	n di as input _n "Data ordering initiated..."
	
	use `without_order_merged', clear
	unab allvars : _all
	local allvars `allvars'
	
	use `question_meta', clear
	local qcount = _N
	local maxdepth = 0
	forvalues x = 1/`qcount'{
		local qname`x' "`=qname[`x']'"
		local qtemplate`x' "`=qtemplate[`x']'"
		local qdepth`x' = qdepth[`x']
		local qseq`x' = qseq[`x']
		if `qdepth`x'' > `maxdepth'{
			local maxdepth = `qdepth`x''
		}
	}
	
	local maxkey = 2 * `maxdepth' + 1
	local keydefs
	forvalues x = 1/`maxkey'{
		local keydefs `keydefs' long k`x'
	}
	postfile `oh' str128 actual byte grp byte matched int origseq long qseq `keydefs' using `variable_order', replace
	
	local origseq = 0
	foreach x of local allvars {
		local ++origseq
		
		if "`x'" == "key"{
			local __postkeys
			forvalues j = 1/`maxkey'{
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
			
			forvalues i = 1/`qcount'{
				local __qname "`qname`i''"
				local __qdepth = `qdepth`i''
				local __suffix = substr("`x'", `=length("`__qname'") + 1', .)
				
				if strpos("`x'", "`__qname'") == 1{
					if `__qdepth' == 0{
						if "`__suffix'" == "" & length("`__qname'") > `bestlen'{
							local bestname "`__qname'"
							local besttempl "`qtemplate`i''"
							local bestdepth = `__qdepth'
							local bestqseq = `qseq`i''
							local besttuple
							local bestlen = length("`__qname'")
						}
					}
					else if regexm("`__suffix'", "^[0-9]+(_[0-9]+)*$"){
						local __suffix_words : subinstr local __suffix "_" " ", all
						local __word_count : word count `__suffix_words'
						
						if `__word_count' == `__qdepth' & length("`__qname'") > `bestlen'{
							local __tuple
							forvalues j = `__word_count'(-1)1{
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
			if `bestlen' >= 0{
				forvalues j = 1/`maxkey'{
					local kval`j' .
				}
				
				if `bestdepth' == 0{
					local __lastpos : word 1 of `besttempl'
					local kval1 = `__lastpos'
				}
				else {
					forvalues j = 1/`bestdepth'{
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
				
				forvalues j = 1/`maxkey'{
					local __postkeys `__postkeys' (`kval`j'')
				}
				post `oh' ("`x'") (1) (1) (`origseq') (`bestqseq') `__postkeys'
			}
			else {
				forvalues j = 1/`maxkey'{
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
	forvalues x = 1/`=_N'{
		local ordered_varlist `ordered_varlist' `=actual[`x']'
	}
	
	use `without_order_merged', clear
	order `ordered_varlist'
	save "${form_id}.dta", replace
	
	n di as result "Data ordering done"
	
	**remove all dta files:
	foreach x of loc rep_group{
		rm `x'.dta
	}
}															 // qui closing
end
	
