/*---------------------
Mena kiser
10-19-25

Create crosswalks, main geo unit of interest if MIGPUMA 2010 definition (migpuma10 )
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


*-------------- MIGPUMA 2000 to 2010 definition ------------------*
* convert year 2011 from 2000 definition to 2010 using largest pair not included elsewhere
import excel using "$or/xwalk/MIGPUMA2000_MIGPUMA2010_crosswalk.xls", clear firstrow cellrange(A1:X2528)
foreach v of varlist _all {
	cap destring `v', replace
}
bys State00 MigPUMA00 (pMigPUMA00_Pop10 pMigPUMA00_Pop00): keep if _n==_N //keep the assigned migpuma2010 with largest intesection (using 2010 pop and breaking ties with 2000 pop)
count if State00 != State10
rename (State00 MigPUMA00 MigPUMA10) (statefips migpuma00 migpuma10)
keep statefips migpuma00 migpuma10 pMigPUMA00_Pop10
compress 
save "$oi/xwalk/migpuma_00_10", replace 

*--------------- PUMA TO MIGPUMA ------------------*
import excel using "$or/xwalk/puma_migpuma1_pwpuma00_2010.xls", clear firstrow cellrange(A3:D2381)
foreach v of varlist _all {
	cap destring `v', replace
}
count if StateofResidenceST != PlaceofWorkStatePWSTATE2o
rename (StateofResidenceST PUMA PWPUMA00orMIGPUMA1) (statefips puma10 migpuma10 )
keep statefips puma10 migpuma10 
isid statefips puma10 //no puma spills over multiple migpuma 

compress 
save "$oi/xwalk/puma10_migpuma10", replace 


*--------------- COUNTY FIPS to MIGPUMA ------------------*
*using geocorr county to puma crosswalk then puma to migpuma crosswalk
*remember every migpuma corresponds to exactly one or more pumas
import delimited using "$or/xwalk/geocorr2018_county_puma.csv", clear varnames(1) 
foreach v of varlist _all {
	local vlab = `v'[1]
	label var `v' "`vlab'"
}
drop if _n==1
foreach v of varlist _all {
	cap destring `v', replace
}
rename (county state puma12) (countyfips statefips puma10) //puma corresponds to '2010 definition' which was used starting 2012, confusing right?
tostring countyfips statefips, replace
replace countyfips = subinstr(countyfips, statefip, "", 1)
destring countyfips statefips, replace

isid countyfips statefips puma10
* add migpuma variable
merge m:1 statefips puma10 using "$oi/xwalk/puma10_migpuma10" , nogen keep(1 3) //dropping PR

* county fips to migpuma 
egen mig_county = tag(statefips migpuma10 countyfips) 
bys statefips migpuma10 : egen countiesinmig = sum(mig_county)
bys statefips countyfips : egen migsincounty = sum(mig_county)

sum countiesinmig migsincounty //every county has exactly one migpuma, meaning counties don't spread across multiple migpumas

collapse (sum) pop10, by(statefips countyfips migpuma10) //remove puma
isid statefips countyfips
bys statefips migpuma10: egen migpop10 = sum(pop10)
gen afact = pop10/migpop10 //share of county pop corresponding to the migpuma

tostring countyfips statefips, replace
replace countyfips = subinstr(countyfips, statefip, "", 1)
destring countyfips statefips, replace
compress 
save "$oi/xwalk/county_migpuma10", replace 


*--------------- PLACE FIPS to MIGPUMA ------------------*
*using geocorr county to puma crosswalk then puma to migpuma crosswalk
*remember every migpuma corresponds to exactly one or more pumas
import delimited using "$or/xwalk/geocorr2018_place_puma.csv", clear varnames(1) 
foreach v of varlist _all {
	local vlab = `v'[1]
	label var `v' "`vlab'"
}
drop if _n==1
foreach v of varlist _all {
	cap destring `v', replace
}
rename (placefp state puma12) (placefips statefips puma10) //puma corresponds to '2010 definition' which was used starting 2012
isid placefips statefips puma10
* add migpuma variable
merge m:1 statefips puma10 using "$oi/xwalk/puma10_migpuma10" , nogen keep(1 3) //dropping PR

* county fips to migpuma 
drop if placefips == 99999
egen mig_place = tag(statefips migpuma10 placefips) 
bys statefips migpuma10 : egen placesinmig = sum(mig_place)
bys statefips placefips : egen migsinplace = sum(mig_place)

sum placesinmig migsinplace //place fips can have multiple migpumas, migpumas can have multiple places

collapse (sum) pop10, by(statefips placefips migpuma10) //remove puma
isid statefips placefips migpuma10

bys statefips migpuma10: egen migpop10 = sum(pop10)
gen afact = pop10/migpop10 //share of place pop corresponding to the migpuma
bys statefips placefips : gen migorder = _n
reshape wide afact migpuma10 pop10 migpop10, i(statefips placefips) j(migorder)

compress 
save "$oi/xwalk/place_migpuma10", replace 



*--------------- PLACE FIPS to COUNTY FIPS ------------------*
import delimited using "$or/xwalk/geocorr2018_place_county.csv", clear varnames(1) 
foreach v of varlist _all {
	local vlab = `v'[1]
	label var `v' "`vlab'"
}
drop if _n==1
foreach v of varlist _all {
	cap destring `v', replace
}
rename (placefp state county) (placefips statefips countyfips) //puma corresponds to '2010 definition' which was used starting 2012
isid placefips statefips countyfips
drop afact placenm cntyname stab

tostring countyfips statefips, replace
replace countyfips = subinstr(countyfips, statefip, "", 1)
destring countyfips statefips, replace

* county fips to migpuma 
drop if placefips == 99999
bys statefips countyfips: egen countypop10 = sum(pop10)
gen afact = pop10/countypop10 //share of place pop in county
bys statefips placefips : gen countyorder = _n
reshape wide afact countyfips pop10 countypop10, i(statefips placefips) j(countyorder)



compress 
save "$oi/xwalk/place_county", replace 


