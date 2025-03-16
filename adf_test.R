#' Augmented Dickey-Fuller (ADF) Unit Root Test
#'
#' @description
#' Performs the ADF test to check for stationarity in time series.
#' If non-stationary series are found, it automatically applies the test on the first difference.
#'
#' @param data DataFrame containing the time series to be tested
#' @param type Type of ADF test to be performed:
#'   - "none": no constant or trend
#'   - "drift": with constant (default)
#'   - "trend": with constant and trend
#'
#' @return
#' If all series are stationary at level:
#'   - DataFrame with test results containing: variable, tau statistic,
#'     critical value (5%), and result (stationary/non-stationary)
#'
#' If there are non-stationary series:
#'   - List with two DataFrames:
#'     1. "Test at level": test results at level
#'     2. "Test with one difference": test results at the first difference
#'        for non-stationary series at level
#'
#' @details
#' - Applies the test only on numeric columns of the DataFrame
#' - Uses 5% significance level critical values
#' - Utilizes the urca package for the ADF test and dplyr/purrr for data manipulation
#' - Uses different statistics for each test type:
#'   * none: tau1
#'   * drift: tau2
#'   * trend: tau3
#'
#' @examples
#' # Test with constant (default)
#' results <- adf_test(data)
#'
#' # Test with constant and trend
#' results <- adf_test(data, type = "trend")
#'
#' # Accessing results when there are non-stationary series
#' results$`Test at level`
#' results$`Test with one difference`
adf_test <- function(data, type = "drift") {
  get_test_values <- function(test, type) {
      if (type == "none") {
          stat <- test@teststat[1] # tau1 statistic
          crit <- test@cval[2] # 5% critical value for tau1
      } else if (type == "drift") {
          stat <- test@teststat[1] # tau2 statistic
          crit <- test@cval[1, 2] # 5% critical value for tau2
      } else if (type == "trend") {
          stat <- test@teststat[1] # tau3 statistic
          crit <- test@cval[1, 2] # 5% critical value for tau3
      }
      return(list(stat = stat, crit = crit))
  }

  adf_test <- data |>
      dplyr::select(dplyr::where(is.numeric)) |>
      purrr::map(~ urca::ur.df(.x, type = type))

  df <- data.frame(
      variable = as.character(),
      tau = as.numeric(),
      critical_value = as.numeric()
  )

  for (i in seq_along(adf_test)) {
      test_values <- get_test_values(adf_test[[i]], type)
      df <- rbind(df, data.frame(
          variable = names(adf_test)[i],
          tau = round(test_values$stat, digits = 3),
          critical_value = round(test_values$crit, digits = 3)
      ))
  }

  df$result <- dplyr::case_when(
      df$tau > df$critical_value ~ "non-stationary",
      df$tau <= df$critical_value ~ "stationary"
  )

  if (any(df$result == "non-stationary")) {
      non_stationary_vars <- df |>
          dplyr::filter(result == "non-stationary") |>
          dplyr::pull(var = "variable")

      adf_test2 <- data |>
          dplyr::select(dplyr::any_of(non_stationary_vars)) |>
          purrr::map(~ diff(.x) |>
              urca::ur.df(type = type))

      df2 <- data.frame(
          variable = as.character(),
          tau = as.numeric(),
          critical_value = as.numeric()
      )

      for (i in seq_along(adf_test2)) {
          test_values <- get_test_values(adf_test2[[i]], type)
          df2 <- rbind(df2, data.frame(
              variable = names(adf_test2)[i],
              tau = round(test_values$stat, digits = 3),
              critical_value = round(test_values$crit, digits = 3)
          ))
      }

      df2$result <- dplyr::case_when(
          df2$tau > df2$critical_value ~ "non-stationary",
          df2$tau <= df2$critical_value ~ "stationary"
      )

      return(list(
          "Test at level" = df,
          "Test with one difference" = df2
      ))
  }

  return(df)
}

