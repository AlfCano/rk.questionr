# rk.questionr: Complex Survey Analysis & Visualization

![Version](https://img.shields.io/badge/Version-0.5.0-blue.svg)
![License](https://img.shields.io/badge/License-GPLv3-blue.svg)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.questionr/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.questionr/actions/workflows/lintr.yml)

This RKWard plugin provides a powerful suite of tools for analyzing and visualizing complex survey data (weighted data). It leverages the `questionr` package alongside `ggplot2` and `survey` to produce statistically correct, publication-ready graphs and tables without writing code.

## What's New in Version 0.5.0

This major update introduces powerful data manipulation directly from the GUI:

*   **Data Filtering (Subset):** Write direct logical expressions (e.g., `age >= 18 & sex == 'Female'`) to filter your survey design on the fly before plotting.
*   **Clean Factor Levels:** Automatically drop unused factor levels (`forcats::fct_drop`) after subsetting to prevent empty categories in your charts without breaking the survey design.
*   **Save Plot Objects:** Save any generated `ggplot2` object directly to your R Workspace for further manipulation, combining with `patchwork`, or exporting.
*   *(Since v0.4.8)* **Multilingual Support:** Fully localized in English, Spanish, French, German, and Portuguese (Brazil).

## What's New in Version 0.4.8

This version focuses on accessibility and internationalization. The entire plugin suite has been fully localized.

*   **Multilingual Support:** The interface is now available in:
    *   🇺🇸 English (Default)
    *   🇪🇸 Spanish (`es`)
    *   🇫🇷 French (`fr`)
    *   🇩🇪 German (`de`)
    *   🇧🇷 Portuguese (Brazil) (`pt_BR`)

## Features

The plugin offers four distinct components, organized for ease of use:

### 1. Survey Bar Chart
A highly customizable bar chart for categorical variables.
*   **Frequency Types**: Switch between **Absolute** counts and **Relative** proportions.
*   **Layouts**: Support for **Stacked**, **Dodged**, and **Proportional (Fill)** bar positions.
*   **Smart Ordering**:
    *   Order X-axis by total frequency.
    *   Order X-axis by the frequency of a specific subgroup (Fill level).
    *   Invert order for vertical layouts.
*   **Value Labels**: Advanced labeling options including **ggrepel** to prevent overlap, custom backgrounds (`geom_label`), and decimal control. Labels are correctly calculated per segment.
*   **Faceting**: Split plots by subgroups with flexible layout controls.

### 2. Survey Histogram
Visualize the distribution of numeric variables in survey designs.
*   **Weighted Visualization**: Correctly accounts for survey weights in bin heights.
*   **Density Curves**: Overlay a weighted density curve on top of the histogram.
*   **Customization**: Control bin count, fill colors, and border colors.

### 3. Survey Boxplot
Compare distributions of numeric variables across groups.
*   **Weighted Statistics**: The boxplots represent weighted quartiles and medians, not just raw data summaries.
*   **Smart Ordering**: Automatically **sort groups by their weighted median** (ascending or descending) for clearer comparison.
*   **Visual Options**: Toggle "Varwidth" (box width proportional to sample size), grouping colors, and coordinate flipping.

### 4. Survey Frequency Table
Generate detailed tabular summaries for categorical variables.
*   **Weighted Counts**: Calculates counts and percentages based on survey design weights.
*   **Options**: Toggle Cumulative Percentages, Total Rows, and exclusion of NA values.
*   **Sorting**: Sort by frequency (increasing/decreasing) or factor levels.
*   **Save Object**: Save the resulting frequency table to the R workspace. This allows the object to be passed to other plugins (like **rk.flextable**) for formatting and export.

---

### Shared Features (All Graphs)
All graphical plugins in this package share a consistent set of data preparation and styling tools:
*   **Data Filtering**: Apply on-the-fly `subset()` operations and drop unused factor levels before rendering.
*   **Save Output**: Export the raw `ggplot2` object to your R workspace.
*   **Theming**: Adjust relative text sizes, legend position, and axis text angles/justification.
*   **Labels & Wrapping**: Automatic text wrapping for long titles, axis labels, and legend items.
*   **Palettes**: Integrated **ColorBrewer** palette selector (Paired, Set1, Dark2, Spectral, etc.) with automatic interpolation for variables with many categories.
*   **Export**: High-resolution export options for PNG and SVG with custom dimensions and **Resolution (ppi)** control.

## Installation

1.  **Prerequisite:** Ensure you have the `remotes` (or `devtools`) package installed in R.
2.  **Install:** Run the following command in the RKWard R Console:

    ```R
    # If you don't have devtools/remotes installed:
    # install.packages("remotes")
    
    local({
      require(remotes)
      install_github("AlfCano/rk.questionr", force = TRUE)
    })
    ```
3.  **Restart:** Restart RKWard to load the new menu entries and translations.

## Usage

After installation, the plugins are organized under the **Survey** menu:

*   **Graphs:**
    *   `Survey -> Graphs -> questionr -> Bar Chart`
    *   `Survey -> Graphs -> questionr -> Histogram`
    *   `Survey -> Graphs -> questionr -> Boxplot`
*   **Tables:**
    *   `Survey -> Descriptive -> Frequency Table`

## Dependencies

This plugin requires the following R packages:
*   `questionr`
*   `survey`
*   `ggplot2`
*   `ggrepel`
*   `RColorBrewer`
*   `dplyr`
*   `forcats`
*   `scales`

## Author & License

*   **Author**: Alfonso Cano (<alfonso.cano@correo.buap.mx>)
*   **Assisted by**: Gemini, a large language model from Google.
*   **License**: GPL (>= 3)
