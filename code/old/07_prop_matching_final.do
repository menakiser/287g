/*---------------------
Mena kiser
10-25-25

Define propensity matching for untreated migpumas to resemble treated migpumas
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"
global oo "$wd/output/"



cap log close 
log using "$oo/logs/prop_matching2012migpuma_t2.pdf", replace

* import ACS data 
use "$oi/working_acs", clear 

*define affected population (presumably undocumented) as male, low-skill (High School or less), Hispanic, foreign-born, noncitizens of ages 18-39, and
keep if year >= 2013
* drop pumas that lost treatment and those always treated, keeoing only never treated and those that gained exposure
//drop if always_treated_migpuma==1 

* create county variables that may predict exposure
gen red_state = inlist(statefip, 1, 2, 4, 5, 13, 16, 20, 21, 22, 28, 29, 30, 31, 38, 40, 45, 46, 47, 48, 49, 54, 56) //https://www.worldatlas.com/articles/states-that-have-voted-republican-in-the-most-consecutive-u-s-presidential-elections.html
gen total_pop = age>=18 & age<=65
cap drop ever_treated_migpuma
bys statefip current_migpuma: egen ever_treated_migpuma = max( exp_any_migpuma>0)
bys statefip: egen ever_treated_state = max( exp_any_state>0)
bys statefip : egen ever_treated_migpuma_st = max( exp_any_migpuma>0)
drop if ever_treated_migpuma_st==0 & ever_treated_state==0
keep if year == 2013
gen ishispanic = hispan!=0 & hispan!=2 //hispanic origin of any kind excluding PR
gen istexas = statefip==48
gen isflorida = statefip==12
drop if puma==77777

* hispan ethnicity
tab  hispan  , gen(int_hispan)
tab educ , gen(int_educ)
tab marst , gen(int_marst)
tab speakeng , gen(int_speakeng)
tab citizen, gen(int_citizen)
tab yrsusa2, gen(int_yrsusa2)
tab language, gen(int_language)
tab  hispand  , gen(int_dhispan)
gen has_child = nchild>0

collapse (sum) total_pop total_targetpop1=targetpop1 total_targetpop2=targetpop2  ///
	(mean) exp* red_state incwage employed target_sh1=targetpop1 target_sh2=targetpop2 foreign_sh=imm young_sh=young  ///
	r_white r_black r_asian int_citizen* int_language* int_yrsusa2* int_hispan* int_dhispan* ///
	int_educ* hs nchild int_marst* no_english int_speakeng* in_school ///
	lowskill_sh=lowskill istexas isflorida   ///
	has_child famsize nchlt5 eldch yngch ///
	trantime departs arrives ///
	(max) ever_treated_state ever_treated_migpuma  ///
	[pw=perwt] ///
	, by(statefip current_migpuma)

/* get propensity score for county exposure */	
logit ever_treated_migpuma total_pop target_sh1 foreign_sh young_sh int_yrsusa2* lowskill_sh red_state istexas isflorida ever_treated_state ///
	r_white r_black r_asian int_citizen2-int_citizen4 int_dhispan* int_educ* int_marst* in_school no_english ///
	has_child famsize nchild  [pw=total_targetpop1]

//like doing it at the individual level
cap drop phat
predict phat
corr phat ever_treated_migpuma


/* weights to get everyone to look like treated */
sum phat
gen wt = 1 if ever_treated_migpuma==1
replace wt=phat/(1-phat) if ever_treated_migpuma==0
replace wt=1 if ever_treated_migpuma==0 & wt>1

/* graph the propensity score */
kdensity phat if ever_treated_migpuma==1 , gen(x_1 d_1)
label var d_1 "treatment group"
kdensity phat if ever_treated_migpuma==0 , gen(x_0 d_0)
label var d_0 "control group, unweighted"
kdensity phat if ever_treated_migpuma==0 [aw=wt], gen(x_0w d_0w)
label var d_0w "control group, weighted"
twoway (line d_1 x_1, sort) (line d_0 x_0, sort) (line d_0w x_0w, sort), legend(pos(6) rows(1))
//graph export "$oo/troubleshoot_propscore/propensity_weights2012migpuma_t2.pdf", replace

/* look at distribution of weights -- sometimes end out putting tons of weight on a few obs */
summ wt if ever_treated_migpuma==0, d

keep statefip current_migpuma phat ever_treated_migpuma wt d_1 x_1 d_0 x_0 d_0w x_0w


compress
save "$oi/propensity_weights2012migpuma_t2", replace


log close 
translate "$oo/logs/prop_matching2012migpuma_t2.pdf" "$oo/logs/prop_matching2012migpuma_t2.pdf", translator(smcl2pdf) replace