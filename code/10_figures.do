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
use "$oi/propensity_weights", clear 
twoway (line d_1 x_1, sort  lpattern(solid) lcolor(midblue) lwidth(0.3)  ) ///
	(line d_0 x_0, sort lpattern(dash) lcolor(dkorange) lwidth(0.4)  ) ///
	 (line d_0w x_0w, sort lpattern(shortdash) lcolor(dkgreen) lwidth(0.5) ) ///
	 , legend(pos(6)  rows(1) order( 1 "Treatment group" 2 "Control group, unweighted" 3 "Control group, weighted" ) ) ///
	 xtitle("Pr(County is ever exposed)") ytitle("Density")
graph export "$oo/prop_score.pdf", replace


/**************************************************************
Figure 2: Event study for mobility
**************************************************************/
use "$oi/acs_w_propensity_weights", clear 

* drop 15 counties that lost treatment at some point 
drop if lost_treatment==1
* define exposure and target population interaction
//gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3
gen allpop = placebo1==1 | targetpop==1
gen exp_pop =  exp_any_binary*targetpop

* define event year dummies
gen event_year = year if exp_any_binary==1
bys statefip countyfip : ereplace event_year = min(event_year)
replace event_year = 0 if ever_treated==0
gen relative_year = (year-event_year)*ever_treated
replace relative_year = . if ever_treated==0
gen targ_relative_year = targetpop*relative_year
gen ry0 = relative_year==0  
gen targ_ry0 = targetpop*ry0
gen ever_ry0 = ever_treated*ry0
forval i=1/6 {
	gen rym`i' = relative_year==-`i'
	gen targ_rym`i' = targetpop*rym`i'
	gen ryp`i' = relative_year==`i'
	gen targ_ryp`i' = targetpop*ryp`i'
}

forval i=1/6 {
	gen ever_rym`i' = ever_treated*rym`i'
}
forval i=1/6 {
	gen ever_ryp`i' = ever_treated*ryp`i'
}

*any move
reghdfe move_any rym6 rym5 rym4 rym3 rym2 o.rym1 ry0 ///
	ryp1 ryp2 ryp3 ryp4 ryp5 ryp6 exp_any_binary  ///
	[pw=perwt_wt] if allpop==1, vce(cluster group_id) absorb(geoid year)
est store e_any
		
coefplot (e_any, label("Target population relative to placebo")  mcolor(navy) ciopts(lcolor(navy) recast(rcap))) ///
	, nooffsets keep(rym* o.rym1 ry0 ryp*) yline(0, lcolor(black)) xline(6, lcolor(black) ) omit vertical ///
	ytitle("Probability of Any Move") ///
	rename(rym6 = "-6" rym5 = "-5" rym4 = "-4" rym3 = "-3" rym2 = "-2" rym1 = "-1" ///
	ry0 = "0"  ryp1 = "+1" ryp2 = "+2" ryp3 = "+3" ryp4 = "+4" ryp5 ="+5" ryp6 ="+6" ) ///
	xtitle("Years") graphregion(color(white)) egend(off) xlabel(,labsize(*.8)) ylabel(-.2(.1).6)

* move county
reghdfe move_county rym6 rym5 rym4 rym3 rym2 o.rym1 ry0 ///
	ryp1 ryp2 ryp3 ryp4 ryp5 ryp6 exp_any_binary  ///
	[pw=perwt_wt] if allpop==1, vce(cluster group_id) absorb(geoid year)
est store e_county
		
coefplot (e_county, label("Target population relative to placebo")  mcolor(navy) ciopts(lcolor(navy) recast(rcap))) ///
	, nooffsets keep(rym* o.rym1 ry0 ryp*) yline(0, lcolor(black)) xline(6, lcolor(black) ) omit vertical ///
	ytitle("Probability of County Move") ///
	rename(rym6 = "-6" rym5 = "-5" rym4 = "-4" rym3 = "-3" rym2 = "-2" rym1 = "-1" ///
	ry0 = "0"  ryp1 = "+1" ryp2 = "+2" ryp3 = "+3" ryp4 = "+4" ryp5 ="+5" ryp6 ="+6" ) ///
	xtitle("Years") graphregion(color(white)) legend(off) ylabel(-.2(.1).6)

* move state
reghdfe move_state rym6 rym5 rym4 rym3 rym2 o.rym1 ry0 ///
	ryp1 ryp2 ryp3 ryp4 ryp5 ryp6 exp_any_binary  ///
	[pw=perwt_wt] if allpop==1, vce(cluster group_id) absorb(geoid year)
est store e_state
		
