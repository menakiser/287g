/*---------------------
Mena kiser
10-15-25

Obtain geo codes from LEA participating in 287g 
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
replace LEA = "City of Mesa Police Department" if LEA == "Mesa Police Department"
replace LEA = "City of Durham Police Department" if LEA == "Durham Police Department"
replace LEA = "Prince William-Manassas Regional Adult Detention Center" if LEA == "Prince William-Manassas Regional Jail"
replace LEA = "Massachusetts Department of Corrections" if LEA=="Massachusetts Department of Correction"
replace LEA = subinstr(LEA, " (Addendum)", "", . )
replace LEA = subinstr(LEA, " Addendum", "", . )
* burnet county was mistakenly assigned florida: https://web.archive.org/web/20200606022401/https://www.ice.gov/doclib/287gMOA/287gWSO_BurnetCoTx2019-11-05.pdf
replace STATE = "TEXAS" if LEA =="Burnet County Sheriff's Office"
replace LEA = "Harford County Sheriff's Office" if LEA == "Hartford County Sheriff's Office"
replace LEA = subinstr(LEA, "St Johns", "St. Johns", .)
replace LEA = subinstr(LEA, "Albermarle", "Albemarle", .) if STATE == "GEORGIA" | STATE == "NORTH CAROLINA"
replace STATE = "NORTH CAROLINA" if strpos(LEA, "Albemarle")>0
replace STATE = "NORTH CAROLINA" if strpos(LEA, "Caldwell County") & STATE == "GEORGIA" 
replace STATE = "TEXAS" if strpos(LEA, "Aransas County")
replace STATE = "MONTANA" if strpos(LEA, "Gallatin")>0
replace LEA = subinstr(LEA, "Mantiowoc", "Manitowoc", .)

tab supporttype

* remove duplicates, storing the date of first and last retrieval
//datesigned = YYYY-MM-DD
gen dateretrieved = substr(datename, 1, 4) + "-" + substr(datename, 5, 2) + "-" + substr(datename, 7, 2)

duplicates report STATE LEA supporttype datesigned dateretrieved
destring datename, replace
bys STATE LEA supporttype datesigned dateretrieved (datename): keep if _n==_N

/*
bys STATE supporttype LEA datesigned (dateretrieved) : gen firstretrieval = dateretrieved if _n==1
bys STATE supporttype LEA datesigned (dateretrieved) : ereplace firstretrieval = mode(firstretrieval)
bys STATE supporttype LEA datesigned (dateretrieved) : gen lastretrieval = dateretrieved if _n==_N
bys STATE supporttype LEA datesigned (dateretrieved) : ereplace lastretrieval = mode(lastretrieval)

bys STATE supporttype LEA datesigned (dateretrieved) : keep if _n==_N
*/

drop link1 link2 information1 information2 filename
sort dateretrieved STATE supporttype LEA 

sort STATE supporttype LEA

drop datename table_order norder total_tables


* Find localities
gen jurisdiction  = "county" if strpos(strlower(LEA), "county")>0
replace jurisdiction  = "city" if strpos(strlower(LEA), "city")>0 & mi(jurisdiction)
replace jurisdiction  = "parish" if strpos(strlower(LEA), "parish")>0 & mi(jurisdiction)
replace jurisdiction  = "state" if strpos(strupper(LEA), STATE)>0 & mi(jurisdiction)
replace jurisdiction = "corrections" if strpos(strlower(LEA), "jail")>0 | strpos(strlower(LEA), "correction")>0 | strpos(strlower(LEA), "detention")>0

* examine LEA's with missing jurisdictions
egen unique_lea = tag(STATE LEA)
count if  unique_lea==1 & mi(jurisdiction) //only 10, hardcode it

* 17 LEA with missing jurisdiction info
replace jurisdiction = "county" if LEA=="Kodiak Police Department"
replace jurisdiction = "town" if LEA=="Florence Police Department"
replace jurisdiction = "city" if LEA=="Rogers Police Department"
replace jurisdiction = "city" if LEA=="Jacksonville Sheriff's Office"
replace jurisdiction = "city" if LEA=="Carrollton Police Department"
replace jurisdiction = "city" if LEA=="Farmers Branch Police Department"
replace jurisdiction = "city" if LEA=="Las Vegas Metropolitan Police Department"
replace jurisdiction = "town" if LEA=="Herndon Police Department"
replace jurisdiction = "city" if LEA=="Manassas Park Police Department"
replace jurisdiction = "city" if LEA=="Manassas Police Department"

* obtain geography
gen geoname = LEA 
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

expand 2 if LEA=="Prince William-Manassas Regional Adult Detention Center", gen(dup)
replace geoname = "prince william county" if LEA=="Prince William-Manassas Regional Adult Detention Center" & dup==0
replace geoname = "manassas city" if LEA=="Prince William-Manassas Regional Adult Detention Center" & dup==1
drop dup
*simplify jurisdiction
replace jurisdiction = "county" if jurisdiction=="parish" //county or equivalent
replace jurisdiction = "city" if jurisdiction=="town" //anything smaller than county

gen state = strlower(STATE)

* state level correction facilities
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
drop countyname placename STATE unique_lea countyfips

compress 
save  "$oi/ice_all_287g_clean", replace
