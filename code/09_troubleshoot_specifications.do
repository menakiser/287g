/*---------------------
Mena kiser
11-13-25
troubleshoot different specifications
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"
global oo "$wd/output/"

global covars "age i.race i.educ i.speakeng i.hcovany i.school ownhome " 
global invars "SC_any exp_any_state"
global outvars "prev_SC_any prev_exp_any_state"


/**************************************************************
extyear
**************************************************************/
use "$oi/working_acs", clear 

* using targetpop1 at county level
drop targetpop2 targetpop3 targetpop4 targetpop5 targetpop6 targetpop7 targetpop8 targetpop9
drop geoid_migpuma prev_geoid_migpuma group_id_migpuma group_id1_migpuma

* define propensity weights
merge m:1 statefip countyfip  using  "$oi/troubleshoot/propensity_weights_t1" , nogen keep(1 3) keepusing(ever_treated_county phat wt)
gen perwt_wt = perwt*wt


* in migration 2011-2019
cap mat drop extyear
reghdfe move_any exp_any_county  SC_any [pw=perwt]  if targetpop==1 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_any ) indvars(exp_any_county $invars) mat(extyear)
reghdfe move_any exp_any_county SC_any $covars [pw=perwt]  if targetpop==1 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_any ) indvars(exp_any_county $invars) mat(extyear)

reghdfe move_any exp_any_county  $invars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_any) indvars(exp_any_county $invars) mat(extyear)
reghdfe move_any exp_any_county $invars $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_any) indvars(exp_any_county $invars) mat(extyear)

preserve
fill_tables, mat(extyear) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 
restore


* in migration 2013-2019
cap mat drop baseline
reghdfe move_any exp_any_county  SC_any [pw=perwt]  if targetpop==1 & year>=2013, vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_any ) indvars(exp_any_county $invars) mat(baseline)
reghdfe move_any exp_any_county SC_any $covars [pw=perwt]  if targetpop==1 & year>=2013 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_any ) indvars(exp_any_county $invars) mat(baseline)

reghdfe move_any exp_any_county  $invars [pw=perwt_wt]  if targetpop==1 & year>=2013 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_any) indvars(exp_any_county $invars) mat(baseline)
reghdfe move_any exp_any_county $invars  $covars [pw=perwt_wt]  if targetpop==1  & year>=2013, vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_any) indvars(exp_any_county $invars) mat(baseline)

preserve
fill_tables, mat(baseline) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 
restore
