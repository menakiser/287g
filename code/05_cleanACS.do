/*---------------------
Mena kiser
10-19-25

Create exposure level variable matching migration level codes: county and puma
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"


* exposure 
 //"$oi/exposure_county_year"


* import ACS data 
use "$or/usa_00048.dta", clear 

**** Sample restrictions
*50 US states and DC
keep if statefip<=56
*Eliminate people living in group quarters (military or convicts): those with the gq variable equal to 0, 3 or 4.
drop if inlist(gq, 0, 3, 4)
*restrict census year 
keep if year>=2011 & year <=2019

**** individual variables
*education levels for internal use, combining educd and higraded
gen inteduc = 0 //left as zero if no answer
replace inteduc = 1 if educ <=5  //less than high school (post1980) or less than grade 12 (pre1980)
replace inteduc = 2 if educ==6 //high school or ged or completed 12th grade (pre1980)
replace inteduc = 3 if educ>=7 & educ <=9 //some college but no degree 
replace inteduc = 3 if educd==65 & year>=2000 //counting some college but less than one year as some college, followinf educreq https://usa.ipums.org/usa/revisions.shtml
replace inteduc = 4 if educ==10 //bachelors or completed 4th year of college
replace inteduc = 5 if educ==11 //over 4 years of college

gen lowskill = inteduc<=2  //high school or less

* identify immigrants
gen born_abroad = bpld>= 15000 & bpld!=90011 & bpld!=90021  & bpld!=90022 
gen imm = born_abroad & citizen==3 //immigrants are defined as born abroad and currently not a citizen 
replace imm = 0 if mi(imm)

* identify young people
gen young = age>=18 & age<=39

*clean income variables
replace incwage=. if incwage==999999 | incwage==0 

* other ind vars 
gen male = sex==1 
gen hs = inteduc == 2
gen married = inlist(marst, 1, 2)
gen never_married = inlist(marst, 6)
gen ownhome = ownershp==1
gen employed = empstat==1

********************************************************
**** location variables: obtaining current migpuma
*********************************************************
gen puma00 = puma if year<2012
//state 22
merge m:1 statefip puma00 using "$oi/xwalk/puma00_puma10"  , nogen keep(1 3) //louisiana 77777 no matches due to katrina

replace puma10 = puma if year>=2012
merge m:1 statefip puma10 using "$oi/xwalk/puma10_migpuma10" , nogen keep(1 3)
rename (puma10 ) ( current_puma  ) 

********************************************************
**** obtain exposure variables at the migpuma level for CURRENT year
*********************************************************
* county
merge m:1 statefip countyfip year using "$oi/exposure_county_year" , keepusing(exp_any_county exp_jail_county exp_task_county exp_warrant_county) nogen keep(1 3) 
foreach v in exp_any_county exp_jail_county exp_task_county exp_warrant_county {
	replace `v' = 0 if mi(`v')
}

*migpuma
merge m:1 statefip migpuma10 year using "$oi/exposure_migpuma10_year" , keepusing(exp_any_migpuma exp_jail_migpuma exp_task_migpuma exp_warrant_migpuma) nogen keep(1 3) //all 2012-2020 match
foreach v in exp_any_migpuma exp_jail_migpuma exp_task_migpuma exp_warrant_migpuma {
	replace `v' = 0 if mi(`v')
}
rename migpuma10 current_migpuma

* state
merge m:1 statefip year using "$oi/exposure_state_year" , nogen keep(1 3) keepusing(exp_any_state exp_jail_state exp_task_state exp_warrant_state)
foreach v in exp_any_state exp_jail_state exp_task_state exp_warrant_state {
	replace `v' = 0 if mi(`v')
}

*****define mobility variables
gen move_any = migrate1>1
replace migplac1 = statefip if migrate1d<=24 //fill in current year state if they didn't move states
replace migcounty1 = countyfip if migcounty1==0 //fill in current county if they didn't move counties
replace migpuma1 = current_migpuma if migpuma1==0 //fill in current migpuma if they didn't move migpumas, note migpuma==1 lived abroad, migpuma==2 lived in PR but currently in US

gen move_county = migcounty1 != countyfip & migrate1d>10
gen move_migpuma = migpuma1 != current_migpuma & migrate1d>=24 //verify this
gen move_state = migplac1 != statefip  & migrate1d>24
gen move_abroad = migpuma1==1 // move from outside of the US

**** obtain exposure from the previous year
* rename vars from previous year for merge
rename statefip current_statefip
rename (migplac1 migpuma1) (statefip migpuma10)
gen current_year = year
replace year = current_year -1 

********************************************************
**** obtain exposure variables at the migpuma level for previous year
*********************************************************
*county
foreach v in exp_any_county exp_jail_county exp_task_county exp_warrant_county {
	rename `v' current_`v'
}
merge m:1 statefip countyfip year using "$oi/exposure_county_year" , nogen keep(1 3) keepusing(exp_any_county exp_jail_county exp_task_county exp_warrant_county)
foreach v in exp_any_county exp_jail_county exp_task_county exp_warrant_county {
	replace `v' = 0 if mi(`v')
	rename `v' prev_`v'
	rename current_`v'  `v'
}


*migpuma
foreach v in exp_any_migpuma exp_jail_migpuma exp_task_migpuma exp_warrant_migpuma {
	rename `v' current_`v'
}
merge m:1 statefip migpuma10 year using "$oi/exposure_migpuma10_year" , nogen keep(1 3) keepusing(exp_any_migpuma exp_jail_migpuma exp_task_migpuma exp_warrant_migpuma)
foreach v in exp_any_migpuma exp_jail_migpuma exp_task_migpuma exp_warrant_migpuma {
	replace `v' = 0 if mi(`v')
	rename `v' prev_`v'
	rename current_`v'  `v'
}
rename migpuma10 prev_migpuma

*state 
foreach v in exp_any_state exp_jail_state exp_task_state exp_warrant_state {
	rename `v' current_`v'
}
merge m:1 statefip year using "$oi/exposure_state_year" , nogen keep(1 3) keepusing(exp_any_state exp_jail_state exp_task_state exp_warrant_state)
foreach v in exp_any_state exp_jail_state exp_task_state exp_warrant_state {
	replace `v' = 0 if mi(`v')
	rename `v' prev_`v'
	rename current_`v'  `v'
}
rename (statefip migcounty1 ) (prev_statefip prev_county) 
rename current_statefip statefip
replace year = current_year

* add list of secure communities
rename (current_migpuma ) (migpuma10 )
merge m:1 migpuma10 statefip year using "$oi/migpuma10_SC" , nogen keep( 1 3) 
replace SC= 0 if mi(SC)
replace SC_any = 1 if year==2013 | year==2014
replace SC_any = 0 if year>=2015
rename  (migpuma10 ) (current_migpuma )
bys statefip current_migpuma year: ereplace SC_any = max(SC_any)
rename SC_any current_SC_any

* add list of secure communities of previous year
rename   statefip current_statefip
rename (prev_migpuma prev_statefip) (migpuma10 statefip)
replace year = current_year - 1
merge m:1 migpuma10 statefip year using "$oi/migpuma10_SC" , nogen keep( 1 3) 
rename (migpuma10 statefip) (prev_migpuma prev_statefip) 
rename current_statefip statefip

replace SC_any= 0 if mi(SC_any)
replace SC_any = 1 if year==2013 | year==2014
replace SC_any = 0 if year>=2015
bys prev_statefip prev_migpuma year: ereplace SC_any = max(SC_any)

replace year = current_year
rename SC_any prev_SC_any
rename current_SC_any SC_any


/* restrictions to remember
drop if puma== 77777 //louisiana katrina
drop if countyfip==000 //not identifiable
*/


