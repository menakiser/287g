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
use "$oi/acs_w_propensity_weights", clear 
gen rentprice = rent if ownhome==0
gen mortprice = mortamt1 if ownhome==1
cap mat drop sumstat
foreach v in male age exp_any_migpuma hs move_any move_migpuma move_state married never_married nchild employed wkswork1 uhrswork incwage ownhome rentprice mortprice {
    
    * targeted population
    qui reg `v' targetpop [pw=perwt] if exp_any_migpuma==0 , nocons 
    local m1 = _b[targetpop]
    qui reg `v' targetpop [pw=perwt] if  exp_any_migpuma>0 , nocons 
    local m2 = _b[targetpop]

    * citizens
    qui reg `v' placebo1 [pw=perwt] if exp_any_migpuma==0 , nocons 
    local m3 = _b[placebo1]
    qui reg `v' placebo1 [pw=perwt] if exp_any_migpuma>0 , nocons 
    local m4 = _b[placebo1]

	* propensity score matched
	* targeted population
    qui reg `v' targetpop [pw=perwt_wt] if exp_any_migpuma==0 , nocons 
    local m5 = _b[targetpop]
    qui reg `v' targetpop [pw=perwt_wt] if  exp_any_migpuma>0 , nocons 
    local m6 = _b[targetpop]

    * citizens
    qui reg `v' placebo1 [pw=perwt_wt] if exp_any_migpuma==0 , nocons 
    local m7 = _b[placebo1]
    qui reg `v' placebo1 [pw=perwt_wt] if exp_any_migpuma>0 , nocons 
    local m8 = _b[placebo1]

    mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4', `m5', `m6', `m7', `m8' )
}

qui count if targetpop==1 & exp_any_migpuma==0 
local m1 = r(N)
qui count if targetpop==1 & exp_any_migpuma>0
local m2 = r(N)
qui count if placebo1==1 & exp_any_migpuma==0
local m3 = r(N)
qui count if placebo1==1 & exp_any_migpuma>0 
local m4 = r(N)

mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4', `m1', `m2', `m3', `m4')


* Create table
cap file close sumstat
file open sumstat using "$oo/t2_sumstat.tex", write replace
file write sumstat "\begin{tabular}{lcccccccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & & & & & \multicolumn{4}{c}{Propensity score weighting} \\" _n
file write sumstat " & \multicolumn{2}{c}{Targeted population} & \multicolumn{2}{c}{Placebo} & \multicolumn{2}{c}{Targeted population} & \multicolumn{2}{c}{Placebo}  \\" _n
file write sumstat " & Exposure=0 & Exposure=1 & Exposure=0 & Exposure=1 & Exposure=0 & Exposure=1 & Exposure=0 & Exposure=1 \\" _n
file write sumstat " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Male" "Age" "Exposure" "High School" "Any move" "Moved migpuma" "Moved state" "Married" "Never married" "Number of children" "Employed" "Weeks worked" "Usual weekly hours worked" "Wage income" "Owns a home" "Rent price" "Mortgage price" "Sample size" "'
forval r = 1/18 {
	local varname : word `r' of $varnames
	file write sumstat " `varname' "
	di "Writing row `r'"
	forval c = 1/8 {
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
use "$oi/acs_w_propensity_weights", clear 
global covars "age i.race i.educ i.speakeng i.hcovany i.school ownhome " 
global invars "SC_any exp_any_state"
global outvars "prev_SC_any prev_exp_any_state"

* in migration
cap mat drop inmig1
reghdfe move_any exp_any_migpuma  $covars $invars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any ) indvars(exp_any_migpuma ) mat(inmig1)
reghdfe move_any exp_any_migpuma  $covars $invars [pw=perwt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any ) indvars(exp_any_migpuma ) mat(inmig1)

reghdfe move_any exp_any_migpuma  $covars $invars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any) indvars(exp_any_migpuma ) mat(inmig1)
reghdfe move_any exp_any_migpuma $covars $invars [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any) indvars(exp_any_migpuma ) mat(inmig1)


cap mat drop inmig2
reghdfe move_migpuma exp_any_migpuma  $covars $invars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inmig2)
reghdfe move_migpuma exp_any_migpuma  $covars $invars [pw=perwt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inmig2)

reghdfe move_migpuma exp_any_migpuma  $covars $invars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inmig2)
reghdfe move_migpuma exp_any_migpuma  $covars $invars [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma ) mat(inmig2)


cap mat drop inmig3
reghdfe move_state exp_any_migpuma  $covars $invars [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any_migpuma) mat(inmig3)
reghdfe move_state exp_any_migpuma  $covars $invars [pw=perwt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any_migpuma) mat(inmig3)

