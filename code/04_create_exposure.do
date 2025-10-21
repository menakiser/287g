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

*frequency of retrieval
preserve 
keep dateretrieved
gen dateretrieved_d = date(dateretrieved, "YMD")
duplicates drop 
gen year = year(dateretrieved_d)
gen month = month(dateretrieved_d)
egen gt = group( year month )
bys gt : gen size = _N 
sum gt size
label var size "Retrieval dates per month"
hist size , frequency ysize(6) xsize(6)
restore 

* obtaining county shares for cities/towns
gen temp_countyfips =countyfips1
drop countyfips*
merge m:1 statefips placefips using "$oi/xwalk/place_county", nogen keep(1 3)
drop *4 *5
reshape long countyfips afact pop10 countypop10, i(lea supporttype datesigned dateretrieved state statefips placefips ) j(countyorder)
drop if countyorder>1 & (placefips==. | countyfips==.)
replace countyfips = temp_countyfips if countyfips==.
drop temp_countyfips
replace afact= 1 if mi(afact)


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
drop if jurisdiction=="state" | geolevel=="state" 

* obtain county level exposure at date of retrieval
collapse (sum) afact (max) signing_date, by(dateretrieved supporttype statefips countyfips)
egen authority = group(supporttype statefips countyfips)

* obtain authority by date panel for treatment
xtset authority dateretrieved_d
tsfill, full
foreach v in supporttype statefips countyfips {
	bys authority: ereplace `v' = mode(`v')
}

* flag exposure
gen observed = !mi(afact)
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

* weight exposure
cap drop exposure_weight
sort authority date
by authority (date): gen exposure_weight = afact if !missing(afact)
by authority (date): replace exposure_weight = exposure_weight[_n-1] if missing(exposure_weight)  & exposure==1
replace exposure_weight = 0 if exposure == 0

replace exposure = exposure * exposure_weight
drop exposure_weight

* collapse by year from 2011 (first year of retrieval) to 2019 (last year of sample)
sort date //start date 01 feb 2005, end on 21 feb 2025 (last date of retrieval)
gen year = year(date) 
collapse (mean) exposure , by(year supporttype statefips countyfips)

keep if year >=2011 & year <=2019

*drop counties with no exposure during this period
bys statefips countyfips: egen some_exp = max(exposure)
drop if some_exp == 0
drop some_exp

gen exp_jail = exposure if strpos(supporttype, "jail")>0
replace exp_jail = 0 if mi(exp_jail)
gen exp_task = exposure if strpos(supporttype, "task")>0
replace exp_task = 0 if mi(exp_task)
gen exp_warrant = exposure if strpos(supporttype, "warrant")>0
replace exp_warrant = 0 if mi(exp_warrant)

collapse (sum) exp_any=exposure exp_jail exp_task exp_warrant, by(statefips countyfips year)

tab year
drop if countyfips==0


//155 unique counties
//9 years of treatment

compress
save "$oi/exposure_county_year", replace

