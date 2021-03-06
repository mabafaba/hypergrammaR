#' Map to Design
#'
#' creates a `survey` design object from the data
#'
#' @param data
#' @param cluster.var if cluster sampling was used, what's the name of the column in `data` that identifies the cluster?
#' @details create a `survey` package design object from the data and information on the sampling strategy
#' @return a `survey` package design object
#' @examples map_to_design(data,cluster.var="cluster_id")
#' @export
map_to_design <- function(data,
                          cluster.var = NULL) {
  if(is.null(cluster.var)){
    cluster.ids <- as.formula(c("~1"))}else{
    cluster.ids <- cluster.var}
  strata.weights <- reachR:::weights_of(data)
  survey.design <- svydesign(data = data,
      ids = formula(cluster.ids),
      strata = names(strata.weights),
      weights = as.vector(strata.weights))
    return(survey.design)}
#add to this an option that strata weights can be the vector of weights if there is one in the data & warning that we usually dont do this

#' Map to case
#'
#' creates a string that other functions can use to know what analysis case they are dealing with
#'
#' @param data missing documentation
#' @param hypothesis.type
#' @param dependent.var
#' @param independent.var
#' @param paired
#' @return a string that other functions can use to know what analysis case they are dealing with. It has a class "analysis_case" assigned
#' @examples map_to_design(data,cluster.var="cluster_id")
#' @export
map_to_case<-function(data,
                      hypothesis.type,
                      dependent.var,
                      independent.var = NULL,
                      paired = NULL){
  variable.type <- paste0(reachR:::variable_type(dependent.var), "_", reachR:::variable_type(independent.var))
  case <- paste(c("CASE",hypothesis.type,variable.type, paired), collapse = "_")
  class(case)<-"analysis_case"
  return(case)
}


list_all_cases<-function(implemented_only=F){

  if(!implemented_only){
    hypothesis_types<-c("direct_reporting","group_difference","limit","correlation","change")
    dependent.var.types<-c("numerical","categorical")
    independent.var.types<-c("numerical","categorical")
    valid_cases<- apply(expand.grid("CASE",hypothesis_types, dependent.var.types,independent.var.types), 1, paste, collapse="_")
    return(valid_cases)
  }

  return(c(
    "CASE_group_difference_categorical_categorical",
    "CASE_group_difference_numerical_categorical",
    "CASE_direct_reporting_numeric_",
    "CASE_direct_reporting_categorical_"
  ))
}


is_valid_case_string<-function(x,implemented_only=T){

  return(x %in% list_all_cases(implemented_only = implemented_only))

}

case_not_implemented_error<-function(case,situation){
  stop(paste(situation,":  case", case, "not implemented"))
}



#' map to summary statistic
#'
#' selects an appropriate summary statistic function based on the analysis case
#'
#' @param case a string uniquely identifying the analysis case. output of \link{\code{map_to_case}}. To list valid case strings use \link{\code{list_all_cases}}
#' @return a _function_ that computes the relevant summary statistic
#' @examples map_to_summary_statistic("group_difference_categorical_categorical")
#' @examples my_case<- map_to_case( ... )
#' my_sumstat <- map_to_summary_statistic(my_case)
#' my_sumstat( ... )
#' @export
map_to_summary_statistic <- function(case) {
  # sanitise input:
  if(!is_valid_case_string(case)){stop("input to map_to_summary_statistic must be a valid analysis case")}

  # define summary functions for all cases:
  summary_functions<-list()
  summary_functions$CASE_group_difference_categorical_categorical <- percent_with_confints
  summary_functions$CASE_direct_reporting_numeric_ <- confidence_intervals_num
  summary_functions$CASE_direct_reporting_categorical_ <- percent_with_confints
  # summary_functions$CASE_group_difference_numerical_numerical <- function(...){stop(paste("summary statistic for case",case,"not implemented"))}hypothesis_test_one_sample_t
  summary_functions$CASE_group_difference_numerical_categorical <- confidence_intervals_num_groups



  # return corresponding summary function:

  return(summary_functions[[case]])

}



#' map to hypothesis test
#'
#' selects an appropriate hypothesis test function based on the analysis case
#'
#' @param case a string uniquely identifying the analysis case. output of \link{\code{map_to_case}}. To list valid case strings use \link{\code{list_all_cases}}
#' @return a _function_ that computes the relevant hypothesis test
#' @examples map_to_summary_statistic("group_difference_categorical_categorical")
#' @examples my_case<- map_to_case( ... )
#' my_hyptest <- map_to_hypothesis_test(my_case)
#' my_hyptest( ... )
#' @export
map_to_hypothesis_test <- function(case) {
  # prefill all valid cases with 'not implemented' errors:
  hypothesis_test_functions<-list()
  hypothesis_test_functions<-lapply(list_all_cases(implemented_only = F),function(x){
    function(...){stop(paste("not implemented: hypothesis test for case",x,".\n the geneva data unit can help!"))}
  })
  names(hypothesis_test_functions)<-list_all_cases(implemented_only = F)

  # add implemented cases:
  hypothesis_test_functions[["CASE_group_difference_categorical_categorical"]] <- hypothesis_test_chisquared
  hypothesis_test_functions[["CASE_direct_reporting_numerical_"]] <- hypothesis_test_empty
  hypothesis_test_functions[["CASE_direct_reporting_categorical_"]] <- hypothesis_test_empty
  hypothesis_test_functions[["CASE_group_difference_numerical_categorical"]] <- hypothesis_test_t_two_sample
  # return function belonging to this case:
  return(hypothesis_test_functions[[case]])
}


#################################
# map to visualisation:         #
#################################


#' map to visualisation
#'
#' selects an appropriate visualisation function based on the analysis case
#'
#' @param case a string uniquely identifying the analysis case. output of \link{\code{map_to_case}}. To list valid case strings use \link{\code{list_all_cases}}
#' @return a _function_ that creates the relevant ggplot object
#' @examples map_to_visualisation("group_difference_categorical_categorical")
#' @examples my_case<- map_to_case( ... )
#' my_vis_fun <- map_to_visualisation(my_case)
#' my_ggplot_obj<-my_vis_fun( ... )
#' my_ggplot_obj # plots the object
#' @export

map_to_visualisation <- function(case) {
  visualisation_functions<-list()
  # prefill all valid cases with 'not implemented' errors:
  visualisation_functions<-list()
  visualisation_functions<-lapply(list_all_cases(implemented_only = F),function(x){
    function(...){stop(paste("not implemented: visualisation for case",x,".\n the geneva data unit can help!"))}
  })
  names(visualisation_functions)<-list_all_cases(implemented_only = F)

  # add implemented cases:
  visualisation_functions[["CASE_group_difference_categorical_categorical"]] <- barchart_with_error_bars
  visualisation_functions[["CASE_direct_reporting_categorical_"]] <- barchart_with_error_bars
  visualisation_functions[["CASE_direct_reporting_numerical_"]] <- barchart_with_error_bars
  visualisation_functions[["CASE_group_difference_numerical_categorical"]] <- barchart_with_error_bars

  return(visualisation_functions[[case]])
}


