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
    qui reg `v' placebo1 [pw=perwt] if exp_any==0 , nocons 
    local m3 = _b[placebo1]
    qui reg `v' placebo1 [pw=perwt] if exp_any>0 , nocons 
    local m4 = _b[placebo1]

	* propensity score matched
	* targeted population
    qui reg `v' targetpop [pw=perwt_wt] if exp_any==0 , nocons 
    local m5 = _b[targetpop]
    qui reg `v' targetpop [pw=perwt_wt] if  exp_any>0 , nocons 
    local m6 = _b[targetpop]

    * citizens
    qui reg `v' placebo1 [pw=perwt_wt] if exp_any==0 , nocons 
    local m7 = _b[placebo1]
    qui reg `v' placebo1 [pw=perwt_wt] if exp_any>0 , nocons 
    local m8 = _b[placebo1]

    mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4', `m5', `m6', `m7', `m8' )
}

qui count if targetpop==1 & exp_any==0 
local m1 = r(N)
qui count if targetpop==1 & exp_any>0
local m2 = r(N)
qui count if placebo1==1 & exp_any==0
local m3 = r(N)
qui count if placebo1==1 & exp_any>0 
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
reghdfe move_any exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_any) indvars(exp_any ) mat(inmig1)

cap mat drop inmig2
reghdfe move_county exp_any  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any ) mat(inmig2)
reghdfe move_county exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar( move_county ) indvars( exp_any ) mat(inmig2)

cap mat drop inmig3
reghdfe move_state exp_any  [pw=perwt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any) mat(inmig3)
reghdfe move_state exp_any  [pw=perwt_wt]  if targetpop==1 , vce(cluster group_id) absorb(geoid year)
reg_to_mat, depvar(move_state) indvars(exp_any) mat(inmig3)


* Create table
cap file close sumstat
file open sumstat using "$wd/output/t3_inmigtarget.tex", write replace
file write sumstat "\begin{tabular}{lcccccc}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat " & & Propensity Weights  \\" _n
file write sumstat " & (1) & (2)  \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Any move" "Move county" "Move state"  "'
forval i = 1/3 {
	local varname : word `i' of $varnames

	local b = string(inmig`i'[1,1], "%12.4fc" )
	local p = inmig`i'[2,1]
	local stars_abs = cond(`p' < 0.01, "***", cond(`p' < 0.05, "**", cond(`p' < 0.1, "*", "")))
	local sd = string(inmig`i'[3,1], "%12.4fc" )
	local f = string(inmig`i'[7,1], "%12.4fc" )

	local bp = string(inmig`i'[1,2], "%12.4fc" )
	local pp = inmig`i'[2,2]
	local stars_absp = cond(`pp' < 0.01, "***", cond(`pp' < 0.05, "**", cond(`pp' < 0.1, "*", "")))
	local sdp = string(inmig`i'[3,2], "%12.4fc" )
	local fp = string(inmig`i'[7,2], "%12.4fc" )

	file write sumstat " `varname' & `b'`stars_abs' & `bp'`stars_absp' \\" _n 
	file write sumstat " \textit{SE} & (`sd') & (`sdp') \\" _n 
	file write sumstat " \textit{F-stat} & `f' & `fp' \\" _n 
}
local n1 = string(inmig1[6,1], "%12.0fc" )
local n2 = string(inmig1[6,2], "%12.0fc" )
file write sumstat "Sample Size	& `n1' & `n2'  \\" _n 

file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\end{tabular}"
file close sumstat