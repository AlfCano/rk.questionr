local({
  # =========================================================================================
  # Package Definition and Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  package_about <- rk.XML.about(
    name = "rk.questionr",
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "A plugin package to analyze complex survey designs with custom plugins and the 'questionr' package.",
      version = "0.4.1",
      url = "https://github.com/AlfCano/rk.questionr",
      license = "GPL (>= 3)"
    )
  )

  # =========================================================================================
  # --- Reusable UI Components & JS Helpers ---
  # =========================================================================================

  js_helpers <- '
    function getColumnName(fullName) {
        if (!fullName) return "";
        var lastBracketPos = fullName.lastIndexOf("[[");
        if (lastBracketPos > -1) {
            var lastPart = fullName.substring(lastBracketPos);
            var match = lastPart.match(/\\[\\[\\"(.*?)\\"\\]\\]/);
            if (match) {
                return match[1];
            }
        }
        if (fullName.indexOf("$") > -1) {
            return fullName.substring(fullName.lastIndexOf("$") + 1);
        } else {
            return fullName;
        }
    }
  '

  labels_tab <- rk.XML.col(
    rk.XML.input(label = "Plot Title", id.name = "plot_title"),
    rk.XML.input(label = "Plot Subtitle", id.name = "plot_subtitle"),
    rk.XML.input(label = "X-axis Label (blank for auto)", id.name = "plot_xlab"),
    rk.XML.spinbox(label = "Wrap X-axis Label at (chars, 0 to disable)", id.name = "plot_xlab_wrap", min = 0, max = 100, initial = 0),
    rk.XML.input(label = "Y-axis Label", id.name = "plot_ylab"),
    rk.XML.spinbox(label = "Wrap Y-axis Label at (chars, 0 to disable)", id.name = "plot_ylab_wrap", min = 0, max = 100, initial = 0),
    rk.XML.input(label = "Legend Title (blank for auto)", id.name = "plot_legend_title"),
    rk.XML.spinbox(label = "Wrap Legend Title at (chars, 0 to disable)", id.name = "legend_title_wrap_width", min = 0, max = 100, initial = 20),
    rk.XML.spinbox(label = "Wrap Legend Labels at (chars, 0 to disable)", id.name = "legend_wrap_width", min = 0, max = 100, initial = 20),
    rk.XML.input(label = "Plot Caption", id.name = "plot_caption")
  )

  # MODIFIED: Both checkboxes are now unchecked by default
  value_labels_tab <- rk.XML.col(
    rk.XML.cbox(label="Show value labels on bars", id.name="show_value_labels", value="1"),
    rk.XML.frame(label="Label Style", child=rk.XML.col(
      rk.XML.cbox(label="Repel labels to prevent overlap (ggrepel)", id.name="label_repel", value="1"),
      rk.XML.cbox(label="Add background to labels (geom_label)", id.name="label_background", value="1")
    )),
    rk.XML.dropdown(label="Label Color Preset", id.name="label_color_preset", options=list(
        "Black"=list(val="black", chk=TRUE),
        "White"=list(val="white"),
        "Grey"=list(val="grey50"),
        "Blue"=list(val="blue"),
        "Red"=list(val="red"),
        "Use Custom Field Below"=list(val="custom")
    )),
    rk.XML.input(label="Custom Label Color (e.g., #FFC0CB)", id.name="label_color_custom"),
    rk.XML.spinbox(label="Label text size", id.name="label_size", min=1, max=20, initial=3, real=TRUE),
    rk.XML.spinbox(label="Decimal places (for %)", id.name="label_decimals", min=0, max=5, initial=1),
    rk.XML.spinbox(label="Max. Overlaps (if repelling)", id.name="label_max_overlaps", min=0, max=1000, initial=10)
  )

  device_tab <- rk.XML.col(
    rk.XML.dropdown(label = "Device type", id.name = "device_type", options = list("PNG" = list(val = "PNG", chk = TRUE), "SVG" = list(val = "SVG"), "JPG" = list(val = "JPG"))),
    rk.XML.spinbox(label = "JPG Quality (0-100)", id.name = "jpg_quality", min = 0, max = 100, initial = 75),
    rk.XML.spinbox(label = "Width (px)", id.name = "dev_width", min = 100, max = 4000, initial = 1024),
    rk.XML.spinbox(label = "Height (px)", id.name = "dev_height", min = 100, max = 4000, initial = 724),
    rk.XML.spinbox(label = "Resolution (ppi)", id.name = "dev_res", min = 50, max = 600, initial = 200),
    rk.XML.dropdown(label = "Background", id.name = "dev_bg", options = list("Transparent" = list(val = "transparent", chk = TRUE), "White" = list(val = "white")))
  )

  color_palette_dropdown <- rk.XML.dropdown(label = "Color Palette (ColorBrewer)", id.name = "palette_input", options = list(
    "Default (Paired)" = list(val = "Paired", chk = TRUE), "Accent" = list(val = "Accent"), "Dark2" = list(val = "Dark2"),
    "Pastel1" = list(val = "Pastel1"), "Pastel2" = list(val = "Pastel2"), "Set1" = list(val = "Set1"),
    "Set2" = list(val = "Set2"), "Set3" = list(val = "Set3"), "Blues" = list(val = "Blues"),
    "Greens" = list(val = "Greens"), "Oranges" = list(val = "Oranges"), "Reds" = list(val = "Reds"),
    "Purples" = list(val = "Purples"), "RdYlBu" = list(val = "RdYlBu"), "Spectral" = list(val = "Spectral")
  ))

  js_printout <- '
    if(!is_preview){
      var graph_options = [];
      graph_options.push("device.type=\\"" + getValue("device_type") + "\\"");
      graph_options.push("width=" + getValue("dev_width"));
      graph_options.push("height=" + getValue("dev_height"));
      graph_options.push("res=" + getValue("dev_res"));
      graph_options.push("bg=\\"" + getValue("dev_bg") + "\\"");
      if(getValue("device_type") === "JPG"){
        graph_options.push("quality=" + getValue("jpg_quality"));
      }
      echo("try(rk.graph.on(" + graph_options.join(", ") + "))\\n");
    }
    echo("try(print(p))\\n");
    if(!is_preview){
      echo("try(rk.graph.off())\\n");
    }
  '

  # =========================================================================================
  # --- Main Plugin: Survey Bar Chart ---
  # =========================================================================================

  svy_selector <- rk.XML.varselector(id.name = "svy_selector", label = "Select survey data object")
  svy_object_slot <- rk.XML.varslot(label = "Survey design object", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  x_var_slot <- rk.XML.varslot(label = "X-axis variable (categorical)", source = "svy_selector", required = TRUE, id.name = "x_var"); attr(x_var_slot, "source_property") <- "variables"
  fill_var_slot <- rk.XML.varslot(label = "Fill variable (optional)", source = "svy_selector", id.name = "fill_var"); attr(fill_var_slot, "source_property") <- "variables"
  facet_var_slot <- rk.XML.varslot(label = "Faceting variable (optional)", source = "svy_selector", id.name = "facet_var"); attr(facet_var_slot, "source_property") <- "variables"

  data_tab <- rk.XML.col(
    svy_object_slot,
    x_var_slot,
    fill_var_slot,
    facet_var_slot,
    rk.XML.cbox(label = "Omit NA cases from selected variables", id.name = "omit_na", value = "1", chk = TRUE)
  )

  ordering_frame <- rk.XML.frame(
    label = "X-axis Ordering",
    child = rk.XML.col(
        rk.XML.cbox(label = "Order X-axis by frequency/proportion", id.name = "order_x_freq", value = "1"),
        rk.XML.cbox(label = "Invert final order (for top-to-bottom plots)", id.name = "invert_order", value = "1"),
        rk.XML.input(label = "Order by this level of the Fill variable", id.name = "order_by_level_input"),
        rk.XML.text("<br/><i>Note: Ordering by level is disabled<br/>when faceting absolute frequencies.</i>")
    )
  )

  options_tab <- rk.XML.col(
    rk.XML.dropdown(label = "Frequency type", id.name = "freq_type", options = list("Absolute" = list(val = "abs", chk = TRUE), "Relative" = list(val = "rel"))),
    rk.XML.dropdown(label = "Bar position (for absolute freq.)", id.name = "bar_pos", options = list("Stack" = list(val = "stack", chk = TRUE), "Dodge" = list(val = "dodge"), "Fill (Proportional)" = list(val = "fill"))),
    ordering_frame,
    rk.XML.cbox(label = "Flip coordinates", id.name = "coord_flip", value = "1"),
    rk.XML.dropdown(label="Facet Layout", id.name="facet_layout", options=list(
        "Default Wrap"=list(val="wrap", chk=TRUE), "Single Row"=list(val="row"), "Single Column"=list(val="col")
    )),
    color_palette_dropdown
  )

  theme_tab <- rk.XML.col(
      rk.XML.spinbox(label="Overall text size relative adjustment", id.name="theme_text_rel", min=0.1, max=5, initial=1, real=TRUE),
      rk.XML.spinbox(label="Plot title size relative adjustment", id.name="theme_title_rel", min=0.1, max=5, initial=1.2, real=TRUE),
      rk.XML.spinbox(label="Legend text size relative adjustment", id.name="theme_legend_rel", min=0.1, max=5, initial=0.8, real=TRUE),
      rk.XML.dropdown(label="Legend Position", id.name="theme_legend_pos", options=list(
          "Right (Default)"=list(val="right", chk=TRUE), "Left"=list(val="left"),
          "Top"=list(val="top"), "Bottom"=list(val="bottom"), "None"=list(val="none")
      )),
      rk.XML.frame(label="X-Axis Text", child=rk.XML.row(
        rk.XML.spinbox(label="Angle", id.name="theme_x_angle", min=0, max=90, initial=0),
        rk.XML.spinbox(label="H-Just", id.name="theme_x_hjust", min=0, max=1, initial=0.5, real=TRUE),
        rk.XML.spinbox(label="V-Just", id.name="theme_x_vjust", min=0, max=1, initial=0.5, real=TRUE)
      )),
      rk.XML.frame(label="X-Axis Value Labels", child=rk.XML.spinbox(label="Wrap at (chars)", id.name="theme_x_val_wrap", min=0, max=100, initial=0)),
      rk.XML.frame(label="Y-Axis Value Labels", child=rk.XML.spinbox(label="Wrap at (chars)", id.name="theme_y_val_wrap", min=0, max=100, initial=0))
  )

  main_dialog <- rk.XML.dialog(
    label = "Survey Bar Chart (ggsurvey)",
    child = rk.XML.row(
      svy_selector,
      rk.XML.col(
        rk.XML.tabbook(tabs = list(
          "Data" = data_tab,
          "Options" = options_tab,
          "Value Labels" = value_labels_tab,
          "Labels" = labels_tab,
          "Theme" = theme_tab,
          "Output Device" = device_tab
        )),
        rk.XML.preview(id.name = "plot_preview")
      )
    )
  )

  # --- JavaScript Logic ---
  js_calculate <- paste(js_helpers, '
    var svy_obj = getValue("svy_object");
    var x_var_full = getValue("x_var");
    var fill_var_full = getValue("fill_var");
    var facet_var_full = getValue("facet_var");

    if (!svy_obj || !x_var_full) return;

    var x_var = getColumnName(x_var_full);
    var fill_var = getColumnName(fill_var_full);
    var facet_var = getColumnName(facet_var_full);

    var omit_na = (getValue("omit_na") === "1");
    var processed_svy_obj = svy_obj;

    if (omit_na) {
        var na_conditions = [];
        if(x_var) na_conditions.push("!is.na(" + x_var + ")");
        if(fill_var) na_conditions.push("!is.na(" + fill_var + ")");
        if(facet_var) na_conditions.push("!is.na(" + facet_var + ")");

        if(na_conditions.length > 0){
            echo("svy_obj_no_na <- subset(" + svy_obj + ", " + na_conditions.join(" & ") + ")\\n");
            processed_svy_obj = "svy_obj_no_na";
        }
    }

    var freq_type = getValue("freq_type");
    var bar_pos = getValue("bar_pos");
    var order_x = (getValue("order_x_freq") === "1");
    var order_level = getValue("order_by_level_input");
    var invert_order = (getValue("invert_order") === "1");
    var coord_flip = (getValue("coord_flip") === "1");
    var palette = getValue("palette_input");
    var show_labels = getValue("show_value_labels") === "1";

    var x_var_for_plot = x_var;

    if (freq_type === "rel") {
        var svytable_vars = "~" + x_var;
        if (fill_var) svytable_vars += " + " + fill_var;
        if (facet_var) svytable_vars += " + " + facet_var;

        echo("data_for_plot <- " + processed_svy_obj + " %>%\\n");
        echo("  survey::svytable(" + svytable_vars + ", design = .) %>%\\n");
        echo("  data.frame() %>%\\n");

        var group_by_vars = [x_var];
        if (facet_var) group_by_vars.push(facet_var);
        echo("  dplyr::group_by(" + group_by_vars.join(", ") + ") %>%\\n");
        echo("  dplyr::mutate(Prop = Freq / sum(Freq, na.rm=TRUE)) %>%\\n");
        echo("  dplyr::ungroup()\\n");

        if (order_x) {
            var ordering_group_vars = [x_var];
            if (facet_var) ordering_group_vars.push(facet_var);

            echo("data_for_plot <- data_for_plot %>%\\n");
            echo("  dplyr::group_by(" + ordering_group_vars.join(", ") + ") %>%\\n");

            if (fill_var && order_level) {
                echo("  dplyr::mutate(ordering_value = max(Prop[" + fill_var + " == \\"" + order_level + "\\"], 0, na.rm=TRUE)) %>%\\n");
            } else {
                echo("  dplyr::mutate(ordering_value = sum(Freq, na.rm=TRUE)) %>%\\n");
            }
            echo("  dplyr::ungroup()\\n");

            var base_order_call = "forcats::fct_reorder(" + x_var + ", ordering_value, .desc=TRUE)";
            x_var_for_plot = invert_order ? "forcats::fct_rev(" + base_order_call + ")" : base_order_call;
        }

        if(show_labels && fill_var){
            var arrange_vars = [x_var_for_plot, "dplyr::desc(" + fill_var + ")"];
            if(facet_var) arrange_vars.unshift(facet_var);
            echo("data_for_plot <- data_for_plot %>%\\n");
            echo("  dplyr::arrange(" + arrange_vars.join(",") + ") %>%\\n");
            echo("  dplyr::group_by(" + group_by_vars.join(", ") + ") %>%\\n");
            echo("  dplyr::mutate(label_y_pos = cumsum(Prop) - 0.5 * Prop) %>%\\n");
            echo("  dplyr::ungroup()\\n");
        }

        echo("p <- ggplot2::ggplot(data_for_plot, ggplot2::aes(x = " + x_var_for_plot + "))");
        if (fill_var) {
            echo(" + ggplot2::aes(fill = " + fill_var + ")");
        }
        echo(" +\\n  ggplot2::geom_col(aes(y = Prop))");
        echo(" +\\n  ggplot2::scale_y_continuous(labels = scales::percent)");

    } else { // Absolute Frequency
        var pre_ggsurvey_pipe = "";
        if (order_x) {
            if (fill_var && order_level && !facet_var) {
                pre_ggsurvey_pipe += "  {\\n";
                pre_ggsurvey_pipe += "    ordering_df <- survey::svytable(~" + x_var + " + " + fill_var + ", design = .)\\n";
                pre_ggsurvey_pipe += "    ordering_df <- as.data.frame(ordering_df)\\n";
                pre_ggsurvey_pipe += "    ordered_levels <- ordering_df %>%\\n";
                pre_ggsurvey_pipe += "      dplyr::filter(" + fill_var + " == \\"" + order_level + "\\") %>%\\n";
                pre_ggsurvey_pipe += "      dplyr::arrange(dplyr::desc(Freq)) %>%\\n";
                pre_ggsurvey_pipe += "      dplyr::pull(" + x_var + ")\\n";
                pre_ggsurvey_pipe += "    if(" + invert_order + ") { ordered_levels <- rev(ordered_levels) }\\n";
                pre_ggsurvey_pipe += "    .$variables$" + x_var + " <- factor(as.character(.$variables$" + x_var + "), levels = ordered_levels)\\n";
                pre_ggsurvey_pipe += "    . \\n";
                pre_ggsurvey_pipe += "  } %>%\\n";
            } else {
                var base_order_call = "forcats::fct_infreq(" + x_var + ")";
                x_var_for_plot = invert_order ? base_order_call : "forcats::fct_rev(" + base_order_call + ")";
            }
        }

        echo("p <- " + processed_svy_obj + " %>%\\n");
        if(pre_ggsurvey_pipe){
          echo(pre_ggsurvey_pipe);
        }
        echo("  questionr::ggsurvey() +\\n");

        var aes_map = ["x = " + x_var_for_plot];
        if (fill_var) {
            aes_map.push("fill = " + fill_var);
        }
        echo("  ggplot2::aes(" + aes_map.join(", ") + ") +\\n");
        echo("  ggplot2::geom_bar(position = \\"" + bar_pos + "\\")");
    }

    if(show_labels){
      var use_repel = getValue("label_repel") === "1";
      var use_label = getValue("label_background") === "1";
      var label_size = getValue("label_size");
      var label_decimals = getValue("label_decimals");
      var accuracy = 1 / Math.pow(10, parseInt(label_decimals));

      var preset_color = getValue("label_color_preset");
      var final_color = preset_color;
      if(preset_color === "custom"){
          final_color = getValue("label_color_custom");
      }

      var label_geom;
      if(use_repel && use_label) { label_geom = "ggrepel::geom_label_repel"; }
      else if(use_repel) { label_geom = "ggrepel::geom_text_repel"; }
      else if(use_label) { label_geom = "ggplot2::geom_label"; }
      else { label_geom = "ggplot2::geom_text"; }

      var other_opts = [];
      if(use_label){ other_opts.push("fill=\\"white\\""); }
      if(use_repel){ other_opts.push("max.overlaps = " + getValue("label_max_overlaps")); }

      var label_aes;
      if (freq_type === "rel") {
          label_aes = "label = scales::percent(Prop, accuracy = " + accuracy + ")";
          var y_pos_aes = fill_var ? "y = label_y_pos" : "y = Prop";
          var vjust = fill_var ? "" : ", vjust = -0.5";
          echo(" +\\n  " + label_geom + "(aes(" + y_pos_aes + ", " + label_aes + ")" + vjust + ", size=" + label_size + ", color=\\"" + final_color + "\\", " + other_opts.join(", ") + ")");
      } else { // Absolute
          var geom_opts = "";
          var stat_call = "stat=\\"count\\"";

          label_aes = "label = ..count..";
          if(bar_pos === "dodge") {
              geom_opts = "position = ggplot2::position_dodge(width = 0.9), vjust = -0.5";
          } else if (bar_pos === "fill") {
              label_aes = "label = scales::percent(..prop.., accuracy=" + accuracy + ")";
              geom_opts = "position = ggplot2::position_fill(vjust = 0.5)";
          } else { // stack
              geom_opts = "position = ggplot2::position_stack(vjust = 0.5)";
          }

          echo(" +\\n  " + label_geom + "(aes(" + label_aes + "), " + stat_call + ", " + geom_opts + ", size=" + label_size + ", color=\\"" + final_color + "\\", " + other_opts.join(", ") + ")");
      }
    }

    echo("\\n");
    if (coord_flip) {
        echo("p <- p + ggplot2::coord_flip()\\n");
    }

    if (fill_var) {
        var legend_wrap_width = getValue("legend_wrap_width");
        var scale_fill_opts = "palette = \\"" + palette + "\\"";
        if (legend_wrap_width && parseInt(legend_wrap_width) > 0) {
            scale_fill_opts += ", labels = scales::label_wrap(" + legend_wrap_width + ")";
        }
        echo("p <- p + ggplot2::scale_fill_brewer(" + scale_fill_opts + ")\\n");
    }

    if (facet_var) {
        var facet_layout = getValue("facet_layout");
        var facet_opts = "";
        if (facet_layout === "row") {
            facet_opts = ", nrow = 1";
        } else if (facet_layout === "col") {
            facet_opts = ", ncol = 1";
        }
        echo("p <- p + ggplot2::facet_wrap(~ " + facet_var + facet_opts + ")\\n");
    }

    var labs_list = [];
    var custom_xlab = getValue("plot_xlab");
    var xlab_wrap = getValue("plot_xlab_wrap");
    var xlab_call;
    if (custom_xlab) {
        xlab_call = "\\"" + custom_xlab + "\\"";
    } else {
        xlab_call = "rk.get.label(" + x_var_full + ")";
    }
    if (xlab_wrap && parseInt(xlab_wrap) > 0) {
        xlab_call = "scales::label_wrap(" + xlab_wrap + ")(" + xlab_call + ")";
    }
    labs_list.push("x = " + xlab_call);

    var custom_ylab = getValue("plot_ylab");
    var ylab_wrap = getValue("plot_ylab_wrap");
    if (custom_ylab) {
        var ylab_call = "\\"" + custom_ylab + "\\"";
        if (ylab_wrap && parseInt(ylab_wrap) > 0) {
            ylab_call = "scales::label_wrap(" + ylab_wrap + ")(" + ylab_call + ")";
        }
        labs_list.push("y = " + ylab_call);
    }

    if (fill_var) {
        var custom_legend_title = getValue("plot_legend_title");
        var legend_title_wrap_width = getValue("legend_title_wrap_width");
        var legend_title_call;
        if (custom_legend_title) {
            legend_title_call = "\\"" + custom_legend_title + "\\"";
        } else {
            legend_title_call = "rk.get.label(" + fill_var_full + ")";
        }
        if (legend_title_wrap_width && parseInt(legend_title_wrap_width) > 0) {
            legend_title_call = "scales::label_wrap(" + legend_title_wrap_width + ")(" + legend_title_call + ")";
        }
        labs_list.push("fill = " + legend_title_call);
    }

    if (getValue("plot_title")) { labs_list.push("title = \\"" + getValue("plot_title") + "\\""); }
    if (getValue("plot_subtitle")) { labs_list.push("subtitle = \\"" + getValue("plot_subtitle") + "\\""); }
    if (getValue("plot_caption")) { labs_list.push("caption = \\"" + getValue("plot_caption") + "\\""); }
    if (labs_list.length > 0) {
      echo("p <- p + ggplot2::labs(" + labs_list.join(", ") + ")\\n");
    }

    var x_val_wrap = getValue("theme_x_val_wrap");
    if (x_val_wrap && parseInt(x_val_wrap) > 0) {
        echo("p <- p + ggplot2::scale_x_discrete(labels = scales::label_wrap(" + x_val_wrap + "))\\n");
    }
    var y_val_wrap = getValue("theme_y_val_wrap");
    if (y_val_wrap && parseInt(y_val_wrap) > 0) {
        echo("p <- p + ggplot2::scale_y_discrete(labels = scales::label_wrap(" + y_val_wrap + "))\\n");
    }

    var theme_list = [];
    if(getValue("theme_text_rel") != 1) { theme_list.push("text = ggplot2::element_text(size = ggplot2::rel(" + getValue("theme_text_rel") + "))"); }
    if(getValue("theme_title_rel") != 1.2) { theme_list.push("plot.title = ggplot2::element_text(size = ggplot2::rel(" + getValue("theme_title_rel") + "))"); }
    if(getValue("theme_legend_rel") != 0.8) { theme_list.push("legend.text = ggplot2::element_text(size = ggplot2::rel(" + getValue("theme_legend_rel") + "))"); }
    if(getValue("theme_legend_pos") != "right") { theme_list.push("legend.position = \\"" + getValue("theme_legend_pos") + "\\""); }

    var x_angle = getValue("theme_x_angle");
    var x_hjust = getValue("theme_x_hjust");
    var x_vjust = getValue("theme_x_vjust");
    if(x_angle != 0 || x_hjust != 0.5 || x_vjust != 0.5) {
        theme_list.push("axis.text.x = ggplot2::element_text(angle=" + x_angle + ", hjust=" + x_hjust + ", vjust=" + x_vjust + ")");
    }

    if(theme_list.length > 0) {
      echo("p <- p + ggplot2::theme(" + theme_list.join(", ") + ")\\n");
    }
  ')

  # =========================================================================================
  # Final Plugin Skeleton Call
  # =========================================================================================
  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    xml = list(
      dialog = main_dialog
    ),
    js = list(
      require = c("questionr", "srvyr", "survey", "ggplot2", "dplyr", "forcats", "stringr", "scales", "RColorBrewer", "ggrepel"),
      calculate = js_calculate,
      printout = js_printout
    ),
    pluginmap = list(
      name = "Bar Chart (questionr)",
      hierarchy = list("Survey", "Graphs", "ggGraphs")
    ),
    create = c("pmap", "xml", "js", "desc"),
    load = TRUE,
    overwrite = TRUE,
    show = TRUE
  )

})
