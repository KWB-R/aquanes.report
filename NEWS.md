
# [aquanes.report 0.5.0](https://github.com/KWB-R/aquanes.report/releases/tag/v.0.5.0)

Offical release for AQUANES

- Haridwar (site 5): completed
- Berlin (sites 1 & 12): integrated with performance optimisation (but without analytics)
- Basel (site 6): integrated operational and analytical data for Wiese/Rhine sites (with new 
                  metadata for analytics)

Cite as: [![DOI](https://zenodo.org/badge/83431353.svg)](https://zenodo.org/badge/latestdoi/83431353)

# [aquanes.report 0.4.1](https://github.com/KWB-R/aquanes.report/releases/tag/v.0.4.1)

- Haridwar (site 5): completed
- Berlin site (sites 1 & 12): performance optimisation, analytics still to be integrated 

Cite as: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.888819.svg)](https://doi.org/10.5281/zenodo.888819)

# [aquanes.report 0.4.0](https://github.com/KWB-R/aquanes.report/releases/tag/v.0.4.0)

Cite as: [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.825030.svg)](https://doi.org/10.5281/zenodo.825030)


* adapted "analytics" import routine to new Autarcon spreadsheet style (for details, 
  check the [documentation](https://kwb-r.github.io/aquanes.report/reference/import_data_haridwar.html)):


    1. All sheets, which are not excluded explicitly will be imported
  
    2. Lab data import starts in row 70 (i.e. 69 rows are now skipped, formerly: 10 rows) 
  

* add ERROR messages for all sheets with lab data that should be imported to 
  identify sheets with data values not statisfying the requirements for the 
  following two variables:
  
  
    1. **DateTime**: non-date-time compliant format of first column raises an error 
  
    2. **ParameterValue**: non-numeric parameter values are not allowed!
	

# [aquanes.report 0.3.0](https://github.com/KWB-R/aquanes.report/releases/tag/v.0.3.0)

* version as presented on GA in Greece

# [aquanes.report 0.2.0-alpha](https://github.com/KWB-R/aquanes.report/releases/tag/v.0.2.0-alpha)

* Add first report parameterisation & generation in app (for Haridwar site)

# [aquanes.report 0.1.0-pre-alpha](https://github.com/KWB-R/aquanes.report/releases/tag/v.0.1.0-pre-alpha)

* First offline/online shiny app for Haridwar (pre-alpha version)
