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
/*
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
merge m:1 statefip current_migpuma  using  "$oi/propensity_weights2012migpuma_t2" , nogen keep(3) keepusing(phat wt)
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

    * Difference

    qui reg `v' targetpop2 [pw=perwt_wt2] if  ever_treated_migpuma==0 , nocons 
    local m3 = _b[targetpop]


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

*/

/**************************************************************
Table 3: in migration Regressions
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
cap mat drop intarget
* with simple weights
* without controls
reghdfe move_migpuma exp_any_migpuma  [pw=perwt]  if targetpop2==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget) wt(perwt) wttype(pw)

* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if targetpop2==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget) wt(perwt) wttype(pw)

**** IN MIGRATION FOR PLACEBO POPULATION
* with simple weights
* without controls
reghdfe move_migpuma exp_any_migpuma  [pw=perwt]  if placebo1==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget) wt(perwt) wttype(pw)
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if placebo1==1 , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget) wt(perwt) wttype(pw)


* Create table
cap file close sumstat
file open sumstat using "$oo/final/in_migration_target2.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " & \multicolumn{2}{c}{Target population} & \multicolumn{2}{c}{Placebo}  \\" _n
file write sumstat " Move migpuma & (1) & (2)  & (3) & (4)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Treated migpuma" "'

local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(intarget[1,`c'], "%12.4fc" )
    local temp = intarget[1,`c']/intarget[5,`c']*100
    local bmean`c' = string(`temp', "%12.2fc" )
    local p`c' = intarget[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(intarget[3,`c'], "%12.4fc" )
    local r`c' = string(intarget[4,`c'], "%12.4fc" )
    local um`c' = string(intarget[5,`c'], "%12.4fc" )
	local n`c' = string(intarget[6,`c'], "%12.0fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\\" _n 
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n

file write sumstat "\end{tabular}"
file close sumstat



/**************************************************************
Losers vs gainers
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

gen exp_lost_migpuma = (year>=lost_exp_year)*(ever_lost_exp_migpuma==1)
gen exp_gain_migpuma = (year>=gain_exp_year)*(ever_gain_exp_migpuma==1)


**** IN MIGRATION FOR TARGET POPULATION
cap mat drop intarget
* GAIINERS + NEVER TREATED
* with simple weights
* with controls 
reghdfe move_migpuma exp_any_migpuma  [pw=perwt]  if targetpop2==1  & ever_lost_exp_migpuma==0,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars(exp_any_migpuma) mat(intarget) wt(perwt) wttype(pw)
* with propensity weights
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if targetpop2==1  & ever_lost_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget) wt(perwt) wttype(pw)

* LOSERS + NEVER TREATED
* with simple weights
* with controls 
reghdfe move_migpuma exp_any_migpuma [pw=perwt]  if targetpop2==1  & ever_gain_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget) wt(perwt) wttype(pw)
* with propensity weights
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if targetpop2==1  & ever_gain_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(intarget) wt(perwt) wttype(pw)

**** IN MIGRATION FOR PLACEBO POPULATION
cap mat drop inplacebo
** GAINERS ONLY
* with simple weights
* with controls 
reghdfe move_migpuma exp_any_migpuma  [pw=perwt]  if placebo1==1  & ever_lost_exp_migpuma==0,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inplacebo) wt(perwt) wttype(pw)
* with propensity weights
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if placebo1==1  & ever_lost_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inplacebo) wt(perwt) wttype(pw)

* LOOSERS ONLY 
* with simple weights
* with controls 
reghdfe move_migpuma exp_any_migpuma [pw=perwt]  if placebo1==1  & ever_gain_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inplacebo) wt(perwt) wttype(pw)
* with propensity weights
* with controls 
reghdfe move_migpuma exp_any_migpuma $covars $invars [pw=perwt]  if placebo1==1  & ever_gain_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inplacebo) wt(perwt) wttype(pw)



* Create table
cap file close sumstat
file open sumstat using "$oo/final/in_gain_lost.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " \multicolumn{5}{c}{Panel A: Target population}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " & \multicolumn{2}{c}{Only gainers} & \multicolumn{2}{c}{Only losers}  \\" _n
file write sumstat "Move migpuma & (1) & (2)  & (3) & (4) \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Treated migpuma" "'

local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(intarget[1,`c'], "%12.4fc" )
    local temp = intarget[1,`c']/intarget[5,`c']*100
    local bmean`c' = string(`temp', "%12.2fc" )
    local p`c' = intarget[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(intarget[3,`c'], "%12.4fc" )
    local r`c' = string(intarget[4,`c'], "%12.4fc" )
    local um`c' = string(intarget[5,`c'], "%12.4fc" )
	local n`c' = string(intarget[6,`c'], "%12.0fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\\" _n 
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n

* panel b placebo
file write sumstat " \multicolumn{5}{c}{Panel B: Placebo}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " & \multicolumn{2}{c}{Only gainers} & \multicolumn{2}{c}{Only losers}  \\" _n
file write sumstat "Move migpuma & (5) & (6)  & (7) & (8) \\" _n
file write sumstat "\midrule " _n

global varnames `"   "Treated migpuma" "'
local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(inplacebo[1,`c'], "%12.4fc" )
    local temp = inplacebo[1,`c']/inplacebo[5,`c']*100
    local bmean`c' = string(`temp', "%12.2fc" )
    local p`c' = inplacebo`i'[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(inplacebo[3,`c'], "%12.4fc" )
    local r`c' = string(inplacebo[4,`c'], "%12.4fc" )
    local um`c' = string(inplacebo[5,`c'], "%12.4fc" )
    local n`c' = string(inplacebo[6,`c'], "%12.0fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat



**** trying doug's suggestion
cap mat drop intarget
* no controls 
reghdfe move_migpuma exp_gain_migpuma exp_lost_migpuma  [pw=perwt]  if targetpop2==1,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) wt(perwt) wttype(pw)
* with controls 
reghdfe move_migpuma exp_gain_migpuma exp_lost_migpuma  $covars $invars [pw=perwt]  if targetpop2==1,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) wt(perwt) wttype(pw)
* no controls 
reghdfe move_migpuma exp_gain_migpuma exp_lost_migpuma  [pw=perwt]  if placebo1==1,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) wt(perwt) wttype(pw)
* with controls 
reghdfe move_migpuma exp_gain_migpuma exp_lost_migpuma  $covars $invars [pw=perwt]  if placebo1==1,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) wt(perwt) wttype(pw)



* Create table
cap file close sumstat
file open sumstat using "$oo/final/in_gain_lost_join.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & \multicolumn{2}{c}{Target population} & \multicolumn{2}{c}{Placebo}  \\" _n
file write sumstat "Move migpuma & (1) & (2)  & (3) & (4) \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Gain treatment" "Lose treatment" "'

forval i = 1/2 {
    local varname : word `i' of $varnames
    forval c = 1/4  {
        local row = 1 +3*(`i'-1)
        local b`c' = string(intarget[`row',`c'], "%12.4fc" )
        local temp = intarget[`row',`c']/intarget[5,`c']*100
        local bmean`c' = string(`temp', "%12.2fc" )
        local++ row
        local p`c' = intarget[`row',`c']
        local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
        local++ row
        local sd`c' = string(intarget[`row',`c'], "%12.4fc" )
        
    }
    file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
    file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
    file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
}
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
forval c = 1/4  {
    local r`c' = string(intarget[7,`c'], "%12.4fc" )
    local um`c' = string(intarget[8,`c'], "%12.4fc" )
    local n`c' = string(intarget[9,`c'], "%12.0fc" )
}
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
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
merge m:1 statefip current_migpuma  using  "$oi/propensity_weights2012migpuma_t2" , nogen keep(3) keepusing( phat wt)
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
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i') wt(perwt_wt) wttype(pw)

        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 & no_english==1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i') wt(perwt_wt) wttype(pw)

        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 & no_english==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i') wt(perwt_wt) wttype(pw)

        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 & prev_exp_any_migpuma==1, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i') wt(perwt_wt) wttype(pw)

        reghdfe `v' exp_any_migpuma $covars $invars [pw=perwt_wt]  if targetpop`i'==1 & prev_exp_any_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
        reg_to_mat, depvar( `v' ) indvars( exp_any_migpuma ) mat(`v'_target`i') wt(perwt_wt) wttype(pw)
    }
}

* Create table
cap file close sumstat
file open sumstat using "$oo/final/move_het.tex", write replace
file write sumstat "\begin{tabular}{lcccccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " \multicolumn{6}{c}{Panel A: Target population}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " &  & &  & Previous year & Previous year   \\" _n
file write sumstat " & Baseline & Poor English & Some English & treated & untreated  \\" _n
file write sumstat "Outcome & (1) & (2)  & (3) & (4) & (5)   \\" _n
file write sumstat "\midrule " _n

local order = 1
global varnames `"  "Move migpuma" "Move state" "Move from abroad" "'
foreach v in move_migpuma move_state move_abroad {
    local varname : word `order' of $varnames
    forval c = 1/5  {
        local b`c' = string(`v'_target2[1,`c'], "%12.4fc" )
        local temp = `v'_target2[1,`c']/`v'_target2[5,`c']*100
        local bmean`c' = string(`temp', "%12.2fc" )
        local p`c' = `v'_target2[2,`c']
        local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
        local sd`c' = string(`v'_target2[3,`c'], "%12.4fc" )
        local r`c' = string(`v'_target2[4,`c'], "%12.4fc" )
        local um`c' = string(`v'_target2[5,`c'], "%12.4fc" )
        local n`c' = string(`v'_target2[6,`c'], "%12.0fc" )
    }
   if "`v'"!="move_abroad" {
        file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4'  & `b5'`stars_abs5' \\" _n 
        file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$]  & [`bmean5'$\%$] \\" _n 
        file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') & (`sd5')  \\" _n 
        file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4' & `r5'  \\" _n 
        file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4' & `um5'  \\" _n 
        file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4' & `n5'  \\" _n
    }
    if "`v'"=="move_abroad" {
        file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & & \\" _n 
        file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & & \\" _n 
        file write sumstat " & (`sd1') & (`sd2') & (`sd3') & & \\" _n 
        file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & & \\" _n 
        file write sumstat " Untreated mean & `um1' & `um2' & `um3' & & \\" _n 
        file write sumstat "Sample Size & `n1' & `n2' & `n3' & & \\" _n
    }
    local++ order
    file write sumstat "\\" _n 
}
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n

* Panel B
file write sumstat " \multicolumn{6}{c}{Panel B: Mexican}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " &  & &  & Previous year & Previous year   \\" _n
file write sumstat " & Baseline & Poor English & Some English & treated & untreated  \\" _n
file write sumstat "Outcome & (6) & (7) & (8)  & (9) & (10) \\" _n
file write sumstat "\midrule " _n

local order = 1
global varnames `"  "Move migpuma" "Move state" "Move from abroad" "'
foreach v in move_migpuma move_state move_abroad {
    local varname : word `order' of $varnames
    forval c = 1/5  {
        local b`c' = string(`v'_target5[1,`c'], "%12.4fc" )
        local temp = `v'_target5[1,`c']/`v'_target5[5,`c']*100
        local bmean`c' = string(`temp', "%12.2fc" )
        local p`c' = `v'_target5[2,`c']
        local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
        local sd`c' = string(`v'_target5[3,`c'], "%12.4fc" )
        local r`c' = string(`v'_target5[4,`c'], "%12.4fc" )
        local um`c' = string(`v'_target5[5,`c'], "%12.4fc" )
        local n`c' = string(`v'_target5[6,`c'], "%12.0fc" )
    }
   if "`v'"!="move_abroad" {
        file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4'  & `b5'`stars_abs5' \\" _n 
        file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$]  & [`bmean5'$\%$] \\" _n 
        file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') & (`sd5')  \\" _n 
        file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4' & `r5'  \\" _n 
        file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4' & `um5'  \\" _n 
        file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4' & `n5'  \\" _n
    }
    if "`v'"=="move_abroad" {
        file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & & \\" _n 
        file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & & \\" _n 
        file write sumstat " & (`sd1') & (`sd2') & (`sd3') & & \\" _n 
        file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & & \\" _n 
        file write sumstat " Untreated mean & `um1' & `um2' & `um3' & & \\" _n 
        file write sumstat "Sample Size & `n1' & `n2' & `n3' & & \\" _n
    }
    local++ order
    file write sumstat "\\" _n 
}
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n

file write sumstat "\end{tabular}"
file close sumstat



/**************************************************************
Table 3: in migration Regressions POPULATION
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

* age
gen int_age1 = inrange(age, 0, 9) 
gen int_age2 = inrange(age, 10, 19) 
gen int_age3 = inrange(age, 20, 29)
gen int_age4 = inrange(age, 30, 39)
gen int_age5 = inrange(age, 40, 49)
gen int_age6 = inrange(age, 50, 59)
gen int_age7 = inrange(age, 60, 69)
gen int_age8 = inrange(age, 70, 100)

global covarsPOP "int_age1 int_age2 int_age3 int_age4 int_age5 int_age6 r_white r_black r_asian hs in_school no_english ownhome"

foreach v in $covarsPOP {
    replace `v' = `v'*perwt
}

collapse (sum) move_target move_migpuma move_target_wwt move_migpuma_wwt total_targetpop2 total_targetpop2_wwt total_pop total_pop_wwt placebo1 placebo1_wwt perwt ///
	(mean) $covarsPOP ///
	(max) exp_any_migpuma  ever_treated_migpuma ever_lost_exp_migpuma ever_gain_exp_migpuma lost_exp_year gain_exp_year ///
	relative_year_gain relative_year_lost geoid_migpuma $invars ///
	, by(current_migpuma statefip year)

foreach v in $covarsPOP {
    replace `v' = log(`v' + 1)
}

gen exp_lost_migpuma = (year>=lost_exp_year)*(ever_lost_exp_migpuma==1)
gen exp_gain_migpuma = (year>=gain_exp_year)*(ever_gain_exp_migpuma==1)


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


gen log_total_pop = log(total_pop + 1)
gen log_total_targetpop2 = log(total_targetpop2 + 1) 
gen log_total_placebo1 = log(placebo1 + 1)

egen group_id_migpuma = group(geoid_migpuma year) 

**** IN MIGRATION FOR TARGET POPULATION
cap mat drop intarget
* with simple weights
* without controls
reghdfe log_total_targetpop2 exp_any_migpuma , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_targetpop2 ) indvars( exp_any_migpuma ) mat(intarget)
* with controls 
reghdfe log_total_targetpop2 exp_any_migpuma $covarsPOP $invars, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_targetpop2 ) indvars( exp_any_migpuma ) mat(intarget)

**** IN MIGRATION FOR PLACEBO POPULATION
* with simple weights
* without controls
reghdfe log_total_placebo1 exp_any_migpuma , vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_placebo1 ) indvars( exp_any_migpuma ) mat(intarget)
* with controls 
reghdfe log_total_placebo1 exp_any_migpuma $covarsPOP $invars, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_placebo1 ) indvars( exp_any_migpuma ) mat(intarget)


* Create table
cap file close sumstat
file open sumstat using "$oo/final/logpop_reg.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " & \multicolumn{2}{c}{Target population} & \multicolumn{2}{c}{Placebo}  \\" _n
file write sumstat " Move migpuma & (1) & (2)  & (3) & (4)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Treated migpuma" "'

local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(intarget[1,`c'], "%12.4fc" )
    local temp = intarget[1,`c']/intarget[5,`c']*100
    local bmean`c' = string(`temp', "%12.2fc" )
    local p`c' = intarget[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(intarget[3,`c'], "%12.4fc" )
    local r`c' = string(intarget[4,`c'], "%12.4fc" )
    local um`c' = string(intarget[5,`c'], "%12.4fc" )
	local n`c' = string(intarget[6,`c'], "%12.0fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\\" _n 
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n

file write sumstat "\end{tabular}"
file close sumstat


**** gainers vs losers separately 

**** IN MIGRATION FOR TARGET POPULATION
cap mat drop intarget
* GAIINERS + NEVER TREATED
* with simple weights
* with controls 
reghdfe log_total_targetpop2 exp_any_migpuma  if ever_lost_exp_migpuma==0,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_targetpop2 ) indvars(exp_any_migpuma) mat(intarget) 
* with propensity weights
* with controls 
reghdfe log_total_targetpop2 exp_any_migpuma $covarsPOP $invars if ever_lost_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_targetpop2 ) indvars( exp_any_migpuma ) mat(intarget) 

* LOSERS + NEVER TREATED
* with simple weights
* with controls 
reghdfe log_total_targetpop2 exp_any_migpuma if ever_gain_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_targetpop2 ) indvars( exp_any_migpuma ) mat(intarget) 
* with propensity weights
* with controls 
reghdfe log_total_targetpop2 exp_any_migpuma $covarsPOP $invars if ever_gain_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_targetpop2 ) indvars( exp_any_migpuma ) mat(intarget) 

**** IN MIGRATION FOR PLACEBO POPULATION
cap mat drop inplacebo
** GAINERS ONLY
* with simple weights
* with controls 
reghdfe log_total_placebo1 exp_any_migpuma  if ever_lost_exp_migpuma==0,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_placebo1 ) indvars( exp_any_migpuma ) mat(inplacebo)
* with propensity weights
* with controls 
reghdfe log_total_placebo1 exp_any_migpuma $covarsPOP $invars  if ever_lost_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_placebo1 ) indvars( exp_any_migpuma ) mat(inplacebo)

* LOOSERS ONLY 
* with simple weights
* with controls 
reghdfe log_total_placebo1 exp_any_migpuma if ever_gain_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_placebo1 ) indvars( exp_any_migpuma ) mat(inplacebo)
* with propensity weights
* with controls 
reghdfe log_total_placebo1 exp_any_migpuma $covarsPOP $invars if ever_gain_exp_migpuma==0, vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_placebo1 ) indvars( exp_any_migpuma ) mat(inplacebo)



* Create table
cap file close sumstat
file open sumstat using "$oo/final/in_gain_lost_logpop.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " \multicolumn{5}{c}{Panel A: Target population}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " & \multicolumn{2}{c}{Only gainers} & \multicolumn{2}{c}{Only losers}  \\" _n
file write sumstat "Move migpuma & (1) & (2)  & (3) & (4) \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Treated migpuma" "'

local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(intarget[1,`c'], "%12.4fc" )
    local temp = intarget[1,`c']/intarget[5,`c']*100
    local bmean`c' = string(`temp', "%12.2fc" )
    local p`c' = intarget[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(intarget[3,`c'], "%12.4fc" )
    local r`c' = string(intarget[4,`c'], "%12.4fc" )
    local um`c' = string(intarget[5,`c'], "%12.4fc" )
	local n`c' = string(intarget[6,`c'], "%12.0fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\\" _n 
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n

* panel b placebo
file write sumstat " \multicolumn{5}{c}{Panel B: Placebo}  \\" _n
file write sumstat "\midrule " _n
file write sumstat " & \multicolumn{2}{c}{Only gainers} & \multicolumn{2}{c}{Only losers}  \\" _n
file write sumstat "Move migpuma & (5) & (6)  & (7) & (8) \\" _n
file write sumstat "\midrule " _n

global varnames `"   "Treated migpuma" "'
local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(inplacebo[1,`c'], "%12.4fc" )
    local temp = inplacebo[1,`c']/inplacebo[5,`c']*100
    local bmean`c' = string(`temp', "%12.2fc" )
    local p`c' = inplacebo`i'[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(inplacebo[3,`c'], "%12.4fc" )
    local r`c' = string(inplacebo[4,`c'], "%12.4fc" )
    local um`c' = string(inplacebo[5,`c'], "%12.4fc" )
    local n`c' = string(inplacebo[6,`c'], "%12.0fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat








**** trying doug's suggestion
cap mat drop intarget
* no controls 
reghdfe log_total_targetpop2 exp_gain_migpuma exp_lost_migpuma ,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_targetpop2 ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) 
* with controls 
reghdfe log_total_targetpop2 exp_gain_migpuma exp_lost_migpuma  $covarsPOP $invars ,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_targetpop2 ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) 
* no controls 
reghdfe log_total_placebo1 exp_gain_migpuma exp_lost_migpuma  ,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_placebo1 ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) 
* with controls 
reghdfe log_total_placebo1 exp_gain_migpuma exp_lost_migpuma  $covarsPOP $invars,  vce(cluster group_id_migpuma) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_total_placebo1 ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) 



* Create table
cap file close sumstat
file open sumstat using "$oo/final/in_gain_lost_join_log.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & \multicolumn{2}{c}{Target population} & \multicolumn{2}{c}{Placebo}  \\" _n
file write sumstat "Move migpuma & (1) & (2)  & (3) & (4) \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Gain treatment" "Lose treatment" "'

forval i = 1/2 {
    local varname : word `i' of $varnames
    forval c = 1/4  {
        local row = 1 +3*(`i'-1)
        local b`c' = string(intarget[`row',`c'], "%12.4fc" )
        local temp = intarget[`row',`c']/intarget[5,`c']*100
        local bmean`c' = string(`temp', "%12.2fc" )
        local++ row
        local p`c' = intarget[`row',`c']
        local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
        local++ row
        local sd`c' = string(intarget[`row',`c'], "%12.4fc" )
        
    }
    file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
    file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
    file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
}
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
forval c = 1/4  {
    local r`c' = string(intarget[7,`c'], "%12.4fc" )
    local um`c' = string(intarget[8,`c'], "%12.4fc" )
    local n`c' = string(intarget[9,`c'], "%12.0fc" )
}
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated mean & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat
