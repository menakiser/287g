/*---------------------
Mena kiser
10-19-25

Validate treatment using ICE FOIA list exposure level variable matching migration level codes: county and puma

---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


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


*-------- PART 2: OBTAIN FOIA LEA AND COUNTIES -----------
* OBTAIN FOIA lists
import excel using "$or/foia/287gCommunities2009-2017", clear 

* obtain what i assume are retrieval dates?
gen ym = ""
forval y = 2009/2017 {
	replace ym = A if strpos(A, "`y'")>0
}
replace ym = ym[_n-1] if ym=="" &  ym[_n-1] !=""
drop if mi(A) | A==ym

rename (A B) (lea geoname)
drop if _n==1

generate num_date = date(ym, "MY")
gen year = year(num_date)
gen month = month(num_date)
drop num_date ym

replace lea = strlower(lea)
duplicates drop 


gen state = substr(geoname, -4, 4)
replace geoname = subinstr(geoname, state, "", .)
replace state = subinstr(state, ", ", "", .)
replace state = "TX" if state == "exas"
replace state = trim(state)
replace state = "FL" if state=="Fl"
replace geoname = trim(geoname)
replace geoname = subinstr(geoname, ", T", "", .)
replace geoname = subinstr(geoname, ",", "", .)

* clean some lea namess
replace lea = subinstr(lea, " - ", "-", .)
replace lea = subinstr(lea, ", ar", "", .)
replace lea = subinstr(lea, ", ut", "", .)
replace lea = subinstr(lea, ", nc", "", .)
replace lea = subinstr(lea, ",", "", .)
replace lea = subinstr(lea, " (tfo)", "", .)
replace lea = subinstr(lea , "sheriff's department", "sheriff's office", .)
replace lea = subinstr(lea, "city of manassas", "manassas city", .)
replace lea = subinstr(lea, "prince william-manassas adult detention center", "prince william-manassas regional adult detention center", .)
replace lea = subinstr(lea, "sheriff’s", "sheriff's", .)
replace lea = subinstr(lea, "." , "" , .)
replace lea = subinstr(lea, "  " , " " , .)
replace lea = subinstr(lea, "’" , `"'"' , .)
replace lea = subinstr(lea, "sheriffs" , "sheriff's" , .)
replace lea = subinstr(lea, "sheriff's department" , "sheriff's office" , .)
replace lea = subinstr(lea, "city of " , "" , .)
replace lea = subinstr(lea, "sheriff office" , "sheriff's office", .)
replace lea = subinstr(lea, "colunty" , "county", .)

rename state ST2digitcode  
merge m:1 ST2digitcode  using "/Users/jimenakiser/liegroup Dropbox/Jimena Villanueva Kiser/handy crosswalks/state_crosswalk.dta", keepusing(state) nogen keep(1 3)

replace lea = "manassas police department" if lea=="manassas city police department" & state=="virginia"
replace lea = "maricopa county sheriff's office" if lea == "maricopa county az sheriff's office" & state=="arizona"
replace lea = "prince william county sheriff's office" if lea == "prince william sheriff's office" & state=="virginia"

duplicates drop
isid lea year state

gen infoia = 1
tempfile icefoia
save `icefoia'



*------------------*
keep geoname state
duplicates drop





merge 1:m lea state using "$oi/ice_all_287g_clean"







gen dateretrieved_d = date(dateretrieved, "YMD")

anne arundel anne arundel county detention facilities
replace lea = subinstr(lea , "sheriffs", "sheriff's", .)
replace lea = subinstr(lea , "sheriff's department", "sheriff's office", .)
replace lea = subinstr(lea , "sheriff department", "sheriff's office", .)
replace lea = subinstr(lea , "sheriff office", "sheriff's office", .)
keep lea state dateretrieved_d
duplicates drop

* obtain authority by date panel for treatment
gen observed = 1
egen authority = group(lea state)
xtset authority dateretrieved_d
tsfill, full
foreach v in lea state  {
	bys authority: ereplace `v' = mode(`v')
}
replace observed =  0 if mi(observed)

* flag exposure
bys dateretrieved: egen any_observed = max(observed)
tab observed any_observed
* used CHATGPT for lines 59 to 74
gen toggle = .
replace toggle = 1 if any_observed == 1 & observed == 1     // turn ON
replace toggle = 0 if any_observed == 1 & observed == 0     // turn OFF

* flag any exposure
bys authority (date): gen exposure = .
bys authority (date): replace exposure = toggle if toggle < .
bys authority (date): replace exposure = exposure[_n-1] if missing(exposure)
bys authority: replace exposure = 0 if missing(exposure)

gen year = year(dateretrieved_d)
gen month = month(dateretrieved_d)
merge m:1 lea year month state using `icefoia'
count if _m==2 & year>=2011 //31


use "$oi/exposure_county_year", clear 


lea
anne arundel county detention facilities
calhoun county sheriff's office
chambers county sheriff's office
cumberland county sheriff's office
danbury police department
dewitt colunty sheriff's office
durham police department
east baton rouge parish sheriff's office
east baton rouge parish sheriff's office
galveston county sheriff's office
goliad county sheriff's office
hudson police department
knox county sheriff's office
lavaca county sheriff's office
manassas city police department
massachusetts state police
montgomery county sheriff's office
nye county sheriff's office
nye county sheriff's office
phoenix police department
prince william sheriff's office
refugio county sheriff's office
salem county sheriff's office
smith county sheriff's office
springdale police department
tarrant county sheriff's office
tennessee highway patrol
victoria county sheriff's office
walker county sheriff's office
waller county sheriff's office
wharton county sheriff's office