//DACA requirements
//entered pre 2007
gen yr_enterus = year-yrsusa1
replace yr_enterus = . if bpl<100  //Don't want this for native born
gen enterpre2007 = yr_enterus<=2007
// requirement: younger than 31 on June 15, 2012
gen agejun12q = 2012-birthyr //years minus quarters before born in birth year plus first two quarters of 2012. 
gen in2012_over31 = agejun12q>=31
gen in2012_under31 = agejun12q <31
// requirement: younger than 16 when entered
gen entage = age - yrsusa1
replace entage = 0 if entage == -1 // possible missinterpretation of the questionaire
gen enterunder16 = entage<16
// requirement: education
gen reqedu = 0 if educd < 62 & school == 1
replace reqedu = 1 if educd >= 62 | school == 2
la var reqedu "Meets education requirement"
la def reqedu 0 "No" 1 "Yes, in school or GED or higher attained"
la val reqedu

gen daca = in2012_under31 == 1 & enterpre2007 == 1 & reqedu == 1 & citizen == 3 & enterunder16==1
drop yr_enterus enterpre2007 agejun12q in2012_over31 in2012_under31 entage enterunder16 reqedu


* define targetpop
cap drop targetpop*
gen targetpop1 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & daca==0 & /*yrimmig>2007 &*/ inlist(yrsusa2 , 1) //hispanic, young, <10 yrs in the country
gen targetpop2 = targetpop1==1 & marst>=3
gen targetpop3 = targetpop1==1 & marst>=3 & nchild==0 
gen targetpop4 = targetpop1==1 & bpl==200 //mexican, young, <10 yrs in the country
gen targetpop5 = targetpop4==1 & marst>=3
gen targetpop6 = targetpop4==1 & marst>=3 & nchild==0 
gen targetpop7 = targetpop1==1 & bpl!=200 //non-mexican hispanic, young, <10 yrs in the country
gen targetpop8 = targetpop7==1 & marst>=3
gen targetpop9 = targetpop7==1 & marst>=3 & nchild==0 

label var targetpop1 "hispanic immigrants"
label var targetpop2 "hispanic immigrants unmarried"
label var targetpop3 "hispanic immigrants unmarried, no kids"
label var targetpop4 "mexican immigrants"
label var targetpop5 "mexican immigrants unmarried"
label var targetpop6 "mexican immigrants unmarried, no kids"
label var targetpop7 "hispanic non-mexican immigrants"
label var targetpop8 "hispanic non-mexican immigrants unmarried"
label var targetpop9 "hispanic non-mexican immigrants unmarried, no kids"

