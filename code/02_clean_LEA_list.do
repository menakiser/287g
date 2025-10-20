/*---------------------
Mena kiser
10-15-25

Obtain geo codes from lea participating in 287g 
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


*-------- PART 1: OBTAIN OF GEOCODES -----------
import excel using "$or/xwalk/all-geocodes-v2020", cellrange(A5:G43823) clear firstrow
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

* obtain geo names for areas smaller than counties
preserve
drop if subcountyfips==0 & placefips==0 & cityfips==0
bys statefips countyfips subcountyfips placefips cityfips (ogorder): keep if _n==1
gen placename = geoname
keep if inlist(statefips, 4, 5, 9, 12, 32, 37, 48, 51) //keeping only relevant states
bys state geoname: drop if _N>1 //dropping lakeside town, oak ridge town, reno city , not needed
tempfile places
save `places'
restore 


*-------- PLACE BY COUNTY -----------
*used to obtain county codes for each place
insheet using "$or/xwalk/national_place_by_county2020.txt", clear delimiter("|")
rename (statefp countyfp placefp) (statefips countyfips placefips)
keep if inlist(statefips, 4, 5, 9, 12, 32, 37, 48, 51)
replace placename = strlower(placename)
replace countyname = strlower(countyname)
tempfile places_wcounty
save `places_wcounty'

use `places' , clear 
drop countyfips 
merge 1:m statefips placename using `places_wcounty', keep(3) keepusing(statefips placename placefips countyfips) nogen
keep statefips placename placefips countyfips
//adjust for cities spanning over multiple counties
bys statefips placefips: gen countyorder = _n 
reshape wide countyfips , i(statefips placename placefips) j(countyorder)
tempfile places_wcounty
save `places_wcounty', replace

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

* obtain geography
gen geoname = lea 
replace geoname = "" if jurisdiction=="state"
local lea_keywords `" "sheriff's" "sheriff’s" "sheriffs" "sheriff"  "office" "department of" "department" "public safety" "district jail" "jail" "corrections" "police" "state" "regional adult detention center" "criminal justice authority" "'
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

*simplify jurisdiction
replace jurisdiction = "county" if jurisdiction=="parish" //county or equivalent
replace jurisdiction = "city" if jurisdiction=="town" //anything smaller than county

* drop state level agreements and state level correction facilities
replace geoname = "" if jurisdiction=="state" | geoname==state

***** MERGE WITH GEOCODES
*obtain state codes
merge m:1 state using `states', nogen keep(1 3) keepusing(state statefips )

*obtain county codes
gen countyname = geoname if jurisdiction=="county" | strpos(geoname, "county")>0
merge m:1 statefips countyname using `counties', keep(1 3) keepusing(statefips countyfips countyname) nogen
*obtain city/town codes
gen placename = geoname if countyfips==.
merge m:1 statefips placename using `places', keep(1 3) keepusing(placename statefips countyfips subcountyfips placefips cityfips) nogen
drop subcountyfips cityfips //all missing
bys state: ereplace statefips = mode(statefips)
* assign a county to all city/town codes
merge m:1 statefips placefips using `places_wcounty', keep(1 3) keepusing(placename statefips countyfips*) nogen //all placenames are assigned a county
drop countyfips4 countyfips5 //all missing 
replace countyfips1 = countyfips if mi(countyfips1)

gen geolevel = "state" if mi(countyfips) & mi(placefips)
replace geolevel = "county" if !mi(countyfips)
replace geolevel = "place" if !mi(placefips)

replace geoname = state if mi(geoname)
drop countyname placename unique_lea countyfips

compress 
save  "$oi/ice_all_287g_clean", replace
