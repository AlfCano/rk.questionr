// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

function preview(){
	preprocess(true);
	calculate(true);
	printout(true);
}

function preprocess(is_preview){
	// add requirements etc. here

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
    
    if(freq == "rel") {
        echo("plot_data <- " + processed_svy + " %>% survey::svytable(~" + x + (fill ? "+"+fill : "") + (facet ? "+"+facet : "") + ", design=.) %>% as.data.frame()\n");
        echo("plot_data <- plot_data %>% group_by(" + x + (facet ? ","+facet : "") + ") %>% mutate(Prop = Freq/sum(Freq)) %>% ungroup()\n");
        if(ord == "1") {
            var ord_metric = "Freq";
            if(fill && ord_lvl) {
                echo("plot_data <- plot_data %>% group_by(" + x + ") %>% mutate(ord_val = sum(Prop[" + fill + "==\"" + ord_lvl + "\"])) %>% ungroup()\n");
                ord_metric = "ord_val";
            } else {
                 echo("plot_data <- plot_data %>% group_by(" + x + ") %>% mutate(ord_val = sum(Freq)) %>% ungroup()\n");
                 ord_metric = "ord_val";
            }
            var fct = "fct_reorder(" + x + ", " + ord_metric + ", .desc=TRUE)";
            if(inv == "1") fct = "fct_rev(" + fct + ")";
            echo("plot_data$" + x + " <- " + fct + "\n");
        }
        echo("p <- ggplot(plot_data, aes(x=" + x + ", y=Prop" + (fill ? ", fill="+fill : "") + ")) + geom_col(position=\"" + pos + "\") + scale_y_continuous(labels=scales::percent)\n");
    } else {
        if(ord == "1") {
             echo("tmp_counts <- svytable(~" + x + ", " + processed_svy + ")\n");
             echo("lvls <- names(sort(tmp_counts, decreasing=" + (inv=="1"?"FALSE":"TRUE") + "))\n");
             echo(processed_svy + "$variables[[" + "\"" + x + "\"]] <- factor(" + processed_svy + "$variables[[" + "\"" + x + "\"]], levels=lvls)\n");
        }
        echo("p <- questionr::ggsurvey(" + processed_svy + ") + geom_bar(aes(x=" + x + ", weight=.weights" + (fill ? ", fill="+fill : "") + "), position=\"" + pos + "\")\n");
    }
    if(fill) {
        var legw = getValue("legend_wrap_width");
        var pal_opts = "palette=\"" + pal + "\"";
        if(legw > 0) pal_opts += ", labels=scales::label_wrap(" + legw + ")";
        echo("p <- p + scale_fill_brewer(" + pal_opts + ")\n");
    }
    if(flip == "1") echo("p <- p + coord_flip()\n");
    if(facet) {
        var lay = getValue("facet_layout");
        var lay_opt = "";
        if(lay == "row") lay_opt = ", nrow=1";
        if(lay == "col") lay_opt = ", ncol=1";
        echo("p <- p + facet_wrap(~" + facet + lay_opt + ")\n");
    }
    if(getValue("show_value_labels") == "1") {
       var style = getValue("label_style");
       var col_pre = getValue("label_color_preset");
       var col = (col_pre == "custom") ? getValue("label_color_custom") : col_pre;
       var size = getValue("label_size");
       var dec = getValue("label_decimals");
       var geom = "geom_text";
       if(style.includes("label")) geom = "geom_label";
       if(style.includes("repel")) geom = "ggrepel::geom_" + style;
       var aes_lbl = (freq == "rel") ? "scales::percent(Prop, accuracy=0." + "0".repeat(dec) + "1)" : "scales::number(..count.., accuracy=1)";
       if(pos == "fill") aes_lbl = "scales::percent(..prop.., accuracy=0." + "0".repeat(dec) + "1)";
       var opts = ", color=\"" + col + "\", size=" + size;
       if(style.includes("repel")) opts += ", max.overlaps=" + getValue("label_max_overlaps");
       if(style.includes("label")) opts += ", fill=\"white\"";
       var pos_func = "position_stack(vjust=0.5)";
       if(pos == "dodge") pos_func = "position_dodge(width=0.9)";
       if(pos == "fill") pos_func = "position_fill(vjust=0.5)";
       if(freq == "rel") {
           echo("p <- p + " + geom + "(aes(label=" + aes_lbl + "), position=" + pos_func + opts + ")\n");
       } else {
           echo("p <- p + " + geom + "(aes(label=" + aes_lbl + ", weight=.weights), stat=\"count\", position=" + pos_func + opts + ")\n");
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
    if(labs.length > 0) echo("p <- p + ggplot2::labs(" + labs.join(",") + ")\n");

    if(getValue("theme_x_val_wrap") > 0) echo("p <- p + ggplot2::scale_x_discrete(labels = scales::label_wrap(" + getValue("theme_x_val_wrap") + "))\n");
    if(getValue("theme_y_val_wrap") > 0) echo("p <- p + ggplot2::scale_y_discrete(labels = scales::label_wrap(" + getValue("theme_y_val_wrap") + "))\n");

    var thm = [];
    if(getValue("theme_text_rel") != 1) thm.push("text=ggplot2::element_text(size=ggplot2::rel(" + getValue("theme_text_rel") + "))");
    if(getValue("theme_legend_pos") != "right") thm.push("legend.position=\"" + getValue("theme_legend_pos") + "\"");
    if(getValue("theme_x_angle") != 0) thm.push("axis.text.x=ggplot2::element_text(angle=" + getValue("theme_x_angle") + ", hjust=" + getValue("theme_x_hjust") + ")");
    if(thm.length > 0) echo("p <- p + ggplot2::theme(" + thm.join(",") + ")\n");
  
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
      graph_options.push("bg=\"" + getValue("dev_bg") + "\"");
      echo("try(rk.graph.on(" + graph_options.join(", ") + "))\n");
    }
    echo("try(print(p))\n");
    if(!is_preview){ echo("try(rk.graph.off())\n"); }
  

}

