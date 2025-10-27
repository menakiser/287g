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

** Sample restrictions
*50 US states and DC
keep if statefip<=56
drop if countyfip==000 //not identifiable
*Eliminate people living in group quarters (military or convicts): those with the gq variable equal to 0, 3 or 4.
drop if inlist(gq, 0, 3, 4)
*restrict census year 
keep if year>=2010 & year <=2020

** individual variables
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
gen imm = inlist(citizen, 2, 3)
replace imm = 1 if bpld>= 15000 & bpld!=90011 & bpld<90021 & year==1960
replace imm = 0 if mi(imm)

gen young = age>=18 & age<=39

*define affected population (presumably undocumented) as male, low-skill (High School or less), Hispanic, foreign-born, noncitizens of ages 18-39, and
gen targetpop = sex==1 & lowskill==1 & hispan!=0 & imm==1 & young==1 & yrimmig>2007
gen nottargetpop = sex==1 & lowskill==1 & hispan!=0 & (bpld<15000 | bpld==90011 | bpld==90021 | citizen==1| citizen==2 ) & young==1

*clean variables
replace incwage=. if incwage==999999 | incwage==0 

* obtain exposure var 
rename (statefip countyfip) (statefips countyfips)
merge m:1 countyfips statefips year using "$oi/exposure_county_year" , nogen keep(1 3)
foreach v in exp_any exp_jail exp_task exp_warrant {
	replace `v' = 0 if mi(`v')
}
rename  (statefips countyfips) (statefip countyfip)
bys statefip: egen st_exp = max(exp_any>0)

* obtain list of SC
preserve 
use  "$or/287g_SC_EVerify_5_13_22", clear 
collapse (mean) SC_sh=SC (max) SC_any=SC , by(countyfip statefip year )
keep if year>=2010
tempfile sclist 
save `sclist'
restore 

merge m:1 countyfip statefip year using `sclist', nogen keep( 1 3)
foreach v in SC_sh SC_any {
	replace `v' = 0 if mi(`v')
}

* other ind vars 
gen male = sex==1 
gen hs = inteduc == 2
gen married = inlist(marst, 1, 2)
gen never_married = inlist(marst, 6)
gen ownhome = ownershp==1
gen employed = empstat==1

sum age exp_any nchild wkswork1 uhrswork incwage rent mortamt1

*define mobility variables
gen move_any = migrate1>1
replace migplac1 = statefip if migrate1d<=24 //fill in current year state if they didn't move states
replace migcounty1 = countyfip if migrate1d<=10 //fill in current county if they didn't move counties
gen move_county = migcounty1 != countyfip & migrate1d>10
gen move_state = migplac1 != statefip  & migrate1d>24



compress 
save "$oi/working_acs", replace