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


/*

/**************************************************************
Table 1: Distinct retrievals
**************************************************************/
use "$oi/ice_all_287g_clean", clear 

*retrievals by year
keep dateretrieved lea
gen dateretrieved_d = date(dateretrieved, "YMD")
gen year = year(dateretrieved_d)
gen month = month(dateretrieved_d)

preserve 
keep if year>=2013 & year <=2019
egen leatag = tag(lea)
tab leatag
restore 

egen leas = tag(year lea )
bys year : ereplace leas = sum(leas)
keep dateretrieved_d year month leas
duplicates drop 
gen dates = 1
egen months = tag(year month)
collapse (sum) dates months (first) leas, by(year)
//keep if year<=2019
sort year
label var year "Year"
label var dates "Dates"
label var months "Months"


* Create table
cap file close sumstat
file open sumstat using "$oo/t1_retrievals.tex", write replace
file write sumstat "\begin{tabular}{lccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & \multicolumn{3}{c}{Distinct retrivals} \\" _n
file write sumstat " Year & Days & Months & LEAs \\" _n
file write sumstat "\midrule " _n

forval i = 1/9 {
	di "Writing row `i'"
	local y = year[`i']
	local d = dates[`i']
	local m = months[`i']
	local l = leas[`i']
	file write sumstat "`y' & `d' & `m' & `l' \\" _n 
}
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\end{tabular}"
file close sumstat

*/

/**************************************************************
Table 2: Summary Statistics
**************************************************************/

* import clean ACS data ready for regressions
use "$oi/working_acs", clear 
gen rentprice = rent if ownhome==0
gen mortprice = mortamt1 if ownhome==1

* restrict sample 
keep if year >= 2012
drop if always_treated_migpuma==1 //ruling out always treated counties

* define propensity weights for hispanic singles
merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t2" , nogen keep(3) keepusing(phat wt)
rename (phat wt) (phat2 wt2)
gen perwt_wt2 = perwt*wt2
drop if mi(perwt_wt2)

gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & young==1  & marst>=3  //hispanic citizens born in the usa
//remember you see some effects in migration for born_abroad==1 & citizen!=3
* create summary values
cap mat drop sumstat
foreach v in exp_any_migpuma move_any move_migpuma move_state move_abroad age r_white r_black r_asian hs no_english in_school nchild employed wkswork1 uhrswork incwage ownhome rentprice mortprice {
    di in red "Processing `v'"
    * TARGET POPULATION FOR HISPANICS
    * Ever exposed
    qui reg `v' targetpop2 [pw=perwt_wt2] if ever_treated_migpuma==1 , nocons 
    local m1 = _b[targetpop]

    * Never exposed
    qui reg `v' targetpop2 [pw=perwt] if ever_treated_migpuma==0 , nocons 
    local m2 = _b[targetpop]
    qui reg `v' targetpop2 [pw=perwt_wt2] if  ever_treated_migpuma==0 , nocons 
    local m3 = _b[targetpop]

    * PLACEBO
    * Ever exposed
    qui reg `v' placebo1 [pw=perwt_wt2] if ever_treated_migpuma==1 , nocons 
    local m4 = _b[placebo1]

    * Never exposed
    qui reg `v' placebo1 [pw=perwt] if ever_treated_migpuma==0 , nocons 
    local m5 = _b[placebo1]
    qui reg `v' placebo1 [pw=perwt_wt2] if  ever_treated_migpuma==0 , nocons 
    local m6 = _b[placebo1]

    mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3',`m4', `m5', `m6'  )
}

qui count if targetpop2==1 & exp_any_migpuma==1
local m1 = r(N)
qui count if targetpop2==1 & exp_any_migpuma==0 
local m2 = r(N)
qui count if targetpop2==1 & exp_any_migpuma==0
local m3 = r(N)

qui count if placebo1==1 & exp_any_migpuma==1
local m4 = r(N)
qui count if placebo1==1 & exp_any_migpuma==0 
local m5 = r(N)
qui count if placebo1==1 & exp_any_migpuma==0
local m6 = r(N)

mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3',`m4', `m5', `m6'  )


* Create table
cap file close sumstat
file open sumstat using "$oo/t2_sumstat.tex", write replace
file write sumstat "\begin{tabular}{lccc|ccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & \multicolumn{3}{c|}{Target Population} & \multicolumn{3}{c}{Placebo} \\" _n
file write sumstat "\midrule " _n
file write sumstat " & Exposed & \multicolumn{2}{c|}{Never Exposed} & Exposed & \multicolumn{2}{c}{Never Exposed} \\" _n
file write sumstat " &  &  & Propensity &  &  & Propensity \\" _n
file write sumstat " &  &  & weighted &  &  & weighted \\" _n
file write sumstat " & (1) & (2) & (3) & (4) & (5) & (6)  \\" _n
file write sumstat "\midrule " _n

global varnames `" "Exposure" "Any move" "Moved migpuma" "Moved state" "Moved from abroad" "Age" "Race: White" "Race: Black" "Race: Asian" "High School" "Poor English" "In School" "Number of children" "Employed" "Weeks worked" "Usual weekly hours worked" "Wage income" "Owns a home" "Rent price" "Mortgage price" "Sample size" "'
forval r = 1/21 {
	local varname : word `r' of $varnames
	file write sumstat " `varname' "
	di "Writing row `r'"
	forval c = 1/6 {
		di "Writing column `c'"
		local a = string(sumstat[`r',`c'], "%12.2fc" )
		file write sumstat " & `a'"
		}
	file write sumstat "\\" _n 
}
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\end{tabular}"
file close sumstat



/**************************************************************
Table 3: Regressions
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
cap mat drop intarget
* with simple weights
* without controls
reghdfe move_migpuma exp_any_migpuma  [pw=perwt]  if targetpop2==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget)
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if targetpop2==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget)
* with propensity weights
* without controls
reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if targetpop2==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget)
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop2==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget)

**** IN MIGRATION FOR PLACEBO POPULATION
cap mat drop inplacebo
* with simple weights
* without controls
reghdfe move_migpuma exp_any_migpuma  [pw=perwt]  if placebo1==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inplacebo)
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if placebo1==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inplacebo)
* with propensity weights
* without controls
reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inplacebo)
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inplacebo)


* Create table
cap file close sumstat
file open sumstat using "$oo/in_migration_target2.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " \multicolumn{5}{c}{Panel A: Target population}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " & & & \multicolumn{2}{c}{Propensity weighted}  \\" _n
file write sumstat " & (1) & (2)  & (3) & (4)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Move migpuma" "'

local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(intarget[1,`c'], "%12.4fc" )
    local p`c' = intarget[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(intarget[3,`c'], "%12.4fc" )
    local r`c' = string(intarget[4,`c'], "%12.4fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat "Sample Size "
forval i = 1/4 {
	local n`i' = string(intarget[6,`i'], "%12.0fc" )
	file write sumstat " & `n`i'' "
}
file write sumstat "\\" _n 
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n

* out migration
file write sumstat " \multicolumn{5}{c}{Panel B: Placebo}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " & & & \multicolumn{2}{c}{Propensity weighted}  \\" _n
file write sumstat " & (5) & (6)  & (7) & (8)  \\" _n
file write sumstat "\midrule " _n

global varnames `"   "Move migpuma" "'
local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(inplacebo[1,`c'], "%12.4fc" )
    local p`c' = inplacebo`i'[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(inplacebo[3,`c'], "%12.4fc" )
    local r`c' = string(inplacebo[4,`c'], "%12.4fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat "  & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " R-2 & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat "Sample Size "
forval i = 1/4 {
	local n`i' = string(inplacebo[6,`i'], "%12.0fc" )
	file write sumstat " & `n`i'' "
}
file write sumstat "\\" _n 
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n

file write sumstat "\end{tabular}"
file close sumstat



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

**** OUT MIGRATION FOR TARGET POPULATION
cap mat drop outtarget
* with simple weights
* without controls
reghdfe move_migpuma prev_exp_any_migpuma  [pw=perwt]  if targetpop2==1 & year>=2013 , vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma ) mat(outtarget)
* with controls 
reghdfe move_migpuma prev_exp_any_migpuma $covars $outvars [pw=perwt]  if targetpop2==1 & year>=2013 , vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma ) mat(outtarget)
* with propensity weights
* without controls
reghdfe move_migpuma prev_exp_any_migpuma  [pw=perwt_wt]  if targetpop2==1 & year>=2013, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma ) mat(outtarget)
* with controls 
reghdfe move_migpuma prev_exp_any_migpuma $covars $outvars [pw=perwt_wt]  if targetpop2==1 & year>=2013 , vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma ) mat(outtarget)

**** OUT MIGRATION FOR PLACEBO POPULATION
cap mat drop outplacebo
* with simple weights
* without controls
reghdfe move_migpuma exp_any_migpuma  [pw=perwt]  if placebo1==1  & year>=2013, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(outplacebo)
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if placebo1==1  & year>=2013, vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(outplacebo)
* with propensity weights
* without controls
reghdfe move_migpuma exp_any_migpuma  [pw=perwt_wt]  if placebo1==1 & year>=2013 , vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(outplacebo)
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt_wt]  if placebo1==1 & year>=2013 , vce(cluster group_id1_migpuma) absorb(prev_geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(outplacebo)


* Create table
cap file close sumstat
file open sumstat using "$oo/out_migration_target2.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " \multicolumn{5}{c}{Panel A: Target population}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " & & & \multicolumn{2}{c}{Propensity weighted}  \\" _n
file write sumstat " & (1) & (2)  & (3) & (4)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Move migpuma" "'

local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(outtarget[1,`c'], "%12.4fc" )
    local p`c' = outtarget[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(outtarget[3,`c'], "%12.4fc" )
    local r`c' = string(outtarget[4,`c'], "%12.4fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat "Sample Size "
forval i = 1/4 {
	local n`i' = string(outtarget[6,`i'], "%12.0fc" )
	file write sumstat " & `n`i'' "
}
file write sumstat "\\" _n 
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n

* out migration
file write sumstat " \multicolumn{5}{c}{Panel B: Placebo}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " & & & \multicolumn{2}{c}{Propensity weighted}  \\" _n
file write sumstat " & (5) & (6)  & (7) & (8)  \\" _n
file write sumstat "\midrule " _n

global varnames `"   "Move migpuma" "'
local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(outplacebo[1,`c'], "%12.4fc" )
    local p`c' = outplacebo`i'[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(outplacebo[3,`c'], "%12.4fc" )
    local r`c' = string(outplacebo[4,`c'], "%12.4fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat "  & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " R-2 & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat "Sample Size "
forval i = 1/4 {
	local n`i' = string(outplacebo[6,`i'], "%12.0fc" )
	file write sumstat " & `n`i'' "
}
file write sumstat "\\" _n 
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n

file write sumstat "\end{tabular}"
file close sumstat



/**************************************************************
Heterogeneity
**************************************************************/
global covars "age r_white r_black r_asian hs in_school no_english ownhome"
global invars "exp_any_state " //SC_any
global outvars "prev_exp_any_state " //prev_SC_any

use "$oi/working_acs", clear 
keep if year >= 2012
drop if always_treated_migpuma==1
* define propensity weights for target population 2
merge m:1 statefip current_migpuma  using  "$oi/troubleshoot/propensity_weights2013migpuma_t2" , nogen keep(3) keepusing( phat wt)
rename (phat wt) (phat2 wt2)
gen perwt_wt2 = perwt*wt
drop if mi(perwt_wt2)

**** IN MIGRATION FOR TARGET POPULATION
foreach i in 2 5 {
    foreach v in move_migpuma move_state move_abroad {
        di in red "Processing `v', target pop `i' "
        cap mat drop `v'_target`i'
        * with propensity weights
        * baseline
        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i')

        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 & no_english==1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i')

        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 & no_english==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i')

        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 & prev_exp_any_migpuma==1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i')

        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 & prev_exp_any_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i')
    }
}

* Create table
cap file close sumstat
file open sumstat using "$oo/move_het.tex", write replace
file write sumstat "\begin{tabular}{lcccccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " \multicolumn{6}{c}{Panel A: Target population}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " &  & &  & Previous year & Previous year   \\" _n
file write sumstat " & Baseline & No English & Some English & exposure=1 & exposure=0  \\" _n
file write sumstat " & (1) & (2)  & (3) & (4) & (5)   \\" _n
file write sumstat "\midrule " _n

local order = 1
global varnames `"  "Move migpuma" "Move state" "Move from abroad" "'
foreach v in move_migpuma move_state move_abroad {
    local varname : word `order' of $varnames
    forval c = 1/5  {
        local b`c' = string(`v'_target2[1,`c'], "%12.4fc" )
        local p`c' = `v'_target2[2,`c']
        local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
        local sd`c' = string(`v'_target2[3,`c'], "%12.4fc" )
        local r`c' = string(`v'_target2[4,`c'], "%12.4fc" )
    }
   if "`v'"!="move_abroad" {
        file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4'  & `b5'`stars_abs5' \\" _n 
        file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') & (`sd5')  \\" _n 
        
        file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4' & `r5'  \\" _n 
        file write sumstat "Sample Size "
        forval i = 1/5 {
            local n`i' = string(`v'_target2[6,`i'], "%12.0fc" )
            file write sumstat " & `n`i'' "
        }
    }
    if "`v'"=="move_abroad" {
        file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & & \\" _n 
        file write sumstat " & (`sd1') & (`sd2') & (`sd3') & & \\" _n 
        
        file write sumstat " \textit{R2} & `r1' & `r2' & `r3' &  &   \\" _n 
        file write sumstat "Sample Size "
        forval i = 1/3 {
            local n`i' = string(`v'_target2[6,`i'], "%12.0fc" )
            file write sumstat " & `n`i'' "
        }
    }
    local++ order
    file write sumstat "\\" _n 
    file write sumstat "\\" _n 
}
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n

