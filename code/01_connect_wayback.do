/*---------------------
Mena kiser
09-20-25

Connect lists of 287g participating agencies extracted from Wayback machines from  ICE official websites
---------------------*/

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


clear all 
save "$oi/ice_all_287g", replace emptyok

local files : dir "$or/wayback/pre2015/tables/" files "*.xlsx"

foreach file in `files' {
	//all agreements
	import excel using "`file'", sheet("Table1") firstrow clear
	append using "ice_all_287g" 
	save "ice_all_287g", replace
	//pending agreements
	capture {
		import excel using "`file'", sheet("Table2") firstrow clear
		append using "ice_all_287g" 
		save "ice_all_287g", replace
	}
}

sort datename
