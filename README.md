# rk.questionr: Survey Data Visualization for RKWard

![Version](https://img.shields.io/badge/Version-0.4.1-blue.svg)

This RKWard plugin provides a powerful and user-friendly graphical interface for creating highly customized bar charts from complex survey data. It leverages the capabilities of the `questionr`, `ggsurvey`, `srvyr`, and `ggplot2` packages to produce publication-quality plots without writing code.

## Features

This plugin is designed to give you granular control over nearly every aspect of your survey bar chart.

### Data & Core Plotting

*   **Frequency Type**: Choose between **Absolute** frequencies (counts) or **Relative** frequencies (proportions).
*   **Bar Positioning**: For absolute frequency plots, control the bar layout with **Stack**, **Dodge**, or **Fill (Proportional)** options.
*   **Faceting**: Split your plot into multiple panels using a faceting variable, with full control over the layout (wrap, single row, or single column).
*   **Advanced Ordering**:
    *   Order the x-axis based on total frequency or proportion.
    *   Order the x-axis based on the contribution of a *single, specific level* from the fill variable.
    *   Invert the final plot order for intuitive top-to-bottom displays when coordinates are flipped.
*   **Coordinate Flipping**: Easily switch between vertical and horizontal bar charts.
*   **NA Handling**: Conveniently omit missing cases from all selected variables with a single checkbox.

### Value Labels

*   **Display Labels**: Add value or percentage labels directly onto the bars.
*   **Flexible Labeling Style**:
    *   Use `geom_text` for simple text.
    *   Use `geom_label` to add a high-contrast background to each label.
    *   Enable `ggrepel` to intelligently prevent labels from overlapping. Both `geom_text_repel` and `geom_label_repel` are supported.
*   **Appearance Control**: Customize label color (with presets or a custom hex code), size, and the number of decimal places for percentages.

### Advanced Customization & Theming

*   **Automatic Labeling**: Axis and legend titles are automatically populated from RKWard's variable labels (`rk.get.label()`), but can be easily overridden.
*   **Comprehensive Text Wrapping**: Control line wrapping width for:
    *   Plot Titles & Subtitles
    *   Axis Titles (X and Y)
    *   Axis Value Labels (X and Y)
    *   Legend Title and Legend Item Labels
*   **Color Control**:
    *   Select from a curated list of `RColorBrewer` palettes for the main plot aesthetics.
*   **Full Theme Control**:
    *   Adjust the relative size of all plot text, titles, and legend text.
    *   Precisely control the angle and justification (`hjust`, `vjust`) of x-axis text to handle long labels.
    *   Change the legend position (top, bottom, left, right, or none).
*   **Output Device Options**: Full control over the output format (PNG, SVG, JPG), dimensions, resolution, and background color.



## Installation

1.  You must have the `remotes` package installed in R. If not, run:
    ```R
    install.packages("remotes")
    ```
2.  Install the plugin directly from GitHub by running the following command in R:
    ```R
    remotes::install_github("AlfCano/rk.questionr")
    ```
3.  Restart the RKWard application. The plugin will be automatically detected and loaded.

## Usage

After installation, you can find the plugin in the RKWard menu under:

**Survey -> Graphs -> ggGraphs -> Bar Chart (questionr)**

## Dependencies

For this plugin to function correctly, the following R packages must be installed:

*   `questionr`
*   `srvyr`
*   `survey`
*   `ggplot2`
*   `dplyr`
*   `forcats`
*   `stringr`
*   `scales`
*   `RColorBrewer`
*   `ggrepel`

## Author & License

*   **Author**: Alfonso Cano (<alfonso.cano@correo.buap.mx>) and Gemeni a LLM from Google.
*   **License**: GPL (>= 3)
