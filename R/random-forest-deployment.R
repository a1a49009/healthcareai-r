#' Deploy a production-ready predictive RandomForest model
#'
#' @description This step allows one to
#' \itemize{
#' \item Load a saved model from \code{\link{RandomForestDevelopment}}
#' \item Run the model against test data to generate predictions
#' \item Push these predictions to SQL Server
#' \item Identify factors that could benefit outcomes (see final examples)
#' }
#' @docType class
#' @usage RandomForestDeployment(type, df, grainCol, predictedCol, impute, debug, cores, modelName)
#' @import caret
#' @import doParallel
#' @importFrom R6 R6Class
#' @import ranger
#' @param type The type of model (either 'regression' or 'classification')
#' @param df Dataframe whose columns are used for new predictions. Data structure should match development as 
#' much as possible. Number of columns, names, types, grain, and predicted must be the same.
#' @param grainCol The dataframe's column that has IDs pertaining to the grain
#' @param predictedCol Column that you want to predict.
#' @param impute For training df, set all-column imputation to T or F.
#' If T, this uses values calculated in development.
#' F leads to removal of rows containing NULLs and is not recommended.
#' @param debug Provides the user extended output to the console, in order
#' @param cores Number of cores you'd like to use.  Defaults to 2.
#' @param modelName Optional string. Can specify the model name. If used, you must load the same one in the deploy step.
#' @section Methods: 
#' The above describes params for initializing a new randomForestDeployment class with 
#' \code{$new()}. Individual methods are documented below.
#' @section \code{$new()}:
#' Initializes a new random forest deployment class using the 
#' parameters saved in \code{p}, documented above. This method loads, cleans, and prepares data for
#' generating predictions. \cr
#' \emph{Usage:} \code{$new(p)}
#' @section \code{$deploy()}:
#' Generate new predictions, calculate top factors, and prepare the output dataframe. \cr
#' \emph{Usage:} \code{$deploy()} 
#' @section \code{$getTopFactors()}:
#' Return the grain, all top factors, and their weights. \cr
#' \emph{Usage:} \code{$getTopFactors(numberOfFactors = NA, includeWeights = FALSE)} \cr
#' Params: \cr
#'   - \code{numberOfFactors:} returns the top \code{n} factors. Defaults to all factors. \cr
#'   - \code{includeWeights:} If \code{TRUE}, returns weights associated with each factor.
#' @section \code{$getOutDf()}:
#' Returns the output dataframe. \cr
#' \emph{Usage:} \code{$getOutDf()} 
#' @section \code{$getProcessVariablesDf()}:
#' Builds and returns a dataframe with information about the modifiable process 
#' variables. \cr
#' \emph{Usage:} \code{$getProcessVariablesDf(modifiableVariables, 
#' variableLevels = NULL, grainColumnValues = NULL, smallerBetter = TRUE, 
#' repeatedFactors = FALSE, numTopFactors = 3)} \cr
#' Params: \cr
#'   - \code{modifiableVariables} A vector of names of categorical variables.\cr
#'   - \code{variableLevels} A list of variable values indexed by 
#'   modifiable variable names. This allows one to use numeric variables by 
#'   specifying baselines and to restrict categorical variables by limiting 
#'   which factors can be recommended.\cr
#'   - \code{grainColumnIDs} A vector of grain column IDs. If \code{NULL}, the 
#'   whole deployment dataframe will be used.\cr
#'   - \code{smallerBetter} A boolean determining whether or not lower 
#'   predictions/probabilities are more desirable. \cr
#'   - \code{repeatedFactors} A boolean determining whether or not a single 
#'   modifiable factor can be listed several times. \cr
#'   - \code{numTopFactors} The number of modifiable process variables to 
#'   nclude in each row.
#' @export
#' @seealso \code{\link{healthcareai}}
#' @seealso \code{\link{writeData}}
#' @seealso \code{\link{selectData}}
#' @examples
#' 
#' #### Classification Example using csv data ####
#' ## 1. Loading data and packages.
#' ptm <- proc.time()
#' library(healthcareai)
#' 
#' # setwd('C:/Yourscriptlocation/Useforwardslashes') # Uncomment if using csv
#' 
#' # Can delete this line in your work
#' csvfile <- system.file("extdata", 
#'                        "HCRDiabetesClinical.csv", 
#'                        package = "healthcareai")
#' 
#' # Replace csvfile with 'path/file'
#' df <- read.csv(file = csvfile, 
#'                header = TRUE, 
#'                na.strings = c("NULL", "NA", ""))
#' 
#' df$PatientID <- NULL # Only one ID column (ie, PatientEncounterID) is needed remove this column
#' 
#' # Save a dataframe for validation later on
#' dfDeploy <- df[951:1000,]
#' 
#' ## 2. Train and save the model using DEVELOP
#' print('Historical, development data:')
#' str(df)
#' 
#' set.seed(42)
#' p <- SupervisedModelDevelopmentParams$new()
#' p$df <- df
#' p$type <- "classification"
#' p$impute <- TRUE
#' p$grainCol <- "PatientEncounterID"
#' p$predictedCol <- "ThirtyDayReadmitFLG"
#' p$debug <- FALSE
#' p$cores <- 1
#' 
#' # Run RandomForest
#' RandomForest <- RandomForestDevelopment$new(p)
#' RandomForest$run()
#' 
#' ## 3. Load saved model and use DEPLOY to generate predictions. 
#' print('Fake production data:')
#' str(dfDeploy)
#' 
#' p2 <- SupervisedModelDeploymentParams$new()
#' p2$type <- "classification"
#' p2$df <- dfDeploy
#' p2$grainCol <- "PatientEncounterID"
#' p2$predictedCol <- "ThirtyDayReadmitFLG"
#' p2$impute <- TRUE
#' p2$debug <- FALSE
#' p2$cores <- 1
#' 
#' dL <- RandomForestDeployment$new(p2)
#' dL$deploy()
#' 
#' dfOut <- dL$getOutDf()
#' head(dfOut)
#' # Write to CSV (or JSON, MySQL, etc) using plain R syntax
#' # write.csv(dfOut,'path/predictionsfile.csv')
#' 
#' print(proc.time() - ptm)
#' 
#' \donttest{
#' #### Classification example using SQL Server data ####
#' # This example requires you to first create a table in SQL Server
#' # If you prefer to not use SAMD, execute this in SSMS to create output table:
#' # CREATE TABLE dbo.HCRDeployClassificationBASE(
#' #   BindingID float, BindingNM varchar(255), LastLoadDTS datetime2,
#' #   PatientEncounterID int, <--change to match inputID
#' #   PredictedProbNBR decimal(38, 2),
#' #   Factor1TXT varchar(255), Factor2TXT varchar(255), Factor3TXT varchar(255)
#' # )
#' 
#' ## 1. Loading data and packages.
#' ptm <- proc.time()
#' library(healthcareai)
#' 
#' connection.string <- "
#' driver={SQL Server};
#' server=localhost;
#' database=SAM;
#' trusted_connection=true
#' "
#' 
#' query <- "
#' SELECT
#' [PatientEncounterID] --Only need one ID column for random forest
#' ,[SystolicBPNBR]
#' ,[LDLNBR]
#' ,[A1CNBR]
#' ,[GenderFLG]
#' ,[ThirtyDayReadmitFLG]
#' FROM [SAM].[dbo].[HCRDiabetesClinical]
#' "
#' 
#' df <- selectData(connection.string, query)
#' 
#' # Save a dataframe for validation later on
#' dfDeploy <- df[951:1000,]
#' 
#' ## 2. Train and save the model using DEVELOP
#' print('Historical, development data:')
#' str(df)
#' 
#' set.seed(42)
#' p <- SupervisedModelDevelopmentParams$new()
#' p$df <- df
#' p$type <- "classification"
#' p$impute <- TRUE
#' p$grainCol <- "PatientEncounterID"
#' p$predictedCol <- "ThirtyDayReadmitFLG"
#' p$debug <- FALSE
#' p$cores <- 1
#' 
#' # Run RandomForest
#' RandomForest <- RandomForestDevelopment$new(p)
#' RandomForest$run()
#' 
#' ## 3. Load saved model and use DEPLOY to generate predictions. 
#' print('Fake production data:')
#' str(dfDeploy)
#' 
#' p2 <- SupervisedModelDeploymentParams$new()
#' p2$type <- "classification"
#' p2$df <- dfDeploy
#' p2$grainCol <- "PatientEncounterID"
#' p2$predictedCol <- "ThirtyDayReadmitFLG"
#' p2$impute <- TRUE
#' p2$debug <- FALSE
#' p2$cores <- 1
#' 
#' dL <- RandomForestDeployment$new(p2)
#' dL$deploy()
#' dfOut <- dL$getOutDf()
#' 
#' writeData(MSSQLConnectionString = connection.string,
#'           df = dfOut,
#'           tableName = 'HCRDeployClassificationBASE')
#' 
#' print(proc.time() - ptm)
#' }
#' 
#' \donttest{
#' #### Regression Example using SQL Server data ####
#' # This example requires you to first create a table in SQL Server
#' # If you prefer to not use SAMD, execute this in SSMS to create output table:
#' # CREATE TABLE dbo.HCRDeployRegressionBASE(
#' #   BindingID float, BindingNM varchar(255), LastLoadDTS datetime2,
#' #   PatientEncounterID int, <--change to match inputID
#' #   PredictedValueNBR decimal(38, 2),
#' #   Factor1TXT varchar(255), Factor2TXT varchar(255), Factor3TXT varchar(255)
#' # )
#' 
#' ## 1. Loading data and packages.
#' ptm <- proc.time()
#' library(healthcareai)
#' 
#' connection.string <- "
#' driver={SQL Server};
#' server=localhost;
#' database=SAM;
#' trusted_connection=true
#' "
#' 
#' query <- "
#' SELECT
#' [PatientEncounterID] --Only need one ID column for random forest
#' ,[SystolicBPNBR]
#' ,[LDLNBR]
#' ,[A1CNBR]
#' ,[GenderFLG]
#' ,[ThirtyDayReadmitFLG]
#' FROM [SAM].[dbo].[HCRDiabetesClinical]
#' "
#' 
#' df <- selectData(connection.string, query)
#' 
#' # Save a dataframe for validation later on
#' dfDeploy <- df[951:1000,]
#' 
#' ## 2. Train and save the model using DEVELOP
#' print('Historical, development data:')
#' str(df)
#' 
#' set.seed(42)
#' p <- SupervisedModelDevelopmentParams$new()
#' p$df <- df
#' p$type <- "regression"
#' p$impute <- TRUE
#' p$grainCol <- "PatientEncounterID"
#' p$predictedCol <- "A1CNBR"
#' p$debug <- FALSE
#' p$cores <- 1
#' 
#' # Run Random Forest
#' RandomForest <- RandomForestDevelopment$new(p)
#' RandomForest$run()
#' 
#' ## 3. Load saved model and use DEPLOY to generate predictions. 
#' dfDeploy$A1CNBR <- NULL # You won't know the response in production
#' print('Fake production data:')
#' str(dfDeploy)
#' 
#' p2 <- SupervisedModelDeploymentParams$new()
#' p2$type <- "regression"
#' p2$df <- dfDeploy
#' p2$grainCol <- "PatientEncounterID"
#' p2$predictedCol <- "A1CNBR"
#' p2$impute <- TRUE
#' p2$debug <- FALSE
#' p2$cores <- 1
#' 
#' dL <- RandomForestDeployment$new(p2)
#' dL$deploy()
#' dfOut <- dL$getOutDf()
#' 
#' writeData(MSSQLConnectionString = connection.string,
#'           df = dfOut,
#'           tableName = 'HCRDeployRegressionBASE')
#' 
#' print(proc.time() - ptm)
#' }
#' 
#' #' #### Classification example pulling from CSV and writing to SQLite ####
#' 
#' ## 1. Loading data and packages.
#' ptm <- proc.time()
#' library(healthcareai)
#' 
#' # Can delete these system.file lines in your work
#' csvfile <- system.file("extdata", 
#'                        "HCRDiabetesClinical.csv", 
#'                        package = "healthcareai")
#'                        
#' sqliteFile <- system.file("extdata",
#'                           "unit-test.sqlite",
#'                           package = "healthcareai")
#' 
#' # Read in CSV; replace csvfile with 'path/file'
#' df <- read.csv(file = csvfile, 
#'                header = TRUE, 
#'                na.strings = c("NULL", "NA", ""))
#' 
#' df$PatientID <- NULL # Only one ID column (ie, PatientEncounterID) is needed remove this column
#' 
#' # Save a dataframe for validation later on
#' dfDeploy <- df[951:1000,]
#' 
#' ## 2. Train and save the model using DEVELOP
#' print('Historical, development data:')
#' str(df)
#' 
#' set.seed(42)
#' p <- SupervisedModelDevelopmentParams$new()
#' p$df <- df
#' p$type <- "classification"
#' p$impute <- TRUE
#' p$grainCol <- "PatientEncounterID"
#' p$predictedCol <- "ThirtyDayReadmitFLG"
#' p$debug <- FALSE
#' p$cores <- 1
#' 
#' # Run Random Forest
#' RandomForest <- RandomForestDevelopment$new(p)
#' RandomForest$run()
#' 
#' ## 3. Load saved model and use DEPLOY to generate predictions. 
#' print('Fake production data:')
#' str(dfDeploy)
#' 
#' p2 <- SupervisedModelDeploymentParams$new()
#' p2$type <- "classification"
#' p2$df <- dfDeploy
#' p2$grainCol <- "PatientEncounterID"
#' p2$predictedCol <- "ThirtyDayReadmitFLG"
#' p2$impute <- TRUE
#' p2$debug <- FALSE
#' p2$cores <- 1
#' 
#' dL <- RandomForestDeployment$new(p2)
#' dL$deploy()
#' dfOut <- dL$getOutDf()
#' 
#' writeData(SQLiteFileName = sqliteFile,
#'           df = dfOut,
#'           tableName = 'HCRDeployClassificationBASE')
#' 
#' print(proc.time() - ptm)
#' 
#' #### Regression example pulling from CSV and writing to SQLite ####
#' 
#' ## 1. Loading data and packages.
#' ptm <- proc.time()
#' library(healthcareai)
#' 
#' # Can delete these system.file lines in your work
#' csvfile <- system.file("extdata", 
#'                        "HCRDiabetesClinical.csv", 
#'                        package = "healthcareai")
#' 
#' sqliteFile <- system.file("extdata",
#'                           "unit-test.sqlite",
#'                           package = "healthcareai")
#' 
#' # Read in CSV; replace csvfile with 'path/file'
#' df <- read.csv(file = csvfile, 
#'                header = TRUE, 
#'                na.strings = c("NULL", "NA", ""))
#' 
#' df$PatientID <- NULL # Only one ID column (ie, PatientEncounterID) is needed remove this column
#' 
#' # Save a dataframe for validation later on
#' dfDeploy <- df[951:1000,]
#' 
#' ## 2. Train and save the model using DEVELOP
#' print('Historical, development data:')
#' str(df)
#' 
#' set.seed(42)
#' p <- SupervisedModelDevelopmentParams$new()
#' p$df <- df
#' p$type <- "regression"
#' p$impute <- TRUE
#' p$grainCol <- "PatientEncounterID"
#' p$predictedCol <- "A1CNBR"
#' p$debug <- FALSE
#' p$cores <- 1
#' 
#' # Run Random Forest
#' RandomForest<- RandomForestDevelopment$new(p)
#' RandomForest$run()
#' 
#' ## 3. Load saved model and use DEPLOY to generate predictions. 
#' dfDeploy$A1CNBR <- NULL # You won't know the response in production
#' print('Fake production data:')
#' str(dfDeploy)
#' 
#' p2 <- SupervisedModelDeploymentParams$new()
#' p2$type <- "regression"
#' p2$df <- dfDeploy
#' p2$grainCol <- "PatientEncounterID"
#' p2$predictedCol <- "A1CNBR"
#' p2$impute <- TRUE
#' p2$debug <- FALSE
#' p2$cores <- 1
#' 
#' dL <- RandomForestDeployment$new(p2)
#' dL$deploy()
#' dfOut <- dL$getOutDf()
#' 
#' writeData(SQLiteFileName = sqliteFile,
#'           df = dfOut,
#'           tableName = 'HCRDeployRegressionBASE')
#' 
#' print(proc.time() - ptm)
#' 
#' #### Example Get Recommendations from Deployed Model: getProcessVariablesDf####
#' # This example shows how to use the getProcessVariableDf() function, using a
#' # model similar to the one built in Classification Example using csv data. 
#' # The main difference is that we use a data set where systolic blood pressure 
#' # is a categorical variable.
#'
#' csvfile <- system.file("extdata", 
#'                       "HCRDiabetesClinical.csv", 
#'                       package = "healthcareai")
#'
#' # Replace csvfile with 'path/file'
#' df <- read.csv(file = csvfile, 
#'                header = TRUE, 
#'                na.strings = c("NULL", "NA", ""))
#' 
#' df$PatientID <- NULL # Remove extra ID
#' 
#' # Convert systolic blood pressure from a numeric variable to a categorical 
#' # variable with 5 categories: normal, pre-hypertension, stage 1 hypertension,
#' # stage 2 hypertension, and hypertensive crisis
#' df$SystolicBP <- ifelse(df$SystolicBPNBR < 140, 
#'                         ifelse(df$SystolicBPNBR < 120, 
#'                                "Normal", 
#'                                "Pre-hypertensive"), 
#'                         ifelse(df$SystolicBPNBR < 160, 
#'                                "Stage_1", 
#'                                ifelse(df$SystolicBP < 180, "Stage_2", "Crisis")))
#' df$SystolicBPNBR <- NULL
#' 
#' # Save a dataframe for validation later on
#' dfDeploy <- df[951:1000,]
#' 
#' ## Develop and Deploy the model
#' set.seed(42)
#' p <- SupervisedModelDevelopmentParams$new()
#' p$df <- df
#' p$type <- "classification"
#' p$impute <- TRUE
#' p$grainCol <- "PatientEncounterID"
#' p$predictedCol <- "ThirtyDayReadmitFLG"
#' p$debug <- FALSE
#' p$cores <- 1
#' 
#' RandomForest <- RandomForestDevelopment$new(p)
#' RandomForest$run()
#' 
#' p2 <- SupervisedModelDeploymentParams$new()
#' p2$type <- "classification"
#' p2$df <- dfDeploy
#' p2$grainCol <- "PatientEncounterID"
#' p2$predictedCol <- "ThirtyDayReadmitFLG"
#' p2$impute <- TRUE
#' p2$debug <- FALSE
#' p2$cores <- 1
#' 
#' dL <- RandomForestDeployment$new(p2)
#' dL$deploy()
#' 
#' ## Get Recommendations using getProcessVariablesDf
#' 
#' # Categorical variables can simply be listed as modifiableVariables and all
#' # factors levels will be used for comparison purposes. The dataframe 
#' # generated from the code below will consider all possible blood pressure
#' # categories.
#' dL$getProcessVariablesDf(modifiableVariables = c("SystolicBP"))
#' 
#' # By default, the function returns recommendations for all rows, but we can 
#' # restrict to specific rows using the grainColumnIDs parameter
#' dL$getProcessVariablesDf(modifiableVariables = c("SystolicBP"), 
#'                          grainColumnIDs = c(954, 965, 996))
#' 
#' # The variableLevels parameter can be used to limit which factor levels are
#' # considered (for categorical variables). The dataframe generated from the 
#' # code below will only make comparisons with normal BP and pre-hypertensive
#' dL$getProcessVariablesDf(modifiableVariables = c("SystolicBP"),
#'                          variableLevels = list(SystolicBP = c("Normal",
#'                                                               "Pre-hypertensive")))
#' 
#' # The variableLevels parameter can also be used to allow recommendations for 
#' # numeric variables, by providing specific target values of the numeric 
#' # variable to make comparisons to. In the code below, the predictions will be 
#' # compared to those for an A1C of 5.6
#' dL$getProcessVariablesDf(modifiableVariables = c("A1CNBR"),
#'                          variableLevels = list(A1CNBR = c(5.6)))
#' 
#' # The repeatedFactors parameter allows one to get multiple recommendations  
#' # for the same variable. For example, reducing A1C to 5.0 might most improve
#' # a patient's risk, but reducing A1C to 5.5 is likely to also reduce the risk
#' # and that change might be more impactful than altering the patient's blood
#' # pressure. When repeatedFactors is TRUE, both those results will
#' # be included. If repeatedFactors were FALSE, only the most beneficial
#' # value of A1C would be included.
#' dL$getProcessVariablesDf(modifiableVariables = c("SystolicBP", "A1CNBR"),
#'                          variableLevels = list(SystolicBP = c("Normal",
#'                                                               "Pre-hypertensive"),
#'                                                A1CNBR = c(5.0, 5.5, 6, 6.5)), 
#'                          repeatedFactors = TRUE)
#' 
#' # The numTopFactors parameter allows one to set the maximum number of 
#' # recommendations to display (with the default being 3)
#' dL$getProcessVariablesDf(modifiableVariables = c("SystolicBP", "A1CNBR"),
#'                          variableLevels = list(SystolicBP = c("Normal",
#'                                                               "Pre-hypertensive"),
#'                                                A1CNBR = c(5.0, 5.5, 6, 6.5)), 
#'                          repeatedFactors = TRUE, 
#'                          numTopFactors = 5)
#' 
#' # If greater values of the predicted variable are preferable, setting
#' # smallerBetter to FALSE will identify the factors that most increase
#' # the value of the outcome variable. In this case, the deltas will be 
#' # positive, corresponding to an increased risk
#' dL$getProcessVariablesDf(modifiableVariables = c("SystolicBP"),
#'                          smallerBetter = FALSE)

