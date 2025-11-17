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

keep statefip current_migpuma year exp_any_migpuma always_treated_migpuma
duplicates drop 

collapse (sum) exp_any_migpuma always_treated_migpuma, by(year)
gen not_always = exp_any_migpuma - always_treated_migpuma

twoway (bar always_treated_migpuma year, barw(0.6)  color(gs9) ) ///
	(rbar always_treated_migpuma exp_any_migpuma year, barw(0.6) color(gs3) )  ///
	(scatter exp_any_migpuma year , mstyle(none) mlabel(exp_any_migpuma) mlabcolor(black) mlabgap(1) mlabpos(12) mlabsize(3.7) ) ///
	, legend(pos(6) rows(1) order(1 "Always active" 2 "Not always active" ) ) ytitle(Migpuma count) xtitle(Survey year)  ///
	xlabel(2012(1)2019) ylabel(0(25)100)
graph export "$oo/bar_active_agreements.png", replace




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
merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t2" , nogen keep(3) keepusing( phat wt)
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
	$invars  $covars [pw=perwt]  if targetpop2==1  & year>=2013 & ever_lost_exp_migpuma==0, ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target
* Plot with separate colors for pre- and post-event coefficients
coefplot ///
	(in_target , keep(gain_ry_minus* gain_ry_plus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma")  ///
	ylabel(-.2(.1).3)
graph export "$oo/estudy/final/ingain_targetpop2_nowt.png", replace


**** GAINERS, WITH WEIGHT
reghdfe move_migpuma gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3  ///
	$invars  $covars [pw=perwt_wt]  if targetpop2==1  & year>=2013 & ever_lost_exp_migpuma==0, ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target
* Plot with separate colors for pre- and post-event coefficients
coefplot ///
	(in_target , keep(gain_ry_minus* gain_ry_plus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma")  ///
	ylabel(-.2(.1).3)
graph export "$oo/estudy/final/ingain_targetpop2_wwt.png", replace



replace lost_ry_minus6 = lost_ry_minus7 | lost_ry_minus6
**** LOSERS, NO WEIGHT
reghdfe move_migpuma lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6  ///
	$invars  $covars [pw=perwt]  if targetpop2==1  & year>=2013 & ever_gain_exp_migpuma==0, ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target
* Plot 
coefplot ///
	(in_target , keep(lost_ry_minus* lost_ry_plus* o.lost_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
	, nooffsets xline(7, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma") 
graph export "$oo/estudy/final/inlost_targetpop2_nowt.png", replace


**** LOSERS, WITH WEIGHT
reghdfe move_migpuma lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6  ///
	$invars  $covars [pw=perwt_wt]  if targetpop2==1  & year>=2013 & ever_gain_exp_migpuma==0, ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target
* Plot
coefplot ///
	(in_target , keep(lost_ry_minus* lost_ry_plus* o.lost_ry_minus1) msymbol(circle ) mcolor(midblue) ciopts(lcolor(midblue) lwidth(0.1) recast(rcap))) ///
	, nooffsets xline(7, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) legend(off) ///
	xtitle("Relative year")   ytitle("Move migpuma")
graph export "$oo/estudy/final/inlost_targetpop2_wwt.png", replace

