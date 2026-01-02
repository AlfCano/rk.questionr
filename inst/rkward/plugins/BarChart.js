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
		echo("if(!base::require(ggplot2)){stop(" + i18n("Preview not available, because package ggplot2 is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(ggplot2)\n");
	}	if(is_preview) {
		echo("if(!base::require(survey)){stop(" + i18n("Preview not available, because package survey is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(survey)\n");
	}	if(is_preview) {
		echo("if(!base::require(ggrepel)){stop(" + i18n("Preview not available, because package ggrepel is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(ggrepel)\n");
	}	if(is_preview) {
		echo("if(!base::require(scales)){stop(" + i18n("Preview not available, because package scales is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(scales)\n");
	}	if(is_preview) {
		echo("if(!base::require(dplyr)){stop(" + i18n("Preview not available, because package dplyr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(dplyr)\n");
	}	if(is_preview) {
		echo("if(!base::require(forcats)){stop(" + i18n("Preview not available, because package forcats is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(forcats)\n");
	}	if(is_preview) {
		echo("if(!base::require(RColorBrewer)){stop(" + i18n("Preview not available, because package RColorBrewer is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(RColorBrewer)\n");
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
            if (match) { return match[1]; }
        }
        if (fullName.indexOf("$") > -1) { return fullName.substring(fullName.lastIndexOf("$") + 1); }
        else { return fullName; }
    }
   
    var svy = getValue("svy_object"); var x_full = getValue("x_var"); var fill_full = getValue("fill_var"); var facet_full = getValue("facet_var");
    var x = getColumnName(x_full); var fill = getColumnName(fill_full); var facet = getColumnName(facet_full);
    var processed_svy = svy;

    // NA Omission
    if (getValue("omit_na") == "1") {
        var conds = [];
        if(x) conds.push("!is.na(" + x + ")");
        if(fill) conds.push("!is.na(" + fill + ")");
        if(facet) conds.push("!is.na(" + facet + ")");
        if(conds.length > 0) {
            echo("svy_clean <- subset(" + svy + ", " + conds.join(" & ") + ")\n");
            processed_svy = "svy_clean";
        }
    }

    var freq = getValue("freq_type"); var pos = getValue("bar_pos"); var ord = getValue("order_x_freq");
    var inv = getValue("invert_order"); var ord_lvl = getValue("order_by_level_input");
    var pal = getValue("palette_input"); var flip = getValue("coord_flip");

    // --- RELATIVE FREQUENCY LOGIC ---
    if(freq == "rel") {
        echo("plot_data <- " + processed_svy + " %>% survey::svytable(~" + x + (fill ? "+"+fill : "") + (facet ? "+"+facet : "") + ", design=.) %>% as.data.frame()\n");
        // Calculate Proportions
        echo("plot_data <- plot_data %>% group_by(" + x + (facet ? ","+facet : "") + ") %>% mutate(Prop = Freq/sum(Freq)) %>% ungroup()\n");

        // Ordering (Using mutate to ensure variable scope)
        if(ord == "1") {
            var metric_val = "Freq"; // default total
            if(fill && ord_lvl) {
                echo("plot_data <- plot_data %>% group_by(" + x + ") %>% mutate(ord_val = sum(Prop[" + fill + "==\"" + ord_lvl + "\"])) %>% ungroup()\n");
                metric_val = "ord_val";
            } else {
                 echo("plot_data <- plot_data %>% group_by(" + x + ") %>% mutate(ord_val = sum(Freq)) %>% ungroup()\n");
                 metric_val = "ord_val";
            }
            var desc_arg = (inv == "1") ? "" : ", .desc=TRUE"; // Invert logic for fct_reorder is opposite to sort()
            echo("plot_data <- plot_data %>% mutate(" + x + " = fct_reorder(" + x + ", " + metric_val + desc_arg + "))\n");
        }

        echo("p <- ggplot(plot_data, aes(x=" + x + ", y=Prop" + (fill ? ", fill="+fill : "") + ")) + geom_col(position=\"" + pos + "\") + scale_y_continuous(labels=scales::percent)\n");

    // --- ABSOLUTE FREQUENCY LOGIC ---
    } else {
        if(ord == "1") {
             if(fill && ord_lvl) {
                 // Sort by specific fill level
                 echo("ord_stats <- svytable(~" + x + "+" + fill + ", " + processed_svy + ")\n");
                 echo("target_col <- which(colnames(ord_stats) == \"" + ord_lvl + "\")\n");
                 echo("ord_vals <- if(length(target_col) > 0) ord_stats[, target_col] else margin.table(ord_stats, 1)\n");
             } else {
                 // Sort by total count
                 echo("ord_vals <- svytable(~" + x + ", " + processed_svy + ")\n");
             }
             echo("lvls <- names(sort(ord_vals, decreasing=" + (inv=="1"?"FALSE":"TRUE") + "))\n");
             // Update design using update() which is safer
             echo(processed_svy + " <- update(" + processed_svy + ", " + x + " = factor(" + x + ", levels=lvls))\n");
        }
        echo("p <- questionr::ggsurvey(" + processed_svy + ") + geom_bar(aes(x=" + x + ", weight=.weights" + (fill ? ", fill="+fill : "") + "), position=\"" + pos + "\")\n");
    }

    // --- COMMON STYLING ---
    if(fill) {
        var legw = getValue("legend_wrap_width");
        var lab_opt = (legw > 0) ? ", labels=scales::label_wrap(" + legw + ")" : "";
        echo("n_colors <- length(unique(na.omit(" + processed_svy + "$variables[[" + "\"" + fill + "\"]])))\n");
        echo("if(n_colors > 8) {\n");
        echo("  p <- p + scale_fill_manual(values = colorRampPalette(RColorBrewer::brewer.pal(8, \"" + pal + "\"))(n_colors)" + lab_opt + ")\n");
        echo("} else {\n");
        echo("  p <- p + scale_fill_brewer(palette=\"" + pal + "\"" + lab_opt + ")\n");
        echo("}\n");
    }

    if(flip == "1") echo("p <- p + coord_flip()\n");

    if(facet) {
        var lay = getValue("facet_layout");
        var lay_opt = "";
        if(lay == "row") lay_opt = ", nrow=1";
        if(lay == "col") lay_opt = ", ncol=1";
        echo("p <- p + facet_wrap(~" + facet + lay_opt + ")\n");
    }

    // --- LABELS ---
    if(getValue("show_value_labels") == "1") {
       var style = getValue("label_style");
       var col_pre = getValue("label_color_preset");
       var col = (col_pre == "custom") ? getValue("label_color_custom") : col_pre;
       var size = getValue("label_size");
       var dec = getValue("label_decimals");
       var geom = "geom_text";
       if(style.includes("label")) geom = "geom_label";
       if(style.includes("repel")) geom = "ggrepel::geom_" + style;

       var aes_lbl = (freq == "rel") ? "scales::percent(Prop, accuracy=0." + "0".repeat(dec) + "1)" : "scales::number(after_stat(count), accuracy=1)";
       if(pos == "fill") aes_lbl = "scales::percent(after_stat(prop), accuracy=0." + "0".repeat(dec) + "1)";

       var opts = ", color=\"" + col + "\", size=" + size;
       if(style.includes("repel")) opts += ", max.overlaps=" + getValue("label_max_overlaps");
       if(style.includes("label")) opts += ", fill=\"white\"";

       var pos_func = "position_stack(vjust=0.5)";
       if(pos == "dodge") pos_func = "position_dodge(width=0.9)";
       if(pos == "fill") pos_func = "position_fill(vjust=0.5)";

       var aes_extras = "";
       if(fill) aes_extras = ", group=" + fill;

       if(freq == "rel") {
           echo("p <- p + " + geom + "(aes(label=" + aes_lbl + aes_extras + "), position=" + pos_func + opts + ")\n");
       } else {
           // Explicit mapping of X is required for stat_count to work in this layer
           echo("p <- p + " + geom + "(aes(x=" + x + ", label=" + aes_lbl + ", weight=.weights" + aes_extras + "), stat=\"count\", position=" + pos_func + opts + ")\n");
       }
    }
     
    var labs = [];
    var xl = getValue("plot_xlab"); var xlw = getValue("plot_xlab_wrap");
    if(xl) { if(xlw > 0) xl = "scales::label_wrap(" + xlw + ")(\"" + xl + "\")"; else xl = "\"" + xl + "\""; labs.push("x=" + xl); }
    var yl = getValue("plot_ylab"); var ylw = getValue("plot_ylab_wrap");
    if(yl) { if(ylw > 0) yl = "scales::label_wrap(" + ylw + ")(\"" + yl + "\")"; else yl = "\"" + yl + "\""; labs.push("y=" + yl); }
    var leg = getValue("plot_legend_title"); var legw = getValue("legend_title_wrap_width");
    if(leg) { if(legw > 0) leg = "scales::label_wrap(" + legw + ")(\"" + leg + "\")"; else leg = "\"" + leg + "\""; labs.push("fill=" + leg); }
    if(getValue("plot_title")) labs.push("title=\"" + getValue("plot_title") + "\"");
    if(getValue("plot_subtitle")) labs.push("subtitle=\"" + getValue("plot_subtitle") + "\"");
    if(getValue("plot_caption")) labs.push("caption=\"" + getValue("plot_caption") + "\"");
    if(labs.length > 0) echo("p <- p + labs(" + labs.join(",") + ")\n");

    if(getValue("theme_x_val_wrap") > 0) echo("p <- p + scale_x_discrete(labels = scales::label_wrap(" + getValue("theme_x_val_wrap") + "))\n");
    if(getValue("theme_y_val_wrap") > 0) echo("p <- p + scale_y_discrete(labels = scales::label_wrap(" + getValue("theme_y_val_wrap") + "))\n");

    var thm = [];
    if(getValue("theme_text_rel") != 1) thm.push("text=element_text(size=rel(" + getValue("theme_text_rel") + "))");
    if(getValue("theme_legend_pos") != "right") thm.push("legend.position=\"" + getValue("theme_legend_pos") + "\"");
    if(getValue("theme_x_angle") != 0) thm.push("axis.text.x=element_text(angle=" + getValue("theme_x_angle") + ", hjust=" + getValue("theme_x_hjust") + ")");
    if(thm.length > 0) echo("p <- p + theme(" + thm.join(",") + ")\n");
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Bar Chart results")).print();	
	}
    if(!is_preview){
      var graph_options = [];
      graph_options.push("device.type=\"" + getValue("device_type") + "\"");
      graph_options.push("width=" + getValue("dev_width"));
      graph_options.push("height=" + getValue("dev_height"));
      graph_options.push("res=" + getValue("dev_res"));
      graph_options.push("bg=\"" + getValue("dev_bg") + "\"");
      echo("rk.graph.on(" + graph_options.join(", ") + ")\n");
    }
    echo("try({\n");
    echo("  print(p)\n");
    echo("})\n");
    if(!is_preview){ echo("rk.graph.off()\n"); }
  

}

