/*---------------------
Mena kiser
10-25-25

Tables in research proposal
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


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
file open sumstat using "$wd/output/t1_retrievals.tex", write replace
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



/**************************************************************
Table 2: Summary Statistics
**************************************************************/

* import clean ACS data ready for regressions
use "$oi/acs_w_propensity_weights", clear 
gen rentprice = rent if ownhome==0
gen mortprice = mortamt1 if ownhome==1
cap mat drop sumstat
foreach v in male age exp_any hs move_any move_county move_state married never_married nchild employed wkswork1 uhrswork incwage ownhome rentprice mortprice {
    
    * targeted population
    qui reg `v' targetpop [pw=perwt] if exp_any==0 , nocons 
    local m1 = _b[targetpop]
    qui reg `v' targetpop [pw=perwt] if  exp_any>0 , nocons 
    local m2 = _b[targetpop]

    * citizens
    qui reg `v' placebo5 [pw=perwt] if exp_any==0 , nocons 
    local m3 = _b[placebo5]
    qui reg `v' placebo5 [pw=perwt] if exp_any>0 , nocons 
    local m4 = _b[placebo5]

	* propensity score matched
	* targeted population
    qui reg `v' targetpop [pw=perwt_wt] if exp_any==0 , nocons 
    local m5 = _b[targetpop]
    qui reg `v' targetpop [pw=perwt_wt] if  exp_any>0 , nocons 
    local m6 = _b[targetpop]

    * citizens
    qui reg `v' placebo5 [pw=perwt_wt] if exp_any==0 , nocons 
    local m7 = _b[placebo5]
    qui reg `v' placebo5 [pw=perwt_wt] if exp_any>0 , nocons 
    local m8 = _b[placebo5]

    mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4', `m5', `m6', `m7', `m8' )
}

qui count if targetpop==1 & exp_any==0 
local m1 = r(N)
qui count if targetpop==1 & exp_any>0
local m2 = r(N)
qui count if placebo5==1 & exp_any==0
local m3 = r(N)
qui count if placebo5==1 & exp_any>0 
local m4 = r(N)

mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4', `m1', `m2', `m3', `m4')


* Create table
cap file close sumstat
file open sumstat using "$wd/output/t2_sumstat.tex", write replace
file write sumstat "\begin{tabular}{lcccccccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & & & & & \multicolumn{4}{c}{Propensity score weighting} \\" _n
file write sumstat " & \multicolumn{2}{c}{Targeted population} & \multicolumn{2}{c}{Hispanic citizens} & \multicolumn{2}{c}{Targeted population} & \multicolumn{2}{c}{Hispanic citizens}  \\" _n
file write sumstat " & Exposure=0 & Exposure$>$0 & Exposure=0 & Exposure$>$0 & Exposure=0 & Exposure$>$0 & Exposure=0 & Exposure$>$0 \\" _n
file write sumstat " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Male" "Age" "Exposure" "High School" "Any move" "Moved county" "Moved state" "Married" "Never married" "Number of children" "Employed" "Weeks worked" "Usual weekly hours worked" "Wage income" "Owns a home" "Rent price" "Mortgage price" "Sample size" "'
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

