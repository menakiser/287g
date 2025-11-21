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

keep year statefip current_migpuma exp_any_migpuma
duplicates drop

* identify if migpuma was ever treated
bys statefip current_migpuma: egen ever_treated_migpuma = max( exp_any_migpuma>0)
keep if ever_treated_migpuma==1

*identify if migpuma was always treated
bys statefip current_migpuma: egen always_treated_migpuma = max( exp_any_migpuma==0)
replace always_treated_migpuma = !always_treated_migpuma
sort statefip current_migpuma year

* identifying gain and lost events
bys statefip current_migpuma (year): gen gain_exp_migpuma = exp_any_migpuma[_n-1] == 0 & exp_any_migpuma==1
bys statefip current_migpuma (year): gen lost_exp_migpuma = exp_any_migpuma[_n-1] == 1 & exp_any_migpuma==0
gen gain_exp_year = year if gain_exp_migpuma==1
gen lost_exp_year = year if lost_exp_migpuma==1
replace gain_exp_year = 0 if mi(gain_exp_year)
replace lost_exp_year = 0 if mi(lost_exp_year)
bys statefip current_migpuma (year): ereplace gain_exp_year = max(gain_exp_year)
bys statefip current_migpuma (year): ereplace lost_exp_year = max(lost_exp_year)

bys statefip current_migpuma (year): egen ever_gain_exp_migpuma = max(gain_exp_migpuma)
bys statefip current_migpuma (year): egen ever_lost_exp_migpuma = max(lost_exp_migpuma)

tab exp_any_migpuma if year>=gain_exp_year & ever_gain_exp_migpuma==1 //all 1
tab exp_any_migpuma if year<gain_exp_year & ever_gain_exp_migpuma==1 //all zero except for two migpumas

tab exp_any_migpuma if year<lost_exp_year & ever_lost_exp_migpuma==1 //all 1
tab exp_any_migpuma if year>=lost_exp_year & ever_lost_exp_migpuma==1 //all zero except for two migpumas

drop exp_any_migpuma

* save for all current migpuma
save "$oi/list_gain_lost_migpuma", replace


* save for previous migpuma
use "$oi/list_gain_lost_migpuma", clear
foreach v in  year statefip ever_treated_migpuma always_treated_migpuma gain_exp_migpuma lost_exp_migpuma gain_exp_year lost_exp_year ever_gain_exp_migpuma ever_lost_exp_migpuma {
	rename `v' prev_`v'
}
rename current_migpuma prev_migpuma
tempfile prev_losttreat 
save `prev_losttreat'


use "$oi/working_acs" , clear
* connect lost and gains for current migpuma
merge m:1 statefip current_migpuma year using "$oi/list_gain_lost_migpuma", nogen keep(1 3)
foreach v in  ever_treated_migpuma always_treated_migpuma gain_exp_migpuma lost_exp_migpuma  ever_gain_exp_migpuma ever_lost_exp_migpuma  {
	replace `v' = 0 if mi(`v')
}
* connect lost and gains for previous migpuma
merge m:1 prev_statefip prev_migpuma prev_year using `prev_losttreat', nogen keep(1 3) //missing if living abroad
foreach v in  ever_treated_migpuma always_treated_migpuma gain_exp_migpuma lost_exp_migpuma  ever_gain_exp_migpuma ever_lost_exp_migpuma  {
	replace prev_`v' = 0 if mi(prev_`v')
}

compress
save  "$oi/working_acs" , replace