RandomForestDeployment <- R6Class("RandomForestDeployment",
  #Inheritance
  inherit = SupervisedModelDeployment,

  #Private members
  private = list(

    # variables
    coefficients = NA,
    multiplyRes = NA,
    orderedFactors = NA,
    predictedValsForUnitTest = NA,
    outDf = NA,
    
    fitRF = NA,
    predictions = NA,
    algorithmShortName = 'RF',
    algorithmName = 'RandomForest',

    # functions
    # Perform prediction
    performPrediction = function() {
      # Calculate predictions
      private$predictions <- self$performNewPredictions(self$params$df)
      
      # Print first few predictions if debug = TRUE
      if (self$params$debug) {
        if (self$params$type == "classification") {
          cat('Number of predictions: ', nrow(private$predictions), '\n')
          cat('First 10 raw classification probability predictions', '\n')
          print(round(private$predictions[1:10],2))
        } else {# type == "regression"
          cat('Rows in regression prediction: ', 
              length(private$predictions), '\n')
          cat('First 10 raw regression predictions (with row # first)', '\n')
          print(round(private$predictions[1:10],2))
        }
      }
    },

    calculateCoeffcients = function() {
      # Do semi-manual calc to rank cols by order of importance
      coeffTemp <- self$modelInfo$fitLogit$coefficients

      if (isTRUE(self$params$debug)) {
        cat('Coefficients for the default logit (for ranking var import)', '\n')
        print(coeffTemp)
      }

      private$coefficients <-
        coeffTemp[2:length(coeffTemp)] # drop intercept
    },

    calculateMultiplyRes = function() {
      if (isTRUE(self$params$debug)) {
        cat("Test set to be multiplied with coefficients", '\n')
        cat(str(private$dfTestRaw), '\n')
      }

      # Apply multiplication of coeff across each row of test set
      private$multiplyRes <- sweep(private$dfTestRaw, 2, private$coefficients, `*`)

      if (isTRUE(self$params$debug)) {
        cat('Data frame after multiplying raw vals by coeffs', '\n')
        print(private$multiplyRes[1:10, ])
      }
    },

    calculateOrderedFactors = function() {
      # Calculate ordered factors of importance for each row's prediction
      private$orderedFactors <- t(sapply
                                  (1:nrow(private$multiplyRes),
                                  function(i)
                                    colnames(private$multiplyRes[order(private$multiplyRes[i, ],
                                                                        decreasing = TRUE)])))

      if (isTRUE(self$params$debug)) {
        cat('Data frame after getting column importance ordered', '\n')
        print(head(private$orderedFactors, n = 10))
      }
    }
  ),

  #Public members
  public = list(
    #Constructor
    #p: new SupervisedModelDeploymentParams class object,
    #   i.e. p = SupervisedModelDeploymentParams$new()
    initialize = function(p) {

      super$initialize(p)

      if (!is.null(p$rfmtry))
        self$params$rfmtry <- p$rfmtry

      if (!is.null(p$trees))
        self$params$trees <- p$trees
    },

    #Override: deploy the model
    deploy = function() {
      
      # Start sink to capture console ouptut
      sink("tmp_prediction_console_output.txt", append = FALSE, split = TRUE)

      # Try to load the model
      private$fitRF <- private$fitObj
      private$fitObj <- NULL
      
      # Make sure factor columns have the training data factor levels
      super$formatFactorColumns()
      # Update self$params$df to reflect the training data factor levels
      self$params$df <- private$dfTestRaw

      # Predict
      private$performPrediction()

      # Get dummy data based on factors from develop
      super$makeFactorDummies()

      # Calculate Coeffcients
      private$calculateCoeffcients()

      # Calculate MultiplyRes
      private$calculateMultiplyRes()

      # Calculate Ordered Factors
      private$calculateOrderedFactors()

      # create dataframe for output
      super$createDf()
      
      sink()  # Close connection
      # Get metadata, attach to output DF and write to text file
      super$getMetadata()
      
    },
    
    # Surface outDf as attribute for export to Oracle, MySQL, etc
    getOutDf = function() {
      return(private$outDf)
    },
    
    # Perform predictions on new data
    performNewPredictions = function(newData) {
      if (self$params$type == "classification") {
        predictions <- caret::predict.train(object = private$fitRF,
                                            newdata = newData,
                                            type = 'prob')
        predictions <- predictions[,2]
      } else {
        predictions <- caret::predict.train(private$fitRF, newdata = newData)
      }
      return(predictions)
    }
  )
)