reghdfe move_state exp_any_migpuma  $covars $invars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any_migpuma) mat(inmig3)
reghdfe move_state exp_any_migpuma  $covars $invars [pw=perwt_wt]  if placebo1==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any_migpuma) mat(inmig3)


* out migration
cap mat drop outmig1
reghdfe move_any prev_exp_any_migpuma  $covars $outvars [pw=perwt]  if targetpop==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar(move_any ) indvars(prev_exp_any_migpuma ) mat(outmig1)
reghdfe move_any prev_exp_any_migpuma  $covars $outvars [pw=perwt]  if placebo1==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar(move_any ) indvars(prev_exp_any_migpuma ) mat(outmig1)

reghdfe move_any prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if targetpop==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar(move_any) indvars(prev_exp_any_migpuma ) mat(outmig1)
reghdfe move_any prev_exp_any_migpuma $covars $outvars  [pw=perwt_wt]  if placebo1==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar(move_any) indvars(prev_exp_any_migpuma ) mat(outmig1)

cap mat drop outmig2
reghdfe move_migpuma prev_exp_any_migpuma  $covars $outvars [pw=perwt]  if targetpop==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma ) mat(outmig2)
reghdfe move_migpuma prev_exp_any_migpuma  $covars $outvars [pw=perwt]  if placebo1==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma ) mat(outmig2)

reghdfe move_migpuma prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if targetpop==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma ) mat(outmig2)
reghdfe move_migpuma prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if placebo1==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma ) mat(outmig2)

cap mat drop outmig3
reghdfe move_state prev_exp_any_migpuma  $covars $outvars [pw=perwt]  if targetpop==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar(move_state) indvars(prev_exp_any_migpuma) mat(outmig3)
reghdfe move_state prev_exp_any_migpuma  $covars $outvars [pw=perwt]  if placebo1==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar(move_state) indvars(prev_exp_any_migpuma) mat(outmig3)

reghdfe move_state prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if targetpop==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar(move_state) indvars(prev_exp_any_migpuma) mat(outmig3)
reghdfe move_state prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if placebo1==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar(move_state) indvars(prev_exp_any_migpuma) mat(outmig3)


* Create table
cap file close sumstat
file open sumstat using "$oo/t3_inmigtarget.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n

* in migration
file write sumstat " \multicolumn{5}{c}{Panel A: In migration}  \\" _n
file write sumstat " & & & \multicolumn{2}{c}{Propensity weighting}  \\" _n
file write sumstat " & Targeted & Placebo & Targeted & Placebo \\" _n
file write sumstat " & (1) & (2)  & (3) & (4)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Any move" "Move migpuma" "Move state"  "'
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
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n

* out migration
file write sumstat " \multicolumn{5}{c}{Panel B: Out migration}  \\" _n
file write sumstat " & & & \multicolumn{2}{c}{Propensity weighting}  \\" _n
file write sumstat " & Targeted & Placebo & Targeted & Placebo \\" _n
file write sumstat " & (5) & (6)  & (7) & (8)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Any move" "Move migpuma" "Move state"  "'
forval i = 1/3 {
	local varname : word `i' of $varnames
	forval c = 1/4  {
		local b`c' = string(outmig`i'[1,`c'], "%12.4fc" )
		local p`c' = outmig`i'[2,`c']
		local stars_abs`c' = cond(`p`c'' < 0.01, "***", cond(`p`c'' < 0.05, "**", cond(`p`c'' < 0.1, "*", "")))
		local sd`c' = string(outmig`i'[3,`c'], "%12.4fc" )
		local r`c' = string(outmig`i'[4,`c'], "%12.4fc" )
	}
	file write sumstat " `varname' & `b1'`stars_abs1' & `b2'`stars_abs2' & `b3'`stars_abs3' & `b4'`stars_abs4' \\" _n 
	file write sumstat " \textit{SE} & (`sd1') & (`sd2') & (`sd3') & (`sd4') \\" _n 
	file write sumstat " \textit{R2} & `r1' & `r2' & `r3' & `r4'  \\" _n 
	file write sumstat "\\" _n 
}
file write sumstat "Sample Size "
forval i = 1/4 {
	local n`i' = string(outmig1[6,`i'], "%12.0fc" )
	file write sumstat " & `n`i'' "
}
file write sumstat "\\" _n 
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n

file write sumstat "\end{tabular}"
file close sumstat






/**************************************************************
Table 4: Zooming in
**************************************************************/
use "$oi/acs_w_propensity_weights", clear 
global covars "age i.race i.educ i.speakeng i.hcovany i.school ownhome " 
global invars "exp_any_state SC_any"
global outvars "prev_exp_any_state prev_SC_any"

