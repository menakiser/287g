/*---------------------
Mena kiser
10-19-25

Create exposure level variable matching migration level codes: county and puma
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


*--------------- exposure at the COUNTY LEVEL ------------------*
use "$oi/ice_all_287g_clean", clear 

*register date signed as the first date retrieved
sort dateretrieved //first observed year 2011-02-20, all date signed in 2011 were pre 2010-08-19
expand 2 if dateretrieved!=datesigned, gen(dup)
replace dateretrieved=datesigned if dup==1 
gen signing_date =  dateretrieved==datesigned
drop dup datesigned
duplicates drop
gen dateretrieved_d = date(dateretrieved, "YMD")
format dateretrieved_d  %td
drop dateretrieved 

* exclude state and state-level corrections
gen county_exp = !(agctype==5) & !(jurisdiction=="state" & mi(agctype))
gen state_exp = agctype==5 | (jurisdiction=="state" & mi(agctype))

* obtain county level exposure at date of retrieval
collapse (max) county_exp state_exp signing_date, by(dateretrieved supporttype statefips countyfips)
replace countyfips = 99999 if mi(countyfips)
egen authority = group(supporttype statefips countyfips)

* obtain authority by date panel for treatment
xtset authority dateretrieved_d
tsfill, full
foreach v in supporttype statefips countyfips {
	bys authority: ereplace `v' = mode(`v')
}

* flag exposure
gen observed = !mi(county_exp) | !mi(state_exp)
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

* county exposure
cap drop exposure_county
sort authority date
by authority (date): gen exposure_county = county_exp if !missing(county_exp)
by authority (date): replace exposure_county = exposure_county[_n-1] if missing(exposure_county)  & exposure==1
replace exposure_county = 0 if exposure == 0

* state exposure
cap drop exposure_state
sort authority date
by authority (date): gen exposure_state = state_exp if !missing(state_exp)
by authority (date): replace exposure_state = exposure_state[_n-1] if missing(exposure_state)  & exposure==1
replace exposure_state = 0 if exposure == 0

* collapse by year from 2011 (first year of retrieval) to 2019 (last year of sample)
sort date //start date 01 feb 2005, end on 21 feb 2025 (last date of retrieval)
gen year = year(date) 
gen month = month(date) 

* drop task force and hybrid after 2012
replace exposure_state = 0 if  supporttype =="jail & task force" & year>=2013
replace exposure_state = 0 if  supporttype =="task force" & year>=2013

collapse (max) exposure_state  exposure_county  , by(year month supporttype statefips countyfips) 
keep if year >=2011 & year <=2019
keep if month==1
drop month

*drop counties with no exposure during this period
bys statefips countyfips: egen some_exp = max(exposure_state>0 | exposure_county>0)
drop if some_exp == 0
drop some_exp

foreach t in jail task warrant {
	foreach j in state county {
		gen exp_`t'_`j' = exposure_`j' if strpos(supporttype, "`t'")>0
		replace exp_`t'_`j' = 0 if mi(exp_`t'_`j')	
	}
}

collapse (max) exp_any_state=exposure_state exp_any_county=exposure_county ///
	exp_jail_state exp_jail_county ///
	exp_task_state exp_task_county ///
	exp_warrant_state exp_warrant_county, by(statefips countyfips year)

* rename to match acs 
rename countyfips countyfip
rename statefips statefip

* store county exposure
preserve
drop if countyfip==99999
drop *_state
tab year if countyfip<99999
//100 unique counties
//9 years of treatment

compress
save "$oi/exposure_county_year", replace
restore 

* store state exposure
collapse (max) exp_any_state exp_jail_state exp_task_state exp_warrant_state, by(statefip year)


compress
save "$oi/exposure_state_year", replace


* migpuma exposure
use "$oi/exposure_county_year" , clear
rename countyfip countyfips
merge m:1 statefip countyfip using "$oi/xwalk/county_migpuma10", nogen keep(1 3)
rename countyfips countyfip
collapse (max) exp_any_migpuma=exp_any_county exp_jail_migpuma=exp_jail_county exp_task_migpuma=exp_task_county exp_warrant_migpuma=exp_warrant_county, by(statefip migpuma10 year)
compress
save "$oi/exposure_migpuma10_year", replace

* migpuma exposure
use "$oi/exposure_county_year" , clear
rename countyfip countyfips
merge m:1 statefip countyfip using "$oi/xwalk/county_puma10" , nogen keep(1 3)
rename countyfips countyfip
reshape long puma10 pop10 afact , i(statefip countyfip year) j(pumaorder)
drop if mi(afact)
drop if mi(puma10)
duplicates drop

foreach v in exp_any_ exp_jail_ exp_task_ exp_warrant_ {
	gen wt_`v'puma = `v'county*afact
}

collapse (max) exp_any_puma=exp_any_county exp_jail_puma=exp_jail_county exp_task_puma=exp_task_county exp_warrant_puma=exp_warrant_county ///
	(sum) wt_exp_any_puma wt_exp_jail_puma wt_exp_task_puma wt_exp_warrant_puma ///
	, by(statefip puma10 year)
compress
save "$oi/exposure_puma10_year", replace

