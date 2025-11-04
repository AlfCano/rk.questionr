// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

function preview(){
	preprocess(true);
	calculate(true);
	printout(true);
}

function preprocess(is_preview){
	// add requirements etc. here
	if(is_preview) {
		echo("if(!base::require(questionr)){stop(" + i18n("Preview not available, because package questionr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(questionr)\n");
	}	if(is_preview) {
		echo("if(!base::require(srvyr)){stop(" + i18n("Preview not available, because package srvyr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(srvyr)\n");
	}	if(is_preview) {
		echo("if(!base::require(survey)){stop(" + i18n("Preview not available, because package survey is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(survey)\n");
	}	if(is_preview) {
		echo("if(!base::require(ggplot2)){stop(" + i18n("Preview not available, because package ggplot2 is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(ggplot2)\n");
	}	if(is_preview) {
		echo("if(!base::require(dplyr)){stop(" + i18n("Preview not available, because package dplyr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(dplyr)\n");
	}	if(is_preview) {
		echo("if(!base::require(forcats)){stop(" + i18n("Preview not available, because package forcats is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(forcats)\n");
	}	if(is_preview) {
		echo("if(!base::require(stringr)){stop(" + i18n("Preview not available, because package stringr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(stringr)\n");
	}	if(is_preview) {
		echo("if(!base::require(scales)){stop(" + i18n("Preview not available, because package scales is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(scales)\n");
	}	if(is_preview) {
		echo("if(!base::require(RColorBrewer)){stop(" + i18n("Preview not available, because package RColorBrewer is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(RColorBrewer)\n");
	}	if(is_preview) {
		echo("if(!base::require(ggrepel)){stop(" + i18n("Preview not available, because package ggrepel is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(ggrepel)\n");
	}
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    function getColumnName(fullName) {
        if (!fullName) return "";
        var lastBracketPos = fullName.lastIndexOf("[[");
        if (lastBracketPos > -1) {
            var lastPart = fullName.substring(lastBracketPos);
            var match = lastPart.match(/\[\[\"(.*?)\"\]\]/);
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
            echo("svy_obj_no_na <- subset(" + svy_obj + ", " + na_conditions.join(" & ") + ")\n");
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
    var show_labels = (getValue("show_value_labels") === "1");

    var x_var_for_plot = x_var;

    if (freq_type === "rel") {
        var svytable_vars = "~" + x_var;
        if (fill_var) svytable_vars += " + " + fill_var;
        if (facet_var) svytable_vars += " + " + facet_var;

        echo("data_for_plot <- " + processed_svy_obj + " %>%\n");
        echo("  survey::svytable(" + svytable_vars + ", design = .) %>%\n");
        echo("  data.frame() %>%\n");

        var group_by_vars = [x_var];
        if (facet_var) group_by_vars.push(facet_var);
        echo("  dplyr::group_by(" + group_by_vars.join(", ") + ") %>%\n");
        echo("  dplyr::mutate(Prop = Freq / sum(Freq, na.rm=TRUE)) %>%\n");
        echo("  dplyr::ungroup()\n");

        if (order_x) {
            var ordering_group_vars = [x_var];
            if (facet_var) ordering_group_vars.push(facet_var);

            echo("data_for_plot <- data_for_plot %>%\n");
            echo("  dplyr::group_by(" + ordering_group_vars.join(", ") + ") %>%\n");

            if (fill_var && order_level) {
                echo("  dplyr::mutate(ordering_value = max(Prop[" + fill_var + " == \"" + order_level + "\"], 0, na.rm=TRUE)) %>%\n");
            } else {
                echo("  dplyr::mutate(ordering_value = sum(Freq, na.rm=TRUE)) %>%\n");
            }
            echo("  dplyr::ungroup()\n");

            var base_order_call = "forcats::fct_reorder(" + x_var + ", ordering_value, .desc=TRUE)";
            x_var_for_plot = invert_order ? "forcats::fct_rev(" + base_order_call + ")" : base_order_call;
        }

        if(show_labels && fill_var){
            var arrange_vars = [x_var_for_plot, "dplyr::desc(" + fill_var + ")"];
            if(facet_var) arrange_vars.unshift(facet_var);
            echo("data_for_plot <- data_for_plot %>%\n");
            echo("  dplyr::arrange(" + arrange_vars.join(",") + ") %>%\n");
            echo("  dplyr::group_by(" + group_by_vars.join(", ") + ") %>%\n");
            echo("  dplyr::mutate(label_y_pos = cumsum(Prop) - 0.5 * Prop) %>%\n");
            echo("  dplyr::ungroup()\n");
        }

        echo("p <- ggplot2::ggplot(data_for_plot, ggplot2::aes(x = " + x_var_for_plot + "))");
        if (fill_var) {
            echo(" + ggplot2::aes(fill = " + fill_var + ")");
        }
        echo(" +\n  ggplot2::geom_col(aes(y = Prop))");
        echo(" +\n  ggplot2::scale_y_continuous(labels = scales::percent)");

    } else { // Absolute Frequency
        var pre_ggsurvey_pipe = "";
        x_var_for_plot = x_var;

        if (order_x) {
            pre_ggsurvey_pipe += "  {\n";
            if (fill_var && order_level && !facet_var) {
                pre_ggsurvey_pipe += "    ordering_df <- survey::svytable(~" + x_var + " + " + fill_var + ", design = .)\n";
                pre_ggsurvey_pipe += "    ordering_df <- as.data.frame(ordering_df)\n";
                pre_ggsurvey_pipe += "    ordered_levels <- ordering_df %>%\n";
                pre_ggsurvey_pipe += "      dplyr::filter(" + fill_var + " == \"" + order_level + "\") %>%\n";
                pre_ggsurvey_pipe += "      dplyr::arrange(dplyr::desc(Freq)) %>%\n";
                pre_ggsurvey_pipe += "      dplyr::pull(" + x_var + ")\n";
            } else {
                pre_ggsurvey_pipe += "    ordering_df <- survey::svytable(~" + x_var + ", design = .)\n";
                pre_ggsurvey_pipe += "    ordering_df <- as.data.frame(ordering_df)\n";
                pre_ggsurvey_pipe += "    ordered_levels <- ordering_df %>%\n";
                pre_ggsurvey_pipe += "      dplyr::arrange(dplyr::desc(Freq)) %>%\n";
                pre_ggsurvey_pipe += "      dplyr::pull(" + x_var + ")\n";
            }
            var r_invert_order = invert_order ? "TRUE" : "FALSE";
            pre_ggsurvey_pipe += "    if(" + r_invert_order + ") { ordered_levels <- rev(ordered_levels) }\n";
            pre_ggsurvey_pipe += "    .$variables$" + x_var + " <- factor(as.character(.$variables$" + x_var + "), levels = ordered_levels)\n";
            pre_ggsurvey_pipe += "    . \n";
            pre_ggsurvey_pipe += "  } %>%\n";
        }

        echo("p <- " + processed_svy_obj + " %>%\n");
        if(pre_ggsurvey_pipe){
          echo(pre_ggsurvey_pipe);
        }
        echo("  questionr::ggsurvey() +\n");

        var aes_map = ["x = " + x_var_for_plot];
        if (fill_var) {
            aes_map.push("fill = " + fill_var);
        }
        echo("  ggplot2::aes(" + aes_map.join(", ") + ") +\n");
        echo("  ggplot2::geom_bar(position = \"" + bar_pos + "\")");
    }

    if(show_labels){
      var label_style = getValue("label_style");
      var label_size = getValue("label_size");
      var label_decimals = getValue("label_decimals");
      var accuracy = 1 / Math.pow(10, parseInt(label_decimals));

      var preset_color = getValue("label_color_preset");
      var final_color = preset_color;
      if(preset_color === "custom"){
          final_color = getValue("label_color_custom");
      }

      var label_geom;
      var is_stacked = (freq_type !== "rel" && (bar_pos === "stack" || bar_pos === "fill"));

      if (label_style === "label_repel" && is_stacked) {
          // Fallback for the incompatible combination
          label_geom = "ggplot2::geom_label";
      } else if (label_style === "label_repel") {
          label_geom = "ggrepel::geom_label_repel";
      } else if (label_style === "text_repel") {
          label_geom = "ggrepel::geom_text_repel";
      } else if (label_style === "label") {
          label_geom = "ggplot2::geom_label";
      } else {
          label_geom = "ggplot2::geom_text";
      }

      var other_opts = [];
      if(label_geom.indexOf("label") > -1){ other_opts.push("fill=\"white\""); }
      if(label_geom.indexOf("repel") > -1){ other_opts.push("max.overlaps = " + getValue("label_max_overlaps")); }

      var label_aes;
      if (freq_type === "rel") {
          label_aes = "label = scales::percent(Prop, accuracy = " + accuracy + ")";
          var y_pos_aes = fill_var ? "y = label_y_pos" : "y = Prop";
          var vjust = fill_var ? "" : ", vjust = -0.5";
          var other_opts_str = other_opts.length > 0 ? ", " + other_opts.join(", ") : "";
          echo(" +\n  " + label_geom + "(aes(" + y_pos_aes + ", " + label_aes + ")" + vjust + ", size=" + label_size + ", color=\"" + final_color + "\"" + other_opts_str + ")");
      } else { // Absolute
          var geom_opts = "";
          var stat_call = "stat=\"count\"";

          label_aes = "label = ..count..";
          if(bar_pos === "dodge") {
              geom_opts = "position = ggplot2::position_dodge(width = 0.9), vjust = -0.5";
          } else if (bar_pos === "fill") {
              label_aes = "label = scales::percent(..prop.., accuracy=" + accuracy + ")";
              geom_opts = "position = ggplot2::position_fill(vjust = 0.5)";
          } else { // stack
              geom_opts = "position = ggplot2::position_stack(vjust = 0.5)";
          }
          var other_opts_str = other_opts.length > 0 ? ", " + other_opts.join(", ") : "";
          echo(" +\n  " + label_geom + "(aes(" + label_aes + "), " + stat_call + ", " + geom_opts + ", size=" + label_size + ", color=\"" + final_color + "\"" + other_opts_str + ")");
      }
    }

    echo("\n");
    if (coord_flip) {
        echo("p <- p + ggplot2::coord_flip()\n");
    }

    if (fill_var) {
        var legend_wrap_width = getValue("legend_wrap_width");
        var scale_fill_opts = "palette = \"" + palette + "\"";
        if (legend_wrap_width && parseInt(legend_wrap_width) > 0) {
            scale_fill_opts += ", labels = scales::label_wrap(" + legend_wrap_width + ")";
        }
        echo("p <- p + ggplot2::scale_fill_brewer(" + scale_fill_opts + ")\n");
    }

    if (facet_var) {
        var facet_layout = getValue("facet_layout");
        var facet_opts = "";
        if (facet_layout === "row") {
            facet_opts = ", nrow = 1";
        } else if (facet_layout === "col") {
            facet_opts = ", ncol = 1";
        }
        echo("p <- p + ggplot2::facet_wrap(~ " + facet_var + facet_opts + ")\n");
    }

    var labs_list = [];
    var custom_xlab = getValue("plot_xlab");
    var xlab_wrap = getValue("plot_xlab_wrap");
    var xlab_call;
    if (custom_xlab) {
        xlab_call = "\"" + custom_xlab + "\"";
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
        var ylab_call = "\"" + custom_ylab + "\"";
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
            legend_title_call = "\"" + custom_legend_title + "\"";
        } else {
            legend_title_call = "rk.get.label(" + fill_var_full + ")";
        }
        if (legend_title_wrap_width && parseInt(legend_title_wrap_width) > 0) {
            legend_title_call = "scales::label_wrap(" + legend_title_wrap_width + ")(" + legend_title_call + ")";
        }
        labs_list.push("fill = " + legend_title_call);
    }

    if (getValue("plot_title")) { labs_list.push("title = \"" + getValue("plot_title") + "\""); }
    if (getValue("plot_subtitle")) { labs_list.push("subtitle = \"" + getValue("plot_subtitle") + "\""); }
    if (getValue("plot_caption")) { labs_list.push("caption = \"" + getValue("plot_caption") + "\""); }
    if (labs_list.length > 0) {
      echo("p <- p + ggplot2::labs(" + labs_list.join(", ") + ")\n");
    }

    var x_val_wrap = getValue("theme_x_val_wrap");
    if (x_val_wrap && parseInt(x_val_wrap) > 0) {
        echo("p <- p + ggplot2::scale_x_discrete(labels = scales::label_wrap(" + x_val_wrap + "))\n");
    }
    var y_val_wrap = getValue("theme_y_val_wrap");
    if (y_val_wrap && parseInt(y_val_wrap) > 0) {
        echo("p <- p + ggplot2::scale_y_discrete(labels = scales::label_wrap(" + y_val_wrap + "))\n");
    }

    var theme_list = [];
    if(getValue("theme_text_rel") != 1) { theme_list.push("text = ggplot2::element_text(size = ggplot2::rel(" + getValue("theme_text_rel") + "))"); }
    if(getValue("theme_title_rel") != 1.2) { theme_list.push("plot.title = ggplot2::element_text(size = ggplot2::rel(" + getValue("theme_title_rel") + "))"); }
    if(getValue("theme_legend_rel") != 0.8) { theme_list.push("legend.text = ggplot2::element_text(size = ggplot2::rel(" + getValue("theme_legend_rel") + "))"); }
    if(getValue("theme_legend_pos") != "right") { theme_list.push("legend.position = \"" + getValue("theme_legend_pos") + "\""); }

    var x_angle = getValue("theme_x_angle");
    var x_hjust = getValue("theme_x_hjust");
    var x_vjust = getValue("theme_x_vjust");
    if(x_angle != 0 || x_hjust != 0.5 || x_vjust != 0.5) {
        theme_list.push("axis.text.x = ggplot2::element_text(angle=" + x_angle + ", hjust=" + x_hjust + ", vjust=" + x_vjust + ")");
    }

    if(theme_list.length > 0) {
      echo("p <- p + ggplot2::theme(" + theme_list.join(", ") + ")\n");
    }
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Bar Chart (questionr) results")).print();	
	}
    if(!is_preview){
      var graph_options = [];
      graph_options.push("device.type=\"" + getValue("device_type") + "\"");
      graph_options.push("width=" + getValue("dev_width"));
      graph_options.push("height=" + getValue("dev_height"));
      graph_options.push("res=" + getValue("dev_res"));
      graph_options.push("bg=\"" + getValue("dev_bg") + "\"");
      if(getValue("device_type") === "JPG"){
        graph_options.push("quality=" + getValue("jpg_quality"));
      }
      echo("try(rk.graph.on(" + graph_options.join(", ") + "))\n");
    }
    echo("try(print(p))\n");
    if(!is_preview){
      echo("try(rk.graph.off())\n");
    }
  

}

