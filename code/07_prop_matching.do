/*---------------------
Mena kiser
10-25-25

Define propensity matched counterfactual
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


* import ACS data 
use "$oi/working_acs", clear 

*define affected population (presumably undocumented) as male, low-skill (High School or less), Hispanic, foreign-born, noncitizens of ages 18-39, and
gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 /*born abroad and not a citizen*/ & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3

* create county variables that may predict exposure
gen red_state = inlist(statefip, 1, 2, 4, 5, 13, 16, 20, 21, 22, 28, 29, 30, 31, 38, 40, 45, 46, 47, 48, 49, 54, 56) //https://www.worldatlas.com/articles/states-that-have-voted-republican-in-the-most-consecutive-u-s-presidential-elections.html
gen hprice = rent 
replace hprice = mortamt1 if hprice==0
gen total_pop = age>17 

collapse (sum) total_pop foreign_pop=imm young_pop=young hispan_pop=hispan lowskill_pop=lowskill  ///
	(mean) targetpop_sh=targetpop exp* red_state avg_income=incwage hprice [pw=perwt] ///
	, by(statefip countyfip year)
keep if year>=2013 & year<=2019

/* get propensity score for county exposure */
logit exp_any targetpop_sh lowskill_pop red_state total_pop foreign_pop young_pop avg_income hprice 
cap drop phat
predict phat

/* weights to get everyone to look like treated */
bys statefip countyfip: egen ever_treated = max( exp_any>0)
sum phat
gen wt = phat if ever_treated==1
replace wt=phat/(1-phat) if ever_treated==0

/*weights to get everyone to look like untreated */
gen wt_un = 1 if ever_treated==0
replace wt_un=(1-phat)/phat if ever_treated==1

/*weights to get everyone to look like average */
gen wt_avg = 1/(1-phat) if ever_treated==0
replace wt_avg=1/phat if ever_treated==1

/* means of key controls unweighted and weighted */
tabstat targetpop_sh lowskill_pop red_state total_pop foreign_pop young_pop avg_income hprice , by(ever_treated)
tabstat targetpop_sh lowskill_pop red_state total_pop foreign_pop young_pop avg_income hprice  [aw=wt], by(ever_treated)
tabstat targetpop_sh lowskill_pop red_state total_pop foreign_pop young_pop avg_income hprice [aw=wt_un], by(ever_treated)
tabstat targetpop_sh lowskill_pop red_state total_pop foreign_pop young_pop avg_income hprice [aw=wt_avg], by(ever_treated)

/* graph the propensity score */
histogram phat, by(ever_treated) kdensity

kdensity phat if ever_treated==1, gen(x_1 d_1)
label var d_1 "treatment group"
kdensity phat if ever_treated==0, gen(x_0 d_0)
label var d_0 "control group, unweighted"
kdensity phat if ever_treated==0 [aw=wt], gen(x_0w d_0w)
label var d_0w "control group, weighted"
twoway (line d_1 x_1, sort) (line d_0 x_0, sort) (line d_0w x_0w, sort)

/* look at distribution of weights -- sometimes end out putting tons of weight on a few obs */
summ wt if ever_treated==0, d
summ wt_un if ever_treated==1, d
summ wt_avg, d

keep year statefip countyfip phat ever_treated wt wt_un wt_avg d_1 x_1 d_0 x_0 d_0w x_0w
isid year statefip countyfip

compress
save "$oi/propensity_weights", replace


*run regressions using weights
use "$oi/working_acs", clear 
keep if year >=2013 & year<=2019
merge m:1 year statefip countyfip using  "$oi/propensity_weights" , nogen keep(1 3) keepusing(ever_treated phat wt)

//move_any move_county move_state
/* run survival regressions with & without controls, with & without weighting */
//gen target_exp_any = targetpop*exp_any_cap
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

gen perwt_wt = perwt*wt

save "$oi/acs_w_propensity_weights", replace