*define placebo
cap drop placebo*
gen placebo1 = sex==1 & lowskill==1 & hispan!=0 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 //hispanic citizens born in the usa, 113,260, n 
gen placebo2 = sex==1 & lowskill==1 & hispan==0 & imm==1 & young==1 & daca==0 & inlist(yrsusa2 , 1) & marst>=3 //same as target but not hispanic, 9,316, p
gen placebo3 = sex==1 & lowskill==1 & hispan==0 & born_abroad==1 & citizen!=3 & young==1 & daca==0 & inlist(yrsusa2 , 1) & marst>=3 & nchild==0 //non-hispanic citizen (born to american parents, naturalized citizen) born abroad,  2,731 n
gen placebo4 = sex==1 & lowskill==1 & hispan==0 & born_abroad==0 & citizen!=3 & young==1  & marst>=3  //non-hispanic citizens born in the usa,  532,596 n
gen placebo5 = sex==1 & lowskill==1 & hispan==0 & race==1 & born_abroad==0 & citizen!=3 & young==1  & marst>=3 //non-hispanic white citizens born in the usa,  400,003 n

label var placebo1 "hispanic citizen US born"
label var placebo2 "non-hispanic target"
label var placebo3 "non-hispanic citizen"
label var placebo4 "non-hispanic citizen US born"
label var placebo5 "non-hispanic white citizen US born"


gen prev_year = year-1

* define FE and SE for county
gen geoid_county = statefip*1000 + countyfip //unique county-state group
gen prev_geoid_county = prev_statefip*1000 +  countyfip if move_county==1
replace prev_geoid_county = geoid if move_county==0

egen group_id_county = group(geoid_county year) 
egen group_id1_county = group(prev_geoid_county prev_year)


* define FE and SE for migpuma
gen geoid_migpuma = statefip*100000 + current_migpuma //unique county-state group
gen prev_geoid_migpuma = prev_statefip*100000 +  prev_migpuma if move_migpuma==1
replace prev_geoid_migpuma = geoid_migpuma if move_migpuma==0

egen group_id_migpuma = group(geoid_migpuma year) 
egen group_id1_migpuma = group(prev_geoid_migpuma prev_year)

**************************************************
* Identify migpumas that lose treatment
**************************************************

* drop years and puma's we don't need
keep if year>=2012
drop if puma==77777

/*
preserve
bys statefip current_migpuma: egen ever_treated_migpuma = max( exp_any_migpuma>0)
collapse (mean) exp_any_migpuma ever_treated_migpuma, by(statefip current_migpuma year)
gen lost_treatment_migpuma = 0
bys statefip current_migpuma (year): replace lost_treatment_migpuma = 1 if ever_treated_migpuma==1 & exp_any_migpuma[_n-1]==1 & exp_any_migpuma==0
bys statefip current_migpuma year: ereplace lost_treatment_migpuma = max(lost_treatment_migpuma)

* get year of treatment 
gen event_year_migpuma = year if exp_any_migpuma==1
* Get the year of loss
bys statefip current_migpuma (year): egen year_lost_migpuma = min(cond(lost_treatment_migpuma==1, year, .))

* transform to state and migpuma
collapse (max) lost_treatment_migpuma ever_treated_migpuma year_lost_migpuma (sum) treat_length_migpuma = exp_any_migpuma (min) event_year_migpuma, by(statefip current_migpuma) 
* save for migpuma
tempfile losttreat 
save `losttreat'

* save for previous migpuma
foreach v in  lost_treatment_migpuma ever_treated_migpuma year_lost_migpuma treat_length_migpuma statefip event_year_migpuma {
	rename `v' prev_`v'
}
rename current_migpuma prev_migpuma
tempfile prev_losttreat 
save `prev_losttreat'

restore 

merge m:1 statefip current_migpuma using `losttreat', nogen keep(1 3)
merge m:1 prev_statefip prev_migpuma using `prev_losttreat', nogen keep(1 3) //missing if living abroad

foreach v in prev_lost_treatment_migpuma prev_ever_treated_migpuma prev_year_lost_migpuma prev_treat_length_migpuma prev_event_year_migpuma {
	replace `v' = 0 if mi(`v')
}
*/


* Create covariates
gen r_white = race==1
gen r_black = race==2
gen r_asian = inlist(race, 4, 6)
gen in_school = school==2
gen no_english = inlist(speakeng, 1, 6)


rename current_puma puma10
merge m:1 puma10 statefip year using  "$oi/exposure_puma10_year", nogen keep(1 3) keepusing(exp_any*)
rename puma10 current_puma
replace exp_any_puma = 0 if mi(exp_any_puma)

compress 
save "$oi/working_acs", replace

bys statefip current_puma: egen ever_treated_puma = max( exp_any_puma==1)

//bys statefip current_puma: egen ever_treated_migpuma = max( exp_any_migpuma==1)