/*---------------------
Mena kiser
09-20-25

Connect lists of 287g participating agencies extracted from Wayback machines from  ICE official websites
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"

program main

*-------- PART 1: COMPEND ALL TABLES -----------
clear
save "$oi/ice_all_287g", replace emptyok

local subfolders factsheets icegov idarrests news_factsheets

foreach subfolder in `subfolders' {	
	
	local files : dir "$oi/wayback/`subfolder'/" files "*.xlsx"
	
	foreach file in `files' {
	
		import excel using "$oi/wayback/`subfolder'/`file'", sheet("Table1") clear allstring 
		di in red "Processing file `subfolder'/`file' - Table 1"
		
		* make sure all variables are stored consistently 
		rename_id_vars	// rename from A..H to v1..v9
		store_2rows //store first two rows of information on current status of agreements
		//assign consistent varnames
		replace information1 = "" if _n==1
		replace information2 = "" if _n==1
		nrow
		gen norder = _n
		gen filename = "`subfolder'/`file'"
		
		* identify how many tables (sheets) exist in the file 
		id_nsheets 
		qui sum total_tables
		local ttables = r(max)
		di in red "`ttables' tables fount in `subfolder'/`file'"
		
		*append
		append using "$oi/ice_all_287g" 
		save "$oi/ice_all_287g", replace
		
		
		*if multiple tables have been found import the next sheets
		if `ttables' > 1 {
			local i = 2
			while `i' <= `ttables' {
				import excel using "$oi/wayback/`subfolder'/`file'", sheet("Table`i'") clear allstring
				di in red "Processing file `subfolder'/`file' - Table `i'"
				
				* make sure all variables are stored consistently as for Table 1
				rename_id_vars	// rename from A..H to v1..v9
				store_2rows //store first two rows of info
				
				*assign consistent varnames
				replace information1 = "" if _n==1
				replace information2 = "" if _n==1
				nrow
				gen norder = _n
				gen filename = "`subfolder'/`file'"
				id_nsheets //identify how many tables exist, for consistency
				
				* append
				append using "$oi/ice_all_287g" 
				save "$oi/ice_all_287g", replace
				local++ i
			}
		}
	}
}


*-------- PART 2: CLEAN TABLE COMPILATION -----------
use "$oi/ice_all_287g", clear
compress
rename (LAWENFORCEMENTAGENCY SUPPORTTYPE DATESSIGNED)  (LEA supporttype datesigned)
foreach var of varlist _all {
	capture replace `var' = trim(`var') 
}
* extra vars v2 v3 SIGNED v4
tab LEA if !mi(v2)
count if  !mi(v2)
replace LEA = v2 if mi(LEA) & !mi(v2)

count if  !mi(v2)
replace LEA = v2 if mi(LEA) & !mi(v2)

tab supporttype if !mi(v3)
count if !mi(v3)
replace supporttype = v3 if mi(supporttype) & !mi(v3)

tab datesigned if !mi(SIGNED)
count if !mi(SIGNED)
replace datesigned = SIGNED if mi(datesigned) & !mi(SIGNED)

tab datesigned if !mi(v4)
count if !mi(v4)
replace datesigned = v4 if mi(datesigned) & !mi(v4)

drop v2 v3 SIGNED v4

* inspect missing values and homogenize values
foreach var of varlist _all {
	qui count if mi(`var')
	if `r(N)' > 0 {
		di in red "`r(N)' missing values for `var'"
		}
}
tab MOA
drop MOA
replace STATE = subinstr(STATE, "*", "", .)
replace supporttype = strupper(supporttype)
replace supporttype = "JAIL ENFORCEMENT" if supporttype=="JAILENFORCEMENT"
replace supporttype = "JAIL ENFORCEMENT" if supporttype=="JAIL ENFORCEMENT MODEL" 
replace supporttype = "WARRANT SERVICE OFFICER" if supporttype=="WARRANTSERVICEOFFICER"
replace LEA = "Etowah County Sheriff's Office"  if LEA=="EtowahCountySheriff'sOffice"
replace LEA =  "Department of Corrections"  if LEA == "DepartmentofCorrections" 
tab supporttype

* remove duplicates, storing the date of first and last retrieval
//datesigned = YYYY-MM-DD
gen dateretrieved = substr(datename, 1, 4) + "-" + substr(datename, 5, 2) + "-" + substr(datename, 7, 2)

duplicates report STATE LEA supporttype datesigned dateretrieved
destring datename, replace
bys STATE LEA supporttype datesigned dateretrieved (datename): keep if _n==_N

bys STATE supporttype LEA datesigned (dateretrieved) : gen firstretrieval = dateretrieved if _n==1
bys STATE supporttype LEA datesigned (dateretrieved) : ereplace firstretrieval = mode(firstretrieval)
bys STATE supporttype LEA datesigned (dateretrieved) : gen lastretrieval = dateretrieved if _n==_N
bys STATE supporttype LEA datesigned (dateretrieved) : ereplace lastretrieval = mode(lastretrieval)

drop link1 link2 information1 information2 filename
bys STATE supporttype LEA datesigned (dateretrieved) : keep if _n==_N
sort dateretrieved STATE supporttype LEA dateretrieved

sort STATE supporttype LEA

drop datename table_order norder total_tables


* Find localities
gen jurisdiction  = "county" if strpos(strlower(LEA), "county")>0
replace jurisdiction  = "city" if strpos(strlower(LEA), "city")>0 & mi(jurisdiction)
replace jurisdiction  = "parish" if strpos(strlower(LEA), "parish")>0 & mi(jurisdiction)
replace jurisdiction  = "state" if strpos(strupper(LEA), STATE)>0 & mi(jurisdiction)




compress 


end



program rename_id_vars
	local i = 1
	foreach var of varlist _all {
		replace `var' = subinstr(`var', " ", "", .) if _n==3 //for storing names
		rename `var' v`i'
		local++ i 
	}
end

program store_2rows
	gen information1 = v1 if _n==1
	gen information2 = v1 if _n==2
	ereplace information1 = mode(information1)
	ereplace information2 = mode(information2)
	if information1[1]!="STATE" {
		drop if _n==1
		if information2[1]!="STATE" {
			drop if _n==1
		}
	}
end

program update_varnames
	syntax, nvar(int) 
	local datevar = `nvar'-3
	local tabvar = `nvar'-2
	rename (v1 v2 v3 v4 v5 v6) (STATE LEA supporttype datesigned moa link1)
	rename v`datevar'  datename
	rename v`tabvar'  table_order
	local i = 1 
	if _rc == 0 {
		local vorder = 7
		local lorder = 2
		capture rename v`vorder' link`lorder'
		local++ vorder
		local++ lorder
	}
end

program id_nsheets
	split table_order, parse("/")
	replace table_order = table_order1
	drop table_order1 
	rename table_order2 total_tables
	destring table_order total_tables, replace
end


main 

