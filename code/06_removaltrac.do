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
keep if year>=2011 & year<=2019
collapse (sum) val, by(char group)
sort group val
drop if val==0

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
file open sumstat using "$oo/removaltable.tex", write replace
file write sumstat "\begin{tabular}{rrrll}" _n
file write sumstat "\toprule" _n
file write sumstat "\toprule" _n
file write sumstat "\multicolumn{1}{l}{Characteristics}                         & Removals & Share  &  &  \\"
file write sumstat "\midrule " _n
file write sumstat "\multicolumn{1}{l}{Gender}                                  &          &        &  &  \\"
file write sumstat "Male  & 87,923   & 0.9587 &  &  \\"
file write sumstat "Female & 3,790    & 0.0413 &  &  \\"
file write sumstat "\multicolumn{1}{l}{Age group}                               &          &        &  &  \\"
file write sumstat "0-17  & 82       & 0.0009 &  &  \\"
file write sumstat "18-24 & 17,911   & 0.1953 &  &  \\"
file write sumstat "25-29 & 21,588   & 0.2354 &  &  \\"
file write sumstat "30-34 & 19,568   & 0.2134 &  &  \\"
file write sumstat "35-39 & 14,631   & 0.1595 &  &  \\"
file write sumstat "40-44 & 9,040    & 0.0986 &  &  \\"
file write sumstat "45-49 & 4,985    & 0.0544 &  &  \\"
file write sumstat "50-54 & 2,384    & 0.0260 &  &  \\"
file write sumstat "55-59 & 1,004    & 0.0109 &  &  \\"
file write sumstat "60-64 & 365      & 0.0040 &  &  \\"
file write sumstat "65-69 & 115      & 0.0013 &  &  \\"
file write sumstat "70-74 & 32       & 0.0003 &  &  \\"
file write sumstat "75+   & 9        & 0.0001 &  &  \\"
file write sumstat "\multicolumn{1}{l}{Latin Citizenship} & 90,235   & 0.9839 &  &  \\"
file write sumstat "\multicolumn{1}{l}{Citizenship}                             &          &        &  &  \\"
file write sumstat "Mexico & 68,038   & 0.7418 &  &  \\"
file write sumstat "Guatemala & 8,042    & 0.0877 &  &  \\"
file write sumstat "Honduras & 6,618    & 0.0722 &  &  \\"
file write sumstat "El Salvador & 5,300    & 0.0578 &  &  \\"
file write sumstat "Nicaragua & 329      & 0.0036 &  &  \\"
file write sumstat "Brazil & 306      & 0.0033 &  &  \\"
file write sumstat "\multicolumn{1}{l}{Level of Conviction}         &          &        &  &  \\"
file write sumstat "No Conviction & 16,270   & 0.1774 &  &  \\"
file write sumstat "Level 1 Crime & 25,620   & 0.2793 &  &  \\"
file write sumstat "Level 2 Crime & 9,065    & 0.0988 &  &  \\"
file write sumstat "Level 3 Crime & 40,759   & 0.4444 &  & "
file write sumstat "\bottomrule" _n
file write sumstat "\bottomrule" _n
file write sumstat "\end{tabular}"
file close sumstat


