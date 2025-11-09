/*---------------------
Mena kiser
11-08-2025

Obtain geo codes from lea participating in 287g 
through list of ICPSR location identifiers
https://www.icpsr.umich.edu/web/ICPSR/studies/35158/datadocumentation#
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


*-------- PART 2: CleaN TABLE COMPILATION -----------
use "$oi/ice_all_287g", clear

*remove if 287g is pending 
drop if !mi(meetingdate) //will maybe come back to this later
drop moaname meetingdate location type
compress
rename (lawenforcementagency supporttype signed)  (lea supporttype datesigned)
foreach var of varlist _all { 
	capture replace `var' = trim(`var') 
}
* extra vars v2 v3 SIGNED v4
tab lea if !mi(v2)
count if  !mi(v2)
replace lea = v2 if mi(lea) & !mi(v2)

count if  !mi(v2)
replace lea = v2 if mi(lea) & !mi(v2)

tab supporttype if !mi(v3)
count if !mi(v3)
replace supporttype = v3 if mi(supporttype) & !mi(v3)

tab datesigned if !mi(v4)
count if !mi(v4)
replace datesigned = v4 if mi(datesigned) & !mi(v4)

drop v2 v3 v4
drop if mi(supporttype) // all of this are in second table, in 2025, assumed to be pending. will maybe come back to this later


* inspect missing values and homogenize values
foreach var of varlist _all {
	qui count if mi(`var')
	if `r(N)' > 0 {
		di in red "`r(N)' missing values for `var'"
		}
}
tab moa
drop moa
replace state = subinstr(state, "*", "", .)
replace supporttype = "jail enforcement" if supporttype=="jailenforcement"
replace supporttype = "jail enforcement" if supporttype=="jail enforcement model" 
replace supporttype = "task force" if supporttype=="task force model" 
replace supporttype = "warrant service officer" if supporttype=="warrantserviceofficer"
replace lea = "etowah county sheriff's office"  if lea=="etowahcountysheriff'soffice"
replace lea =  "department of corrections"  if lea == "departmentofcorrections" 
replace lea = "city of mesa police department" if lea == "mesa police department"
replace lea = "city of durham police department" if lea == "durham police department"
replace lea = "prince william-manassas regional adult detention center" if lea == "prince william-manassas regional jail"
replace lea = "massachusetts department of corrections" if lea=="massachusetts department of correction"
replace lea = subinstr(lea, " (addendum)", "", . )
replace lea = subinstr(lea, " addendum", "", . )
* burnet county was mistakenly assigned florida: https://web.archive.org/web/20200606022401/https://www.ice.gov/doclib/287gmoa/287gwso_burnetcotx2019-11-05.pdf
replace state = "texas" if lea =="burnet county sheriff's office"
replace lea = "harford county sheriff's office" if lea == "hartford county sheriff's office"
replace lea = subinstr(lea, "st johns", "st. johns", .)
replace lea = subinstr(lea, "albermarle", "albemarle", .) if state == "georgia" | state == "north carolina"
replace state = "north carolina" if strpos(lea, "albemarle")>0
replace state = "north carolina" if strpos(lea, "caldwell county") & state == "georgia" 
replace state = "texas" if strpos(lea, "aransas county")
replace state = "montana" if strpos(lea, "gallatin")>0
replace lea = subinstr(lea, "mantiowoc", "manitowoc", .)
replace lea = "owyhee county sheriff's office" if lea=="owyhee couny sheriff's office" 

tab supporttype

* remove duplicates, storing the date of first and last retrieval
//datesigned = YYYY-MM-DD
gen dateretrieved = substr(datename, 1, 4) + "-" + substr(datename, 5, 2) + "-" + substr(datename, 7, 2)

duplicates report state lea supporttype datesigned dateretrieved
destring datename, replace
bys state lea supporttype datesigned dateretrieved (datename): keep if _n==_N

/*
bys STATE supporttype lea datesigned (dateretrieved) : gen firstretrieval = dateretrieved if _n==1
bys STATE supporttype lea datesigned (dateretrieved) : ereplace firstretrieval = mode(firstretrieval)
bys STATE supporttype lea datesigned (dateretrieved) : gen lastretrieval = dateretrieved if _n==_N
bys STATE supporttype lea datesigned (dateretrieved) : ereplace lastretrieval = mode(lastretrieval)

bys STATE supporttype lea datesigned (dateretrieved) : keep if _n==_N
*/

drop link1 link2 information1 information2 filename
sort dateretrieved state supporttype lea 

sort state supporttype lea

drop datename table_order norder total_tables


* Find localities
gen jurisdiction  = "county" if strpos(strlower(lea), "county")>0
replace jurisdiction  = "city" if strpos(strlower(lea), "city")>0 & mi(jurisdiction)
replace jurisdiction  = "parish" if strpos(strlower(lea), "parish")>0 & mi(jurisdiction)
replace jurisdiction  = "state" if strpos(strupper(lea), state)>0 & mi(jurisdiction)
replace jurisdiction = "corrections" if strpos(strlower(lea), "jail")>0 | strpos(strlower(lea), "correction")>0 | strpos(strlower(lea), "detention")>0

