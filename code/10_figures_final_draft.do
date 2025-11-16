/*---------------------
Mena kiser
10-25-25

Figures in research proposal
---------------------*/


clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"
global oo "$wd/output/"

/**************************************************************
Figure 1: propensity score density
**************************************************************/
use "$oi/troubleshoot/propensity_weights2013migpuma_t2" , clear 
twoway (line d_1 x_1, sort  lpattern(solid) lcolor(midblue) lwidth(0.3)  ) ///
	(line d_0 x_0, sort lpattern(longdash) lcolor(dkorange) lwidth(0.4)  ) ///
	 (line d_0w x_0w, sort lpattern(shortdash) lcolor(black) lwidth(0.5) ) ///
	 , legend(pos(6)  rows(1) order( 1 "Treatment group" 2 "Control group, unweighted" 3 "Control group, weighted" ) ) ///
	 xtitle("Pr(Migpuma is ever exposed)") ytitle("Density")
graph export "$oo/prop_score.png", replace


/**************************************************************
Figure 2: Event study for mobility
**************************************************************/
global covars "age r_white r_black r_asian hs in_school no_english ownhome"
global invars "exp_any_state " //SC_any
global outvars "prev_exp_any_state " //prev_SC_any

use "$oi/working_acs", clear 
keep if year >= 2012
drop if ever_lost_exp_migpuma==1 | always_treated_migpuma==1
* define propensity weights
merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t2" , nogen keep(3) keepusing( phat wt)
gen perwt_wt = perwt*wt
drop if mi(perwt_wt)
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & young==1  & marst>=3  //hispanic citizens born in the usa

* define event year dummies for in migration
gen event_year = year if exp_any_migpuma==1
bys geoid: ereplace event_year = min(event_year)
replace event_year = . if ever_treated_migpuma==0
gen relative_year = (year-event_year)*ever_treated_migpuma
replace relative_year = . if ever_treated_migpuma==0

* define event year dummies for out migration
bys prev_geoid: egen prev_ever_treated_migpuma = max(prev_exp_any_migpuma>0 & year>=2014) 
gen prev_event_year = year if prev_exp_any_migpuma == 1
bys prev_geoid: ereplace prev_event_year = min(prev_event_year)
replace prev_event_year = . if prev_ever_treated_migpuma == 0
gen prev_relative_year = (year - prev_event_year) * prev_ever_treated_migpuma
replace prev_relative_year = . if prev_ever_treated_migpuma == 0

* there's twice as much people living in a treated migpuma the year before than currently
 sum prev_ever_treated_migpuma ever_treated_migpuma

* in migration
eventdd move_any $covars $invars i.year i.geoid [pw=perwt_wt]  if targetpop==1 , timevar(relative_year) method(ols, cluster(group_id)) graph_op(ytitle("Any move") xtitle("Relative year") xlabel(-5(1)5) legend(off)) leads(5) lags(5) accum
	graph export "$oo/es_in_any.png", replace

eventdd move_migpuma $covars $invars i.year i.geoid [pw=perwt_wt]  if targetpop==1 , timevar(relative_year) method(ols, cluster(group_id)) graph_op(ytitle("Move migpuma") xtitle("Relative year") xlabel(-5(1)5) legend(off)) leads(5) lags(5) accum
	graph export "$oo/es_in_migpuma.png", replace

eventdd move_state $covars $invars i.year i.geoid [pw=perwt_wt]  if targetpop==1 , timevar(relative_year) method(ols, cluster(group_id)) graph_op(ytitle("Move state") xtitle("Relative year") xlabel(-5(1)5) legend(off)) leads(5) lags(5) accum
	graph export "$oo/es_in_state.png", replace

* out migration
eventdd move_any $covars $outvars i.year i.prev_geoid [pw=perwt_wt]  if targetpop==1 & year>=2012, timevar(prev_relative_year) method(ols, cluster(group_id)) graph_op(ytitle("Any move") xtitle("Relative year") xlabel(-5(1)5) legend(off)) leads(5) lags(5) accum
	graph export "$oo/es_out_any.png", replace

eventdd move_migpuma $covars $outvars i.year i.prev_geoid [pw=perwt_wt]  if targetpop==1 & year>=2012, timevar(prev_relative_year) method(ols, cluster(group_id)) graph_op(ytitle("Move migpuma") xtitle("Relative year") xlabel(-5(1)5) legend(off)) leads(5) lags(5)  accum
	graph export "$oo/es_out_migpuma.png", replace

eventdd move_state $covars $outvars i.year i.prev_geoid [pw=perwt_wt]  if targetpop==1 & year>=2012, timevar(prev_relative_year) method(ols, cluster(group_id)) graph_op(ytitle("Move state") xtitle("Relative year") xlabel(-5(1)5) legend(off)) leads(5) lags(5) accum
	graph export "$oo/es_out_state.png", replace
