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
Troubleshoot populations at the migpuma level
**************************************************************/

cap mat drop nocontrols
cap mat drop wcontrols

forval i = 1/9 {
    di in red "Processing target population `i' "

    use "$oi/working_acs", clear 
    * using county level vars

    keep if year >= 2013
    * define propensity weights
    merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t`i'" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)
    gen perwt_wt = perwt*wt

    /* restrictions to remember
    drop if puma== 77777 //louisiana katrina
    */

    * base no controls or state exposure
    reghdfe move_migpuma exp_any_migpuma  SC_any [pw=perwt_wt]  if targetpop`i'==1 & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(nocotrols)

    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(wcontrols)
}

mat targetpop_migpuma = nocotrols , wcontrols

preserve
fill_tables, mat(targetpop_migpuma) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 
restore






/**************************************************************
Troubleshoot populations at the migpuma level OUT MIGRATION
**************************************************************/

cap mat drop nocontrols
cap mat drop wcontrols
cap mat drop targetpop_migpuma_out

forval i = 1/9 {
    di in red "Processing target population `i' "

    use "$oi/working_acs", clear 
    * using county level vars

    keep if year >= 2013
    * define propensity weights
    merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t`i'" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)
    gen perwt_wt = perwt*wt

    /* restrictions to remember
    drop if puma== 77777 //louisiana katrina
    */

    * base no controls or state exposure
    reghdfe move_migpuma prev_exp_any_migpuma  prev_SC_any [pw=perwt_wt]  if targetpop`i'==1 & year>=2012, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(prev_exp_any_migpuma $outvars) mat(nocontrols)

    * with controls and state exposure
    reghdfe move_migpuma prev_exp_any_migpuma $outvars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2012, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(prev_exp_any_migpuma $outvars) mat(wcontrols)
}

mat targetpop_migpuma_out = nocontrols , wcontrols

preserve
fill_tables, mat(targetpop_migpuma_out) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 
restore
