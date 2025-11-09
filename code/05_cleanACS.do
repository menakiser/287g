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
drop if countyfip==000 //not identifiable
*Eliminate people living in group quarters (military or convicts): those with the gq variable equal to 0, 3 or 4.
drop if inlist(gq, 0, 3, 4)
*restrict census year 
keep if year>=2010 & year <=2020

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

* obtain exposure var 
rename (statefip countyfip) (statefips countyfips)
merge m:1 countyfips statefips year using "$oi/exposure_county_year" , nogen keep(1 3) keepusing(exp_any_county exp_jail_county exp_task_county exp_warrant_county)
foreach v in exp_any_county exp_jail_county exp_task_county exp_warrant_county {
	replace `v' = 0 if mi(`v')
}

merge m:1 statefips year using "$oi/exposure_state_year" , nogen keep(1 3) keepusing(exp_any_state exp_jail_state exp_task_state exp_warrant_state)
foreach v in exp_any_state exp_jail_state exp_task_state exp_warrant_state {
	replace `v' = 0 if mi(`v')
}
rename  (statefips countyfips) (statefip countyfip)

* other ind vars 
gen male = sex==1 
gen hs = inteduc == 2
gen married = inlist(marst, 1, 2)
gen never_married = inlist(marst, 6)
gen ownhome = ownershp==1
gen employed = empstat==1

sum age exp_any* nchild wkswork1 uhrswork incwage rent mortamt1

*define mobility variables
gen move_any = migrate1>1
replace migplac1 = statefip if migrate1d<=24 //fill in current year state if they didn't move states
replace migcounty1 = countyfip if migrate1d<=10 //fill in current county if they didn't move counties
gen move_county = migcounty1 != countyfip & migrate1d>10
gen move_state = migplac1 != statefip  & migrate1d>24



compress 
save "$oi/working_acs", replace