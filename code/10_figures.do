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
global covars "age i.race i.educ i.speakeng i.hcovany i.school ownhome" 

* drop 15 counties that lost treatment at some point 
drop if lost_treatment==1

* define event year dummies
gen event_year = year if exp_any_migpuma==1
bys statefip countyfip : ereplace event_year = min(event_year)
replace event_year = . if ever_treated_migpuma==0
gen relative_year = (year-event_year)*ever_treated_migpuma
replace relative_year = . if ever_treated_migpuma==0

reghdfe move_any exp_any_migpuma  $covars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
exp_any_migpuma

*any move
eventdd move_any $covars i.year i.geoid [pw=perwt_wt]  if targetpop==1 , timevar(relative_year) method(ols, cluster(group_id)) graph_op(ytitle("Any move") xlabel(-6(1)6)) leads(5) lags(5) accum legend(off)
graph export "$od/es_`var'.png", replace
reghdfe move_any rym6 rym5 rym4 rym3 rym2 o.rym1 ry0 ///
	ryp1 ryp2 ryp3 ryp4 ryp5 ryp6 exp_any_migpuma  ///
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
	ryp1 ryp2 ryp3 ryp4 ryp5 ryp6 exp_any_migpuma  ///
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
	ryp1 ryp2 ryp3 ryp4 ryp5 ryp6 exp_any_migpuma  ///
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
	ever_ryp1 ever_ryp2 ever_ryp3 ever_ryp4 ever_ryp5 ever_ryp6 exp_any_migpuma  ///
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
	ever_ryp1 ever_ryp2 ever_ryp3 ever_ryp4 ever_ryp5 ever_ryp6 exp_any_migpuma  ///
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
	ever_ryp1 ever_ryp2 ever_ryp3 ever_ryp4 ever_ryp5 ever_ryp6 exp_any_migpuma  ///
	[pw=perwt_wt] if targetpop==1, vce(cluster group_id) absorb(geoid year)
est store e_state
		
coefplot (e_state, label("Target population relative to placebo")  mcolor(navy) ciopts(lcolor(navy) recast(rcap))) ///
	, nooffsets keep(ever_rym* o.ever_rym1 ever_ry0 ever_ryp*) yline(0, lcolor(black)) xline(6, lcolor(black) ) omit vertical ///
	ytitle("Probability of State Move") ///
	rename(ever_rym6 = "-6" ever_rym5 = "-5" ever_rym4 = "-4" ever_rym3 = "-3" ever_rym2 = "-2" ever_rym1 = "-1" ///
	ever_ry0 = "0"  ever_ryp1 = "+1" ever_ryp2 = "+2" ever_ryp3 = "+3" ever_ryp4 = "+4" ever_ryp5 ="+5" ever_ryp6 ="+6" ) ///
	xtitle("Years") graphregion(color(white)) legend(off) ylabel(-.2(.1).6)

