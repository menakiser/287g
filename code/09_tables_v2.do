/*---------------------
Mena kiser
10-25-25

Tables in research proposal
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"
global oo "$wd/output/"


/**************************************************************
Table 3: Regressions
**************************************************************/
use "$oi/acs_w_propensity_weights", clear 

replace exp_any1 = 1 if exp_any1>0 & !mi(exp_any1)

reghdfe move_county exp_any_binary  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_county exp_any_binary exp_any1 [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_county exp_any_binary  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)




reghdfe move_county exp_any_binary  [pw=perwt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)

reghdfe move_county exp_any_binary  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reghdfe move_county exp_any_binary  [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)





* in migration
cap mat drop inmig1
reghdfe move_any exp_any_binary  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any ) indvars(exp_any_binary ) mat(inmig1)
reghdfe move_any exp_any_binary  [pw=perwt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any ) indvars(exp_any_binary ) mat(inmig1)

reghdfe move_any exp_any_binary  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any) indvars(exp_any_binary ) mat(inmig1)
reghdfe move_any exp_any_binary  [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any) indvars(exp_any_binary ) mat(inmig1)


cap mat drop inmig2
reghdfe move_county exp_any_binary  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any_binary ) mat(inmig2)
reghdfe move_county exp_any_binary  [pw=perwt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any_binary ) mat(inmig2)

reghdfe move_county exp_any_binary  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any_binary ) mat(inmig2)
reghdfe move_county exp_any_binary  [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any_binary ) mat(inmig2)


cap mat drop inmig3
reghdfe move_state exp_any_binary  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any_binary) mat(inmig3)
reghdfe move_state exp_any_binary  [pw=perwt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any_binary) mat(inmig3)

reghdfe move_state exp_any_binary  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any_binary) mat(inmig3)
reghdfe move_state exp_any_binary  [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any_binary) mat(inmig3)


* Create table
cap file close sumstat
file open sumstat using "$oo/t3_inmigtarget.tex", write replace
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
		local r`c' = string(inmig`i'[4,`c'], "%12.4fc" )
	}
	file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
	file write sumstat " \textit{SE} & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
	file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
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





