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
global invars "exp_any_state"
global outvars "prev_exp_any_state"


/**************************************************************
Troubleshoot populations at the migpuma IN level
**************************************************************/

cap mat drop in_nocontrols_wwt
cap mat drop in_wcontrols_wwt
cap mat drop in_nocontrols_nowt
cap mat drop in_wcontrols_nowt

cap mat drop out_nocontrols_wwt
cap mat drop out_wcontrols_wwt
cap mat drop out_nocontrols_nowt
cap mat drop out_wcontrols_nowt

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

    /**************************************************************
    IN migration
    **************************************************************/
    di in red "IN migration: Target population `i' WITH weights "
    **** WITH WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(in_nocontrols_wwt)

    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(in_wcontrols_wwt)

    di in red "IN migration: Target population `i' NO weights "
    **** NO WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma exp_any_migpuma  if targetpop`i'==1 & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(in_nocontrols_nowt)

    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars  if targetpop`i'==1  & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(in_wcontrols_nowt)


    /**************************************************************
    OUT migration
    **************************************************************/
    di in red "OUT migration: Target population `i' WITH weights "
    **** WITH WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma prev_exp_any_migpuma [pw=perwt_wt]  if targetpop`i'==1 & year>=2014, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(prev_exp_any_migpuma $outvars) mat(out_nocontrols_wwt)

    * with controls and state exposure
    reghdfe move_migpuma prev_exp_any_migpuma $outvars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2014, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(prev_exp_any_migpuma $outvars) mat(out_wcontrols_wwt)

    di in red "OUT migration: Target population `i' NO weights "
    **** NO WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma prev_exp_any_migpuma  if targetpop`i'==1 & year>=2014, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(prev_exp_any_migpuma $outvars) mat(out_nocontrols_nowt)

    * with controls and state exposure
    reghdfe move_migpuma prev_exp_any_migpuma $outvars  $covars  if targetpop`i'==1  & year>=2014, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(prev_exp_any_migpuma $outvars) mat(out_wcontrols_nowt)

}


**** Consolidate matrices
mat targetpop_in_wwt = in_nocontrols_wwt , in_wcontrols_wwt
mat targetpop_in_nowt = in_nocontrols_nowt , in_wcontrols_nowt

mat targetpop_out_wwt = out_nocontrols_wwt , out_wcontrols_wwt
mat targetpop_out_nowt = out_nocontrols_nowt , out_wcontrols_nowt


**** Input matrices in spreadsheet
fill_tables, mat(targetpop_in_wwt) save_txt("$oo/resolution_specifications") save_excel("$oo/resolution_specifications") 
fill_tables, mat(targetpop_in_nowt) save_txt("$oo/resolution_specifications") save_excel("$oo/resolution_specifications") 

fill_tables, mat(targetpop_out_wwt) save_txt("$oo/resolution_specifications") save_excel("$oo/resolution_specifications") 
fill_tables, mat(targetpop_out_nowt) save_txt("$oo/resolution_specifications") save_excel("$oo/resolution_specifications") 
