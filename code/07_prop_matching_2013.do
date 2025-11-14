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

forval i = 1/9 {
	cap log close 
	log using "$oo/logs/prop_matching2013_t`i'.pdf", replace
	* import ACS data 
	use "$oi/working_acs", clear 

	*define affected population (presumably undocumented) as male, low-skill (High School or less), Hispanic, foreign-born, noncitizens of ages 18-39, and
	keep if year >= 2013
	* create county variables that may predict exposure
	gen red_state = inlist(statefip, 1, 2, 4, 5, 13, 16, 20, 21, 22, 28, 29, 30, 31, 38, 40, 45, 46, 47, 48, 49, 54, 56) //https://www.worldatlas.com/articles/states-that-have-voted-republican-in-the-most-consecutive-u-s-presidential-elections.html
	gen total_pop = age>=18 & age<=65
	bys statefip countyfip: egen ever_treated_county = max( exp_any_county>0)
	bys statefip: egen ever_treated_state = max( exp_any_state>0)
	keep if year == 2013
	gen ishispanic = hispan!=0 & hispan!=2 //hispanic origin of any kind excluding PR
	gen istexas = statefip==48

	collapse (sum) total_pop target_pop=targetpop`i' foreign_pop=imm young_pop=young hispan_pop=ishispanic lowskill_pop=lowskill  ///
		(mean) targetpop_sh=targetpop`i' exp* red_state incwage employed target_sh=targetpop`i' foreign_sh=imm young_sh=young  ///
		hispan_sh=ishispanic lowskill_sh=lowskill istexas ///
		(max) ever_treated_state ever_treated_county ///
		[pw=perwt] ///
		, by(statefip countyfip)
drop if countyfip==000
	/* get propensity score for county exposure */
	logit ever_treated_county total_pop target_sh foreign_sh young_sh hispan_sh lowskill_sh istexas ever_treated_state [pw=total_pop]
	//like doing it at the individual level
	cap drop phat
	predict phat

	/* weights to get everyone to look like treated */
	sum phat
	gen wt = phat if ever_treated_county==1
	replace wt=phat/(1-phat) if ever_treated_county==0

	/* graph the propensity score */
	histogram phat, by(ever_treated_county) kdensity

	kdensity phat if ever_treated_county==1, gen(x_1 d_1)
	label var d_1 "treatment group"
	kdensity phat if ever_treated_county==0, gen(x_0 d_0)
	label var d_0 "control group, unweighted"
	kdensity phat if ever_treated_county==0 [aw=wt], gen(x_0w d_0w)
	label var d_0w "control group, weighted"
	twoway (line d_1 x_1, sort) (line d_0 x_0, sort) (line d_0w x_0w, sort)

	/* look at distribution of weights -- sometimes end out putting tons of weight on a few obs */
	summ wt if ever_treated_county==0, d

	keep statefip countyfip phat ever_treated_county wt d_1 x_1 d_0 x_0 d_0w x_0w

	compress
	save "$oi/troubleshoot/propensity_weights2013_t`i'", replace


	log close 
	translate "$oo/logs/prop_matching2013_t`i'.pdf" "$oo/logs/prop_matching2013_t`i'.pdf", translator(smcl2pdf) replace

}

/*run regressions using weights
use "$oi/working_acs", clear 
merge m:1 statefip current_migpuma using  "$oi/propensity_weights" , nogen keep(1 3) keepusing(ever_treated_migpuma phat wt)

//move_any move_county move_state
/* run survival regressions with & without controls, with & without weighting */
//gen target_exp_any = targetpop*exp_any_cap
gen geoid = statefip*100000 + current_migpuma //unique county-state group
gen prev_geoid = prev_statefip*100000 +  prev_migpuma if move_migpuma==1
replace prev_geoid = geoid if move_migpuma==0
gen prev_year = year-1
gen perwt_wt = perwt*wt

* create exposure
gen targetpop = sex==1 & lowskill==1 & bpl==200 & imm==1 /*born abroad and not a citizen*/ & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0

* Identify counties that lose treatment
preserve
collapse (mean) exp_any_migpuma ever_treated_migpuma, by(statefip current_migpuma year)
gen lost_treatment_migpuma = 0
bys statefip current_migpuma (year): replace lost_treatment_migpuma = 1 if ever_treated_migpuma==1 & exp_any_migpuma[_n-1]==1 & exp_any_migpuma==0
bys statefip current_migpuma year: ereplace lost_treatment_migpuma = max(lost_treatment_migpuma)
* Get the year of loss
bys statefip current_migpuma (year): egen year_lost_migpuma = min(cond(lost_treatment_migpuma==1, year, .))
collapse (max) lost_treatment_migpuma ever_treated_migpuma year_lost_migpuma (sum) treat_length = exp_any_migpuma, by(statefip current_migpuma) 
tempfile losttreat 
save `losttreat'
/* info
21% of ever treated counties lose treatment at some point -- 15/74
*/
restore
merge m:1 statefip current_migpuma using `losttreat', nogen keep(1 3)





global covars "age i.race i.educ i.speakeng i.hcovany i.school ownhome" 

/*define placebos
cap drop placebo*
//gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & bpl!=200 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 & nchild==0 //hispanic citizens born in the usa, 113,260, n 
gen placebo2 = sex==1 & lowskill==1 & hispan==0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 //same as target but not hispanic, 9,316, p
gen placebo3 = sex==1 & lowskill==1 & hispan==0 & born_abroad==1 & citizen!=3 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) & marst>=3 & nchild==0 //non-hispanic citizen (born to american parents, naturalized citizen) born abroad,  2,731 n
gen placebo4 = sex==1 & lowskill==1 & hispan==0 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 & nchild==0 //non-hispanic citizens born in the usa,  532,596 n
gen placebo5 = sex==1 & lowskill==1 & hispan==0 & race==1 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 & nchild==0 //non-hispanic white citizens born in the usa,  400,003 n

label var placebo1 "hispanic citizen US born"
label var placebo2 "non-hispanic target"
label var placebo3 "non-hispanic citizen"
label var placebo4 "non-hispanic citizen US born"
label var placebo5 "non-hispanic white citizen US born"
*/

compress
save "$oi/acs_w_propensity_weights", replace

*/