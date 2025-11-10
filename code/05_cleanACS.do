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
//drop if countyfip==000 //not identifiable
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

**** location variables: obtaining current migpuma
rename ( puma) ( puma10)
merge m:1 statefip puma10 using "$oi/xwalk/puma10_migpuma10" , nogen keep(1 3)
rename (puma10) ( current_puma ) 

* obtain exposure variables at the migpuma level
/* All migpumas match with some exposure, missing matches arise from years that do not observe these pumas
keep statefip migpuma10
duplicates drop 
merge 1:m statefip migpuma10  using "$oi/exposure_migpuma10_year"
*/
merge m:1 statefip migpuma10 year using "$oi/exposure_migpuma10_year" , keepusing(exp_any_migpuma exp_jail_migpuma exp_task_migpuma exp_warrant_migpuma) nogen keep(1 3) //all 2012-2020 match
foreach v in exp_any_migpuma exp_jail_migpuma exp_task_migpuma exp_warrant_migpuma {
	replace `v' = 0 if mi(`v')
}
rename migpuma10 current_migpuma
* obtain exposure variables at the migpuma level
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

* obtain exposure variables at the migpuma level
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
* obtain exposure variables at the migpuma level
foreach v in exp_any_state exp_jail_state exp_task_state exp_warrant_state {
	rename `v' current_`v'
}
merge m:1 statefip year using "$oi/exposure_state_year" , nogen keep(1 3) keepusing(exp_any_state exp_jail_state exp_task_state exp_warrant_state)
foreach v in exp_any_state exp_jail_state exp_task_state exp_warrant_state {
	replace `v' = 0 if mi(`v')
	rename `v' prev_`v'
	rename current_`v'  `v'
}
rename statefip prev_statefip 
rename migcounty1 prev_county
rename current_statefip statefip


* add list of secure communities
rename (current_migpuma ) (migpuma10 )
merge m:1 migpuma10 statefip year using "$oi/migpuma10_SC" , nogen keep( 1 3) 
replace SC= 0 if mi(SC)

replace SC_any = 1 if year==2013 | year==2014
replace SC_any = 0 if year>=2015
bys statefip current_migpuma year: ereplace SC_any = max(SC_any)



compress 
save "$oi/working_acs", replace