* examine lea's with missing jurisdictions
egen unique_lea = tag(state lea)
count if  unique_lea==1 & mi(jurisdiction) //only 10, hardcode it

* 17 lea with missing jurisdiction info
replace jurisdiction = "county" if lea=="kodiak police department"
replace jurisdiction = "town" if lea=="florence police department"
replace jurisdiction = "city" if lea=="rogers police department"
replace jurisdiction = "city" if lea=="jacksonville sheriff's office"
replace jurisdiction = "city" if lea=="carrollton police department"
replace jurisdiction = "city" if lea=="farmers branch police department"
replace jurisdiction = "city" if lea=="las vegas metropolitan police department"
replace jurisdiction = "town" if lea=="herndon police department"
replace jurisdiction = "city" if lea=="manassas park police department"
replace jurisdiction = "city" if lea=="manassas police department"

* clean lea names
replace lea = subinstr(lea, "." , "" , .)
replace lea = subinstr(lea, "  " , " " , .)
replace lea = subinstr(lea, "’" , `"'"' , .)
replace lea = subinstr(lea, "sheriffs" , "sheriff's" , .)
replace lea = subinstr(lea, "sheriff's department" , "sheriff's office" , .)
replace lea = subinstr(lea, "city of " , "" , .)
replace lea = subinstr(lea, "sheriff office" , "sheriff's office", .)
replace lea = "anne arundel county detention facilities" if strpos(lea, "anne arundel county" )>0
replace lea = "tennessee highway patrol" if strpos(lea, "tennessee highway patrol" )>0
save "$oi/xwalk/wayback_lea_list", replace


*-------- PART 1: OBTAIN LIST OF LEA TO COUNTIES -----------
use "$or/ICPSR_35158-2/DS0001/35158-0001-Data.dta", clear

rename (FSTATE FCOUNTY NAME AGCYTYPE STATENAME) (statefips countyfips lea agctype state )
keep statefips countyfips lea agctype state
replace lea = strlower(lea)
replace state = strlower(state)
drop if lea =="south carolina law enforcement division"  & agctype==6

* clean terminology
replace lea = subinstr(lea, " pd" , " police department" , .) if agctype==0 & strpos(lea, "police department")==0
replace lea = subinstr(lea, " police dept." , " police department" , .) if agctype==0 & strpos(lea, "police department")==0
replace lea = subinstr(lea, " police dept" , " police department" , .) if agctype==0 & strpos(lea, "police department")==0
replace lea = subinstr(lea, " police" , " police department" , .) if agctype==0 & strpos(lea, "department")==0
replace lea = subinstr(lea, " co " , " county " , .) if strpos(lea, "county")==0
replace lea = subinstr(lea, " cnty " , " county " , .) if strpos(lea, "county")==0
replace lea = subinstr(lea, " vlg " , " village " , .) if strpos(lea, "village")==0
replace lea = subinstr(lea, " twp " , " township " , .) if strpos(lea, "township")==0
replace lea = subinstr(lea, " twnshp " , " township " , .) if strpos(lea, "township")==0
replace lea = subinstr(lea, " tnshp " , " township " , .) if strpos(lea, "township")==0
replace lea = subinstr(lea, " so" , " sheriff's office" , .) if agctype==1 & strpos(lea, "sheriff's office")==0
replace lea = subinstr(lea, "sheriffs" , "sheriff's" , .) if agctype==1 & strpos(lea, "sheriff's office")==0
replace lea = subinstr(lea, " ofc" , " office" , .) if strpos(lea, "office")==0
replace lea = subinstr(lea, "." , "" , .)
replace lea = subinstr(lea, "  " , " " , .)

replace lea = subinstr(lea, "chp " , "california highway patrol " , .) if agctype==5 & strpos(lea, "california highway Patrol")==0
replace lea = subinstr(lea, "dept " , "department " , .) if strpos(lea, "department")==0
replace lea = subinstr(lea, "sp " , "state police " , .) if agctype==5 & strpos(lea, "state police")==0
replace lea = subinstr(lea, "sp:" , "state police:" , .) if agctype==5 & strpos(lea, "state police")==0
replace lea = subinstr(lea, "st ptrl:" , "state patrol:" , .) if agctype==5 & strpos(lea, "state patrol")==0
replace lea = subinstr(lea, "div " , "division " , .) if agctype==5 & strpos(lea, "division")==0
replace lea = subinstr(lea, "dps " , "department of public safety " , .) if agctype==5 & strpos(lea, "department of public safety")==0
replace lea = subinstr(lea, "dps-" , "department of public safety-" , .) if agctype==5 & strpos(lea, "department of public safety")==0
replace lea = subinstr(lea, "hp:" , "highway patrol:" , .) if agctype==5 & strpos(lea, "highway patrol")==0
replace lea = subinstr(lea, "hp " , "highway patrol " , .) if agctype==5 & strpos(lea, "highway patrol")==0
replace lea = subinstr(lea, "sheriffs" , "sheriff's" , .)
replace lea = subinstr(lea, "sheriff's department" , "sheriff's office" , .)
replace lea = subinstr(lea, "sheriff's dept" , "sheriff's office" , .)
duplicates drop

*make lea to geo
bys lea state agctype: gen geoorder = _n 
reshape wide statefips countyfips ,i(lea state agctype) j(geoorder)
sort lea state 
gen leaorder_icpsr = _n

duplicates drop lea state , force

save "$oi/xwalk/lea_geo_icpsr", replace



*-------- PART 1: OBTAIN OF GEOCODES -----------
import excel using "$or/xwalk/all-geocodes-v2018", cellrange(A5:G43823) clear firstrow
gen ogorder = _n
rename (StateCodeFIPS CountyCodeFIPS CountySubdivisionCodeFIPS PlaceCodeFIP ConsolidtatedCityCodeFIPS AreaName) ///
(statefips countyfips subcountyfips placefips cityfips geoname)
replace geoname = strlower(geoname)
foreach v of varlist _all {
	cap destring `v', replace
	cap replace `v' = strlower(`v')
}
drop if statefips==0
gen state = geoname if countyfips==0 & subcountyfips==0 &  placefips==0 &  cityfips==0
bys statefips: ereplace state = mode(state)

