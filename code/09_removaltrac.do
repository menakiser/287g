/*---------------------
Mena kiser
11-09-2025
Clean removal information extracted from trac
https://tracreports.org/phptools/immigration/remove/
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"
global oo "$wd/output/"


import excel using "$or/removal_trac.xlsx", clear cellrange(A4:V78) firstrow sheet(rawdata)

* identify groups
gen group = val2010 if val2010==char2010
replace group = "All" if _n==1
replace group = group[_n-1] if group[_n-1]!="" & group==""
drop if val2010==group

*destring all
foreach v of varlist _all {
	cap destring(`v'), replace
}
gen ogorder = _n
reshape long char val, i(ogorder) j(year)

* restrict to focus years
keep if year>=2013 & year<=2019
collapse (sum) val, by(char group)
sort group val
drop if val==0

* bar graph for each fiscal year
preserve
keep if group=="All"
destring char, replace
format val %12.0fc
twoway (bar val char, barw(0.6)  color(gs9) ) ///
	(scatter val char , mstyle(none) mlabel(val) mlabcolor(black) mlabgap(1) mlabpos(12) mlabsize(3.7) ) ///
	, legend(off) ytitle(Deportation count) xtitle(Fiscal year)  ///
	xlabel(2013(1)2019) ylabel(0(5000)15000)
graph export "$oo/deportations.png", replace
restore

* obtain shares
gen total = val if group=="All"
ereplace total = sum(total)
gen share = val/total

* identify latinos
gen latin_america = 0
replace latin_america = 1 if inlist(char, "Argentina", "Belize", "Bolivia", "Brazil", "Chile", "Colombia") |  ///
    inlist(char, "Costa Rica", "Cuba", "Dominican Republic", "Ecuador", "El Salvador") |  ///
    inlist(char, "Guatemala", "Haiti", "Honduras", "Jamaica", "Mexico", "Nicaragua") |  ///
    inlist(char, "Panama", "Paraguay", "Peru", "Trinidad And Tobago", "Uruguay", "Venezuela") |  ///
    inlist(char, "Guyana", "Suriname")
replace latin_america = latin_america*val
ereplace latin_america = sum(latin_america)
expand 2 if _n==_N
replace char = "Latin American or Caribbean Citizenship" if _n==_N
replace group = "Latin American or Caribbean Citizenship" if _n==_N
replace val = latin_america if _n==_N
replace share = latin_america/total if _n==_N
drop latin_america
bys group (val): drop if _n<_N-5 & group=="Citizenship"
drop if group=="All"

sort group char val
bys group: gen torder = _n
gsort group -val
bys group: replace torder = _n if group!="Age group"
replace group = "Seriousness Level of Conviction" if group=="Seriousness Level of MSCC Conviction"
sort group torder

cap file close sumstat
file open sumstat using "$oo/fina/removaltable.tex", write replace
file write sumstat "\begin{tabular}{rllll}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat "\multicolumn{1}{l}{Characteristics} & \multicolumn{1}{r}{Removals} & \multicolumn{1}{r}{Share ($\%$)}   \\" _n
file write sumstat "\midrule" _n
file write sumstat "\multicolumn{1}{l}{Gender} & &   \\" _n
file write sumstat "Male & 87,923 & 95.87   \\" _n
file write sumstat "Female & 3,790 & 4.13   \\" _n
file write sumstat "\multicolumn{1}{l}{Age group} & &   \\" _n
file write sumstat "0-17 & 82 & 0.09   \\" _n
file write sumstat "18-24 & 17,911 & 19.53   \\" _n
file write sumstat "25-29 & 21,588 & 23.54   \\" _n
file write sumstat "30-34 & 19,568 & 21.34   \\" _n
file write sumstat "35-39 & 14,631 & 15.95   \\" _n
file write sumstat "40-44 & 9,040 & 9.86   \\" _n
file write sumstat "45-49 & 4,985 & 5.44   \\" _n
file write sumstat "50-54 & 2,384 & 2.60   \\" _n
file write sumstat "55-59 & 1,004 & 1.09   \\" _n
file write sumstat "60-64 & 365 & 0.40   \\" _n
file write sumstat "65-69 & 115 & 0.13   \\" _n
file write sumstat "70-74 & 32 & 0.03   \\" _n
file write sumstat "75+ & 9 & 0.01   \\" _n
file write sumstat "\multicolumn{1}{l}{Latin American Citizen} & 90,235 & 98.39   \\" _n
file write sumstat "\multicolumn{1}{l}{Citizenship} & &   \\" _n
file write sumstat "Mexico & 68,038 & 74.18   \\" _n
file write sumstat "Guatemala & 8,042 & 8.77   \\" _n
file write sumstat "Honduras & 6,618 & 7.22   \\" _n
file write sumstat "El Salvador & 5,300 & 5.78   \\" _n
file write sumstat "Nicaragua & 329 & 0.36   \\" _n
file write sumstat "Brazil & 306 & 0.33   \\" _n
file write sumstat "\multicolumn{1}{l}{Level of Conviction} & &   \\" _n
file write sumstat "No Conviction & 16,270 & 17.74   \\" _n
file write sumstat "Level 1 Crime & 25,620 & 27.93   \\" _n
file write sumstat "Level 2 Crime & 9,065 & 9.88   \\" _n
file write sumstat "Level 3 Crime & 40,759 & 44.44   \\" _n
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\end{tabular}"
file close sumstat
