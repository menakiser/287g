/*---------------------
Mena kiser
10-25-25

Define propensity matched counterfactual
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


use "$oi/acs_w_propensity_weights", clear 
keep if year >=2013 & year<=2019 //rule out SC areas

/**************************************************************
 troubleshoot initial regressions
**************************************************************/
/* check effects in target population */
egen person_id = group(serial pernum)
egen group_id = group(geoid year) 
egen group_id1 = group(prev_geoid prev_year)

global covars "age i.race i.educ i.speakeng i.hcovany i.school ownhome" 

/* without weights
reghdfe move_any exp_any_migpuma  $covars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_any prev_exp_any_migpuma  $covars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(prev_geoid year)

reghdfe move_migpuma exp_any_migpuma  $covars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid prev_geoid year)
reghdfe move_migpuma prev_exp_any_migpuma $covars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb( prev_geoid year)

reghdfe move_state exp_any_migpuma $covars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_state prev_exp_any_migpuma $covars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(prev_geoid year)

* with weights
reghdfe move_any exp_any_migpuma  $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_any prev_exp_any_migpuma  $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(prev_geoid year)

reghdfe move_migpuma exp_any_migpuma  $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid prev_geoid year)
reghdfe move_migpuma prev_exp_any_migpuma $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb( prev_geoid year)

reghdfe move_state exp_any_migpuma $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_state prev_exp_any_migpuma $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(prev_geoid year)

*/
/**************************************************************
placebos
**************************************************************/
* define placebo groups
cap drop placebo*
//gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 & nchild==0 //hispanic citizens born in the usa, 113,260, n 
gen placebo2 = sex==1 & lowskill==1 & hispan==0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 //same as target but not hispanic, 9,316, p
gen placebo3 = sex==1 & lowskill==1 & hispan==0 & born_abroad==1 & citizen!=3 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 //non-hispanic citizen (born to american parents, naturalized citizen) born abroad,  2,731 n
gen placebo4 = sex==1 & lowskill==1 & hispan==0 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 & nchild==0 //non-hispanic citizens born in the usa,  532,596 n
gen placebo5 = sex==1 & lowskill==1 & hispan==0 & race==1 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 & nchild==0 //non-hispanic white citizens born in the usa,  400,003 n

label var placebo1 "hispanic citizen US born"
label var placebo2 "non-hispanic target"
label var placebo3 "non-hispanic citizen"
label var placebo4 "non-hispanic citizen US born"
label var placebo5 "non-hispanic white citizen US born"

/*in migration 
forval i = 1/5 {
	di in red "placebo group `i': any move"
	reghdfe move_any exp_any_migpuma  $covars [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "placebo group `i': move county"
	reghdfe move_migpuma exp_any_migpuma  $covars [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "placebo group `i': move state"
	reghdfe move_state exp_any_migpuma  $covars [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
}

*out migration 
forval i = 1/5 {
	di in red "placebo group `i': any move"
	reghdfe move_any prev_exp_any_migpuma  $covars [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(prev_geoid year)
	di in red "placebo group `i': move county"
	reghdfe move_migpuma prev_exp_any_migpuma  $covars [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(prev_geoid year)
	di in red "placebo group `i': move state"
	reghdfe move_state prev_exp_any_migpuma  $covars [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(prev_geoid year)
}*/

compress
save  "$oi/acs_w_propensity_weights", replace


/**************************************************************
Table 3: DiD
**************************************************************
use "$oi/acs_w_propensity_weights", clear 
forval i =1/5 {
	cap drop allpop exp_pop
	gen allpop = placebo`i'==1 | targetpop==1
	gen exp_pop =  exp_any_migpuma_binary*targetpop
	di in red "placebo `i', unweighted "
	reghdfe move_migpuma exp_pop exp_any_migpuma_binary targetpop  [pw=perwt] if allpop==1, vce(cluster group_id) absorb(geoid year)
	di in red "placebo `i', weighted "
	reghdfe move_migpuma exp_pop exp_any_migpuma_binary targetpop  [pw=perwt_wt] if allpop==1, vce(cluster group_id) absorb(geoid year)
}