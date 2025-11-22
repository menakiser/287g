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
twoway (line d_1 x_1 , sort  lpattern(solid) lcolor(midblue) lwidth(0.3)  ) ///
	(line d_0 x_0 , sort lpattern(longdash) lcolor(dkorange) lwidth(0.4)  ) ///
	 (line d_0w x_0w , sort lpattern(shortdash) lcolor(black) lwidth(0.5) ) ///
	 , legend(pos(6)  rows(1) order( 1 "Treatment group" 2 "Control group, unweighted" 3 "Control group, weighted" ) ) ///
	 xtitle("Pr(Migpuma is treated)") ytitle("Density") xsize(7) xlabel(0(0.5)1)
graph export "$oo/final/prop_score.png", replace



/**************************************************************
EVENT STUDY FOR GAINERS AND LOSERS TOTAL POP
**************************************************************/
global covarspop "log_tot_int_age1 log_tot_int_age2 log_tot_int_age3 log_tot_int_age4 log_tot_int_age5 log_tot_int_age6 log_tot_r_white log_tot_r_black log_tot_r_asian log_tot_hs log_tot_in_school log_tot_ownhome"
global covarsnat "log_nat_int_age1 log_nat_int_age2 log_nat_int_age3 log_nat_int_age4 log_nat_int_age5 log_nat_int_age6 log_nat_r_white log_nat_r_black log_nat_r_asian log_nat_hs log_nat_in_school log_nat_ownhome"
global invars "exp_any_state "

use "$oi/migpuma_year_pops", clear

********** In same regression
**** GAINERS, NO WEIGHT
reghdfe log_tot_targetpop2 gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
	gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3  ///
	lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
	lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6 ///
	$covarsnat $invars [aw=tot_targetpop2] , ///
	vce(robust) absorb(geoid_migpuma year)
est store in_target1

**** REDUCE WIDTH
coefplot ///
    (in_target1 , keep(lost_ry_minus* o.lost_ry_minus1 lost_ry_plus* ) msymbol(circle ) offset(-0.15) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
    (in_target1 , keep(gain_ry_minus* o.gain_ry_minus1 gain_ry_plus* ) msymbol(triangle ) offset(-12.85) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
    , xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
    omit vertical ///
    eqlabels(, none) graphregion(color(white)) ///
    xtitle("Relative year")   ytitle("Log of total target population") ///
    title("(a) Gained treatment") ///
    legend(order(2 "Lost" 4 "Gain") row(1) pos(6))  ///
    xlabel(1 "-6" 2 "-5" 3 "-4" 4 "-3" 5 "-2" 6 "-1" 7 "0" 8 "1" 9 "2" 10 "3" 11 "4" 12 "5" 13 "6", noticks) ///
    xscale(range(0.5 6)) plotregion(margin(zero)) //xsize(5)
graph export "$oo/final/ingain_targetpop2_nowt_samereg_log.png", replace

**** LOSERS, NO WEIGHT
coefplot ///
	(in_target1 , keep(lost_ry_minus* o.lost_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	(in_target1 , keep(lost_ry_plus* ) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Log of total target population") ///
	title("(b) Lost treatment")  ///
	legend(order(2 "Active treatment" 4 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/inlost_targetpop2_nowt_samereg_log.png", replace





********** In same regression PLACEBO
**** GAINERS, NO WEIGHT
reghdfe log_total_placebo1 gain_ry_minus6 gain_ry_minus5 gain_ry_minus4 gain_ry_minus3 gain_ry_minus2 o.gain_ry_minus1 ///
	gain_ry_plus0 gain_ry_plus1 gain_ry_plus2 gain_ry_plus3  ///
	lost_ry_minus6 lost_ry_minus5 lost_ry_minus4 lost_ry_minus3 lost_ry_minus2 o.lost_ry_minus1 ///
	lost_ry_plus0 lost_ry_plus1 lost_ry_plus2 lost_ry_plus3 lost_ry_plus4 lost_ry_plus5 lost_ry_plus6 ///
	$covarsPOP $invars , ///
	vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
est store in_target1

**** REDUCE WIDTH
coefplot ///
	(in_target1 , keep(gain_ry_minus* o.gain_ry_minus1) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	(in_target1 , keep(gain_ry_plus* ) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white)) ///
	xtitle("Relative year")   ytitle("Log of total placebo population") ///
	title("(b) Gained treatment - Placebo") ///
	legend(order(4 "Active treatment" 2 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/ingain_placebo_nowt_samereg_log.png", replace

**** LOSERS, NO WEIGHT
coefplot ///
	(in_target1 , keep(lost_ry_minus* o.lost_ry_minus1) msymbol(circle ) mcolor(navy) msize(1.25) ciopts(lcolor(navy) lwidth(0.3) recast(rcap))) ///
	(in_target1 , keep(lost_ry_plus* ) msymbol(circle ) mcolor(midblue) msize(1.25) ciopts(lcolor(midblue) lwidth(0.3) recast(rcap))) ///
	, nooffsets xline(6, lcolor(gray) lpattern(solid))  yline(0, lcolor(gray) lpattern(dash))  ///
	omit vertical ///
	eqlabels(, labels) graphregion(color(white))  ///
	xtitle("Relative year")   ytitle("Log of total placebo population") ///
	title("(d) Lost treatment - Placebo")  ///
	legend(order(2 "Active treatment" 4 "No treatment") row(1) pos(6)) xsize(5)
graph export "$oo/final/inlost_placebo_nowt_samereg_log.png", replace