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

global covarspop "log_tot_age_0_17 log_tot_age_18_24 log_tot_age_25_34 log_tot_age_35_49 log_tot_r_white log_tot_r_black log_tot_r_asian log_tot_hs log_tot_in_school log_tot_ownhome"

//global invars "exp_any_state SC_any"


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
Balance table with differences
**************************************************************/

* import clean ACS data ready for regressions
use "$oi/working_acs", clear 
gen rentprice = rent if ownhome==0
gen mortprice = mortamt1 if ownhome==1

* restrict sample 
keep if year >= 2013
bys statefip current_puma: egen ever_treated_puma = max( exp_any_puma==1)
bys statefip current_puma: egen always_treated_puma = max( exp_any_puma==0)
replace always_treated_puma = !always_treated_puma
drop if always_treated_puma==1 //ruling out always treated counties


* define propensity weights for hispanic singles
merge m:1 statefip current_puma  using  "$oi/propensity_weights2013puma_t2" , nogen keep(3) keepusing(phat wt)
rename (phat wt) (phat2 wt2)
gen perwt_wt2 = perwt*wt2
drop if mi(perwt_wt2)

gen has_child = nchild>0
gen hs_high = educ>=6

//remember you see some effects in migration for born_abroad==1 & citizen!=3
* create summary values
cap mat drop sumstat
cap mat drop matse
cap mat drop matpval

foreach v in move_migpuma move_state move_abroad has_child nchild r_white r_black hs no_english in_school employed wkswork1 uhrswork incwage ownhome rentprice mortprice {
    di in red "Processing `v'"
    * TARGET POPULATION FOR HISPANICS
    * Ever exposed
    qui reg `v' targetpop2 [pw=perwt] if ever_treated_puma==1 , nocons 
    local m1 = _b[targetpop]
    local se1 = _se[targetpop]
    local pval1 = 9999

    * never exposed
    qui reg `v' targetpop2 [pw=perwt] if ever_treated_puma==0 , nocons 
    local m2 = _b[targetpop]
    local se2 = _se[targetpop]
    local pval2 = 9999
   
   * Difference without prop score
    qui reg `v' ever_treated_puma [pw=perwt] if targetpop2==1, robust
    local m3 = _b[ever_treated_puma]
    local se3 = _se[ever_treated_puma]
    local t = _b[ever_treated_puma] / _se[ever_treated_puma]
    local pval3 =  2*ttail(e(df_r), abs(`t'))

    mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3' )
    mat matse = nullmat(matse) \ (`se1', `se2', `se3' )
    mat matpval = nullmat(matpval) \ (`pval1' , `pval2', `pval3' )
}

qui count if targetpop2==1 & ever_treated_puma==1
local m1 = r(N)
qui count if targetpop2==1 & ever_treated_puma==0
local m2 = r(N)
qui count if targetpop2==1 
local m3 = r(N)
mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3' )

qui sum targetpop2 [aw=perwt] if ever_treated_puma==1
local m1 = r(sum)
qui sum targetpop2 [aw=perwt] if ever_treated_puma==0
local m2 = r(sum)
qui sum targetpop2 [aw=perwt]
local m3 = r(sum)
mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3' )


* Create table
cap file close sumstat
file open sumstat using "$oo/final/balancetable.tex", write replace
file write sumstat "\begin{tabular}{lccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & \multicolumn{3}{c}{Target population} & \multicolumn{3}{c}{puma}  \\" _n
file write sumstat " & Treated & Untreated & Difference   \\" _n
file write sumstat " & (1) & (2) & (3)  \\" _n
file write sumstat "\midrule " _n
 
