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

//gen focus_sample = sex==1 & lowskill==1 & young==1 
label var exp_any "Non-zero Exposure"
hist exp_any  [fw=perwt] if focus_sample==1 & year>=2011 & year<=2019 & st_exp==1 & exp_any>0, frequency   ysize(6) xsize(6)
sum exp_any [aw=perwt]  if focus_sample==1 & year>=2011 & year<=2019 & st_exp==1

rename (targetpop nottargetpop) (temp1 temp2)
gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig<2007
gen nottargetpop = sex==1 & lowskill==1 & hispan==0 & (bpld<15000 | bpld==90011 | bpld==90021 | citizen==1| citizen==2 ) & young==1

cap drop focus_sample
gen focus_sample = targetpop==1 | nottargetpop==1

****** SUMMARY STATISTICS
cap mat drop sumstat
foreach v in male age exp_any hs move_any move_county move_state married never_married nchild employed wkswork1 uhrswork incwage ownhome rent mortamt1 {
    
    * citizens
    qui reg `v' nottargetpop [pw=perwt] if exp_any==0 & year>=2011 & year<=2019 & st_exp==1, nocons 
    local m1 = _b[nottargetpop]
    qui reg `v' nottargetpop [pw=perwt] if exp_any>0 & year>=2011 & year<=2019 & st_exp==1, nocons 
    local m2 = _b[nottargetpop]

    *non-citizens
    qui reg `v' targetpop [pw=perwt] if exp_any==0 & year>=2011 & year<=2019 & st_exp==1, nocons 
    local m3 = _b[targetpop]
    qui reg `v' targetpop [pw=perwt] if  exp_any>0 & year>=2011 & year<=2019 & st_exp==1, nocons 
    local m4 = _b[targetpop]

    mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4')
}

qui count if nottargetpop==1 & exp_any==0 & year>=2011 & year<=2019 & st_exp==1
local m1 = r(N)
qui count if nottargetpop==1 & exp_any>0 & year>=2011 & year<=2019 & st_exp==1
local m2 = r(N)
qui count if targetpop==1 & exp_any==0 & year>=2011 & year<=2019 & st_exp==1
local m3 = r(N)
qui count if targetpop==1 & exp_any>0 & year>=2011 & year<=2019 & st_exp==1
local m4 = r(N)

mat sumstat = nullmat(sumstat) \ (`m1', `m2', `m3', `m4')


preserve 
fill_tables, mat(sumstat)  save_txt(sumstat) save_excel("$ot/initial_tables")
restore

** parallel trends
* import clean ACS data 
use  "$oi/working_acs", clear 

gen geoid = statefip*1000 + countyfip
gen geoid1 = migplac1*1000 +  migcounty1 if move_county==1

/*
keep if nottargetpop==1
keep if st_exp==1 
bys geoid: egen geoid_treated = max(exp_any>0)
collapse (mean) move_any move_county move_state [pw=perwt], by(geoid_treated year)

twoway (scatter move_any year if targetpop==1 ) ///
(scatter move_any year if nottargetpop==1 )


*/

****** INITIAL REGRESSION
**** 2011-2019		
*2011-2019: In-Migration
gen geoid = statefip*1000 + countyfip //unique county-state group
gen geoid1 = migplac1*1000 +  migcounty1 if move_county==1
replace geoid1 = geoid if move_county==0
gen year1 = year-1

*obtain previous year exposure corresponding to previous county of residence 
preserve 
collapse (first) exp_any1=exp_any exp_jail1=exp_jail exp_task1=exp_task exp_warrant1=exp_warrant, by(geoid year)
rename (geoid year) (geoid1 year1)
tempfile prevexp 
save `prevexp'
restore 
merge m:1 geoid1 year1 using `prevexp', nogen keep(1 3)

* regression 
* in migration
reghdfe move_any exp_any SC_any [pw=perwt] if (targetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid year) absorb(geoid year) 

reghdfe move_county exp_any SC_any [pw=perwt] if (targetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid year) absorb(geoid year) 

reghdfe move_state exp_any SC_any [pw=perwt] if (targetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid year) absorb(geoid year) 


* Out-Migration	
reghdfe move_any exp_any1 SC_any [pw=perwt] if (targetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_county exp_any1 SC_any [pw=perwt] if (targetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_state exp_any1 SC_any [pw=perwt] if (targetpop==1)  & year>=2011 & year<=2019 & st_exp==1 , vce(cluster geoid1 year1) absorb(geoid1 year1) 




*diff in diff
gen exp_anytarget = targetpop*exp_any
* in
reghdfe move_any exp_anytarget exp_any targetpop  SC_any [pw=perwt] if year>=2011 & year<=2019 & st_exp==1 & focus_sample==1, vce(cluster geoid year) absorb(geoid year) 

reghdfe move_county exp_anytarget exp_any targetpop SC_any [pw=perwt] if year>=2011 & year<=2019 & st_exp==1  & focus_sample==1 , vce(cluster geoid year) absorb(geoid year) 

reghdfe move_state exp_anytarget exp_any targetpop SC_any [pw=perwt] if  year>=2011 & year<=2019 & st_exp==1  & focus_sample==1, vce(cluster geoid year) absorb(geoid year) 


* Out-Migration	
gen exp_anytarget1 = targetpop*exp_any1
reghdfe move_any exp_anytarget1 exp_any1 targetpop SC_any [pw=perwt] if year>=2011 & year<=2019 & st_exp==1  & focus_sample==1 , vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_county exp_anytarget1 exp_any1 targetpop SC_any [pw=perwt] if  year>=2011 & year<=2019 & st_exp==1  & focus_sample==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 

reghdfe move_state exp_anytarget1 exp_any1 targetpop SC_any [pw=perwt] if year>=2011 & year<=2019 & st_exp==1  & focus_sample==1, vce(cluster geoid1 year1) absorb(geoid1 year1) 


**** 2014-2019	
*2014-2019: In-Migration	

*2015-2019: Out-Migration	


