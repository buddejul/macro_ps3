* Generate year-month unemployment rate from CPS data
* Julian Budde
* PS 3 Macro
set graph off

* Note on weights:
* "You should use the orgwgt variable. If you use frequency weights, divide 
* orgwgt by 12 and round to the nearest whole number [ex: gen weight=round
* (orgwgt/12,1)."
* https://ceprdata.org/cps-uniform-data-extracts/cps-outgoing-rotation-group/cps-org-faq/#weight

* Set global root to replicate
global root C:\research\courses\macro\ps3_julia\ps3
cap mkdir $root/bld

cap log close
log using "$root/bld/clean", text replace

use "$root/src/data/cepr_org_1990", clear

local vars hhid lineno year month empl unem fnlwgt age orgwgt educ wbho

keep `vars'

gisid hhid month lineno

forvalues i=1990(1)2019{
    qui append using "$root/src/data/cepr_org_`i'", keep(`vars')
}

cap noi gisid year hhid month lineno
// TODO this is not identifier, why?

* Drop age < 16 (not no missings)
keep if age >= 16
drop age

gen weight = round(orgwgt/12,1)

* Collapse on month level
gen byte all = 1
rename wbho race

foreach group in all education race{

    gcollapse (sum) empl unem [fw = weight], by(year month `group')

    gen unemprate_`group' = unem/empl

    keep year month unemprate_`group'

    histogram unemprate_`group'

    graph export "$root/bld/unemprate_`group'_cps.png", replace

    rename unemprate_`group' unemprate_`group'_cps
    tempfile cps_`group'
    save `cps_`group''
}

* Merge together CPS data

STOP
// BLS data
import excel using "$root/src/data/bls_LNU04000000.xlsx", clear firstrow

rename Year year
rename Jan unemp_1            
rename Feb unemp_2          
rename Mar unemp_3          
rename Apr unemp_4         
rename May unemp_5            
rename Jun unemp_6            
rename Jul unemp_7            
rename Aug unemp_8            
rename Sep unemp_9            
rename Oct unemp_10            
rename Nov unemp_11           
rename Dec unemp_12          

reshape long unemp_, i(year) j(month)
rename unemp_ unemprate_bls

replace unemprate_bls = unemprate_bls / 100

merge 1:1 year month using `cps'
drop _merge

gen date = mdy(month, 1, year)

#delimit ;
twoway
   (connect unemprate_cps date)
   (connect unemprate_bls date)
    if inrange(year, 1990, 2019)
  ,
   legend(
       order(
           1 "Unemployment Rate (CPS)"
           2 "Unemployment Rate (BLS)"
       )
   rows(2) cols(1) ring(0) bplacement(nw) region(lstyle(none))
   size(small) symxsize(medsmall) region(fcolor(white%0))
   )
   ;
#delimit cr

graph export $root/bld/unemprate_bls_cps.png, replace

save $root/bld/unemprates.dta, replace

log close

// FIXME 