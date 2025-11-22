/*---------------------
Mena kiser
10-19-25

Create exposure level variable matching migration level codes: county and puma
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"

global covars "age r_white r_black r_asian hs in_school no_english ownhome"
global invars "exp_any_state " //SC_any
global outvars "prev_exp_any_state " //prev_SC_any

use "$oi/working_acs", clear 
keep if year >= 2012
drop if always_treated_migpuma==1

* define propensity weights
merge m:1 statefip current_migpuma  using  "$oi/propensity_weights2012migpuma_t2" , nogen keep(3) keepusing( phat wt)
gen perwt_wt = perwt*wt
drop if mi(perwt_wt)

* Identify populations
*targetpop2
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & young==1  & marst>=3  //hispanic citizens born in the usa
gen spillover1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==1 & citizen!=3 & young==1 & marst>=3
gen pop = age>=18 & age<=65
gen target_movers = move_migpuma*targetpop2

* Controls
* age
gen int_age1 = inrange(age, 0, 9) 
gen int_age2 = inrange(age, 10, 19) 
gen int_age3 = inrange(age, 20, 29)
gen int_age4 = inrange(age, 30, 39)
gen int_age5 = inrange(age, 40, 49)
gen int_age6 = inrange(age, 50, 59)
gen int_age7 = inrange(age, 60, 69)
gen int_age8 = inrange(age, 70, 100)

* Obtain totals
foreach v in targetpop2 placebo1 spillover1 pop move_migpuma target_movers ///
 r_white r_black r_asian hs in_school ownhome no_english ///
 int_age1 int_age2 int_age3 int_age4 int_age5 int_age6 int_age7 int_age8 {
	di in red "Processing `v'"
	// define unweighted populations
	gen tot_`v' = perwt*(`v'==1)
	// define weighted populations
	gen tot_`v'_wwt = perwt_wt*(`v'==1)
	//define populations for natives
	gen nat_`v' = tot_`v'*(imm==1 )
	gen nat_`v'_wwt = tot_`v'*(imm==1 )
}

drop nat_targetpop2* nat_placebo1* nat_spillover1* nat_target_movers*

* Obtain relative years for gainers and losers
* gainers
gen relative_year_gain =  year - gain_exp_year
replace relative_year_gain = . if gain_exp_year == 0
* losers
gen relative_year_lost =  year - lost_exp_year
replace relative_year_lost = . if lost_exp_year == 0

* collapse at the migpuma and year level
collapse (sum) tot_* nat_*  perwt perwt_wt ///
	(max) exp_any_migpuma  ever_treated_migpuma ever_lost_exp_migpuma ever_gain_exp_migpuma lost_exp_year gain_exp_year ///
	relative_year_gain relative_year_lost geoid_migpuma $invars ///
	, by(current_migpuma statefip year)

* obtain log version of all total and native variables
foreach v of varlist tot_* nat_*  {
    gen log_`v' = log(`v' + 1)
}

* define regression controls
global covarspop "log_tot_int_age1 log_tot_int_age2 log_tot_int_age3 log_tot_int_age4 log_tot_int_age5 log_tot_int_age6 log_tot_r_white log_tot_r_black log_tot_r_asian log_tot_hs log_tot_in_school log_tot_ownhome"
global covarsnat "log_nat_int_age1 log_nat_int_age2 log_nat_int_age3 log_nat_int_age4 log_nat_int_age5 log_nat_int_age6 log_nat_r_white log_nat_r_black log_nat_r_asian log_nat_hs log_nat_in_school log_nat_ownhome"

*** Define variables for DID
* define post for DID
gen exp_lost_migpuma = (year>=lost_exp_year)*(ever_lost_exp_migpuma==1)
gen exp_gain_migpuma = (year>=gain_exp_year)*(ever_gain_exp_migpuma==1)

* event-time indicators
forval n = 1/7 {
	gen gain_ry_plus`n'  = (relative_year_gain == `n')
	gen gain_ry_minus`n' = (relative_year_gain == -`n')
}
* event time = 0
gen gain_ry_plus0 = (relative_year_gain == 0)

* event-time indicators
forval n = 1/7 {
	gen lost_ry_plus`n'  = (relative_year_lost == `n')
	gen lost_ry_minus`n' = (relative_year_lost == -`n')
}
* event time = 0
gen lost_ry_plus0 = (relative_year_lost == 0)

* label years
forval n = 1/7 {
	label var gain_ry_plus`n' "+`n'"
	label var gain_ry_minus`n' "-`n'"
	label var lost_ry_plus`n' "+`n'"
	label var lost_ry_minus`n' "-`n'"
}
label var gain_ry_plus0 "0"
label var lost_ry_plus0 "0"

replace gain_ry_minus6 = gain_ry_minus6 | gain_ry_minus7

* save data 
compress 
save "$oi/migpuma_year_pops", replace