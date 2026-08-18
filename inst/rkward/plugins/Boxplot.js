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
		echo("if(!base::require(RColorBrewer)){stop(" + i18n("Preview not available, because package RColorBrewer is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(RColorBrewer)\n");
	}	if(is_preview) {
		echo("if(!base::require(survey)){stop(" + i18n("Preview not available, because package survey is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(survey)\n");
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
   
    var svy = getValue("svy_object");
    var sub_expr = getValue("subset_expr");
    var drop = getValue("drop_levels");
    var processed_svy = svy;

    if (sub_expr !== "") {
        echo("svy_filtered <- subset(" + svy + ", " + sub_expr + ")\n");
        processed_svy = "svy_filtered";

        if (drop == "1") {
            // Aplicamos forcats::fct_drop directo al data.frame interno del diseño
            echo(processed_svy + "$variables <- " + processed_svy + "$variables %>% dplyr::mutate(dplyr::across(tidyselect::where(is.factor), forcats::fct_drop))\n");
        }
    }
   
    var y = getColumnName(getValue("y_var")); var x = getColumnName(getValue("x_var"));
    var fill_grp = getValue("fill_by_group"); var pal = getValue("palette_input");

    echo("options(survey.lonely.psu=\"adjust\")\n");
    var ord = getValue("order_median");
    var inv = getValue("invert_order");

    // TRUCO DE MEMORIA #3: Pre-calcular los 5 cuartiles pesados de la encuesta
    echo("quantiles_calc <- c(0, 0.25, 0.5, 0.75, 1)\n");

    if (x != "") {
        echo("plot_data <- survey::svyby(~" + y + ", ~" + x + ", " + processed_svy + ", survey::svyquantile, quantiles=quantiles_calc, keep.var=FALSE, na.rm=TRUE)\n");

        // CORRECCIÓN: Uso de comillas dobles escapadas (\") en lugar de simples
        echo("colnames(plot_data)[2:6] <- c(\"ymin\", \"lower\", \"middle\", \"upper\", \"ymax\")\n");

        if (ord == "1") {
            var desc_arg = (inv == "1") ? "TRUE" : "FALSE";
            echo("plot_data <- plot_data[order(plot_data$middle, decreasing=" + desc_arg + "), ]\n");
            echo("plot_data$" + x + " <- factor(plot_data$" + x + ", levels=plot_data$" + x + ")\n");
        }
    } else {
        echo("q_res <- survey::svyquantile(~" + y + ", " + processed_svy + ", quantiles=quantiles_calc, na.rm=TRUE)\n");
        echo("q_vec <- as.numeric(q_res[[1]])\n");
        echo("plot_data <- data.frame(x_dummy = factor(1), ymin=q_vec[1], lower=q_vec[2], middle=q_vec[3], upper=q_vec[4], ymax=q_vec[5])\n");
    }

    var x_aes = (x == "") ? "x_dummy" : x;
    var fill_aes = (fill_grp == "1" && x != "") ? ", fill=" + x : "";

    // Al usar stat="identity", ggplot dibuja la caja directamente desde nuestros 5 números
    echo("p <- ggplot(plot_data, aes(x=" + x_aes + ", ymin=ymin, lower=lower, middle=middle, upper=upper, ymax=ymax" + fill_aes + ")) + geom_boxplot(stat=\"identity\")\n");

    if(fill_grp == "1" && x != "") {
        echo("n_colors <- nrow(plot_data)\n");
        echo("if(n_colors > 8) {\n");
        echo("  p <- p + scale_fill_manual(values = colorRampPalette(RColorBrewer::brewer.pal(8, \"" + pal + "\"))(n_colors))\n");
        echo("} else {\n");
        echo("  p <- p + scale_fill_brewer(palette=\"" + pal + "\")\n");
        echo("}\n");
    }

    if(getValue("coord_flip") == "1") echo("p <- p + coord_flip()\n");
    if(x == "") echo("p <- p + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank()) + labs(x=NULL)\n");
     
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
		new Header(i18n("Boxplot results")).print();	
	}
    // TRUCO DE MEMORIA #1: Desconectar el gráfico del entorno global
    echo("p$plot_env <- emptyenv()\n");

    // TRUCO DE MEMORIA #2 (EL DEFINITIVO): Borrar objetos pesados del bloque local
    // Así evitamos que los "aes()" de ggplot2 los capturen y los guarden en el .RData
    echo("rm(list = intersect(ls(), c(\"svy_filtered\", \"svy_clean\", \"design_for_ord\")))\n");
    echo("gc()\n");

    if(getValue("save_plot.active")) {
        echo("my_plot <- p\n");
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
    if(getValue("save_plot.active")) {
        echo("  print(my_plot)\n");
    } else {
        echo("  print(p)\n");
    }
    echo("})\n");

    if(!is_preview){ echo("rk.graph.off()\n"); }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var savePlot = getValue("save_plot");
		var savePlotActive = getValue("save_plot.active");
		var savePlotParent = getValue("save_plot.parent");
		// assign object to chosen environment
		if(savePlotActive) {
			echo(".GlobalEnv$" + savePlot + " <- my_plot\n");
		}	
	}

}

