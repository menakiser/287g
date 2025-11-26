/*---------------------
Mena kiser
10-19-25

Create exposure level variable matching migration level codes: county and puma
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


use "$oi/working_acs", clear 
keep if year >= 2012
drop if always_treated_puma==1

* define propensity weights
merge m:1 statefip current_puma  using  "$oi/propensity_weights2012puma_t2" , nogen keep(3) keepusing( phat wt)
gen perwt_wt = perwt*wt
drop if mi(perwt_wt)

* Identify populations
*targetpop2
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & young==1  & marst>=3  //hispanic citizens born in the usa
gen pop = age>=18 & age<=65
gen target_movers = move_migpuma*targetpop2
gen spillover1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==1 & citizen!=3 & young==1  & marst>=3 & yrnatur<2012

* Controls
* age
gen age_0_17   = inrange(age, 0, 17)
gen age_18_24  = inrange(age, 18, 24)
gen age_25_34  = inrange(age, 25, 34)
gen age_35_49  = inrange(age, 35, 49)
gen age_50plus = age >= 50
* children
gen has_child = nchild>0 if !mi(nchild)
* citizenship
tab  hispan  , gen(int_hispan)
tab educ , gen(int_educ)
tab marst , gen(int_marst)
tab speakeng , gen(int_speakeng)
tab citizen, gen(int_citizen)
tab yrsusa2, gen(int_yrsusa2)
tab language, gen(int_language)

* Obtain totals
foreach v of varlist targetpop1 targetpop2 targetpop3 targetpop4 targetpop5 targetpop6 placebo1 spillover1 pop move_migpuma target_movers ///
 r_white r_black r_asian hs in_school ownhome no_english employed male has_child ///
 age_0_17 age_18_24 age_25_34 age_35_49 age_50plu ///
 int_hispan* int_educ* int_marst* int_speakeng* int_citizen* int_yrsusa2* int_language1-int_language10  {
	di in red "Processing `v'"
	// define unweighted populations
	rename `v' tot_`v'
}

* Obtain totals FOR HETEROGENEITY
*target
gen tot_target_mexican = tot_targetpop2 & bpl==200 //target mexican
gen tot_target_noenglish = tot_targetpop2 & tot_no_english //target no english
gen tot_target_new = tot_targetpop2 & inlist(yrsusa2 , 1 )  //target new immigrants
gen tot_target_nochild = tot_targetpop2 & nchild==0 //target no children
gen tot_target_nohisp= sex==1 & lowskill==1 & hispan==0 & imm==1 & young==1 & inlist(yrsusa2 , 1)  //target not hispanics
*spillover
gen tot_spill_mexican = tot_spillover1 & bpl==200 //spillover mexican
gen tot_spill_noenglish = tot_spillover1 & tot_no_english //spillover no english
gen tot_spill_new = tot_spillover1 & inlist(yrsusa2 , 1 )  //spillover new immigrants
gen tot_spill_nochild = tot_spillover1 & nchild==0 //spillover no children
gen tot_spill_nohisp= sex==1 & lowskill==1 & hispan==0 & born_abroad==1 & citizen!=3 & young==1  & marst>=3 & yrnatur<2012 //spillover not hispanics
* placebo is a bit different
gen tot_plac_mexican = tot_placebo1 & hispan==1 //placebo mexican
gen tot_plac_noenglish = tot_placebo1 & tot_no_english //placebo no english
//gen tot_plac_new = log_tot_placebo1 & inlist(yrsusa2 , 1 ,2)  //placebo new immigrants -dna
gen tot_plac_nochild = tot_placebo1 & nchild==0 //placebo no children
gen tot_plac_nohisp= sex==1 & lowskill==1 & hispan==0 & born_abroad==0 & young==1  & marst>=3 //placebo not hispanics

* Obtain relative years for gainers and losers
* gainers
gen relative_year_gain =  year - gain_exp_year
replace relative_year_gain = . if gain_exp_year == 0
* losers
gen relative_year_lost =  year - lost_exp_year
replace relative_year_lost = . if lost_exp_year == 0

bys statefip: egen ever_treated_state = max( exp_any_state>0)


* collapse at the puma and year level
collapse (sum) tot_* ///
	(max) exp_any_puma  ever_treated_puma ever_lost_exp_puma ever_gain_exp_puma lost_exp_year gain_exp_year ///
	relative_year_gain relative_year_lost geoid_puma exp_any_state ever_treated_state SC_any trump [pw=perwt] ///
	, by(current_puma statefip year)

* obtain log version of all total and native variables
foreach v of varlist tot_* {
    gen log_`v' = log(`v' + 1)
}

*** Define variables for DID
* define post for DID
gen exp_lost_puma = (year>=lost_exp_year)*(ever_lost_exp_puma==1)
gen exp_gain_puma = (year>=gain_exp_year)*(ever_gain_exp_puma==1)

* event-time indicators
forval n = 1/7 {
	gen gain_ry_plus`n'  = (relative_year_gain == `n')
	gen gain_ry_minus`n' = (relative_year_gain == -`n')
}
* event time = 0
gen gain_ry_plus0 = (relative_year_gain == 0)

* event-time indicators
forval n = 1/7 {
	gen lost_ry_plus`n'  = (relative_year_lost == `n')
	gen lost_ry_minus`n' = (relative_year_lost == -`n')
}
* event time = 0
gen lost_ry_plus0 = (relative_year_lost == 0)

* label years
forval n = 1/7 {
	label var gain_ry_plus`n' "+`n'"
	label var gain_ry_minus`n' "-`n'"
	label var lost_ry_plus`n' "+`n'"
	label var lost_ry_minus`n' "-`n'"
}
label var gain_ry_plus0 "0"
label var lost_ry_plus0 "0"

* save data 
compress 
save "$oi/puma_year_pops", replace


/*
use "$oi/puma_year_pops", clear

gen istexas = statefip==48
gen red_state = inlist(statefip, 1, 2, 4, 5, 13, 16, 20, 21, 22, 28, 29, 30, 31, 38, 40, 45, 46, 47, 48, 49, 54, 56) //https://www.worldatlas.com/articles/states-that-have-voted-republican-in-the-most-consecutive-u-s-presidential-elections.html

keep if year==2012
/* get propensity score for county exposure */	
logit ever_treated_puma log_tot_pop log_tot_age_0_17 log_tot_age_18_24 log_tot_age_25_34 log_tot_age_35_49 log_tot_age_50plus ///
 log_tot_r_white log_tot_r_black log_tot_r_asian ///
 log_tot_hs log_tot_in_school ///
 red_state istexas ever_treated_state /// 
 log_tot_male log_tot_has_child log_tot_ownhome ///
  [pw=tot_targetpop2] 

//like doing it at the individual level
cap drop phat
predict phat
corr phat ever_treated_puma 


/* weights to get everyone to look like treated */
sum phat
gen wt = 1 if ever_treated_puma==1
replace wt=phat/(1-phat) if ever_treated_puma==0
replace wt=1 if ever_treated_puma==0 & wt>1

/* graph the propensity score */
kdensity phat if ever_treated_puma==1 , gen(x_1 d_1)
label var d_1 "treatment group"
kdensity phat if ever_treated_puma==0 , gen(x_0 d_0)
label var d_0 "control group, unweighted"
kdensity phat if ever_treated_puma==0 [aw=wt], gen(x_0w d_0w)
label var d_0w "control group, weighted"
twoway (line d_1 x_1, sort) (line d_0 x_0, sort) (line d_0w x_0w, sort), legend(pos(6) rows(1))
//graph export "$oo/troubleshoot_propscore/propensity_weights2012puma_t2.pdf", replace

/* look at distribution of weights -- sometimes end out putting tons of weight on a few obs */
summ wt if ever_treated_puma==0, d

keep statefip current_puma phat ever_treated_puma wt d_1 x_1 d_0 x_0 d_0w x_0w


compress
save "$oi/propensity_weights2012puma_t2_logtot", replace
*/