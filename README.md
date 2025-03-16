# Unit Root Tests and Differencing in R

## Overview
This repository contains three R functions for handling unit root tests in time series data:

1. **`adf_test`**: Performs the Augmented Dickey-Fuller (ADF) test to check for stationarity in time series. If non-stationary series are detected, the test is automatically applied to their first differences.
2. **`remove_unit_root`**: Sequentially differences non-stationary variables until stationarity is achieved or a maximum number of differences is reached.
3. **`panel_unit_root_tests`**: Conducts panel unit root tests (Maddala and Wu, Choi, and Levin-Lin-Chu) on panel data.

### Why Use These Functions?
These functions automate the process of checking for unit roots and transforming data to stationarity, saving time and effort when working with large datasets. They:
- Apply the ADF test efficiently to multiple time series variables.
- Automatically identify and handle non-stationary series.
- Perform sequential differencing without manual intervention.
- Provide clear outputs, making it easy to track transformations.
- Conduct panel unit root tests to handle panel data.

## Installation
Ensure you have the required R packages installed before using the functions:

```r
install.packages(c("urca", "dplyr", "purrr", "tidyr", "tibble", "plm"))# Unit Root Tests and Differencing in R

## Overview
This repository contains two R functions for handling unit root tests in time series data:

1. **`adf_test`**: Performs the Augmented Dickey-Fuller (ADF) test to check for stationarity in time series. If non-stationary series are detected, the test is automatically applied to their first differences.
2. **`remove_unit_root`**: Sequentially differences non-stationary variables until stationarity is achieved or a maximum number of differences is reached.

### Why Use These Functions?
These functions automate the process of checking for unit roots and transforming data to stationarity, saving time and effort when working with large datasets. They:
- Apply the ADF test efficiently to multiple time series variables.
- Automatically identify and handle non-stationary series.
- Perform sequential differencing without manual intervention.
- Provide clear outputs, making it easy to track transformations.

## Installation
Ensure you have the required R packages installed before using the functions:

```r
install.packages(c("urca", "dplyr", "purrr", "tidyr", "tibble"))
```

## Usage
### Augmented Dickey-Fuller (ADF) Test

```r
# Load the functions
source("adf_test.R")

# Example: Run ADF test on a data frame
results <- adf_test(data)

# Access results
print(results)
```

### Removing Unit Roots with Sequential Differencing

```r
# Load the function
source("remove_unit_root.R")

# Example: Apply sequential differencing
result <- remove_unit_root(data, max_diff = 2)

# Transformed data
transformed_data <- result$data

# Check differencing history
print(result$control)
```

### Panel Unit Root Tests

```r
# Load the function
source("panel_unit_root_tests.R")

# Example: Conduct panel unit root tests
results <- panel_unit_root_tests(panel_data)

# Print summary of results
results$summary()
```

## Function Details
### `adf_test(data, type = "drift")`
- **Description**: Runs the Augmented Dickey-Fuller (ADF) test for stationarity on all numeric columns in a data frame.
- **Parameters**:
  - `data`: A data frame with time series variables.
  - `type`: Type of ADF test (`"none"`, `"drift"`, or `"trend"`). Default is `"drift"`.
- **Returns**:
  - If all series are stationary: A data frame with test results.
  - If non-stationary series are detected: A list with results for level and first difference tests.

### `remove_unit_root(data, max_diff = 3)`
- **Description**: Applies sequential differencing to non-stationary variables.
- **Parameters**:
  - `data`: A data frame with time series variables.
  - `max_diff`: Maximum number of differences to apply (default = 3).
- **Returns**: A list with transformed data and a control table tracking the differencing process.


### `panel_unit_root_tests(panel_data)`

- **Description**: Conducts panel unit root tests (Maddala and Wu, Choi, and Levin-Lin-Chu) on panel data.

- **Parameters**:
  - `data`: A data frame or matrix where rows represent time periods and columns represent individual units (e.g., countries, firms).

- **Returns**: A list containing the results of the Maddala and Wu test (`mw`), Choi test (`choi`), and Levin-Lin-Chu test (`llc`). Each element is an object of class `"htest"` with components:
  - `statistic`: The value of the test statistic.
  - `parameter`: The degrees of freedom for the test statistic.
  - `p.value`: The p-value for the test.
  - `method`: A character string indicating the type of test performed.
  - `data.name`: A character string giving the name of the data.
  - Additionally, the list includes a `summary` function to print the test results.



## Contributions
Feel free to open issues or submit pull requests for improvements!
