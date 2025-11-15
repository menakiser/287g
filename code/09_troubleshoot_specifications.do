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
Baseline: 2013-2019
**************************************************************/

use "$oi/working_acs", clear 
* using targetpop1 at county level
drop targetpop2 targetpop3 targetpop4 targetpop5 targetpop6 targetpop7 targetpop8 targetpop9
drop geoid_migpuma prev_geoid_migpuma group_id_migpuma group_id1_migpuma

* define propensity weights
keep if year>=2013
drop if countyfip==000 //not identifiable
merge m:1 statefip countyfip  using  "$oi/troubleshoot/propensity_weights2013_t1" , nogen keep(1 3) keepusing(ever_treated_county phat wt)
gen perwt_wt = perwt*wt


/* restrictions to remember
drop if puma== 77777 //louisiana katrina
*/

* in migration 2013-2019
cap mat drop baseline
reghdfe move_county exp_any_county  SC_any [pw=perwt_wt]  if targetpop==1 & year>=2013, vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county ) indvars(exp_any_county $invars) mat(baseline)
reghdfe move_county exp_any_county SC_any $covars [pw=perwt_wt]  if targetpop==1 & year>=2013 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county ) indvars(exp_any_county $invars) mat(baseline)

reghdfe move_county exp_any_county  $invars [pw=perwt_wt]  if targetpop==1 & year>=2013 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county) indvars(exp_any_county $invars) mat(baseline)
reghdfe move_county exp_any_county $invars  $covars [pw=perwt_wt]  if targetpop==1  & year>=2013, vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county) indvars(exp_any_county $invars) mat(baseline)


fill_tables, mat(baseline) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 



/**************************************************************
Comparing years: 2011-2019
**************************************************************/

use "$oi/working_acs", clear 

* using targetpop1 at county level
drop targetpop2 targetpop3 targetpop4 targetpop5 targetpop6 targetpop7 targetpop8 targetpop9
drop geoid_migpuma prev_geoid_migpuma group_id_migpuma group_id1_migpuma

* define propensity weights
drop if countyfip==000 //not identifiable
merge m:1 statefip countyfip  using  "$oi/troubleshoot/propensity_weights_t1" , nogen keep(1 3) keepusing(ever_treated_county phat wt)
gen perwt_wt = perwt*wt
* (1,866,942 missing values generated) , all from 2012-onwards, must be counties that changed codes after 2011
drop if mi(perwt_wt)
/* restrictions to remember
drop if puma== 77777 //louisiana katrina
*/

* in migration 2011-2019
cap mat drop extyear
reghdfe move_county exp_any_county  SC_any [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county ) indvars(exp_any_county $invars) mat(extyear)
reghdfe move_county exp_any_county SC_any $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county ) indvars(exp_any_county $invars) mat(extyear)

reghdfe move_county exp_any_county  $invars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county) indvars(exp_any_county $invars) mat(extyear)
reghdfe move_county exp_any_county $invars $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county) indvars(exp_any_county $invars) mat(extyear)


fill_tables, mat(extyear) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 





/**************************************************************
Using migpuma exposure
**************************************************************/

use "$oi/working_acs", clear 

* using targetpop1 at county level
drop targetpop2 targetpop3 targetpop4 targetpop5 targetpop6 targetpop7 targetpop8 targetpop9
drop geoid_county prev_geoid_county group_id_county group_id1_county

* define propensity weights
drop if puma==77777 //louisiana katrina
keep if year>=2013
merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t1" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)
gen perwt_wt = perwt*wt

/* restrictions to remember
drop if countyfip==000 //not identifiable
*/