coefplot (e_state, label("Target population relative to placebo")  mcolor(navy) ciopts(lcolor(navy) recast(rcap))) ///
	, nooffsets keep(rym* o.rym1 ry0 ryp*) yline(0, lcolor(black)) xline(6, lcolor(black) ) omit vertical ///
	ytitle("Probability of State Move") ///
	rename(rym6 = "-6" rym5 = "-5" rym4 = "-4" rym3 = "-3" rym2 = "-2" rym1 = "-1" ///
	ry0 = "0"  ryp1 = "+1" ryp2 = "+2" ryp3 = "+3" ryp4 = "+4" ryp5 ="+5" ryp6 ="+6" ) ///
	xtitle("Years") graphregion(color(white)) legend(off) ylabel(-.2(.1).6)

**** reg
*any move
reghdfe move_any ever_rym6 ever_rym5 ever_rym4 ever_rym3 ever_rym2 o.ever_rym1 ever_ry0 ///
	ever_ryp1 ever_ryp2 ever_ryp3 ever_ryp4 ever_ryp5 ever_ryp6 exp_any_binary  ///
	[pw=perwt_wt] if targetpop==1, vce(cluster group_id) absorb(geoid year)
est store e_any
		
coefplot (e_any, label("Target population relative to placebo")  mcolor(navy) ciopts(lcolor(navy) recast(rcap))) ///
	, nooffsets keep(ever_rym* o.ever_rym1 ever_ry0 ever_ryp*) yline(0, lcolor(black)) xline(6, lcolor(black) ) omit vertical ///
	ytitle("Probability of Any Move") ///
	rename(ever_rym6 = "-6" ever_rym5 = "-5" ever_rym4 = "-4" ever_rym3 = "-3" ever_rym2 = "-2" ever_rym1 = "-1" ///
	ever_ry0 = "0"  ever_ryp1 = "+1" ever_ryp2 = "+2" ever_ryp3 = "+3" ever_ryp4 = "+4" ever_ryp5 ="+5" ever_ryp6 ="+6" ) ///
	xtitle("Years") graphregion(color(white)) legend(off) xlabel(,labsize(*.8)) ylabel(-.4(.2).6)

* move county
reghdfe move_county ever_rym6 ever_rym5 ever_rym4 ever_rym3 ever_rym2 o.ever_rym1 ever_ry0 ///
	ever_ryp1 ever_ryp2 ever_ryp3 ever_ryp4 ever_ryp5 ever_ryp6 exp_any_binary  ///
	[pw=perwt_wt] if targetpop==1, vce(cluster group_id) absorb(geoid year)
est store e_county
		
coefplot (e_county, label("Target population relative to placebo")  mcolor(navy) ciopts(lcolor(navy) recast(rcap))) ///
	, nooffsets keep(ever_rym* o.ever_rym1 ry0 ever_ryp*) yline(0, lcolor(black)) xline(6, lcolor(black) ) omit vertical ///
	ytitle("Probability of County Move") ///
	rename(ever_rym6 = "-6" ever_rym5 = "-5" ever_rym4 = "-4" ever_rym3 = "-3" ever_rym2 = "-2" ever_rym1 = "-1" ///
	ever_ry0 = "0"  ever_ryp1 = "+1" ever_ryp2 = "+2" ever_ryp3 = "+3" ever_ryp4 = "+4" ever_ryp5 ="+5" ever_ryp6 ="+6" ) ///
	xtitle("Years") graphregion(color(white)) legend(off) ylabel(-.2(.1).6)

* move state
reghdfe move_state ever_rym6 ever_rym5 ever_rym4 ever_rym3 ever_rym2 o.ever_rym1 ever_ry0 ///
	ever_ryp1 ever_ryp2 ever_ryp3 ever_ryp4 ever_ryp5 ever_ryp6 exp_any_binary  ///
	[pw=perwt_wt] if targetpop==1, vce(cluster group_id) absorb(geoid year)
est store e_state
		
coefplot (e_state, label("Target population relative to placebo")  mcolor(navy) ciopts(lcolor(navy) recast(rcap))) ///
	, nooffsets keep(ever_rym* o.ever_rym1 ever_ry0 ever_ryp*) yline(0, lcolor(black)) xline(6, lcolor(black) ) omit vertical ///
	ytitle("Probability of State Move") ///
	rename(ever_rym6 = "-6" ever_rym5 = "-5" ever_rym4 = "-4" ever_rym3 = "-3" ever_rym2 = "-2" ever_rym1 = "-1" ///
	ever_ry0 = "0"  ever_ryp1 = "+1" ever_ryp2 = "+2" ever_ryp3 = "+3" ever_ryp4 = "+4" ever_ryp5 ="+5" ever_ryp6 ="+6" ) ///
	xtitle("Years") graphregion(color(white)) legend(off) ylabel(-.2(.1).6)

