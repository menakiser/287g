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
use "$oi/propensity_weights2012migpuma_t2", clear 
twoway (line d_1 x_1, sort  lpattern(solid) lcolor(midblue) lwidth(0.3)  ) ///
	(line d_0 x_0, sort lpattern(longdash) lcolor(dkorange) lwidth(0.4)  ) ///
	 (line d_0w x_0w, sort lpattern(shortdash) lcolor(black) lwidth(0.5) ) ///
	 , legend(pos(6)  rows(1) order( 1 "Treatment group" 2 "Control group, unweighted" 3 "Control group, weighted" ) ) ///
	 xtitle("Pr(Migpuma is ever exposed)") ytitle("Density") xsize(7)
graph export "$oo/final/prop_score.png", replace


/**************************************************************
Figure 2: Event study for mobility
**************************************************************/
global covars "age r_white r_black r_asian hs in_school no_english ownhome"
global invars "exp_any_state " //SC_any
global outvars "prev_exp_any_state " //prev_SC_any

use "$oi/working_acs", clear 
keep if year >= 2012

keep statefip current_migpuma year exp_any_migpuma always_treated_migpuma ever_gain_exp_migpuma ever_lost_exp_migpuma ever_treated_migpuma
duplicates drop 

compress
export delimited using "$oi/list_migpumas_treatment", replace

collapse (sum) exp_any_migpuma always_treated_migpuma ever_gain_exp_migpuma ever_lost_exp_migpuma, by(year)
gen not_always = exp_any_migpuma - always_treated_migpuma

twoway (bar always_treated_migpuma year, barw(0.6)  color(gs9) ) ///
	(rbar always_treated_migpuma exp_any_migpuma year, barw(0.6) color(gs3) )  ///
	(scatter exp_any_migpuma year , mstyle(none) mlabel(exp_any_migpuma) mlabcolor(black) mlabgap(1) mlabpos(12) mlabsize(3.7) ) ///
	, legend(pos(6) rows(1) order(1 "Always active" 2 "Not always active" ) ) ytitle(Migpuma count) xtitle(Survey year)  ///
	xlabel(2012(1)2019) ylabel(0(25)100)
graph export "$oo/final/bar_active_agreements.png", replace




/**************************************************************
Figure 2: Event study for mobility
**************************************************************/
global covars "age r_white r_black r_asian hs in_school no_english ownhome"
global invars "exp_any_state " //SC_any
global outvars "prev_exp_any_state " //prev_SC_any

use "$oi/working_acs", clear 
keep if year >= 2012
drop if always_treated_migpuma==1
* define propensity weights
merge m:1 statefip current_migpuma  using  "$oi/propensity_weights2012migpuma_t2" , nogen keep(3) keepusing( phat wt)
gen perwt_wt = perwt*wt
drop if mi(perwt_wt)
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & young==1  & marst>=3  //hispanic citizens born in the usa

**** IN MIGRATION FOR TARGET POPULATION

*** create relative year for gainers
gen relative_year_gain =  year - gain_exp_year
replace relative_year_gain = . if gain_exp_year == 0

* event-time indicators
forval n = 1/7 {
	gen gain_ry_plus`n'  = (relative_year_gain == `n')
	gen gain_ry_minus`n' = (relative_year_gain == -`n')
}
* event time = 0
gen gain_ry_plus0 = (relative_year_gain == 0)

*** create relative year for losers
gen relative_year_lost =  year - lost_exp_year
replace relative_year_lost = . if lost_exp_year == 0

* event-time indicators
forval n = 1/7 {
	gen lost_ry_plus`n'  = (relative_year_lost == `n')
	gen lost_ry_minus`n' = (relative_year_lost == -`n')
}
* event time = 0
gen lost_ry_plus0 = (relative_year_lost == 0)

* label years
forval n = 1/7 {
	label var gain_ry_plus`n' "+`n'"
	label var gain_ry_minus`n' "-`n'"
	label var lost_ry_plus`n' "+`n'"
	label var lost_ry_minus`n' "-`n'"
}
label var gain_ry_plus0 "0"
label var lost_ry_plus0 "0"