*in migration
cap mat drop zoom1
reghdfe move_migpuma exp_any_migpuma  $covars $invars [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma $invars  ) mat(zoom1)

reghdfe move_migpuma exp_any_migpuma  $covars $invars [pw=perwt_wt]  if targetpop==1 & prev_exp_any_state==1  , vce(cluster group_id) absorb(geoid year) //previous migpuma was treated
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma $invars  ) mat(zoom1)

reghdfe move_migpuma exp_any_migpuma  $covars $invars [pw=perwt_wt]  if targetpop==1 & prev_exp_any_state==0  , vce(cluster group_id) absorb(geoid year) //previous migpuma was untreated
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma $invars ) mat(zoom1)

reghdfe move_migpuma exp_any_migpuma  $covars $invars [pw=perwt_wt]  if targetpop==1 & inlist(speakeng, 1, 6) , vce(cluster group_id) absorb(geoid year) //does not speak english or speaks english but not well
reg_to_mat, depvar( move_migpuma ) indvars( exp_any_migpuma $invars ) mat(zoom1)


* out migration
cap mat drop zoom2
reghdfe move_migpuma prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if targetpop==1 & year>=2012, vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma $outvars) mat(zoom2)

reghdfe move_migpuma prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if targetpop==1 & year>=2012 & prev_exp_any_state==1,  vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma $outvars) mat(zoom2)

reghdfe move_migpuma prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if targetpop==1 & year>=2012 & prev_exp_any_state==0,  vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma $outvars) mat(zoom2)

reghdfe move_migpuma prev_exp_any_migpuma  $covars $outvars [pw=perwt_wt]  if targetpop==1 & year>=2012 & inlist(speakeng, 1, 6), vce(cluster group_id) absorb(prev_geoid year)
reg_to_mat, depvar( move_migpuma ) indvars( prev_exp_any_migpuma $outvars) mat(zoom2)



* Create table
cap file close sumstat
file open sumstat using "$oo/t4_inout_zooming.tex", write replace
file write sumstat "\begin{tabular}{lcccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n

* in migration
file write sumstat " \multicolumn{5}{c}{Panel A: In migration}  \\" _n
file write sumstat " & Baseline & Treated migpuma t-1 & Untreated migpuma t-1 & Poor English language \\" _n
file write sumstat " & (1) & (2)  & (3) & (4)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Migpuma exposure" "State exposure" "In Secure Community"  "'
* store coverage results
local i = 1
local rowcount = 1
while `rowcount' < 10 {
	local varlab: word `i' of $varnames
	* label
	file write sumstat " `varlab'  "
	storecoeff, mat(zoom1) row(`rowcount') cols(1 2 3 4)
	local rowcount = `rowcount' +3
	local++ i
}
file write sumstat "\\" _n
//store sample size
    forval col = 1/4 {
        local r2_`col' = string(zoom1[16,`col'], "%12.3fc")
        local n_`col' = string(zoom1[18,`col'], "%12.0fc")
    }
file write sumstat "R-2 & `r2_1' & `r2_2' & `r2_3' & `r2_4' \\" _n
file write sumstat "Sample size & `n_1' & `n_2' & `n_3' & `n_4' \\" _n
file write sumstat "\midrule" _n
file write sumstat "\midrule" _n

* out migration
file write sumstat " \multicolumn{5}{c}{Panel B: Out migration}  \\" _n
file write sumstat " & & & \multicolumn{2}{c}{Propensity weighting}  \\" _n
file write sumstat " & Baseline & Treated migpuma t-1 & Untreated migpuma t-1 & Poor English language \\" _n
file write sumstat " & (5) & (6)  & (7) & (8)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Prev Migpuma exposure" "Prev State exposure" "Prev in Secure Community"  "'
* store coverage results
local i = 1
local rowcount = 1
while `rowcount' < 10 {
	local varlab: word `i' of $varnames
	* label
	file write sumstat " `varlab'  "
	storecoeff, mat(zoom2) row(`rowcount') cols(1 2 3 4)
	local rowcount = `rowcount' +3
	local++ i
}
file write sumstat "\\" _n
//store sample size
    forval col = 1/4 {
        local r2_`col' = string(zoom2[10,`col'], "%12.3fc")
        local n_`col' = string(zoom2[12,`col'], "%12.0fc")
    }
file write sumstat "R-2 & `r2_1' & `r2_2' & `r2_3' & `r2_4' \\" _n
file write sumstat "Sample size & `n_1' & `n_2' & `n_3' & `n_4' \\" _n
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
