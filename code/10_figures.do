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

eventdd 


* in migration
cap mat drop inmig1
reghdfe move_any exp_any  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any ) indvars(exp_any ) mat(inmig1)
reghdfe move_any exp_any  [pw=perwt]  if placebo5==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any ) indvars(exp_any ) mat(inmig1)

reghdfe move_any exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any) indvars(exp_any ) mat(inmig1)
reghdfe move_any exp_any  [pw=perwt_wt]  if placebo5==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any) indvars(exp_any ) mat(inmig1)


cap mat drop inmig2
reghdfe move_county exp_any  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any ) mat(inmig2)
reghdfe move_county exp_any  [pw=perwt]  if placebo5==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any ) mat(inmig2)

reghdfe move_county exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any ) mat(inmig2)
reghdfe move_county exp_any  [pw=perwt_wt]  if placebo5==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any ) mat(inmig2)


cap mat drop inmig3
reghdfe move_state exp_any  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any) mat(inmig3)
reghdfe move_state exp_any  [pw=perwt]  if placebo5==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any) mat(inmig3)

reghdfe move_state exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any) mat(inmig3)
reghdfe move_state exp_any  [pw=perwt_wt]  if placebo5==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any) mat(inmig3)


* Create table
cap file close sumstat
file open sumstat using "$wd/output/t3_inmigtarget.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & & & \multicolumn{2}{c}{Propensity weighting}  \\" _n
file write sumstat " & Targeted & Placebo & Targeted & Placebo \\" _n
file write sumstat " & (1) & (2)  & (3) & (4)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Any move" "Move county" "Move state"  "'
forval i = 1/3 {
	local varname : word `i' of $varnames
	forval c = 1/4  {
		local b`c' = string(inmig`i'[1,`c'], "%12.4fc" )
		local p`c' = inmig`i'[2,`c']
		local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
		local sd`c' = string(inmig`i'[3,`c'], "%12.4fc" )
		local f`c' = string(inmig`i'[7,`c'], "%12.4fc" )
		local r`c' = string(inmig`i'[4,`c'], "%12.4fc" )
	}
	file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
	file write sumstat " \textit{SE} & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
	file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
	file write sumstat " \textit{F-stat} & `f1' & `f2' & `f3' & `f4'  \\" _n 
	file write sumstat "\\" _n 
}
file write sumstat "Sample Size "
forval i = 1/4 {
	local n`i' = string(inmig1[6,`i'], "%12.0fc" )
	file write sumstat " & `n`i'' "
}
file write sumstat "\\" _n 
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\end{tabular}"
file close sumstat

