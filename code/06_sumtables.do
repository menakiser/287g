/*---------------------
Mena kiser
10-19-25

Create exposure level variable matching migration level codes: county and puma
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"
global ot "$wd/output"

* import clean ACS data 
use  "$oi/working_acs", clear 



****** SUMMARY STATISTICS
cap mat drop sumstat
foreach v in male age exp_any hs move_any move_county move_state married never_married nchild employed wkswork1 uhrswork incwage ownhome rent mortamt1 {
    
    * citizens
    qui sum `v' [aw=perwt] if nottargetpop==1 & exp_any==0 & year>=2011 & year<=2019 & st_exp==1
    local m1 = r(mean)
    qui sum `v' [aw=perwt]  if nottargetpop==1 & exp_any>0 & year>=2011 & year<=2019 & st_exp==1
    local m2 = r(mean)

    *non-citizens
    qui sum `v' [aw=perwt]  if targetpop==1 & exp_any==0 & year>=2011 & year<=2019 & st_exp==1
    local m3 = r(mean)
    qui sum `v' [aw=perwt]  if targetpop==1 & exp_any>0 & year>=2011 & year<=2019 & st_exp==1
    local m4 = r(mean)

    mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4')
}

qui sum male [aw=perwt] if nottargetpop==1 & exp_any==0 & year>=2011 & year<=2019 & st_exp==1
local m1 = r(N)
qui sum male [aw=perwt] if nottargetpop==1 & exp_any>0 & year>=2011 & year<=2019 & st_exp==1
local m2 = r(N)
qui sum male [aw=perwt] if targetpop==1 & exp_any==0 & year>=2011 & year<=2019 & st_exp==1
local m3 = r(N)
qui sum male [aw=perwt] if targetpop==1 & exp_any>0 & year>=2011 & year<=2019 & st_exp==1
local m4 = r(N)

mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4')


preserve 
fill_tables, mat(sumstat)  save_txt(sumstat) save_excel("$ot/initial_tables")
restore

** parallel trends
* import clean ACS data 
use  "$oi/working_acs", clear 

cap gen nottargetpop = sex==1 & lowskill==1 & hispan==1 & (bpld<=1500 | bpld==90011 | bpld==90021) & young==1
cap gen employed = empstat==1
replace exp_any = 1 if exp_any>1
gen move_any = migrate1>1

replace migplac1 = statefip if migrate1d<=24 //fill in current year state if they didn't move states
replace migcounty1 = countyfip if migrate1d<=10 //fill in current county if they didn't move counties

gen move_county = migcounty1 != countyfip & migrate1d>10
gen move_state = migplac1 != statefip  & migrate1d>24


gen geoid = statefip*1000 + countyfip
gen geoid1 = migplac1*1000 +  migcounty1 if move_county==1

bys geoid: egen geoid_treated = max(exp_any>0)
collapse (mean) move_any move_county move_state, by(targetpop nottargetpop year)

drop if targetpop==0 & nottargetpop==0 
twoway (scatter move_any year if targetpop==1 ) ///
(scatter move_any year if nottargetpop==1 )

bys year targetpop: egen avgmove = mean(move_any)


****** INITIAL REGRESSION
**** 2011-2019		
*2011-2019: In-Migration
gen exp_anytarget = exp_any*targetpop

reghdfe move_county exp_any SC_any [aw=perwt] if (targetpop==1 | nottargetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid year) absorb(statefip year statefip##year) 

reghdfe move_county targetpop exp_any SC_any [aw=perwt] if (targetpop==1 | nottargetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid year) absorb(statefip year statefip##year) 

reghdfe move_county targetpop exp_any exp_anytarget SC_any [aw=perwt] if (targetpop==1 | nottargetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid year) absorb(statefip year statefip##year) 

*2012-2019: Out-Migration	



**** 2014-2019	
*2014-2019: In-Migration	

*2015-2019: Out-Migration	