* Panel B
file write sumstat " \multicolumn{6}{c}{Panel B: Mexican}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " &  & &  & Previous year & Previous year   \\" _n
file write sumstat " & Baseline & No English & Some English & exposure=1 & exposure=0  \\" _n
file write sumstat " & (6) & (7) & (8)  & (9) & (10) \\" _n
file write sumstat "\midrule " _n

local order = 1
global varnames `"  "Move migpuma" "Move state" "Move from abroad" "'
foreach v in move_migpuma move_state move_abroad {
    local varname : word `order' of $varnames
    forval c = 1/5  {
            local b`c' = string(`v'_target5[1,`c'], "%12.4fc" )
            local p`c' = `v'_target5[2,`c']
            local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
            local sd`c' = string(`v'_target5[3,`c'], "%12.4fc" )
            local r`c' = string(`v'_target5[4,`c'], "%12.4fc" )
    }
    if "`v'"!="move_abroad" {
        file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4'  & `b5'`stars_abs5' \\" _n 
        file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') & (`sd5')  \\" _n 
        
        file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4' & `r5'  \\" _n 
        file write sumstat "Sample Size "
        forval i = 1/5 {
            local n`i' = string(`v'_target5[6,`i'], "%12.0fc" )
            file write sumstat " & `n`i'' "
        }
    }
    if "`v'"=="move_abroad" {
        file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & & \\" _n 
        file write sumstat " & (`sd1') & (`sd2') & (`sd3') & & \\" _n 
        
        file write sumstat " \textit{R2} & `r1' & `r2' & `r3' &  &   \\" _n 
        file write sumstat "Sample Size "
        forval i = 1/3 {
            local n`i' = string(`v'_target5[6,`i'], "%12.0fc" )
            file write sumstat " & `n`i'' "
        }
    }
    local++ order
    file write sumstat "\\" _n 
    file write sumstat "\\" _n 
}
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n

