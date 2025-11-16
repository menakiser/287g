/*---------------------
Mena kiser
10-19-25

Create exposure level variable matching migration level codes: county and puma
---------------------*/

clear all

global wd "/Users/jimenakiser/Desktop/287g/"
global or "$wd/data/raw"
global oi "$wd/data/int"
global oo "$wd/output/"

//do "$wd/code/05_cleanACS.do"
do "$wd/code/07_prop_matching_2013_migpuma.do"
do "$wd/code/09_troubleshoot_specifications_estudy_v2.do"
//do "$wd/code/10_figures.do"