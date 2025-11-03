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
	
	import excel using "${form_name}", firstrow clear
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
	import excel using "${form_name}", firstrow clear
	keep type name
	drop if regexm(type, "begin") | regexm(type, "end") | regexm(type, "note")
	drop if type == ""

	
	loc order_ques 
	forval x = 1/`=_N'{
		loc __j = `x'
		loc order_ques `order_ques' `=name[`__j']'
	}
	
	n di as result "Nested group data merge with main data done"
	
	*ordering
	
	n di as input _n "Data ordering initiated..."
	
	use `without_order_merged', clear

	local ordered_varlist
	foreach x of local order_ques {
		cap unab matched : `x'*
		
		if !_rc {
			loc ordered_varlist `ordered_varlist' `matched'
		}
		else {
			di "warning: no variables matching `x'*"
		}
	}

	di "`ordered_varlist'"
	
	mata{
		v = tokens(st_local("ordered_varlist")) 
		v2 = invtokens(v[cols(v)..1])   
		st_local("revlist", v2) 
	}
	
	foreach i of loc revlist{
		order `i'
	}
	
	cap conf var submissiondate
	if !_rc{
		order submissiondate, first
	}
	
	n di as result "Data ordering done"
	
	**remove all dta files:
	foreach x of loc rep_group{
		rm `x'.dta
	}
}															 // qui closing
end
	