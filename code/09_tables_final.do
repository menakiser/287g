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
Probability of moving IN migpuma, simple Regressions
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
file open sumstat using "$oo/final/prob_in_migration.tex", write replace
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
LOG POPULATION REGRESSION
**************************************************************/
global covarspop "log_tot_int_age1 log_tot_int_age2 log_tot_int_age3 log_tot_int_age4 log_tot_int_age5 log_tot_int_age6 log_tot_r_white log_tot_r_black log_tot_r_asian log_tot_hs log_tot_in_school log_tot_ownhome"
global covarsnat "log_nat_int_age1 log_nat_int_age2 log_nat_int_age3 log_nat_int_age4 log_nat_int_age5 log_nat_int_age6 log_nat_r_white log_nat_r_black log_nat_r_asian log_nat_hs log_nat_in_school log_nat_ownhome"
global invars "exp_any_state "


use "$oi/migpuma_year_pops", clear

********* IN MIGRATION FOR TARGET POPULATION
cap mat drop intarget
* with simple weights
* without controls
reghdfe log_tot_targetpop2 exp_any_migpuma $invars [aw=tot_targetpop2], vce(robust) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_any_migpuma ) mat(intarget)
* with controls for native
reghdfe log_tot_targetpop2 exp_any_migpuma $covarsnat $invars [aw=tot_targetpop2], vce(robust) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_any_migpuma ) mat(intarget)

**** IN MIGRATION FOR PLACEBO POPULATION
* with simple weights
* without controls
reghdfe log_tot_placebo1 exp_any_migpuma $invars [aw=tot_targetpop2], vce(robust) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_tot_placebo1 ) indvars( exp_any_migpuma ) mat(intarget)
* with controls 
reghdfe log_tot_placebo1 exp_any_migpuma $covarsnat $invars [aw=tot_targetpop2], vce(robust) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_tot_placebo1 ) indvars( exp_any_migpuma ) mat(intarget)


* Create table
cap file close sumstat
file open sumstat using "$oo/final/logtargetpop_reg.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
* Panel A
file write sumstat " & \multicolumn{2}{c}{Target population} & \multicolumn{2}{c}{Placebo population}  \\" _n
file write sumstat " Log population & (1) & (2)  & (3) & (4)  \\" _n
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
LOG POPULATION DID GAINERS AND LOSERS IN SAME REGRESSION
**************************************************************/
global covarspop "log_tot_int_age1 log_tot_int_age2 log_tot_int_age3 log_tot_int_age4 log_tot_int_age5 log_tot_int_age6 log_tot_r_white log_tot_r_black log_tot_r_asian log_tot_hs log_tot_in_school log_tot_ownhome"
global covarsnat "log_nat_int_age1 log_nat_int_age2 log_nat_int_age3 log_nat_int_age4 log_nat_int_age5 log_nat_int_age6 log_nat_r_white log_nat_r_black log_nat_r_asian log_nat_hs log_nat_in_school log_nat_ownhome"
global invars "exp_any_state "

use "$oi/migpuma_year_pops", clear
**** trying doug's suggestion
cap mat drop intarget
* no controls 
reghdfe log_tot_targetpop2 exp_gain_migpuma exp_lost_migpuma $invars [aw=tot_targetpop2], vce(robust) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) 
* with controls for native populations
reghdfe log_tot_targetpop2 exp_gain_migpuma exp_lost_migpuma $covarspop $invars [aw=tot_targetpop2], vce(robust) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) 
* no controls 
reghdfe log_tot_placebo1 exp_gain_migpuma exp_lost_migpuma $invars [aw=tot_targetpop2], vce(robust) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_tot_placebo1 ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) 
* with controls for native populations
reghdfe log_tot_placebo1 exp_gain_migpuma exp_lost_migpuma $covarspop $invars [aw=tot_targetpop2], vce(robust) absorb(geoid_migpuma year)
reg_to_mat, depvar( log_tot_placebo1 ) indvars( exp_gain_migpuma exp_lost_migpuma) mat(intarget) 


* Create table
cap file close sumstat
file open sumstat using "$oo/final/logtargetpop_did.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & \multicolumn{2}{c}{Target population} & \multicolumn{2}{c}{Placebo population}  \\" _n
file write sumstat "Log population & (1) & (2)  & (3) & (4) \\" _n
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
