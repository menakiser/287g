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
rename (State00 MigPUMA00 MigPUMA10) (statefip migpuma00 migpuma10)
keep statefip migpuma00 migpuma10 pMigPUMA00_Pop10
compress 
save "$oi/xwalk/migpuma_00_10", replace 

*--------------- PUMA 2000 TO PUMA 2010 ------------------*
import excel using "$or/xwalk/PUMA2000_PUMA2010_crosswalk.xls", clear firstrow
foreach v of varlist _all {
	cap destring `v', replace
}
rename (State00 PUMA00 State10 PUMA10) (statefip00 puma00 statefip10 puma10)
keep statefip00 puma00 statefip10 puma10 Part_Pop10 Part_Pop00
bys statefip00 puma00 (Part_Pop10 Part_Pop00): keep if _n==_N

drop statefip10 Part_Pop00 Part_Pop10
rename statefip00 statefip
compress 
save "$oi/xwalk/puma00_puma10", replace 

*--------------- PUMA TO MIGPUMA ------------------*
import excel using "$or/xwalk/puma_migpuma1_pwpuma00_2010.xls", clear firstrow cellrange(A3:D2381)
foreach v of varlist _all {
	cap destring `v', replace
}
count if StateofResidenceST != PlaceofWorkStatePWSTATE2o
rename (StateofResidenceST PUMA PWPUMA00orMIGPUMA1) (statefip puma10 migpuma10 )
keep statefip puma10 migpuma10 
isid statefip puma10 //no puma spills over multiple migpuma 

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
rename (county state puma12) (countyfips statefip puma10) //puma corresponds to '2010 definition' which was used starting 2012, confusing right?
tostring countyfips statefip, replace
replace countyfips = subinstr(countyfips, statefip, "", 1)
destring countyfips statefip, replace

isid countyfips statefip puma10

preserve
keep statefip countyfips puma10 pop10 afact
bys statefip countyfips: gen pumaorder = _n
reshape wide puma10 pop10 afact, i(statefip countyfips) j(pumaorder)
save "$oi/xwalk/county_puma10", replace
restore

* add migpuma variable
merge m:1 statefip puma10 using "$oi/xwalk/puma10_migpuma10" , nogen keep(1 3) //dropping PR

* county fips to migpuma 
egen mig_county = tag(statefip migpuma10 countyfips) 
bys statefip migpuma10 : egen countiesinmig = sum(mig_county)
bys statefip countyfips : egen migsincounty = sum(mig_county)

sum countiesinmig migsincounty //every county has exactly one migpuma, meaning counties don't spread across multiple migpumas

collapse (sum) pop10, by(statefip countyfips migpuma10) //remove puma
isid statefip countyfips
bys statefip migpuma10: egen migpop10 = sum(pop10)
gen afact = pop10/migpop10 //share of county pop corresponding to the migpuma

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
rename (placefp state puma12) (placefips statefip puma10) //puma corresponds to '2010 definition' which was used starting 2012
isid placefips statefip puma10
* add migpuma variable
merge m:1 statefip puma10 using "$oi/xwalk/puma10_migpuma10" , nogen keep(1 3) //dropping PR

* county fips to migpuma 
drop if placefips == 99999
egen mig_place = tag(statefip migpuma10 placefips) 
bys statefip migpuma10 : egen placesinmig = sum(mig_place)
bys statefip placefips : egen migsinplace = sum(mig_place)

sum placesinmig migsinplace //place fips can have multiple migpumas, migpumas can have multiple places

collapse (sum) pop10, by(statefip placefips migpuma10) //remove puma
isid statefip placefips migpuma10

bys statefip migpuma10: egen migpop10 = sum(pop10)
gen afact = pop10/migpop10 //share of place pop corresponding to the migpuma
bys statefip placefips : gen migorder = _n
reshape wide afact migpuma10 pop10 migpop10, i(statefip placefips) j(migorder)

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
rename (placefp state county) (placefips statefip countyfips) //puma corresponds to '2010 definition' which was used starting 2012
isid placefips statefip countyfips
drop afact placenm cntyname stab

tostring countyfips statefip, replace
replace countyfips = subinstr(countyfips, statefip, "", 1)
destring countyfips statefip, replace

* county fips to migpuma 
drop if placefips == 99999
bys statefip countyfips: egen countypop10 = sum(pop10)
gen afact = pop10/countypop10 //share of place pop in county
bys statefip placefips : gen countyorder = _n
reshape wide afact countyfips pop10 countypop10, i(statefip placefips) j(countyorder)

compress 
save "$oi/xwalk/place_county", replace 

*--------------- CPUMA10 TO PUMA10 ------------------*
import excel using "$or/CPUMA0010_summary", clear firstrow
split PUMA10_List, gen(puma10_) parse(", ")
destring State_FIPS, gen(statefip)
reshape long puma10_, i(CPUMA0010 statefip) j(pumaorder)

keep CPUMA0010 statefip puma10_
duplicates drop
drop if mi(puma10_)
rename (CPUMA0010 puma10_ ) (cpuma0010 puma10)

* remove state
destring puma10, replace
tostring puma10, replace
replace puma10 = subinstr(puma10, string(statefip), "", 1)
destring puma10, replace
duplicates drop
bys cpuma0010: gen pumaorder = _n
reshape wide puma10 , i(cpuma0010 statefip) j(pumaorder)

compress 
save "$oi/xwalk/cpuma10_puma10", replace 


*--------------- SECURE COMMUNITIES PUMA TO MIGPUMA ------------------*
use "$or/287g_SC_EVerify_5_13_22_cpuma0010.dta", clear
merge m:1 cpuma0010 using "$oi/xwalk/cpuma10_puma10", nogen keep(1 3)

reshape long puma10, i(cpuma0010 statefip year) j(pumaorder)
drop if mi(puma10) & pumaorder>1
drop pumaorder
duplicates drop
gen SC_any = SC_jan>0 |  SC_march>0 | SC_frac>0

preserve 
collapse (max) SC_any, by( statefip year puma10)
compress 
save "$oi/puma10_SC", replace 
restore 

merge m:1 statefip puma10 using "$oi/xwalk/puma10_migpuma10" , nogen keep(1 3)
collapse (max) SC_any, by( statefip year migpuma10)
compress 
save "$oi/migpuma10_SC", replace 
