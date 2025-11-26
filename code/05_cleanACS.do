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
keep if year>=2012 & year <=2019

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
gen puma10 = puma 
merge m:1 statefip puma10 using "$oi/xwalk/puma10_migpuma10" , nogen keep(1 3)
rename migpuma10 current_migpuma

********************************************************
**** obtain exposure variables at the PUMA level for CURRENT year
*********************************************************

*puma
merge m:1 statefip puma10 year using "$oi/exposure_puma10_year" , keepusing(exp_any_puma exp_jail_puma exp_task_puma exp_warrant_puma) nogen keep(1 3) //all 2012-2020 match
foreach v in exp_any_puma exp_jail_puma exp_task_puma exp_warrant_puma {
	replace `v' = 0 if mi(`v')
}
rename (puma10 ) ( current_puma  ) 
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

********************************************************
**** obtain Secure communities
*********************************************************

* add list of secure communities
rename (current_puma ) (puma10 )
merge m:1 puma10 statefip year using "$oi/puma10_SC" , nogen keep( 1 3) 
replace SC= 0 if mi(SC)
replace SC_any = 1 if year==2013 | year==2014
replace SC_any = 0 if year>=2015
rename  (puma10 ) (current_puma )
bys statefip current_puma year: ereplace SC_any = max(SC_any)


********************************************************
**** obtain define targetpop
*********************************************************

* define targetpop
cap drop targetpop*
gen targetpop1 = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007 & inlist(yrsusa2 , 1 ,2) //hispanic, young, <10 yrs in the country
gen targetpop2 = targetpop1==1 & marst>=3
gen targetpop3 = targetpop1==1 & marst>=3 & nchild==0 
/*gen targetpop4 = targetpop1==1 & bpl==200 //mexican, young, <10 yrs in the country
gen targetpop5 = targetpop4==1 & marst>=3
gen targetpop6 = targetpop4==1 & marst>=3 & nchild==0 
gen targetpop7 = targetpop1==1 & bpl!=200 //non-mexican hispanic, young, <10 yrs in the country
gen targetpop8 = targetpop7==1 & marst>=3
gen targetpop9 = targetpop7==1 & marst>=3 & nchild==0 */

label var targetpop1 "hispanic immigrants"
label var targetpop2 "hispanic immigrants unmarried"
label var targetpop3 "hispanic immigrants unmarried, no kids"
/*label var targetpop4 "mexican immigrants"
label var targetpop5 "mexican immigrants unmarried"
label var targetpop6 "mexican immigrants unmarried, no kids"
label var targetpop7 "hispanic non-mexican immigrants"
label var targetpop8 "hispanic non-mexican immigrants unmarried"
label var targetpop9 "hispanic non-mexican immigrants unmarried, no kids"
*/

* define FE and SE for PUMA
gen geoid_puma = statefip*100000 + current_puma //unique county-state group
egen group_id_puma = group(geoid_puma year) 

**************************************************
* Final restrictions
**************************************************

* drop years and puma's we don't need
keep if year>=2012
drop if puma==77777


* Create covariates
gen r_white = race==1
gen r_black = race==2
gen r_asian = inlist(race, 4, 6)
gen in_school = school==2
gen no_english = inlist(speakeng, 1, 6)



compress 
save "$oi/working_acs", replace
