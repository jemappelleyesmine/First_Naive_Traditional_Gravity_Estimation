********************************************************************************
****************  CHAPTER 1 - PARTIAL EQUILIBRIUM TRADE POLICY  ****************
****************      ANALYSIS WITH STRUCTURAL GRAVITY MODELS     ***************
********************************************************************************

/*
APPLICATION 1: TRADITIONAL GRAVITY ESTIMATES

This application estimates the effects of traditional gravity variables using 
different methods to control for multilateral resistance terms (MRTs) and 
alternative estimators.

Data source:
  - Bilateral trade data (international + intra-national) at the aggregate 
    manufacturing level for 69 countries (1986–2006)
    Source: Thomas Zylkin (based on UN COMTRADE, CEPII TradeProd, UNIDO INDSTAT)
  - Regional Trade Agreements: Mario Larch's RTA Database
    (http://www.ewf.uni-bayreuth.de/en/research/RTA-data/index.html)
  - Standard gravity variables (distance, borders, language): CEPII GeoDist
  
IMPORTANT:
  - Run "directory_definition.do" before executing this file.
    do "directory_definition.do"
*/


********************************************************************************
***                           INITIAL SETUP                                  ***
********************************************************************************

clear *
cls
* (Optional) Install or update required commands
* ssc install ftools
* ssc install gtools
* ssc install reghdfe, replace
* ssc install ppmlhdfe, replace

set more off

* Set working directory
cd "~/Dropbox/Lecture/Dauphine/M2 CI/Students/QIE_2024/1.StructuralGravity/"

* Create and open log file
capture log close
log using "Applications/1_TraditionalGravity/Results/TraditionalGravity.log", text replace



********************************************************************************
***                       LOAD AND PREPARE DATA                              ***
********************************************************************************

use "Datasets/Chapter1Application1.dta", clear

* Keep selected years (every 4 years)
keep if inlist(year, 1986, 1990, 1994, 1998, 2002, 2006)

* Generate dependent variable
gen ln_trade = ln(trade)

* Generate main independent variables
gen ln_DIST = ln(DIST)

bys exporter year: egen Y = total(trade)
gen ln_Y = ln(Y)

bys importer year: egen E = total(trade)
gen ln_E = ln(E)

* Label variables
label var ln_trade "Trade (log)"
label var ln_DIST  "Distance (log)"
label var CNTG     "Contiguity"
label var LANG     "Common Official Language"
label var CLNY     "Common Colonizer"
label var ln_Y     "Output (log)"
label var ln_E     "Expenditure (log)"
label var Y        "Output (USD)"
label var E        "Expenditure (USD)"


********************************************************************************
***                    (a) OLS IGNORING MULTILATERAL RESISTANCE              ***
********************************************************************************

reg ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E if exporter != importer, cluster(pair_id)

outreg2 using "Applications/1_TraditionalGravity/Results/Application_TraditionalGravity.xls", ///
    ctitle(OLS) addstat("Number of pairs", e(N_clust)) ///
    addtext("Exporter x Year FE", "No", "Importer x Year FE", "No") ///
    excel label nocons dec(3) se replace

* RESET test
predict fit, xb
gen fit2 = fit^2
reg ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E fit2 if exporter != importer, cluster(pair_id)
test fit2 = 0
drop fit*

* Save intermediate data
save "Datasets/1_TraditionalGravityData.dta", replace


********************************************************************************
***          (b) OLS WITH REMOTENESS INDEXES (APPROXIMATED MRTs)             ***
********************************************************************************

* --- Option 1: Using totals directly ---
use "Datasets/1_TraditionalGravityData.dta", clear

bys exporter year: egen TotEj = total(E)
bys year: egen TotE = max(TotEj)
bys exporter year: egen REM_EXP = total(DIST / (E / TotE))
gen ln_REM_EXP = ln(REM_EXP)

bys importer year: egen TotYi = total(Y)
bys year: egen TotY = max(TotYi)
bys importer year: egen REM_IMP = total(DIST / (Y / TotY))
gen ln_REM_IMP = ln(REM_IMP)

* --- Option 2: Using collapse (cleaner for large datasets) ---

* Total expenditure
use "Datasets/1_TraditionalGravityData.dta", clear
keep importer year E
duplicates drop
collapse (sum) E, by(year)
rename E TotE
save "Datasets/RMTNS_EXP.dta", replace

* Total output
use "Datasets/1_TraditionalGravityData.dta", clear
keep exporter year Y
duplicates drop
collapse (sum) Y, by(year)
rename Y TotY
save "Datasets/RMTNS_IMP.dta", replace

* Merge totals back into main dataset
use "Datasets/1_TraditionalGravityData.dta", clear
merge m:1 year using "Datasets/RMTNS_EXP.dta", nogen
merge m:1 year using "Datasets/RMTNS_IMP.dta", nogen

* Compute remoteness indexes
bys exporter year: egen REM_EXP = total(DIST / (E / TotE))
gen ln_REM_EXP = ln(REM_EXP)

bys importer year: egen REM_IMP = total(DIST / (Y / TotY))
gen ln_REM_IMP = ln(REM_IMP)

* Estimate model with remoteness
reg ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E ln_REM_EXP ln_REM_IMP ///
    if exporter != importer, cluster(pair_id)

outreg2 using "Applications/1_TraditionalGravity/Results/Application_TraditionalGravity.xls", ///
    ctitle(OLS, Remoteness) addstat("Number of pairs", e(N_clust)) ///
    addtext("Exporter x Year FE", "No", "Importer x Year FE", "No") ///
    excel label nocons dec(3) se append

* RESET test
predict fit, xb
gen fit2 = fit^2
reg ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E REM_EXP REM_IMP fit2 ///
    if exporter != importer, cluster(pair_id)
test fit2 = 0
drop fit*


********************************************************************************
***        (c) OLS WITH EXPORTER-YEAR AND IMPORTER-YEAR FIXED EFFECTS        ***
********************************************************************************

egen exp_time = group(exporter year)
egen imp_time = group(importer year)

reghdfe ln_trade ln_DIST CNTG LANG CLNY if exporter != importer, ///
    absorb(exp_time imp_time) cluster(pair_id)

outreg2 using "Applications/1_TraditionalGravity/Results/Application_TraditionalGravity.xls", ///
    ctitle(OLS, FE) addstat("Number of pairs", e(N_clust)) ///
    addtext("Exporter x Year FE", "Yes", "Importer x Year FE", "Yes") ///
    excel label nocons dec(3) se append

* RESET test
predict fit, xb
gen fit2 = fit^2
reghdfe ln_trade ln_DIST CNTG LANG CLNY fit2 if exporter != importer, ///
    absorb(exp_time imp_time) cluster(pair_id)
test fit2 = 0
drop fit*


********************************************************************************
***            (d) PPML WITH EXPORTER-YEAR AND IMPORTER-YEAR FEs             ***
********************************************************************************

ppmlhdfe trade ln_DIST CNTG LANG CLNY if exporter != importer, ///
    absorb(exp_time imp_time) cluster(pair_id) d

outreg2 using "Applications/1_TraditionalGravity/Results/Application_TraditionalGravity.xls", ///
    ctitle(PPML, FE) addstat("Pseudo R2", e(r2_p), "Number of pairs", e(N_clust)) ///
    addtext("Exporter x Year FE", "Yes", "Importer x Year FE", "Yes") ///
    excel label nocons dec(3) se append

* Save final dataset
save "Datasets/1_TraditionalGravity.dta", replace

log close
exit
