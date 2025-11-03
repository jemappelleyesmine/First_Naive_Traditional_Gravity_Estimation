* ---------------------------------------------------------------------
* Quantitative International Economics Class
* First Estimation of Gravity Model 
* Author: Yesmine Hachana
* Date: November 2025
* ---------------------------------------------------------------------

* Clear and set working directory
clear all
global path "\\Client\H$\Desktop\Classes\Dauphine\2nd Year\1st Semester\Quantitative International Economics\Class 3\"
cd "$path"

* Create and open log file. Every command will  be saved on a text file
capture log close
log using "${path}/Gravity_Model_Simulation_Nov_3_25.log", text replace

* Check the data file
use "${path}/Chapter1Application1.dta", clear

* Describe data file, show notes created by the author of the dataset
describe
notes

* Keep seleccted years (every 4 years)
keep if inlist(year, 1986, 1990, 1994, 1998, 2002, 2006)

* Generate dependent variable
gen ln_trade = ln(trade)

* Generate main independent variables
gen ln_DIST = ln(DIST)

* For each exporter and each year, compute total output
bysort exporter year: egen Y = total(trade)
gen ln_Y = ln(Y)
/// everything produced in my country is sold abroad or in my country

* For each importer and each year, compute total expenditure
bysort importer year: egen E = total(trade)
gen ln_E = ln(E)
/// total will not transform missing values into zero when summing, it will just not take them into account

* Label variables
label var ln_trade "Trade (log)"
label var ln_DIST "Distance (log)"
label var CNTG "Contiguity"
label var LANG "Common Official Language"
label var CLNY "Common Colonizer"
label var ln_Y "Output (log)"
label var ln_E "Expenditure (log)"
label var Y "Output (USD)"
label var E "Expenditure (USD)"

* Preliminary visualisations
*hist trade(bin=44, start=0, )
*kdensity trade
*kdensity ln_trade

* First naive estimation equation with ln and no fixed effect
reg ln_trade ln_DIST CNTG LANG CLNY ln_Y ln_E if exporter != importer, cluster(pair_id)

*Trade will decrease by 10% if distance increases by 10%.

