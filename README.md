# healthcareai

[![Build status](https://ci.appveyor.com/api/projects/status/0xrpe233o9a16l4l/branch/master?svg=true)](https://ci.appveyor.com/project/CatalystAdmin/healthcareai-r/) 
[![Travis-CI Build Status](https://travis-ci.org/HealthCatalyst/healthcareai-r.svg?branch=master)](https://travis-ci.org/HealthCatalyst/healthcareai-r)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/HealthCatalystSLC/healthcareai-r/blob/master/LICENSE)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version-last-release/healthcareai)](https://cran.r-project.org/package=healthcareai)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.999334.svg)](https://doi.org/10.5281/zenodo.999334)

The aim of `healthcareai` is to make machine learning easy on healthcare data. The package has two main goals:

-  Allow one to easily develop and compare models based on tabular data, and deploy a best model that pushes predictions to either databases or flat files.

-  Provide tools related to data cleaning, manipulation, and imputation.

## For those starting out

- If you haven't, install [R](https://CRAN.r-project.org/) version >= 3.2.3 and [RStudio](https://www.rstudio.com/products/rstudio/download)

Note: if you're setting up R on an ETL server, don't download RStudio--simply open up RGui

## Install the latest release on Windows

Open RStudio and work in the console
```
install.packages('healthcareai')
```

> If you don't have admin rights on the machine you are working on, and `library(healthcareai)` throws an error about packages not being available, you can likely solve the problem by defining a custom location in which to store R packages. To do this, open the Control Panel and click through User Accounts -> User Accounts -> Change my environment variables, and add a variable called `R_LIBS_USER` with the value being a path to a folder where you want to keep R packages. For example, you might create a new directory: `C:\Users\your.name\Documents\R\my_library` and use that to store your R packages. Then restart R Studio, run `install.packages("healthcareai")` and `library(healthcareai)` again and all should be well.

## How to install the latest version on macOS

Open RStudio and work in the console
```
install.packages('healthcareai')
```

## How to install latest version on Ubuntu (Linux)

* An Ubuntu 14.04 Droplet with at least 1 GB of RAM is required for the installation.
* Follow steps 1 and 2 [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-r-on-ubuntu-14-04) to install R
* Run `sudo apt-get install libiodbc2-dev`
* Run `sudo apt-get install unixodbc unixodbc-dev`
* After typing `R` run `install.packages('healthcareai')`

## Install the bleeding edge version (for folks providing contributions)

Open RStudio and work in the console 
```
library(devtools)
devtools::install_github(repo='HealthCatalyst/healthcareai-r')
```

## Tips on getting started

#### Built-in examples
Load the package you just installed and read the built-in docs
```
library(healthcareai)
?healthcareai
```

#### Website examples
See our [docs website](http://healthcareai-r.readthedocs.io)

## Join the community
Read the blog and join the slack channel at [healthcare.ai](https://healthcare.ai)

## What's new?
The CRAN 1.0.0 release features:
- Added: 
  - Kmeans clustering
  - XGBoost multiclass support
  - findingVariation family of functions
- Changed: 
  - Develop step trains and saves models
  - Deploy no longer trains. Loads and predicts on all rows.
  - SQL uses a DBI back end
- Removed:
  - `testWindowCol` is no longer a param.
  - SQL reading/writing is outside model deployment.

## For issues

- Double check that the code follows the examples in the built-in docs
```R
library(healthcareai)
?healthcareai
```
  
- Make sure you've thoroughly read the descriptions found [here](http://healthcareai-r.readthedocs.io)

- If you're still seeing an error, file an issue on [Stack Overflow](http://stackoverflow.com/) using the healthcare-ai tag. Please provide
  - Details on your environment (OS, database type, R vs Py)
  - Goals (ie, what are you trying to accomplish)
  - Crystal clear steps for reproducing the error

## Contributing

You want to help? Woohoo! We welcome that and are willing to help newbies get started.

First, see [here](CONTRIBUTING.md) for instructions on setting up your development environment and how to contribute.

