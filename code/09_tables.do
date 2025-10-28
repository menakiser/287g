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

cap mat drop sumstat
foreach v in male age exp_any hs move_any move_county move_state married never_married nchild employed wkswork1 uhrswork incwage ownhome rent mortamt1 {
    
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
file write sumstat " & Exposure=0 & Exposure>0 & Exposure=0 & Exposure>0 & Exposure=0 & Exposure>0 & Exposure=0 & Exposure>0 \\" _n
file write sumstat " & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\" _n
file write sumstat "\midrule " _n

global varnames `"  "Male" "Age" "Exposure" "High School" "Any move" "Moved county" "Moved state" "Married" "Never married" "Number of children" "Employed" "Weeks worked" "Usual weekly hours worked" "Wage income" "Owns a home" "Rent price" "Mortgage price" "'
forval r = 1/18 {
	local varname : word `r' of $varnamess
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
