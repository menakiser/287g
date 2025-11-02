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
 troubleshoot target populations 
**************************************************************/
cap drop targetpop*
gen targetpop1 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2)
gen targetpop2 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3
gen targetpop3 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 
gen targetpop4 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & ownhome==0 
gen targetpop5 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 & ownhome==0 

/* check effects in target population */
egen person_id = group(serial pernum)
egen group_id = group(geoid year) 
egen group_id1 = group(geoid1 year1)

/*xtset person_id year
logit move_any exp_any SC_any [pw=perwt]  if targetpop1==1, vce(cluster group_id) 
logit move_any exp_any SC_any i.geoid i.year [pw=perwt]  if targetpop1==1, vce(cluster group_id)  */

forval i =1/5 {
	di in red "target pop `i': any move"
	reghdfe move_any exp_any  [pw=perwt]  if targetpop`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "target pop `i': move county"
	reghdfe move_county exp_any  [pw=perwt]  if targetpop`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "target pop `i': move state"
	reghdfe move_state exp_any  [pw=perwt]  if targetpop`i'==1 , vce(cluster group_id) absorb(geoid year)
} 

forval i =1/5 {
	di in red "target pop `i': any move"
	reghdfe move_any exp_any  [pw=perwt_wt]  if targetpop`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "target pop `i': move county"
	reghdfe move_county exp_any  [pw=perwt_wt]  if targetpop`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "target pop `i': move state"
	reghdfe move_state exp_any  [pw=perwt_wt]  if targetpop`i'==1 , vce(cluster group_id) absorb(geoid year)
} 

* choosing target population 2
cap drop targetpop*
gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3


/**************************************************************
evaluate initial results
**************************************************************/
* in migration
reghdfe move_any exp_any  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_county exp_any  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_state exp_any  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)

reghdfe move_any exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_county exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_state exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)

* out migration
reghdfe move_any exp_any1 [pw=perwt] if targetpop==1 & year>=2014, vce(cluster group_id1) absorb(geoid1 year1) 
reghdfe move_county exp_any1 [pw=perwt] if targetpop==1 & year>=2014, vce(cluster group_id1) absorb(geoid1 year1) 
reghdfe move_state exp_any1 [pw=perwt] if targetpop==1 & year>=2014, vce(cluster group_id1) absorb(geoid1 year1) 

reghdfe move_any exp_any1 [pw=perwt_wt] if targetpop==1 & year>=2014, vce(cluster group_id1) absorb(geoid1 year1) 
reghdfe move_county exp_any1 [pw=perwt_wt] if targetpop==1 & year>=2014, vce(cluster group_id1) absorb(geoid1 year1) 
reghdfe move_state exp_any1 [pw=perwt_wt] if targetpop==1 & year>=2014, vce(cluster group_id1) absorb(geoid1 year1) 


/**************************************************************
placebos
**************************************************************/
* define placebo groups
cap drop placebo*
//gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 //hispanic citizens born in the usa, 90,306, n 
gen placebo2 = sex==1 & lowskill==1 & hispan==0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 //same as target but not hispanic, 7,501, p
gen placebo3 = sex==1 & lowskill==1 & hispan==0 & born_abroad==1 & citizen!=3 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 //non-hispanic citizen (born to american parents, naturalized citizen) born abroad,  2,089 n
gen placebo4 = sex==1 & lowskill==1 & hispan==0 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 //non-hispanic citizens born in the usa,  279,903 n
gen placebo5 = sex==1 & lowskill==1 & hispan==0 & race==1 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 //non-hispanic white citizens born in the usa,  194,945 n

*in migration 
forval i = 1/5 {
	di in red "placebo group `i': any move"
	reghdfe move_any exp_any  [pw=perwt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "placebo group `i': move county"
	reghdfe move_county exp_any  [pw=perwt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "placebo group `i': move state"
	reghdfe move_state exp_any  [pw=perwt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
}

forval i = 1/5 {
	di in red "placebo group `i': any move"
	reghdfe move_any exp_any  [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "placebo group `i': move county"
	reghdfe move_county exp_any  [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
	di in red "placebo group `i': move state"
	reghdfe move_state exp_any  [pw=perwt_wt]  if placebo`i'==1 , vce(cluster group_id) absorb(geoid year)
}

*out migration 
forval i = 1/5 {
	di in red "placebo group `i': any move"
	reghdfe move_any exp_any1  [pw=perwt]  if placebo`i'==1 & year>=2014, vce(cluster group_id1) absorb(geoid1 year1)
	di in red "placebo group `i': move county"
	reghdfe move_county exp_any1  [pw=perwt]  if placebo`i'==1 & year>=2014 , vce(cluster group_id1) absorb(geoid1 year1)
	di in red "placebo group `i': move state"
	reghdfe move_state exp_any1  [pw=perwt]  if placebo`i'==1 & year>=2014 , vce(cluster group_id1) absorb(geoid1 year1)
}

forval i = 1/5 {
	di in red "placebo group `i': any move"
	reghdfe move_any exp_any1  [pw=perwt_wt]  if placebo`i'==1 & year>=2014 , vce(cluster group_id1) absorb(geoid1 year1)
	di in red "placebo group `i': move county"
	reghdfe move_county exp_any1  [pw=perwt_wt]  if placebo`i'==1 & year>=2014 , vce(cluster group_id1) absorb(geoid1 year1)
	di in red "placebo group `i': move state"
	reghdfe move_state exp_any1  [pw=perwt_wt]  if placebo`i'==1 & year>=2014 , vce(cluster group_id1) absorb(geoid1 year1)
}

compress
save  "$oi/acs_w_propensity_weights", replace
