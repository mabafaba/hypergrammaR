
####################
# SETUP
####################
      # clear wd set wd to this script's folder
      rm(list = ls())
      this_script_path<-(dirname(rstudioapi::getActiveDocumentContext()$path))
      setwd(this_script_path)
      getwd()
      
      ####################
      # run once
      ####################
      # install.packages("data.table")
      # .install_reachR(T, branch = "develop")
      ####################
      
      source("./scripts/dependencies.R")
      source("./scripts/analyse_indicator.R")
      source("./scripts/mappings.R")
      source("./scripts/summary_statistics.R")
      source("./scripts/hypothesis_tests.R")
      source("./scripts/visualisations.R")
      
      library(reachR)
      #install.packages("bit64")
      # library(bit64)
      require(data.table)
      require(survey)
      options(survey.lonely.psu = "average")

####################
# LOAD FILES
####################

    # the cleaning checks will be hidden somewhere else, for now they live here
    data <- load_data(file = "./data/kri_winter.csv")

    data <- data[data$group!="#N/A",]
    
    populations <-load_samplingframe("./data/kri_winter_weights.csv",
                                    sampling.frame.population.column="population",
                                    sampling.frame.stratum.column = "group",
                                    data.stratum.column = "group", return.stratum.populations = T)
    
    
    
    questionnaire <- load_questionnaire(data = "./data/kri_winter.csv", 
                                        questions.file = "./data/questions_kri_winter.csv", 
                                        choices.file = "./data/choices_kri_winter.csv", 
                                        choices.label.column.to.use = "english")


    # percent of questions successfully matched:
    (length(questionnaire$questions$name %>% hasdata)/length(questionnaire$questions$name)*100) %>% round %>% paste0("% questions matched") %>% cat
    #this warning needs to be integrated in load_questionnaire
    if("weights" %in% names(data)){stop("'weights' is not allowed as a column name (will be calculated from the sampling frame)")}

####################
# PARAMETERS
####################

  dependent.var = "modality"
    if(nrow(data)==0){stop('dependent var is all NA')}
  independent.var = "idp.ref"
  hypothesis.type="group_difference"
  

####################
# test what becomes analyse_indicator() later:
####################
  data <- data[!is.na(dependent.var),]
  data <- data[!(dependent.var %in% c("NA", "N/A")),]
  
    # select methods
    variable_weights <- reachR:::weights_of(data)
   
    design <- svydesign(ids =~1,
                        strata = data$group,
                        weights = variable_weights %>% as.vector,
                        data = data)


    undebug(analyse_indicator)
    undebug(percent_with_confints)
    
    
  results <-  analyse_indicator(data, dependent.var, independent.var, hypothesis.type, design)  
    
  
  results$visualisation(results$hypothesis.test.result,results$summary.statistic)
  
  
  
  
  
  
  
    
    
    
    
