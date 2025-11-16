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

global covars "exp_any_state age i.race i.race i.hcovany i.school" 
global invars "exp_any_state"
global outvars "prev_exp_any_state"

*** focusing on target population of single and no kids, hispanic and mexican 
* 2 3 5 6 8 9


/**************************************************************
IN migration
**************************************************************/


foreach i in 2 3 5 6 8 9 {
    di in red "IN migration: Target population `i' "
    use "$oi/working_acs", clear 
    
    * drop years and puma we don't need
    keep if year >= 2013
    drop if puma== 77777 //louisiana katrina

    * define propensity weights
    merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t`i'" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)
    gen perwt_wt = perwt*wt
    
    * drop 17 migpumas that lost treatment at some point 
    drop if ever_lost_exp_migpuma==1 | always_treated_migpuma==1

    *** create relative year
    gen relative_year =  year - gain_exp_year
    replace relative_year = . if gain_exp_year == .

    * event-time indicators
    forval n = 1/6 {
        gen ry_plus`n'  = (relative_year == `n')
        gen ry_minus`n' = (relative_year == -`n')
    }
    * event time = 0
    gen ry_plus0 = (relative_year == 0)

   forval n = 1/6 {
        label var ry_plus`n' "+`n'"
        label var ry_minus`n' "-`n'"
    }
    label var ry_plus0 "0"

    gen ry_plus5_group = ry_plus5 | ry_plus6
    gen ry_minus5_group = ry_minus5 | ry_minus6
    label var ry_plus5_group "+5"
    label var ry_minus5_group "-5"

    **** WITH WEIGHT, with controls and state exposure
    reghdfe move_migpuma ry_minus6 ry_minus5 ry_minus4 ry_minus3 ry_minus2 o.ry_minus1 ///
    ry_plus0 ry_plus1 ry_plus2 ry_plus3  ///
        $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2013, ///
        vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    est store in_target
    * Plot with separate colors for pre- and post-event coefficients
    coefplot ///
        (in_target , keep(ry_minus* ry_plus* o.ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
        , nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
        omit vertical ///
        eqlabels(, labels) graphregion(color(white)) legend(off) ///
        xtitle("Relative year")   ytitle("Move migpuma") 
    graph export "$oo/estudy/inmig_targetpop`i'_wwt.pdf", replace

     **** NO WEIGHT, with controls and state exposure
    reghdfe move_migpuma ry_minus6 ry_minus5 ry_minus4 ry_minus3 ry_minus2 o.ry_minus1 ///
    ry_plus0 ry_plus1 ry_plus2 ry_plus3  ///
        $invars  $covars  if targetpop`i'==1  & year>=2013, ///
        vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    est store in_target
    * Plot with separate colors for pre- and post-event coefficients
    coefplot ///
        (in_target , keep(ry_minus* ry_plus* o.ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
        , nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
        omit vertical ///
        eqlabels(, labels) graphregion(color(white)) legend(off) ///
        xtitle("Relative year")   ytitle("Move migpuma") 
    graph export "$oo/estudy/inmig_targetpop`i'_nowt.pdf", replace
}


/**************************************************************
OUT migration
**************************************************************/


foreach i in 2 3 5 6 8 9 {
    di in red "OUT migration: Target population `i' "
    use "$oi/working_acs", clear 
    
    * drop years and puma we don't need
    keep if year >= 2014
    drop if puma== 77777 //louisiana katrina

    * define propensity weights
    merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t`i'" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)
    gen perwt_wt = perwt*wt
    
    * drop 17 migpumas that lost treatment at some point 
    drop if prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1


    *** create relative year
    gen prev_relative_year =  prev_year - prev_gain_exp_year
    replace prev_relative_year = . if prev_gain_exp_year == .

    * event-time indicators
    forval n = 1/6 {
        gen prev_ry_plus`n'  = (prev_relative_year == `n')
        gen prev_ry_minus`n' = (prev_relative_year == -`n')
    }
    * event time = 0
    gen prev_ry_plus0 = (prev_relative_year == 0)

    forval n = 1/6 {
        label var prev_ry_plus`n' "+`n'"
        label var prev_ry_minus`n' "-`n'"
    }
    label var prev_ry_plus0 "0"
    
    gen prev_ry_plus5_group = prev_ry_plus5 | prev_ry_plus6
    gen prev_ry_minus5_group = prev_ry_minus5 | prev_ry_minus6
    label var prev_ry_plus5_group "+5"
    label var prev_ry_minus5_group "-5"


    **** WITH WEIGHT, with controls and state exposure
    reghdfe move_migpuma prev_ry_minus6 prev_ry_minus5 prev_ry_minus4 prev_ry_minus3 prev_ry_minus2 o.prev_ry_minus1 ///
    prev_ry_plus0 prev_ry_plus1 prev_ry_plus2  ///
        $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2014, ///
         vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    est store out_target
    * Plot with separate colors for pre- and post-event coefficients
    coefplot ///
        (out_target , keep(prev_ry_minus* prev_ry_plus* o.prev_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
        , nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
        omit vertical ///
        eqlabels(, labels) graphregion(color(white)) legend(off) ///
        xtitle("Relative year")   ytitle("Move migpuma") 
    graph export "$oo/estudy/outmig_targetpop`i'_wwt.pdf", replace

     **** NO WEIGHT, with controls and state exposure
    reghdfe move_migpuma prev_ry_minus6 prev_ry_minus5 prev_ry_minus4 prev_ry_minus3 prev_ry_minus2 o.prev_ry_minus1 ///
    prev_ry_plus0 prev_ry_plus1 prev_ry_plus2  ///
        $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2014, ///
         vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    est store out_target
    * Plot with separate colors for pre- and post-event coefficients
    coefplot ///
        (out_target , keep(prev_ry_minus* prev_ry_plus* o.prev_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
        , nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
        omit vertical ///
        eqlabels(, labels) graphregion(color(white)) legend(off) ///
        xtitle("Relative year")   ytitle("Move migpuma") 
    graph export "$oo/estudy/outmig_targetpop`i'_nowt.pdf", replace
}





/**************************************************************
Repeat specifications
**************************************************************/

cap mat drop in_nocontrols_wwt
cap mat drop in_wcontrols_wwt
cap mat drop in_nocontrols_nowt
cap mat drop in_wcontrols_nowt

cap mat drop out_nocontrols_wwt
cap mat drop out_wcontrols_wwt
cap mat drop out_nocontrols_nowt
cap mat drop out_wcontrols_nowt

foreach i in 2 3 5 6 8 9 {
    di in red "Processing target population `i' "


    use "$oi/working_acs", clear 
    * using county level vars

    keep if year >= 2013
    * define propensity weights
    keep if !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1)
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
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(in_nocontrols_wwt)

    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2013  & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(in_wcontrols_wwt)

    di in red "IN migration: Target population `i' NO weights "
    **** NO WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma exp_any_migpuma  if targetpop`i'==1 & year>=2013  & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(in_nocontrols_nowt)

    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars  if targetpop`i'==1  & year>=2013  & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(in_wcontrols_nowt)


    /**************************************************************
    OUT migration
    **************************************************************/
    di in red "OUT migration: Target population `i' WITH weights "
    **** WITH WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma prev_exp_any_migpuma [pw=perwt_wt]  if targetpop`i'==1 & year>=2014  & !(prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1) , vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(prev_exp_any_migpuma $outvars) mat(out_nocontrols_wwt)

    * with controls and state exposure
    reghdfe move_migpuma prev_exp_any_migpuma $outvars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2014 & !(prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1), vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(prev_exp_any_migpuma $outvars) mat(out_wcontrols_wwt)

    di in red "OUT migration: Target population `i' NO weights "
    **** NO WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma prev_exp_any_migpuma  if targetpop`i'==1 & year>=2014 & !(prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1), vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(prev_exp_any_migpuma $outvars) mat(out_nocontrols_nowt)

    * with controls and state exposure
    reghdfe move_migpuma prev_exp_any_migpuma $outvars  $covars  if targetpop`i'==1  & year>=2014 & !(prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1), vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(prev_exp_any_migpuma $outvars) mat(out_wcontrols_nowt)

}


**** Consolidate matrices
mat targetpop_in_wwt = in_nocontrols_wwt , in_wcontrols_wwt
mat targetpop_in_nowt = in_nocontrols_nowt , in_wcontrols_nowt

mat targetpop_out_wwt = out_nocontrols_wwt , out_wcontrols_wwt
mat targetpop_out_nowt = out_nocontrols_nowt , out_wcontrols_nowt


**** Input matrices in spreadsheet
fill_tables, mat(targetpop_in_wwt) save_txt("$oo/estudy_specifications") save_excel("$oo/estudy_specifications") 
fill_tables, mat(targetpop_in_nowt) save_txt("$oo/estudy_specifications") save_excel("$oo/estudy_specifications") 

fill_tables, mat(targetpop_out_wwt) save_txt("$oo/estudy_specifications") save_excel("$oo/estudy_specifications") 
fill_tables, mat(targetpop_out_nowt) save_txt("$oo/estudy_specifications") save_excel("$oo/estudy_specifications") 






/**************************************************************
Repeat specifications
**************************************************************/

cap mat drop in_nocontrols_wwt
cap mat drop in_wcontrols_wwt
cap mat drop in_nocontrols_nowt
cap mat drop in_wcontrols_nowt

cap mat drop out_nocontrols_wwt
cap mat drop out_wcontrols_wwt
cap mat drop out_nocontrols_nowt
cap mat drop out_wcontrols_nowt

foreach i in 2 3 5 6 8 9 {
    di in red "Processing target population `i' "


    use "$oi/working_acs", clear 
    * using county level vars

    keep if year >= 2013
    * define propensity weights
    drop if always_treated_migpuma==1
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
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(in_nocontrols_wwt)

    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2013 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(in_wcontrols_wwt)

    di in red "IN migration: Target population `i' NO weights "
    **** NO WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma exp_any_migpuma  if targetpop`i'==1 & year>=2013 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(in_nocontrols_nowt)

    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars  if targetpop`i'==1  & year>=2013 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(in_wcontrols_nowt)


    /**************************************************************
    OUT migration
    **************************************************************/
    di in red "OUT migration: Target population `i' WITH weights "
    **** WITH WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma prev_exp_any_migpuma [pw=perwt_wt]  if targetpop`i'==1 & year>=2014 , vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
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
fill_tables, mat(targetpop_in_wwt) save_txt("$oo/estudy_specifications_full") save_excel("$oo/estudy_specifications_full") 
fill_tables, mat(targetpop_in_nowt) save_txt("$oo/estudy_specifications_full") save_excel("$oo/estudy_specifications_full") 

fill_tables, mat(targetpop_out_wwt) save_txt("$oo/estudy_specifications_full") save_excel("$oo/estudy_specifications_full") 
fill_tables, mat(targetpop_out_nowt) save_txt("$oo/estudy_specifications_full") save_excel("$oo/estudy_specifications_full") 






/**************************************************************
CREATE RAW MEANS PLOTS FOR EACH GROUP
**************************************************************/

foreach i in 2 3 5 6 8 9 {
 use "$oi/working_acs", clear 

* drop years and puma we don't need
keep if year >= 2013
drop if puma== 77777 //louisiana katrina

drop if always_treated_migpuma==1

* define propensity weights
merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t`i'" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)
gen perwt_wt = perwt*wt

* obtain the prop score weighted vsersion
foreach v in   move_migpuma {
    gen `v'_wwt = `v'* perwt_wt
    gen `v'_wwt_targetpop`i' = `v' if targetpop`i'==1
}
* obtain the basic weighted vsersion
foreach v in  move_migpuma  {
    replace `v' = `v'*perwt
    gen `v'_targetpop`i' = `v' if targetpop`i'==1
}

gen weighted_targetpop`i' = perwt_wt
replace targetpop`i' = targetpop`i'*perwt
collapse (sum) sum_move_migpuma=move_migpuma sum_move_migpuma_targetpop`i'=move_migpuma_targetpop`i' ///
    sum_move_migpuma_wwt=move_migpuma_wwt sum_move_migpuma_wwt_targetpop`i'=move_migpuma_wwt_targetpop`i' ///
    weighted_sample=perwt_wt unweighted_sample= perwt ///
    weighted_targetpop`i' targetpop`i' ///
     , by(year ever_treated_migpuma)

gen move_migpuma = sum_move_migpuma / unweighted_sample
gen move_migpuma_targetpop`i' = sum_move_migpuma_targetpop`i' / targetpop`i' 
gen move_migpuma_wwt = sum_move_migpuma_wwt / weighted_sample
gen move_migpuma_wwt_targetpop`i' = sum_move_migpuma_wwt_targetpop`i' / weighted_targetpop`i' 

* graph of migpuma mobility
twoway (connected move_migpuma year if ever_treated_migpuma ==0 , mcolor(midblue) lcolor(midblue) msymbol(circle) msize(1.5) ) ///
    (connected move_migpuma year if ever_treated_migpuma ==1 , mcolor(dkorange) lcolor(dkorange) msymbol(triangle) msize(2) ) ///
    (connected move_migpuma_wwt year if ever_treated_migpuma ==0 , mcolor(midblue) lcolor(midblue) msymbol(circle) lpattern(dash) msize(1.5)  yaxis(2) ) ///
    , legend(pos(6) rows(1) order(1 "Never exposed" 2 "Ever Exposed" 3 "Never exposed, propensity weighted" )) xtitle(Survey year) ytitle(Move migpuma) ///
    xlabel(2013(1)2019)
graph export "$oo/move_means/move_migpuma_wwt.pdf", replace

* graph of migpuma mobility for targetpop
twoway (connected move_migpuma_targetpop`i' year if ever_treated_migpuma ==0 , mcolor(midblue) lcolor(midblue) msymbol(circle) msize(1.5) ) ///
    (connected move_migpuma_targetpop`i' year if ever_treated_migpuma ==1 , mcolor(dkorange) lcolor(dkorange) msymbol(triangle) msize(2) ) ///
    (connected move_migpuma_wwt_targetpop`i' year if ever_treated_migpuma ==0 , mcolor(midblue) lcolor(midblue) msymbol(circle) lpattern(dash) msize(1.5) yaxis(2)) ///
    , legend(pos(6) rows(1) order(1 "Never exposed" 2 "Ever Exposed" 3 "Never exposed, propensity weighted" )) xtitle(Survey year) ytitle(Move migpuma) ///
    xlabel(2013(1)2019)
graph export "$oo/move_means/move_migpuma_targetpop`i'_wwt.pdf", replace
}





/*
/**************************************************************
troubleshoot other stuff
**************************************************************/


foreach i in 2 3 5 6 8 9 {
    di in red "Processing target population `i' "

    use "$oi/working_acs", clear 
    * using county level vars

    keep if year >= 2013
    drop if always_treated_migpuma==1
    * define propensity weights
    merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t`i'" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)
    gen perwt_wt = perwt*wt
    drop if mi(perwt_wt)
    /* restrictions to remember
    drop if puma== 77777 //louisiana katrina
    */
    drop targetpop1 targetpop2 targetpop3 targetpop4 targetpop6 targetpop7 targetpop8 targetpop9

    /**************************************************************
    IN migration
    **************************************************************/

    di in red "IN migration: Target population `i' NO weights "
    * no controls
    reghdfe move_migpuma exp_any_migpuma  if targetpop`i'==1 & year>=2013 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    * with controls
    reghdfe move_migpuma exp_any_migpuma $covars if targetpop`i'==1 & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reghdfe move_migpuma exp_any_migpuma $covars [pw=perwt_wt] if targetpop`i'==1 & year>=2013, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)

    * no controls
    reghdfe move_migpuma exp_any_migpuma  if targetpop`i'==1 & year>=2013 & !(year>=lost_exp_year & ever_lost_exp_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & !(year>=lost_exp_year & ever_lost_exp_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)

    reghdfe move_migpuma exp_any_migpuma  if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)



    * with controls
    reghdfe move_migpuma exp_any_migpuma $covars if targetpop`i'==1 & year>=2013 & !(year>=lost_exp_year & ever_lost_exp_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reghdfe move_migpuma exp_any_migpuma $covars [pw=perwt_wt] if targetpop`i'==1 & year>=2013 & !(year>=lost_exp_year & ever_lost_exp_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)

    reghdfe move_migpuma exp_any_migpuma $covars if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reghdfe move_migpuma exp_any_migpuma $covars [pw=perwt_wt] if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)

    * no controls
    reghdfe move_migpuma exp_any_migpuma  if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma==1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma==1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)


    * with weights
    reghdfe move_migpuma exp_any_migpuma $covars if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma==1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reghdfe move_migpuma exp_any_migpuma $covars [pw=perwt_wt] if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma==1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)


    di in red "IN migration: Target population `i' WITH weights "
    local i = 2
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    **** WITH WEIGHT
    * base no controls or state exposure. Only those gaining exposure
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    

    * base no controls or state exposure. Only those loosing exposure
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & !(ever_gain_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    

    * base no controls or state exposure. Only those always treated
    local i = 2
    reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop`i'==1 & year>=2013 & ever_lost_exp_migpuma!=1  & ever_gain_exp_migpuma!=1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(in_nocontrols_wwt)



    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2013  & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(in_wcontrols_wwt)

    di in red "IN migration: Target population `i' NO weights "
    **** NO WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma exp_any_migpuma  if targetpop`i'==1 & year>=2013  & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(exp_any_migpuma $invars) mat(in_nocontrols_nowt)

    * with controls and state exposure
    reghdfe move_migpuma exp_any_migpuma $invars  $covars  if targetpop`i'==1  & year>=2013  & !(ever_lost_exp_migpuma==1 | always_treated_migpuma==1), vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(exp_any_migpuma $invars) mat(in_wcontrols_nowt)


    /*/**************************************************************
    OUT migration
    **************************************************************/
    di in red "OUT migration: Target population `i' WITH weights "
    **** WITH WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma prev_exp_any_migpuma [pw=perwt_wt]  if targetpop`i'==1 & year>=2014  & !(prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1) , vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(prev_exp_any_migpuma $outvars) mat(out_nocontrols_wwt)

    * with controls and state exposure
    reghdfe move_migpuma prev_exp_any_migpuma $outvars  $covars [pw=perwt_wt]  if targetpop`i'==1  & year>=2014 & !(prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1), vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(prev_exp_any_migpuma $outvars) mat(out_wcontrols_wwt)

    di in red "OUT migration: Target population `i' NO weights "
    **** NO WEIGHT
    * base no controls or state exposure
    reghdfe move_migpuma prev_exp_any_migpuma  if targetpop`i'==1 & year>=2014 & !(prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1), vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma ) indvars(prev_exp_any_migpuma $outvars) mat(out_nocontrols_nowt)

    * with controls and state exposure
    reghdfe move_migpuma prev_exp_any_migpuma $outvars  $covars  if targetpop`i'==1  & year>=2014 & !(prev_ever_lost_exp_migpuma==1 | prev_always_treated_migpuma==1), vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
    reg_to_mat, depvar(move_migpuma) indvars(prev_exp_any_migpuma $outvars) mat(out_wcontrols_nowt)*/ 

}


/**** Consolidate matrices
mat targetpop_in_wwt = in_nocontrols_wwt , in_wcontrols_wwt
mat targetpop_in_nowt = in_nocontrols_nowt , in_wcontrols_nowt

mat targetpop_out_wwt = out_nocontrols_wwt , out_wcontrols_wwt
mat targetpop_out_nowt = out_nocontrols_nowt , out_wcontrols_nowt


**** Input matrices in spreadsheet
fill_tables, mat(targetpop_in_wwt) save_txt("$oo/estudy_specifications") save_excel("$oo/estudy_specifications") 
fill_tables, mat(targetpop_in_nowt) save_txt("$oo/estudy_specifications") save_excel("$oo/estudy_specifications") 

fill_tables, mat(targetpop_out_wwt) save_txt("$oo/estudy_specifications") save_excel("$oo/estudy_specifications") 
fill_tables, mat(targetpop_out_nowt) save_txt("$oo/estudy_specifications") save_excel("$oo/estudy_specifications") 