cap mat drop migpuma
reghdfe move_migpuma exp_any_migpuma  SC_any [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(migpuma)

reghdfe move_migpuma exp_any_migpuma SC_any $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(migpuma)

reghdfe move_migpuma exp_any_migpuma  $invars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(migpuma)

reghdfe move_migpuma exp_any_migpuma $invars $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(migpuma)


fill_tables, mat(migpuma) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 



/**************************************************************
Troubleshooting populations
**************************************************************/
cap mat drop nocontrols
cap mat drop wcontrols

forval i = 1/9 {
    di in red "Processing target population `i' "

    use "$oi/working_acs", clear 
    * using county level vars
    drop geoid_migpuma prev_geoid_migpuma group_id_migpuma group_id1_migpuma

    keep if year >= 2013
    drop if countyfip==000 //not identifiable
    * define propensity weights
    merge m:1 statefip countyfip  using  "$oi/troubleshoot/propensity_weights2013_t`i'" , nogen keep(1 3) keepusing(ever_treated_county phat wt)
    gen perwt_wt = perwt*wt

    /* restrictions to remember
    drop if puma== 77777 //louisiana katrina
    */

    * base no controls or state exposure
    reghdfe move_county exp_any_county  SC_any [pw=perwt_wt]  if targetpop`i'==1 & year>=2013, vce(cluster group_id_county) absorb(geoid_county year)
    reg_to_mat, depvar(move_county ) indvars(exp_any_county $invars) mat(nocotrols)

    * with controls and state exposure
    reghdfe move_county exp_any_county $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2013, vce(cluster group_id_county) absorb(geoid_county year)
    reg_to_mat, depvar(move_county) indvars(exp_any_county $invars) mat(wcontrols)
}

mat targetpop = nocotrols , wcontrols

preserve
fill_tables, mat(targetpop) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 
restore



/**************************************************************
Apply propensity score at the county and year level
**************************************************************/

use "$oi/working_acs", clear 
* using targetpop1 at county level
drop targetpop2 targetpop3 targetpop4 targetpop5 targetpop6 targetpop7 targetpop8 targetpop9
drop geoid_migpuma prev_geoid_migpuma group_id_migpuma group_id1_migpuma

* define propensity weights
drop if countyfip==000 //not identifiable
keep if year>=2013
merge m:1 statefip countyfip year using  "$oi/troubleshoot/propensity_weights2013year_t1" , nogen keep(1 3) keepusing(ever_treated_county phat wt)
gen perwt_wt = perwt*wt

/* restrictions to remember
drop if puma== 77777 //louisiana katrina
*/

* in migration 2013-2019
cap mat drop propscore
reghdfe move_county exp_any_county  SC_any [pw=perwt_wt]  if targetpop==1 & year>=2013, vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county ) indvars(exp_any_county $invars) mat(propscore)
reghdfe move_county exp_any_county SC_any $covars [pw=perwt_wt]  if targetpop==1 & year>=2013 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county ) indvars(exp_any_county $invars) mat(propscore)

reghdfe move_county exp_any_county  $invars [pw=perwt_wt]  if targetpop==1 & year>=2013 , vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county) indvars(exp_any_county $invars) mat(propscore)
reghdfe move_county exp_any_county $invars  $covars [pw=perwt_wt]  if targetpop==1  & year>=2013, vce(cluster group_id_county) absorb(geoid_county year)
reg_to_mat, depvar(move_county) indvars(exp_any_county $invars) mat(propscore)

preserve
fill_tables, mat(propscore) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 
restore




/**************************************************************
Apply propensity score at the Migpuma and year level
**************************************************************/

use "$oi/working_acs", clear 
* using targetpop1 at county level
drop targetpop2 targetpop3 targetpop4 targetpop5 targetpop6 targetpop7 targetpop8 targetpop9

* define propensity weights
keep if year>=2013
drop if puma== 77777 
merge m:1 statefip current_migpuma year using  "$oi/troubleshoot/propensity_weights2013migpumayear_t1" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)
gen perwt_wt = perwt*wt

/* restrictions to remember
drop if puma== 77777 //louisiana katrina
*/

* in migration 2013-2019
cap mat drop propscore_migpuma
reghdfe move_migpuma exp_any_migpuma  SC_any [pw=perwt_wt]  if targetpop==1 & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(propscore_migpuma)
reghdfe move_migpuma exp_any_migpuma SC_any $covars [pw=perwt_wt]  if targetpop==1 & year>=2013 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(propscore_migpuma)

reghdfe move_migpuma exp_any_migpuma  $invars [pw=perwt_wt]  if targetpop==1 & year>=2013 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(propscore_migpuma)
reghdfe move_migpuma exp_any_migpuma $invars  $covars [pw=perwt_wt]  if targetpop==1  & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(propscore_migpuma)

preserve
fill_tables, mat(propscore_migpuma) save_txt("$oo/troubleshooting_specifications") save_excel("$oo/troubleshooting_specifications") 
restore





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
