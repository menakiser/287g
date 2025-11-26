/*---------------------
Mena kiser
10-19-25

Create exposure level variable matching migration level codes: county and puma
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"



use "$oi/working_acs" , clear
* drop years and puma's we don't need
keep if year>=2012
drop if puma==77777

keep year statefip current_puma exp_any_puma
duplicates drop

* identify if migpuma was ever treated
bys statefip current_puma: egen ever_treated_puma = max( exp_any_puma>0)
keep if ever_treated_puma==1

*identify if migpuma was always treated
bys statefip current_puma: egen always_treated_puma = max( exp_any_puma==0)
replace always_treated_puma = !always_treated_puma
sort statefip current_puma year

* identifying gain and lost events
bys statefip current_puma (year): gen gain_exp_puma = exp_any_puma[_n-1] == 0 & exp_any_puma==1
bys statefip current_puma (year): gen lost_exp_puma = exp_any_puma[_n-1] == 1 & exp_any_puma==0
gen gain_exp_year = year if gain_exp_puma==1
gen lost_exp_year = year if lost_exp_puma==1
replace gain_exp_year = 0 if mi(gain_exp_year)
replace lost_exp_year = 0 if mi(lost_exp_year)
bys statefip current_puma (year): ereplace gain_exp_year = max(gain_exp_year)
bys statefip current_puma (year): ereplace lost_exp_year = max(lost_exp_year)

bys statefip current_puma (year): egen ever_gain_exp_puma = max(gain_exp_puma)
bys statefip current_puma (year): egen ever_lost_exp_puma = max(lost_exp_puma)

tab exp_any_puma if year>=gain_exp_year & ever_gain_exp_puma==1 //all 1
tab exp_any_puma if year<gain_exp_year & ever_gain_exp_puma==1 //all zero except for two migpumas

tab exp_any_puma if year<lost_exp_year & ever_lost_exp_puma==1 //all 1
tab exp_any_puma if year>=lost_exp_year & ever_lost_exp_puma==1 //all zero except for two migpumas

drop exp_any_puma

* save for all current migpuma
save "$oi/list_gain_lost_puma", replace


/* save for previous migpuma
use "$oi/list_gain_lost_puma", clear
foreach v in  year statefip ever_treated_puma always_treated_puma gain_exp_puma lost_exp_puma gain_exp_year lost_exp_year ever_gain_exp_puma ever_lost_exp_puma {
	rename `v' prev_`v'
}
rename current_puma prev_puma
tempfile prev_losttreat 
save `prev_losttreat'
*/
//PUMAS 1701 1702 1703 1704 in state 37
use "$oi/working_acs" , clear
cap drop ever_treated_puma always_treated_puma gain_exp_puma lost_exp_puma  ever_gain_exp_puma ever_lost_exp_puma 
* connect lost and gains for current migpuma, full sample
merge m:1 statefip current_puma year using "$oi/list_gain_lost_puma", nogen keep(1 3)
foreach v in  ever_treated_puma always_treated_puma gain_exp_puma lost_exp_puma  ever_gain_exp_puma ever_lost_exp_puma  {
	replace `v' = 0 if mi(`v')
}
/* connect lost and gains for previous migpuma
merge m:1 prev_statefip prev_puma prev_year using `prev_losttreat', nogen keep(1 3) //missing if living abroad
foreach v in  ever_treated_puma always_treated_puma gain_exp_puma lost_exp_puma  ever_gain_exp_puma ever_lost_exp_puma  {
	replace prev_`v' = 0 if mi(prev_`v')
}*/

compress
save  "$oi/working_acs" , replace