*obtain state names
preserve 
keep state statefips
duplicates drop 
tempfile states 
save `states'
restore 

* obtain county names 
preserve
drop if countyfips==0
bys statefips countyfips (ogorder): keep if _n==1
gen countyname = geoname
tempfile counties
save `counties'
restore 

*-------- PART 3: CONNECT -----------
* fuzzy match to lea geo codes
use "$oi/xwalk/wayback_lea_list", clear

* merge to the ICPSR crosswalk
merge m:1 lea state using "$oi/xwalk/lea_geo_icpsr.dta", gen(hasgeo) keep(1 3)

* obtain geography of remaining counties
gen geoname = lea if hasgeo==1
replace geoname = "" if jurisdiction=="state"
local lea_keywords `" "sheriff's" "sheriff’s" "sheriffs" "sheriff"  "office" "department of" "department" "public safety" "district jail" "jail" "corrections" "police" "state" "regional adult detention center" "criminal justice authority" "detention facilities" "'
local nkwords: word count `lea_keywords'
forval i = 1/`nkwords' {
	local kword: word `i' of `lea_keywords'
	replace geoname = subinstr(strlower(geoname), "`kword'", "", .)
}
replace geoname = trim(geoname)
replace geoname = subinstr(strlower(geoname), "city of ", "", .) if strpos(strlower(geoname), "city of ")>0
replace geoname = geoname + " city" if strpos(strlower(geoname), "city")==0 & jurisdiction=="city"
replace geoname = geoname + " town" if strpos(strlower(geoname), "town")==0 & jurisdiction=="town"
replace geoname = geoname + " county" if strpos(strlower(geoname), "county")==0 & jurisdiction=="county"
replace geoname = geoname + " parish" if strpos(strlower(geoname), "parish")==0 & jurisdiction=="parish"
replace geoname = "kodiak island borough" if strpos(strlower(geoname), "kodiak")>0
replace geoname = "las vegas city" if strpos(strlower(geoname), "las vegas")>0
replace geoname = "albemarle city" if geoname=="albemarle"

expand 2 if lea=="prince william-manassas regional adult detention center", gen(dup)
replace geoname = "prince william county" if lea=="prince william-manassas regional adult detention center" & dup==0
replace geoname = "manassas city" if lea=="prince william-manassas regional adult detention center" & dup==1
drop dup
replace geoname = "" if hasgeo==3
*obtain state codes
merge m:1 state using `states', nogen keep(1 3) keepusing(state statefips )

*obtain county codes
gen countyname = geoname if jurisdiction=="county" | strpos(geoname, "county")>0
merge m:1 statefips countyname using `counties', keep(1 3) keepusing(statefips countyfips countyname) nogen //waria-labelon 

replace jurisdiction= "state" if jurisdiction==""


forval i = 4/64 {
	drop statefips`i' countyfips`i'
}

replace countyfips1 = countyfips if mi(countyfips1) & !mi(countyfips)
replace statefips1 = statefips if mi(statefips1) & !mi(statefips)
drop countyfips countyname statefips leaorder_icpsr hasgeo geoname unique_lea
 
//if countyfips1 is missing assume it's a state
replace countyfips1 = . if jurisdiction=="state" | agctype==5
replace countyfips2 = . if jurisdiction=="state" | agctype==5
replace countyfips3 = . if jurisdiction=="state" | agctype==5

replace statefips2 = . if jurisdiction=="state" | agctype==5
replace statefips3 = . if jurisdiction=="state" | agctype==5

drop statefips2 countyfips2 statefips3 countyfips3
rename (statefips1 countyfips1) (statefips countyfips)

compress 
save  "$oi/ice_all_287g_clean", replace




