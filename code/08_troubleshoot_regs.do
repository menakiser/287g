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

replace SC_any = 1 if year>=2015
keep if year >=2013 & year<=2019 //rule out SC areas

/* troubleshoot target populations */
cap drop targetpop*
gen targetpop1 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2)
gen targetpop2 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst==6 
gen targetpop3 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst==6 & nchild==0 //any, county, state
gen targetpop4 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst==6 & nchild==0 & ownhome==0 //any, county, state
gen targetpop5 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & nchild==0 
gen targetpop6 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & ownhome==0
gen targetpop7 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & ownhome==0 & nchild==0 
gen targetpop8 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & ownhome==0 & marst==6 //any, county
gen targetpop9 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 //any, county, state
gen targetpop10 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 & ownhome==0 //any, county, state

/* check effects in target population */
egen person_id = group(serial pernum)
/*xtset person_id year
egen fe_group = group(geoid year) 
logit move_any exp_any SC_any [pw=perwt]  if targetpop1==1, vce(cluster fe_group) 
logit move_any exp_any SC_any i.geoid i.year [pw=perwt]  if targetpop1==1, vce(cluster fe_group)  */

forval i =9/10 {
	di in red "target pop `i': any move"
	reghdfe move_any exp_any  [pw=perwt]  if targetpop`i'==1 , vce(cluster fe_group) absorb(geoid year)
	di in red "target pop `i': move county"
	reghdfe move_county exp_any  [pw=perwt]  if targetpop`i'==1 , vce(cluster fe_group) absorb(geoid year)
	di in red "target pop `i': move state"
	reghdfe move_state exp_any  [pw=perwt]  if targetpop`i'==1 , vce(cluster fe_group) absorb(geoid year)
} 

forval i =9/10 {
	di in red "target pop `i': any move"
	reghdfe move_any exp_any  [pw=perwt_wt]  if targetpop`i'==1 , vce(cluster fe_group) absorb(geoid year)
	di in red "target pop `i': move county"
	reghdfe move_county exp_any  [pw=perwt_wt]  if targetpop`i'==1 , vce(cluster fe_group) absorb(geoid year)
	di in red "target pop `i': move state"
	reghdfe move_state exp_any  [pw=perwt_wt]  if targetpop`i'==1 , vce(cluster fe_group) absorb(geoid year)
} 

* choosing target population 9 
cap drop targetpop*
gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 //any, county, state

* in migration
xtlogit move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt], vce(cluster geoid year) absorb(geoid year) 
reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt_wt], vce(cluster geoid year) absorb(geoid year) 

reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt] if phat>=0 &  phat<.2 & year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt_wt] if phat>=0 & phat<.2 & year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 

reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt] if phat>=.2 &  phat<.4 & year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt_wt] if phat>=.2 & phat<.4 & year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 

reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt] if phat>=.4 &  phat<.6 & year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt_wt] if phat>=.4 & phat<.6 & year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 

reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt] if phat>=.5 & year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_any target_exp_any targetpop exp_any_cap SC_any [pw=perwt_wt] if phat>=.5 & year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 


*out migration


reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt] if year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt_wt] if year>=2011 & year<=2019, vce(cluster geoid year) absorb(geoid year) 

reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt] if phat>=0 &  phat<.2 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt_wt] if phat>=0 & phat<.2 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt] if phat>=.2 &  phat<.4 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt_wt] if phat>=.2 & phat<.4 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt] if phat>=.4 &  phat<.6 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt_wt] if phat>=.4 & phat<.6 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt] if phat>=.6 &  phat<.8 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt_wt] if phat>=.6 & phat<.8 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt] if phat>=.5 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_any target_exp_any1 targetpop exp_any_cap1 SC_any [pw=perwt_wt] if phat>=.5 & year>=2011 & year<=2019, vce(cluster geoid1 year1) absorb(geoid1 year1) 


* placebos 

*in migration 
reghdfe move_any  exp_any SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_county  exp_any SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_state exp_any SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 

reghdfe move_any  exp_jail SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_county  exp_jail SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_state exp_jail SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 

reghdfe move_any  exp_jail  [pw=perwt] if year>=2014 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_county  exp_jail  [pw=perwt] if year>=2014 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_state exp_jail  [pw=perwt] if year>=2014 & year<=2019 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 

reghdfe move_any  exp_task SC_any [pw=perwt] if year>=2011 & year<=2014 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_county  exp_task SC_any [pw=perwt] if year>=2011 & year<=2014 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 
reghdfe move_state exp_task SC_any [pw=perwt] if year>=2011 & year<=2014 & targetpop==1, vce(cluster geoid year) absorb(geoid year) 


*out migration 
reghdfe move_any  exp_any1 SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_county  exp_any1 SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_state exp_any1 SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 


reghdfe move_any  exp_jail1 SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_county  exp_jail1 SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_state exp_jail1 SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_any  exp_jail1  [pw=perwt] if year>=2015 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_county  exp_jail1  [pw=perwt] if year>=2015 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 
reghdfe move_state exp_jail1  [pw=perwt] if year>=2015 & year<=2019 & targetpop==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 


* changing targetpop

forval i = 1/3 {
	di "target pop `i' from 2011 to 2019"
	reghdfe move_any  exp_jail SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop`i'==1, vce(cluster geoid year) absorb(geoid year) 
	reghdfe move_county  exp_jail SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop`i'==1, vce(cluster geoid year) absorb(geoid year) 
	reghdfe move_state exp_jail SC_any [pw=perwt] if year>=2011 & year<=2019 & targetpop`i'==1, vce(cluster geoid year) absorb(geoid year) 
}

forval i = 1/4 {
	di "target pop `i' from 2014 to 2019"
	reghdfe move_any  exp_jail  [pw=perwt] if year>=2014 & year<=2019 & targetpop`i'==1, vce(cluster geoid year) absorb(geoid year) 
	reghdfe move_county  exp_jail  [pw=perwt] if year>=2014 & year<=2019 & targetpop`i'==1, vce(cluster geoid year) absorb(geoid year) 
	reghdfe move_state exp_jail  [pw=perwt] if year>=2014 & year<=2019 & targetpop`i'==1, vce(cluster geoid year) absorb(geoid year) 
}

*out migration
forval i = 1/4 {
	di "target pop `i' from 2014 to 2019"
	reghdfe move_any  exp_jail1  [pw=perwt] if year>=2015 & year<=2019 & targetpop`i'==1, vce(cluster geoid1 year) absorb(geoid1 year) 
	reghdfe move_county  exp_jail1  [pw=perwt] if year>=2015 & year<=2019 & targetpop`i'==1, vce(cluster geoid1 year) absorb(geoid1 year) 
	reghdfe move_state exp_jail1  [pw=perwt] if year>=2015 & year<=2019 & targetpop`i'==1, vce(cluster geoid1 year) absorb(geoid1 year) 
}

*out migration
forval i = 1/4 {
	di "target pop `i' from 2014 to 2019"
	reghdfe move_any  exp_jail1  [pw=perwt_wt] if year>=2015 & year<=2019 & targetpop`i'==1, vce(cluster geoid1 year) absorb(geoid1 year) 
	reghdfe move_county  exp_jail1  [pw=perwt_wt] if year>=2015 & year<=2019 & targetpop`i'==1, vce(cluster geoid1 year) absorb(geoid1 year) 
	reghdfe move_state exp_jail1  [pw=perwt_wt] if year>=2015 & year<=2019 & targetpop`i'==1, vce(cluster geoid1 year) absorb(geoid1 year) 
}


compress 
save "$oi/working_acs", replace