replace gain_ry_minus6 = gain_ry_minus6 | gain_ry_minus7

**** GAINERS, NO WEIGHT
reghdfe move_migpuma gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3  ///
	$invars  $covars [pw=perwt]  if targetpop2==1 & ever_lost_exp_migpuma==0, ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target1
* Plot with separate colors for pre- and post-event coefficients
coefplot ///
	(in_target1 , keep(gain_ry_minus* gain_ry_plus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma")  ///
	ylabel(-.2(.1).3)
graph export "$oo/final/ingain_targetpop2_nowt.png", replace


**** GAINERS, WITH WEIGHT
reghdfe move_migpuma gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3  ///
	$invars  $covars [pw=perwt_wt]  if targetpop2==1 & ever_lost_exp_migpuma==0, ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target2
* Plot with separate colors for pre- and post-event coefficients
coefplot ///
	(in_target2 , keep(gain_ry_minus* gain_ry_plus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma")  ///
	ylabel(-.2(.1).3)
graph export "$oo/final/ingain_targetpop2_wwt.png", replace



replace lost_ry_minus6 = lost_ry_minus7 | lost_ry_minus6
**** LOSERS, NO WEIGHT
reghdfe move_migpuma lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6  ///
	$invars  $covars [pw=perwt]  if targetpop2==1 & ever_gain_exp_migpuma==0, ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target3
* Plot 
coefplot ///
	(in_target3 , keep(lost_ry_minus* lost_ry_plus* o.lost_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma") 
graph export "$oo/final/inlost_targetpop2_nowt.png", replace


**** LOSERS, WITH WEIGHT
reghdfe move_migpuma lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6  ///
	$invars  $covars [pw=perwt_wt]  if targetpop2==1 & ever_gain_exp_migpuma==0, ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target4
* Plot
coefplot ///
	(in_target4 , keep(lost_ry_minus* lost_ry_plus* o.lost_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
	, nooffsets xline(7, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma") 
graph export "$oo/final/inlost_targetpop2_wwt.png", replace 

**** REDUCE WIDTH
coefplot ///
	(in_target1 , keep(gain_ry_minus* gain_ry_plus* o.gain_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma") title("(a): Unweighted") ///
	ylabel(-.2(.1).3) xsize(5)
graph export "$oo/final/ingain_targetpop2_nowt.png", replace

coefplot ///
	(in_target2 ,keep(gain_ry_minus* gain_ry_plus* o.gain_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma") title("(b): Propensity weighted")  ///
	ylabel(-.2(.1).3) xsize(5)
graph export "$oo/final/ingain_targetpop2_wwt.png", replace

**** LOSERS, NO WEIGHT
coefplot ///
	(in_target3 , keep(lost_ry_minus* lost_ry_plus* o.lost_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.25) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma") title("(a): Unweighted") ///
	ylabel(-.2(.1).3) xsize(5)
graph export "$oo/final/inlost_targetpop2_nowt.png", replace
coefplot ///
	(in_target4 , keep(lost_ry_minus* lost_ry_plus* o.lost_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.25) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma") title("(b): Propensity weighted") ///
	ylabel(-.2(.1).3) xsize(5)
graph export "$oo/final/inlost_targetpop2_wwt.png", replace



/**************************************************************
TOTAL NUMBER OF TARGET POP
**************************************************************/
global covars "age r_white r_black r_asian hs in_school no_english ownhome"
global invars "exp_any_state " //SC_any
global outvars "prev_exp_any_state " //prev_SC_any

use "$oi/working_acs", clear 
keep if year >= 2012
drop if always_treated_migpuma==1
* define propensity weights
merge m:1 statefip current_migpuma  using  "$oi/propensity_weights2012migpuma_t2" , nogen keep(3) keepusing( phat wt)
gen perwt_wt = perwt*wt
drop if mi(perwt_wt)
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & young==1  & marst>=3  //hispanic citizens born in the usa

gen total_targetpop2 = perwt if targetpop2==1
gen total_targetpop2_wwt = perwt_wt if targetpop2==1
gen total_pop = perwt if age>=18 & age<=65
gen total_pop_wwt = perwt_wt if age>=18 & age<=65


gen relative_year_gain =  year - gain_exp_year
replace relative_year_gain = . if gain_exp_year == 0

* get moving totals
gen move_target = move_migpuma*total_targetpop2
gen move_target_wwt = move_migpuma*total_targetpop2

gen move_migpuma_wwt = perwt_wt*move_migpuma
replace move_migpuma = perwt*move_migpuma

*** create relative year for losers
gen relative_year_lost =  year - lost_exp_year
replace relative_year_lost = . if lost_exp_year == 0

replace placebo1 = placebo1*perwt 
gen placebo1_wwt = placebo1*wt 

collapse (sum) move_target move_migpuma move_target_wwt move_migpuma_wwt total_targetpop2 total_targetpop2_wwt total_pop total_pop_wwt placebo1 placebo1_wwt ///
	(mean) $covars ///
	(max) exp_any_migpuma  ever_treated_migpuma ever_lost_exp_migpuma ever_gain_exp_migpuma ///
	relative_year_gain relative_year_lost geoid_migpuma $invars ///
	, by(current_migpuma statefip year)

* event-time indicators
forval n = 1/7 {
	gen gain_ry_plus`n'  = (relative_year_gain == `n')
	gen gain_ry_minus`n' = (relative_year_gain == -`n')
}
* event time = 0
gen gain_ry_plus0 = (relative_year_gain == 0)

* event-time indicators
forval n = 1/7 {
	gen lost_ry_plus`n'  = (relative_year_lost == `n')
	gen lost_ry_minus`n' = (relative_year_lost == -`n')
}
* event time = 0
gen lost_ry_plus0 = (relative_year_lost == 0)

* label years
forval n = 1/7 {
	label var gain_ry_plus`n' "+`n'"
	label var gain_ry_minus`n' "-`n'"
	label var lost_ry_plus`n' "+`n'"
	label var lost_ry_minus`n' "-`n'"
}
label var gain_ry_plus0 "0"
label var lost_ry_plus0 "0"

replace gain_ry_minus6 = gain_ry_minus6 | gain_ry_minus7

format total_targetpop2 %12.2fc
gen total_targetpop2_k = total_targetpop2/1000
gen total_targetpop2_wwt_k = total_targetpop2_wwt/1000
gen total_pop2012K = total_pop/1000 if year==2012
bys statefip current_migpuma: ereplace total_pop2012K = mode(total_pop2012K)

format move_target_wwt %12.0fc
gen move_target_wwt_k = move_target_wwt/1000
gen move_target_k = move_target/1000

gen total_targetpop2_sh = total_targetpop2 / total_pop

gen total_pop_k = total_pop /1000

gen placebo1_k = placebo1/1000


gen log_total_pop = total_pop
gen log_total_targetpop2 = total_targetpop2
gen log_total_placebo1 = placebo1

************** TOTAL POPULATION of target pop

************ gainers YES weights, no controls $covars $invars
reghdfe log_total_targetpop2 gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3 exp_any_state ///
	   if ever_lost_exp_migpuma==0, ///
	vce(cluster geoid_migpuma) absorb(geoid_migpuma year) //for those that gain treatment, the total target pop increases with treatment
est store in_target1
* Plot with separate colors for pre- and post-event coefficients
coefplot ///
	(in_target1 , keep(gain_ry_minus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	(in_target1 , keep(gain_ry_plus* ) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Total target population (thousands)") ///
	title("(a) Gained treatment") ///
	legend(order(4 "Active treatment" 2 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/ingain_total_target_nowt.png", replace


************* losers YES weights
reghdfe log_total_targetpop2 lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6 exp_any_state ///
	if ever_gain_exp_migpuma==0, ///
	vce(cluster geoid_migpuma) absorb(geoid_migpuma year)
est store in_target3
* Plot 
coefplot ///
	(in_target3 , keep(lost_ry_minus* o.lost_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	(in_target3 , keep(lost_ry_plus* ) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Total target population (thousands)") ///
	title("(b) Lost treatment")  ///
	legend(order(2 "Active treatment" 4 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/inlost_total_target_nowt.png", replace




************** TOTAL PLACEBO POPULATION 

************ gainers YES weights, no controls $covars $invars
reghdfe log_total_placebo1 gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3 exp_any_state ///
	   if ever_lost_exp_migpuma==0, ///
	vce(cluster geoid_migpuma) absorb(geoid_migpuma year) //for those that gain treatment, the total target pop increases with treatment
est store in_target1
* Plot with separate colors for pre- and post-event coefficients
coefplot ///
	(in_target1 , keep(gain_ry_minus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	(in_target1 , keep(gain_ry_plus* ) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Total placebo population (thousands)") ///
	title("(a) Gained treatment") ///
	legend(order(4 "Active treatment" 2 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/ingain_placebo_nowt.png", replace


************* losers YES weights
reghdfe log_total_placebo1 lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6 exp_any_state ///
	if ever_gain_exp_migpuma==0, ///
	vce(cluster geoid_migpuma) absorb(geoid_migpuma year)
est store in_target3
* Plot 
coefplot ///
	(in_target3 , keep(lost_ry_minus* o.lost_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	(in_target3 , keep(lost_ry_plus* ) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Total placebo population (thousands)") ///
	title("(b) Lost treatment")  ///
	legend(order(2 "Active treatment" 4 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/inlost_placebo_nowt.png", replace




/************** target POPULATION as a share of total pop

************ gainers YES weights, no controls $covars $invars
reghdfe total_targetpop2_sh gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3 exp_any_state ///
	   if ever_lost_exp_migpuma==0, ///
	vce(cluster geoid_migpuma) absorb(geoid_migpuma year) //for those that gain treatment, the total target pop increases with treatment
est store in_target1
* Plot with separate colors for pre- and post-event coefficients
coefplot ///
	(in_target1 , keep(gain_ry_minus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	(in_target1 , keep(gain_ry_plus* ) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Share of target population") ///
	title("(a) Gained treatment") ///
	legend(order(4 "Active treatment" 2 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/ingain_sh_target_nowt.png", replace


************* losers YES weights
reghdfe total_targetpop2_sh lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6 exp_any_state ///
	if ever_gain_exp_migpuma==0, ///
	vce(cluster geoid_migpuma) absorb(geoid_migpuma year)
est store in_target3
* Plot 
coefplot ///
	(in_target3 , keep(lost_ry_minus* o.lost_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	(in_target3 , keep(lost_ry_plus* ) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Share of target population") ///
	title("(b) Lost treatment")  ///
	legend(order(2 "Active treatment" 4 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/inlost_sh_target_nowt.png", replace


************** TOTAL MOVERS

************ gainers YES weights, no controls $covars $invars
reghdfe move_target_k gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3 exp_any_state ///
	   if ever_lost_exp_migpuma==0, ///
	vce(cluster geoid_migpuma) absorb(geoid_migpuma year) //for those that gain treatment, the total target pop increases with treatment
est store in_target1
* Plot with separate colors for pre- and post-event coefficients
coefplot ///
	(in_target1 , keep(gain_ry_minus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	(in_target1 , keep(gain_ry_plus* ) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) ///
	xtitle("Relative year")   ytitle("Total movers and target population (thousands)") ///
	title("(a) Gained treatment") ///
	legend(order(4 "Active treatment" 2 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/ingain_movetotal_target_nowt.png", replace


************* losers YES weights
reghdfe move_target_k lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6 exp_any_state ///
	if ever_gain_exp_migpuma==0, ///
	vce(cluster geoid_migpuma) absorb(geoid_migpuma year)
est store in_target3
* Plot 
coefplot ///
	(in_target3 , keep(lost_ry_minus* o.lost_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	(in_target3 , keep(lost_ry_plus* ) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Total movers and target population (thousands)") ///
	title("(b) Lost treatment") ///
	legend(order(2 "Active treatment" 4 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/inlost_movetotal_target_nowt.png", replace
*/