file write sumstat " \textbf{Mobility} & & &   \\" _n
global varnames `" "Moved migpuma" "Moved state" "Moved from abroad" "'
local i = 1
forval r = 1/3 {
    local varname : word `i' of $varnames
    file write sumstat " `varname' "
    di "Writing row `r'"
    * mean
    forval c = 1/3 {
        di "Writing column `c'"
        local a = string(sumstat[`r',`c'], "%12.2fc" )
        local pval = matpval[`r', `c']
        local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
        file write sumstat " & `a'`stars_abs' "
    }
    file write sumstat "\\" _n 
    * se
    forval c = 1/3 {
        local a = string(matse[`r',`c'], "%12.2fc" )
        file write sumstat " & (`a')"
    }
    file write sumstat "\\" _n 
    local++ i
}
file write sumstat " \textbf{Demographics and education} & & &   \\" _n
global varnames `" "Age" "Has a child" "Race: White" "Race: Black" "High School" "Poor English" "In School" "'
local i = 1
forval r = 4/10 {
    local varname : word `i' of $varnames
    file write sumstat " `varname' "
    di "Writing row `r'"
    * mean
    forval c = 1/3 {
        di "Writing column `c'"
        local a = string(sumstat[`r',`c'], "%12.2fc" )
        local pval = matpval[`r', `c']
        local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
        file write sumstat " & `a'`stars_abs' "
    }
    file write sumstat "\\" _n 
    * se
    forval c = 1/3 {
        local a = string(matse[`r',`c'], "%12.2fc" )
        file write sumstat " & (`a')"
    }
    file write sumstat "\\" _n 
    local++ i
}
file write sumstat " \textbf{Employment and housing} & & &   \\" _n
global varnames `" "Employed" "Weeks worked" "Usual weekly hours worked" "Wage income" "Owns a home" "Rent price" "Mortgage price" "'
local i = 1
forval r = 11/17 {
    local varname : word `i' of $varnames
    file write sumstat " `varname' "
    di "Writing row `r'"
    * mean
    forval c = 1/3 {
        di "Writing column `c'"
        local a = string(sumstat[`r',`c'], "%12.2fc" )
        local pval = matpval[`r', `c']
        local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
        file write sumstat " & `a'`stars_abs' "
    }
    file write sumstat "\\" _n 
    * se
    forval c = 1/3 {
        local a = string(matse[`r',`c'], "%12.2fc" )
        file write sumstat " & (`a')"
    }
    file write sumstat "\\" _n 
    local++ i
}

local a1 = string(sumstat[18,1], "%12.0fc" )
local a2 = string(sumstat[18,2], "%12.0fc" )
local a3 = string(sumstat[18,3], "%12.0fc" )
file write sumstat "Sample size & `a1' & `a2' & \\" _n
local a1 = string(sumstat[19,1], "%12.0fc" )
local a2 = string(sumstat[19,2], "%12.0fc" )
local a3 = string(sumstat[19,3], "%12.0fc" )
file write sumstat "Total population & `a1' & `a2' & \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat


******** BALANCE TABLE WITH WEIGHTS

//remember you see some effects in migration for born_abroad==1 & citizen!=3
* create summary values
cap mat drop sumstat
cap mat drop matse
cap mat drop matpval

foreach v in move_migpuma move_state move_abroad age has_child r_white r_black hs no_english in_school employed wkswork1 uhrswork incwage ownhome rentprice mortprice {
    di in red "Processing `v'"
    * TARGET POPULATION FOR HISPANICS
    * Ever exposed
    qui reg `v' targetpop2 [pw=perwt_wt2] if ever_treated_puma==1 , nocons 
    local m1 = _b[targetpop]
    local se1 = _se[targetpop]
    local pval1 = 9999

    * never exposed
    qui reg `v' targetpop2 [pw=perwt_wt2] if ever_treated_puma==0 , nocons 
    local m2 = _b[targetpop]
    local se2 = _se[targetpop]
    local pval2 = 9999
   
   * Difference without prop score
    qui reg `v' ever_treated_puma [pw=perwt_wt2] if targetpop2==1, robust
    local m3 = _b[ever_treated_puma]
    local se3 = _se[ever_treated_puma]
    local t = _b[ever_treated_puma] / _se[ever_treated_puma]
    local pval3 =  2*ttail(e(df_r), abs(`t'))

    mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3' )
    mat matse = nullmat(matse) \ (`se1', `se2', `se3' )
    mat matpval = nullmat(matpval) \ (`pval1' , `pval2', `pval3' )
}

qui count if targetpop2==1 & ever_treated_puma==1
local m1 = r(N)
qui count if targetpop2==1 & ever_treated_puma==0
local m2 = r(N)
qui count if targetpop2==1 
local m3 = r(N)
mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3' )

qui sum targetpop2 [aw=perwt] if ever_treated_puma==1
local m1 = r(sum)
qui sum targetpop2 [aw=perwt] if ever_treated_puma==0
local m2 = r(sum)
qui sum targetpop2 [aw=perwt]
local m3 = r(sum)
mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3' )


* Create table
cap file close sumstat
file open sumstat using "$oo/final/balancetable_prop.tex", write replace
file write sumstat "\begin{tabular}{lccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & \multicolumn{3}{c}{Target population} & \multicolumn{3}{c}{puma}  \\" _n
file write sumstat " & Treated & Untreated & Difference   \\" _n
file write sumstat " & (1) & (2) & (3)  \\" _n
file write sumstat "\midrule " _n
 
file write sumstat " \textbf{Mobility} & & &   \\" _n
global varnames `" "Moved migpuma" "Moved state" "Moved from abroad" "'
local i = 1
forval r = 1/3 {
    local varname : word `i' of $varnames
    file write sumstat " `varname' "
    di "Writing row `r'"
    * mean
    forval c = 1/3 {
        di "Writing column `c'"
        local a = string(sumstat[`r',`c'], "%12.2fc" )
        local pval = matpval[`r', `c']
        local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
        file write sumstat " & `a'`stars_abs' "
    }
    file write sumstat "\\" _n 
    * se
    forval c = 1/3 {
        local a = string(matse[`r',`c'], "%12.2fc" )
        file write sumstat " & (`a')"
    }
    file write sumstat "\\" _n 
    local++ i
}
file write sumstat " \textbf{Demographics and education} & & &   \\" _n
global varnames `" "Age" "Has a child" "Race: White" "Race: Black" "High School" "Poor English" "In School" "'
local i = 1
forval r = 4/10 {
    local varname : word `i' of $varnames
    file write sumstat " `varname' "
    di "Writing row `r'"
    * mean
    forval c = 1/3 {
        di "Writing column `c'"
        local a = string(sumstat[`r',`c'], "%12.2fc" )
        local pval = matpval[`r', `c']
        local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
        file write sumstat " & `a'`stars_abs' "
    }
    file write sumstat "\\" _n 
    * se
    forval c = 1/3 {
        local a = string(matse[`r',`c'], "%12.2fc" )
        file write sumstat " & (`a')"
    }
    file write sumstat "\\" _n 
    local++ i
}
file write sumstat " \textbf{Employment and housing} & & &   \\" _n
global varnames `" "Employed" "Weeks worked" "Usual weekly hours worked" "Wage income" "Owns a home" "Rent price" "Mortgage price" "'
local i = 1
forval r = 11/17 {
    local varname : word `i' of $varnames
    file write sumstat " `varname' "
    di "Writing row `r'"
    * mean
    forval c = 1/3 {
        di "Writing column `c'"
        local a = string(sumstat[`r',`c'], "%12.2fc" )
        local pval = matpval[`r', `c']
        local stars_abs = cond(`pval' < 0.01, "***", cond(`pval' < 0.05, "**", cond(`pval' < 0.1, "*", "")))
        file write sumstat " & `a'`stars_abs' "
    }
    file write sumstat "\\" _n 
    * se
    forval c = 1/3 {
        local a = string(matse[`r',`c'], "%12.2fc" )
        file write sumstat " & (`a')"
    }
    file write sumstat "\\" _n 
    local++ i
}

file write sumstat "\\" _n 
local a1 = string(sumstat[18,1], "%12.0fc" )
local a2 = string(sumstat[18,2], "%12.0fc" )
local a3 = string(sumstat[18,3], "%12.0fc" )
file write sumstat "Sample size & `a1' & `a2' & \\" _n
local a1 = string(sumstat[19,1], "%12.0fc" )
local a2 = string(sumstat[19,2], "%12.0fc" )
local a3 = string(sumstat[19,3], "%12.0fc" )
file write sumstat "Total population & `a1' & `a2' & \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat




/**************************************************************
LOG POPULATION REGRESSION
**************************************************************/


use "$oi/puma_year_pops", clear
keep if year>=2013
********* IN MIGRATION FOR TARGET POPULATION
cap mat drop intarget
* with simple weights
* without controls
reghdfe log_tot_targetpop2 exp_any_puma  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample1 = e(sample)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_any_puma ) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* with controls for native
reghdfe log_tot_targetpop2 exp_any_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample2 = e(sample)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_any_puma ) mat(intarget) wt(tot_targetpop2) wttype(aw)

**** IN MIGRATION FOR PLACEBO POPULATION
* with simple weights
* without controls
reghdfe log_tot_placebo5 exp_any_puma  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample3 = e(sample)
reg_to_mat, depvar( log_tot_placebo5 ) indvars( exp_any_puma ) mat(intarget) wt(tot_targetpop2) wttype(aw)
* with controls 
reghdfe log_tot_placebo5 exp_any_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample4 = e(sample)
reg_to_mat, depvar( log_tot_placebo5 ) indvars( exp_any_puma ) mat(intarget) wt(tot_targetpop2) wttype(aw)

//store pop size
qui sum tot_targetpop2 if sample1 
local um1 = r(mean)
qui sum tot_targetpop2 if sample2
local um2 = r(mean)
qui sum tot_placebo5 if sample3
local um3 = r(mean)
qui sum tot_placebo5 if sample4
local um4 = r(mean)
mat intarget = nullmat(intarget) \ (`um1', `um2', `um3' , `um4' )

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

global varnames `"  "Treated puma" "'

local varname : word 1 of $varnames
forval c = 1/4  {
    local b`c' = string(intarget[1,`c'], "%12.4fc" )
    local temp = intarget[1,`c']/intarget[5,`c']*100
    local bmean`c' = string(`temp', "%12.2fc" )
    local p`c' = intarget[2,`c']
    local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
    local sd`c' = string(intarget[3,`c'], "%12.4fc" )
    local r`c' = string(intarget[4,`c'], "%12.4fc" )
    local um`c' = string(intarget[8,`c'], "%12.0fc" )
	local n`c' = string(intarget[6,`c'], "%12.0fc" )
}
file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
//file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated pop size & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 

file write sumstat "\end{tabular}"
file close sumstat

/*forval i = 1/5 {
    di in red "placebo `i' "
    reghdfe log_tot_placebo`i' exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
}*/

/**************************************************************
LOG POPULATION DID GAINERS AND LOSERS IN SAME REGRESSION
**************************************************************/

use "$oi/puma_year_pops", clear
keep if year>=2013
**** trying doug's suggestion
cap mat drop intarget
* no controls 
reghdfe log_tot_targetpop2 exp_gain_puma exp_lost_puma  [aw=tot_targetpop2] , vce(robust) absorb( geoid_puma year)
gen sample1 = e(sample)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* with controls for native populations
reghdfe log_tot_targetpop2 exp_gain_puma exp_lost_puma $covarspop [aw=tot_targetpop2] , vce(robust) absorb(geoid_puma year)
gen sample2 = e(sample)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* no controls 
reghdfe log_tot_placebo5 exp_gain_puma exp_lost_puma  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample3 = e(sample)
reg_to_mat, depvar( log_tot_placebo5 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* with controls for native populations
reghdfe log_tot_placebo5 exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample4 = e(sample)
reg_to_mat, depvar( log_tot_placebo5 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)

//store pop size
qui sum tot_targetpop2 if sample1 
local um1 = r(mean)
qui sum tot_targetpop2 if sample2
local um2 = r(mean)
qui sum tot_placebo5 if sample3
local um3 = r(mean)
qui sum tot_placebo5 if sample4
local um4 = r(mean)
mat intarget = nullmat(intarget) \ (`um1', `um2', `um3' , `um4' )


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
    //file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
    file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
}
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
forval c = 1/4  {
    local r`c' = string(intarget[7,`c'], "%12.4fc" )
    local um`c' = string(intarget[11,`c'], "%12.0fc" )
    local n`c' = string(intarget[9,`c'], "%12.0fc" )
}
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated pop size & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat



/**************************************************************
HETEROGENEITY EFFECTS TO OTHER POPS: LOG POPULATION DID GAINERS AND LOSERS IN SAME REGRESSION
**************************************************************/

use "$oi/puma_year_pops", clear
keep if year>=2013
**** trying doug's suggestion
cap mat drop intarget

* BASELINE
reghdfe log_tot_targetpop2 exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample1 = e(sample)
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* MEXICAN TARGET
reghdfe log_tot_target_mexican exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample2 = e(sample)
reg_to_mat, depvar( log_tot_target_mexican ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* POOR ENGLISH TARGET
reghdfe log_tot_target_noenglish exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample3 = e(sample)
reg_to_mat, depvar( log_tot_target_noenglish ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* NEW IMMIGRANT TARGET
reghdfe log_tot_target_old exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample4 = e(sample)
reg_to_mat, depvar( log_tot_target_old ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* TARGET no CHILDREN
reghdfe log_tot_target_nochild exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample5 = e(sample)
reg_to_mat, depvar( log_tot_target_nochild ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)
* NON HISPANIC TARGET
reghdfe log_tot_target_nohisp exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
gen sample6 = e(sample)
reg_to_mat, depvar( log_tot_target_nohisp ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(tot_targetpop2) wttype(aw)

*** STORE POP SIZE ***
qui sum tot_targetpop2 if sample1
local um1 = r(mean)
qui sum tot_target_mexican if sample2
local um2 = r(mean)
qui sum tot_target_noenglish if sample3
local um3 = r(mean)
qui sum tot_target_old if sample4
local um4 = r(mean)
qui sum tot_target_nochild if sample5
local um5 = r(mean)
qui sum tot_target_nohisp if sample6
local um6 = r(mean)
mat intarget = nullmat(intarget) \ (`um1', `um2', `um3', `um4', `um5', `um6')
drop sample*


local i = 1
cap mat drop inplacebo 
* PLACEBO
reghdfe log_tot_placebo5 exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_placebo5 ) indvars( exp_gain_puma exp_lost_puma) mat(inplacebo)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i
* PLACEBO MEXICANS
mat inplacebo = inplacebo , (9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999)
local++ i
* PLACEBO POOR ENGLISH TARGET
reghdfe log_tot_plac_noenglish exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_plac_noenglish ) indvars( exp_gain_puma exp_lost_puma) mat(inplacebo)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i
* PLACEBO NEW IMMIGRANT
mat inplacebo = inplacebo , (9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999 \ 9999)
local++ i
* PLACEBO NO child
reghdfe log_tot_plac_nochild exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_plac_nochild ) indvars( exp_gain_puma exp_lost_puma) mat(inplacebo)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i
* PLACEBO NON HISPANIC
reghdfe log_tot_plac_nohisp exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_plac_nohisp ) indvars( exp_gain_puma exp_lost_puma) mat(inplacebo)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i

*** STORE POP SIZE ***
qui sum tot_placebo5 if sample1
local um1 = r(mean)
qui sum tot_placebo5 if sample1
local um2 = r(mean)
qui sum tot_plac_noenglish if sample3
local um3 = r(mean)
qui sum tot_plac_noenglish if sample3
local um4 = r(mean)
qui sum tot_plac_nochild if sample5
local um5 = r(mean)
qui sum tot_plac_nohisp if sample6
local um6 = r(mean)
mat inplacebo = nullmat(inplacebo) \ (`um1', `um2', `um3', `um4', `um5', `um6')
drop sample*


local i =1 
cap mat drop inspillover
* SPILLOVER
reghdfe log_tot_spillover1 exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spillover1 ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i
* SPILLOVER MEXICANS
reghdfe log_tot_spill1_mexican exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_mexican ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i
* SPILLOVER POOR ENGLISH TARGET
reghdfe log_tot_spill1_noenglish exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_noenglish ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw) 
gen sample`i' = e(sample)
local++ i
* SPILLOVER NEW IMMIGRANT
reghdfe log_tot_spill1_old exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_old ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i
* SPILLOVER NO child
reghdfe log_tot_spill1_nochild exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_nochild ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i
* SPILLOVER NON HISPANIC
reghdfe log_tot_spill1_nohisp exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_nohisp ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
gen sample`i' = e(sample)
local++ i

*** STORE POP SIZE ***
qui sum tot_spillover1 if sample1
local um1 = r(mean)
qui sum tot_spill1_mexican if sample2
local um2 = r(mean)
qui sum tot_spill1_noenglish if sample3
local um3 = r(mean)
qui sum tot_spill1_old if sample4
local um4 = r(mean)
qui sum tot_spill1_nochild if sample5
local um5 = r(mean)
qui sum tot_spill1_nohisp if sample6
local um6 = r(mean)
mat inspillover = nullmat(inspillover) \ (`um1', `um2', `um3', `um4', `um5', `um6')
drop sample*

* Create table
cap file close sumstat
file open sumstat using "$oo/final/logpops_het.tex", write replace
file write sumstat "\begin{tabular}{lcccccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " \multicolumn{7}{c}{Panel A: Target population} \\" _n
file write sumstat "\midrule" _n
file write sumstat " &  & & Poor & Long-term &  &  \\" _n
file write sumstat " & Baseline & Mexican & English & Immigrant & No children & Non-Hispanic \\" _n
file write sumstat "Log population & (1) & (2)  & (3) & (4) & (5) & (6) \\" _n
file write sumstat "\midrule " _n


global varnames `"  "Gain treatment" "Lose treatment" "'

forval i = 1/2 {
    local varname : word `i' of $varnames
    forval c = 1/6  {
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
    file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' & `b5'`stars_abs5' & `b6'`stars_abs6' \\" _n 
    //file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
    file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') & (`sd5') & (`sd6') \\" _n 
}
file write sumstat "\\" _n 
file write sumstat " Controls & X & X & X & X & X & X \\" _n 
forval c = 1/6  {
    local r`c' = string(intarget[7,`c'], "%12.4fc" )
    local um`c' = string(intarget[11,`c'], "%12.0fc" )
    local n`c' = string(intarget[9,`c'], "%12.0fc" )
}
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4' & `r5' & `r6'    \\" _n 
file write sumstat " Untreated pop size & `um1' & `um2' & `um3' & `um4' & `um5' & `um6'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4' & `n5' & `n6'  \\" _n
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n
file write sumstat " \multicolumn{7}{c}{Panel B: Spillover population} \\" _n
file write sumstat "\midrule" _n
file write sumstat " &  & & Poor & Long-term &  &  \\" _n
file write sumstat " & Baseline & Mexican & English & Immigrant & No children & Non-Hispanic \\" _n
file write sumstat "Log population & (7) & (8)  & (9) & (10) & (11) & (12) \\" _n
file write sumstat "\midrule" _n

global varnames `"  "Gain treatment" "Lose treatment" "'

forval i = 1/2 {
    local varname : word `i' of $varnames
    forval c = 1/6  {
        local row = 1 +3*(`i'-1)
        local b`c' = string(inspillover[`row',`c'], "%12.4fc" )
        local temp = inspillover[`row',`c']/inspillover[5,`c']*100
        local bmean`c' = string(`temp', "%12.2fc" )
        local++ row
        local p`c' = inspillover[`row',`c']
        local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
        local++ row
        local sd`c' = string(inspillover[`row',`c'], "%12.4fc" )
        
    }
    file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' & `b5'`stars_abs5' & `b6'`stars_abs6' \\" _n 
    //file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
    file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') & (`sd5') & (`sd6') \\" _n 
}
file write sumstat "\\" _n 
file write sumstat " Controls & X & X & X & . & X & X \\" _n 
forval c = 1/6 {
    local r`c' = string(inspillover[7,`c'], "%12.4fc" )
    local um`c' = string(inspillover[11,`c'], "%12.0fc" )
    local n`c' = string(inspillover[9,`c'], "%12.0fc" )
}
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & . & `r5' & `r6'    \\" _n 
file write sumstat " Untreated pop size & `um1' & `um2' & `um3' & . & `um5' & `um6'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & . & `n5' & `n6'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat






****
* Create table
cap file close sumstat
file open sumstat using "$oo/final/logpops_het_spill.tex", write replace
file write sumstat "\begin{tabular}{lcccccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & Baseline & Mexican & Poor English & New Immigrant & No children & Non-Hispanic \\" _n
file write sumstat "Log population & (1) & (2)  & (3) & (4) & (5) & (6) \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Gain treatment" "Lose treatment" "'

forval i = 1/2 {
    local varname : word `i' of $varnames
    forval c = 1/6  {
        local row = 1 +3*(`i'-1)
        local b`c' = string(inplacebo[`row',`c'], "%12.4fc" )
        local temp = inplacebo[`row',`c']/inplacebo[5,`c']*100
        local bmean`c' = string(`temp', "%12.2fc" )
        local++ row
        local p`c' = inplacebo[`row',`c']
        local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
        local++ row
        local sd`c' = string(inplacebo[`row',`c'], "%12.4fc" )
        
    }
    file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & . & `b5'`stars_abs5' & `b6'`stars_abs6' \\" _n 
    //file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
    file write sumstat " & (`sd1') & (`sd2') & (`sd3') & . & (`sd5') & (`sd6') \\" _n 
}
file write sumstat "\\" _n 
file write sumstat " Controls & X & X & X & . & X & X \\" _n 
forval c = 1/6 {
    local r`c' = string(inplacebo[7,`c'], "%12.4fc" )
    local um`c' = string(inplacebo[11,`c'], "%12.0fc" )
    local n`c' = string(inplacebo[9,`c'], "%12.0fc" )
}
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & . & `r5' & `r6'    \\" _n 
file write sumstat " Untreated pop size & `um1' & `um2' & `um3' & . & `um5' & `um6'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & . & `n5' & `n6'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat

/**************************************************************
LOG POPULATION DID GAINERS AND LOSERS IN SAME REGRESSION WITH PROP WEIGHT
**************************************************************/

use "$oi/puma_year_pops", clear
keep if year>=2013
merge m:1 statefip current_puma  using  "$oi/propensity_weights2013puma_t2" , nogen keep(3) keepusing(phat wt)

gen popwt = tot_targetpop2*wt

**** trying doug's suggestion
local i = 1
cap mat drop intarget
* no controls 
reghdfe log_tot_targetpop2 exp_gain_puma exp_lost_puma  [aw=popwt], vce(robust) absorb(geoid_puma year)
gen sample`i' = e(sample)
local++ i
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(popwt) wttype(aw)
* with controls for native populations
reghdfe log_tot_targetpop2 exp_gain_puma exp_lost_puma $covarspop  [aw=popwt], vce(robust) absorb(geoid_puma year)
gen sample`i' = e(sample)
local++ i
reg_to_mat, depvar( log_tot_targetpop2 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(popwt) wttype(aw)
* no controls 
reghdfe log_tot_placebo5 exp_gain_puma exp_lost_puma  [aw=popwt], vce(robust) absorb(geoid_puma year)
gen sample`i' = e(sample)
local++ i
reg_to_mat, depvar( log_tot_placebo5 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(popwt) wttype(aw)
* with controls for native populations
reghdfe log_tot_placebo5 exp_gain_puma exp_lost_puma $covarspop  [aw=popwt], vce(robust) absorb(geoid_puma year)
gen sample`i' = e(sample)
local++ i
reg_to_mat, depvar( log_tot_placebo5 ) indvars( exp_gain_puma exp_lost_puma) mat(intarget)  wt(popwt) wttype(aw)


*** STORE POP SIZE ***
qui sum tot_targetpop2 if sample1
local um1 = r(mean)
qui sum tot_targetpop2 if sample2
local um2 = r(mean)
qui sum tot_placebo5 if sample3
local um3 = r(mean)
qui sum tot_placebo5 if sample4
local um4 = r(mean)
mat intarget = nullmat(intarget) \ (`um1', `um2', `um3', `um4')
drop sample*

* Create table
cap file close sumstat
file open sumstat using "$oo/final/logtargetpop_did_prop.tex", write replace
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
    //file write sumstat "  & [`bmean1'$\%$] & [`bmean2'$\%$] & [`bmean3'$\%$] & [`bmean4'$\%$] \\" _n 
    file write sumstat " & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
}
file write sumstat "\\" _n 
file write sumstat " Controls &  & X &  & X \\" _n 
forval c = 1/4  {
    local r`c' = string(intarget[7,`c'], "%12.4fc" )
    local um`c' = string(intarget[11,`c'], "%12.0fc" )
    local n`c' = string(intarget[9,`c'], "%12.0fc" )
}
file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
file write sumstat " Untreated pop size & `um1' & `um2' & `um3' & `um4'  \\" _n 
file write sumstat "Sample Size & `n1' & `n2' & `n3' & `n4'  \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\\" _n 
file write sumstat "\end{tabular}"
file close sumstat


/*

cap mat drop inspillover
* SPILLOVER
reghdfe log_tot_spillover1 exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spillover1 ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
* SPILLOVER MEXICANS
reghdfe log_tot_spill1_mexican exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_mexican ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
* SPILLOVER POOR ENGLISH TARGET
reghdfe log_tot_spill1_noenglish exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_noenglish ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
* SPILLOVER NEW IMMIGRANT
reghdfe log_tot_spill1_old exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_old ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
* SPILLOVER NO child
reghdfe log_tot_spill1_nochild exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_nochild ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)
* SPILLOVER NON HISPANIC
reghdfe log_tot_spill1_nohisp exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)
reg_to_mat, depvar( log_tot_spill1_nohisp ) indvars( exp_gain_puma exp_lost_puma) mat(inspillover)  wt(tot_targetpop2) wttype(aw)

*/



use "$oi/puma_year_pops", clear
keep if year>=2013
preserve 
collapse (max) exp_gain_puma exp_lost_puma exp_any_puma, by(statefip current_puma year)
bys statefip current_puma (year): gen exp_gain_puma_t1 = exp_gain_puma[_n-1]
bys statefip current_puma (year): gen exp_lost_puma_t1 = exp_lost_puma[_n-1]
bys statefip current_puma (year): gen exp_any_puma_t1 = exp_any_puma[_n-1]
tempfile t1vars 
save `t1vars'
restore

merge m:1 statefip current_puma year using `t1vars', nogen keep(1 3)

reghdfe log_tot_targetpop2 exp_gain_puma exp_lost_puma exp_gain_puma_t1 exp_lost_puma_t1 $covarspop  [aw=tot_targetpop2], vce(robust) absorb(geoid_puma year)



global covarssh "age r_white r_black r_asian hs in_school "
reghdfe log_tot_targetpop2 exp_gain_puma exp_lost_puma $covarspop  [aw=tot_targetpop2] , vce(robust) absorb(geoid_puma year)

