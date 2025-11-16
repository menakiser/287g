/*---------------------
Mena kiser
10-25-25

Define propensity matched counterfactual
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"
global oo "$wd/output/"


************* FOR CURRENT MIGPUMA
forval i = 1/9 {
	cap log close 
	log using "$oo/logs/prop_matching2013migpuma_t`i'.pdf", replace
	* import ACS data 
	use "$oi/working_acs", clear 

	*define affected population (presumably undocumented) as male, low-skill (High School or less), Hispanic, foreign-born, noncitizens of ages 18-39, and
	keep if year >= 2012
	* drop pumas that lost treatment and those always treated, keeoing only never treated and those that gained exposure
    drop if always_treated_migpuma==1 

	* create county variables that may predict exposure
	gen red_state = inlist(statefip, 1, 2, 4, 5, 13, 16, 20, 21, 22, 28, 29, 30, 31, 38, 40, 45, 46, 47, 48, 49, 54, 56) //https://www.worldatlas.com/articles/states-that-have-voted-republican-in-the-most-consecutive-u-s-presidential-elections.html
	gen total_pop = age>=18 & age<=65
	cap drop ever_treated_migpuma
	bys statefip current_migpuma: egen ever_treated_migpuma = max( exp_any_migpuma>0)
	bys statefip: egen ever_treated_state = max( exp_any_state>0)
	bys statefip : egen ever_treated_migpuma_st = max( exp_any_migpuma>0)
	drop if ever_treated_migpuma_st==0 & ever_treated_state==0
	keep if year == 2012
	gen ishispanic = hispan!=0 & hispan!=2 //hispanic origin of any kind excluding PR
	gen istexas = statefip==48
	gen isflorida = statefip==12
	drop if puma==77777

	collapse (sum) total_pop target_pop=targetpop`i' foreign_pop=imm young_pop=young hispan_pop=ishispanic lowskill_pop=lowskill  ///
		(mean) targetpop_sh=targetpop`i' exp* red_state incwage employed target_sh=targetpop`i' foreign_sh=imm young_sh=young  ///
		hispan_sh=ishispanic lowskill_sh=lowskill istexas isflorida ///
		(max) ever_treated_state ever_treated_migpuma ///
		[pw=perwt] ///
		, by(statefip current_migpuma)
	
	/* get propensity score for county exposure */	
	logit ever_treated_migpuma total_pop target_sh foreign_sh young_sh hispan_sh lowskill_sh red_state istexas ever_treated_state [pw=total_pop]

	//like doing it at the individual level
	cap drop phat
	predict phat
	corr phat ever_treated_migpuma
 

	/* weights to get everyone to look like treated */
	sum phat
	gen wt = 1 if ever_treated_migpuma==1
	replace wt=phat/(1-phat) if ever_treated_migpuma==0

	/* graph the propensity score */
	histogram phat, by(ever_treated_migpuma) kdensity

	kdensity phat if ever_treated_migpuma==1, gen(x_1 d_1)
	label var d_1 "treatment group"
	kdensity phat if ever_treated_migpuma==0, gen(x_0 d_0)
	label var d_0 "control group, unweighted"
	kdensity phat if ever_treated_migpuma==0 [aw=wt], gen(x_0w d_0w)
	label var d_0w "control group, weighted"
	twoway (line d_1 x_1, sort) (line d_0 x_0, sort) (line d_0w x_0w, sort), legend(pos(6))
	graph export "$oo/troubleshoot_propscore/propensity_weights2013migpuma_t`i'.pdf", replace

	/* look at distribution of weights -- sometimes end out putting tons of weight on a few obs */
	summ wt if ever_treated_migpuma==0, d

	keep statefip current_migpuma phat ever_treated_migpuma wt d_1 x_1 d_0 x_0 d_0w x_0w


	compress
	save "$oi/troubleshoot/propensity_weights2013migpuma_t`i'", replace


	log close 
	translate "$oo/logs/prop_matching2013migpuma_t`i'.pdf" "$oo/logs/prop_matching2013migpuma_t`i'.pdf", translator(smcl2pdf) replace
}



/************* BY CURRENT MIGPUMA AND YEAR

cap log close 
log using "$oo/logs/prop_matching2013migpumayear_t1.pdf", replace
* import ACS data 
use "$oi/working_acs", clear 

*define affected population (presumably undocumented) as male, low-skill (High School or less), Hispanic, foreign-born, noncitizens of ages 18-39, and
keep if year >= 2013
drop if puma==77777
* create county variables that may predict exposure
gen red_state = inlist(statefip, 1, 2, 4, 5, 13, 16, 20, 21, 22, 28, 29, 30, 31, 38, 40, 45, 46, 47, 48, 49, 54, 56) //https://www.worldatlas.com/articles/states-that-have-voted-republican-in-the-most-consecutive-u-s-presidential-elections.html
gen total_pop = age>=18 & age<=65
cap drop ever_treated_migpuma
bys statefip current_migpuma: egen ever_treated_migpuma = max( exp_any_migpuma>0)
bys statefip: egen ever_treated_state = max( exp_any_state>0)
//keep if year == 2013
gen ishispanic = hispan!=0 & hispan!=2 //hispanic origin of any kind excluding PR
gen istexas = statefip==48

collapse (sum) total_pop target_pop=targetpop1 foreign_pop=imm young_pop=young hispan_pop=ishispanic lowskill_pop=lowskill  ///
	(mean) targetpop_sh=targetpop1 exp* red_state incwage employed target_sh=targetpop1 foreign_sh=imm young_sh=young  ///
	hispan_sh=ishispanic lowskill_sh=lowskill istexas ///
	(max) ever_treated_state ever_treated_migpuma ///
	[pw=perwt] ///
	, by(statefip current_migpuma year)

/* get propensity score for county exposure */
logit ever_treated_migpuma total_pop target_sh foreign_sh young_sh hispan_sh lowskill_sh istexas ever_treated_state [pw=total_pop]
//like doing it at the individual level
cap drop phat
predict phat

/* weights to get everyone to look like treated */
sum phat
gen wt = 1 if ever_treated_migpuma==1
replace wt=phat/(1-phat) if ever_treated_migpuma==0

/* graph the propensity score */
histogram phat, by(ever_treated_migpuma) kdensity

kdensity phat if ever_treated_migpuma==1, gen(x_1 d_1)
label var d_1 "treatment group"
kdensity phat if ever_treated_migpuma==0, gen(x_0 d_0)
label var d_0 "control group, unweighted"
kdensity phat if ever_treated_migpuma==0 [aw=wt], gen(x_0w d_0w)
label var d_0w "control group, weighted"
twoway (line d_1 x_1, sort) (line d_0 x_0, sort) (line d_0w x_0w, sort) , legend(pos(6))
graph export "$oo/troubleshoot_propscore/propensity_weights2013migpumayear_t1.pdf", replace

/* look at distribution of weights -- sometimes end out putting tons of weight on a few obs */
summ wt if ever_treated_migpuma==0, d

keep statefip current_migpuma phat year ever_treated_migpuma wt d_1 x_1 d_0 x_0 d_0w x_0w

corr phat  ever_treated_migpuma

compress
save "$oi/troubleshoot/propensity_weights2013migpumayear_t1", replace


log close 
translate "$oo/logs/prop_matching2013migpumayear_t1.pdf" "$oo/logs/prop_matching2013migpumayear_t1.pdf", translator(smcl2pdf) replace