file write sumstat "\end{tabular}"
file close sumstat






cap program drop storemean
program define storemean
syntax, varname(str) mat(str) restriction(str) tosum(str) [cond(str)]
    qui reg `varname' `restriction' [pw=perwt] , `cond'
    local m = _b[`tosum']
    local sd = _se[`tosum']
    local n = e(N)
    mat `mat' = nullmat(`mat') \ (`m' , `sd', `n')
end

cap program drop storecoeff
program define storecoeff
syntax, mat(str) row(int) cols(str)
    local rb = `row'
    local rp = `rb' + 1
    local rse = `rp' + 1
    * coefficient with stars
    foreach col in `cols' {
        if `mat'[`rb',`col'] != 9999 {
            local b = string(`mat'[`rb',`col'], "%12.3fc")
            local pval = string(`mat'[`rp',`col'], "%12.3fc")
            local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
            file write sumstat " & `b'`stars_abs'  "
        }
        if `mat'[`rb',`col'] == 9999 {
            file write sumstat " &  "
        }
    }
    file write sumstat "\\" _n
    * standard errors
    foreach col in `cols' {
        if `mat'[`rb',`col'] != 9999 {
            local se = string(`mat'[`rse',`col'], "%12.3fc")
            file write sumstat " & (`se')  "
        }
        if `mat'[`rb',`col'] == 9999 {
            file write sumstat " &   "
        }
    }
    file write sumstat "\\" _n
end