#' Remove Unit Root Through Sequential Differencing
#'
#' @description
#' Applies sequential differencing to non-stationary variables until stationarity
#' is achieved or maximum differences are reached. Uses Augmented Dickey-Fuller test
#' to check for stationarity.
#'
#' @param data A data frame containing time series variables to be tested and
#'   potentially differenced
#' @param max_diff Maximum number of differences to apply. Default is 3
#'
#' @return A list containing two elements:
#'   \itemize{
#'     \item data: The transformed data frame with differenced variables
#'     \item control: A tibble tracking which variables were differenced and how many times
#'   }
#'
#' @examples
#' \dontrun{
#' result <- remove_unit_root(data, max_diff = 2)
#' print(result$control)
#' }
#' @export
remove_unit_root <- function(data, max_diff = 3) {
  df_temp <- data
  df_control <- tibble::tibble(
      variable = character(),
      times_diff = numeric()
  )

  for (i in 1:max_diff) {
      test_data <- df_temp |>
          tidyr::drop_na()
      test_result <- adf_test(test_data)
      if (!is.list(test_result) || !("Test at level" %in% names(test_result))) {
          test_result <- list("Test at level" = test_result)
      }
      names_unit_root <- test_result[["Test at level"]] |>
          dplyr::filter(result == "non-stationary") |>
          dplyr::pull(variable)
      if (length(names_unit_root) == 0) break
      df_temp <- df_temp |>
          dplyr::mutate(
              dplyr::across(
                  .cols = dplyr::all_of(names_unit_root),
                  .fns = ~ c(NA, diff(.x))
              )
          )
      new_controls <- tibble::tibble(
          variable = names_unit_root,
          times_diff = i
      )
      df_control <- dplyr::bind_rows(
          df_control,
          new_controls
      )
  }
  return(list("data" = df_temp, "control" = df_control))
}














#' Conduct Panel Unit Root Tests
#'
#' This function performs three panel unit root tests—Maddala and Wu, Choi, and Levin-Lin-Chu—on the provided panel data.
#'
#' @param data A data frame or matrix where rows represent time periods and columns represent individual units (e.g., countries, firms).
#'
#' @return A list containing the results of the Maddala and Wu test (`mw`), Choi test (`choi`), and Levin-Lin-Chu test (`llc`). Each element is an object of class `"htest"` with components:
#'   \item{statistic}{The value of the test statistic.}
#'   \item{parameter}{The degrees of freedom for the test statistic.}
#'   \item{p.value}{The p-value for the test.}
#'   \item{method}{A character string indicating the type of test performed.}
#'   \item{data.name}{A character string giving the name of the data.}
#' Additionally, the list includes a `summary` function to print the test results.
#'
#' @details
#' **Maddala and Wu Test**: This is a Fisher-type test that combines p-values from individual unit root tests across cross-sections. It does not assume a common autoregressive parameter across panels, making it suitable for heterogeneous panels. [See plm package documentation](https://search.r-project.org/CRAN/refmans/plm/help/purtest.html)
#'
#' **Choi Test**: Another Fisher-type test similar to Maddala and Wu's, but with different combining methods for p-values. It also accommodates heterogeneity across panels. [See plm package documentation](https://search.r-project.org/CRAN/refmans/plm/help/purtest.html)
#'
#' **Levin-Lin-Chu Test**: Assumes a common autoregressive parameter across panels, implying homogeneity. It is more powerful when this assumption holds but may be restrictive for heterogeneous panels. [See plm package documentation](https://search.r-project.org/CRAN/refmans/plm/help/purtest.html)
#'
#' @examples
#' \dontrun{
#' # Assuming 'panel_data' is a data frame with time series data
#' results <- panel_unit_root_tests(panel_data)
#' results$summary()
#' }
#'
#' @import plm
#' @export
panel_unit_root_tests <- function(data) {
    # Prepare data in panel format
    T <- nrow(data)
    N <- ncol(data)
  
    panel_data <- data.frame(
      id = rep(1:N, each = T),
      time = rep(1:T, N),
      y = as.vector(data)
    )
  
    # Create pdata.frame object
    panel_data <- plm::pdata.frame(panel_data, index = c("id", "time"))
  
    # Maddala and Wu test
    mw_test <- plm::purtest(panel_data$y, test = "madwu", exo = "intercept")
  
    # Choi test
    choi_test <- plm::purtest(panel_data$y, test = "Pm", exo = "intercept")
  
    # Levin-Lin-Chu test
    llc_test <- plm::purtest(panel_data$y, test = "levinlin", exo = "intercept")
  
    # Organize results
    results <- list(
      mw = mw_test,
      choi = choi_test,
      llc = llc_test
    )
  
    # Summary function
    summary <- function() {
      cat("\nPanel Unit Root Tests:\n")
      cat("================================\n")
  
      cat("\n1. Maddala and Wu Test:\n")
      print(mw_test)
  
      cat("\n2. Choi Test:\n")
      print(choi_test)
  
      cat("\n3. Levin-Lin-Chu Test:\n")
      print(llc_test)
    }
  
    results$summary <- summary
    return(results)
}
