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
      desc = "A plugin package to analyze complex survey designs. Includes Bar Charts, Histograms, Boxplots, and Frequency Tables.",
      version = "0.4.4",
      url = "https://github.com/AlfCano/rk.questionr",
      license = "GPL (>= 3)"
    )
  )

  # =========================================================================================
  # --- 1. SHARED UI RESOURCES ---
  # =========================================================================================

  js_helpers <- '
    function getColumnName(fullName) {
        if (!fullName) return "";
        var lastBracketPos = fullName.lastIndexOf("[[");
        if (lastBracketPos > -1) {
            var lastPart = fullName.substring(lastBracketPos);
            var match = lastPart.match(/\\[\\[\\"(.*?)\\"\\]\\]/);
            if (match) { return match[1]; }
        }
        if (fullName.indexOf("$") > -1) { return fullName.substring(fullName.lastIndexOf("$") + 1); }
        else { return fullName; }
    }
  '

  # Full Palette Dropdown
  color_palette_dropdown <- rk.XML.dropdown(label = "Color Palette (ColorBrewer)", id.name = "palette_input", options = list(
    "Default (Paired)" = list(val = "Paired", chk = TRUE), "Accent" = list(val = "Accent"), "Dark2" = list(val = "Dark2"),
    "Pastel1" = list(val = "Pastel1"), "Pastel2" = list(val = "Pastel2"), "Set1" = list(val = "Set1"),
    "Set2" = list(val = "Set2"), "Set3" = list(val = "Set3"), "Blues" = list(val = "Blues"),
    "Greens" = list(val = "Greens"), "Oranges" = list(val = "Oranges"), "Reds" = list(val = "Reds"),
    "Purples" = list(val = "Purples"), "RdYlBu" = list(val = "RdYlBu"), "Spectral" = list(val = "Spectral")
  ))

  labels_tab <- rk.XML.col(
    rk.XML.input(label = "Plot Title", id.name = "plot_title"),
    rk.XML.input(label = "Plot Subtitle", id.name = "plot_subtitle"),
    rk.XML.input(label = "X-axis Label (blank for auto)", id.name = "plot_xlab"),
    rk.XML.spinbox(label = "Wrap X-axis Label at (chars)", id.name = "plot_xlab_wrap", min = 0, max = 100, initial = 0),
    rk.XML.input(label = "Y-axis Label", id.name = "plot_ylab"),
    rk.XML.spinbox(label = "Wrap Y-axis Label at (chars)", id.name = "plot_ylab_wrap", min = 0, max = 100, initial = 0),
    rk.XML.input(label = "Legend Title (blank for auto)", id.name = "plot_legend_title"),
    rk.XML.spinbox(label = "Wrap Legend Title at (chars)", id.name = "legend_title_wrap_width", min = 0, max = 100, initial = 20),
    rk.XML.spinbox(label = "Wrap Legend Labels at (chars)", id.name = "legend_wrap_width", min = 0, max = 100, initial = 20),
    rk.XML.input(label = "Plot Caption", id.name = "plot_caption")
  )

  theme_tab <- rk.XML.col(
      rk.XML.spinbox(label="Overall text size", id.name="theme_text_rel", min=0.1, max=5, initial=1, real=TRUE),
      rk.XML.dropdown(label="Legend Position", id.name="theme_legend_pos", options=list(
          "Right"=list(val="right", chk=TRUE), "Left"=list(val="left"),
          "Top"=list(val="top"), "Bottom"=list(val="bottom"), "None"=list(val="none")
      )),
      rk.XML.frame(label="X-Axis Text", child=rk.XML.row(
        rk.XML.spinbox(label="Angle", id.name="theme_x_angle", min=0, max=90, initial=0),
        rk.XML.spinbox(label="H-Just", id.name="theme_x_hjust", min=0, max=1, initial=0.5, real=TRUE),
        rk.XML.spinbox(label="Value Labels Wrap (chars)", id.name="theme_x_val_wrap", min=0, max=100, initial=0)
      )),
      rk.XML.frame(label="Y-Axis Text", child=rk.XML.row(
        rk.XML.spinbox(label="Value Labels Wrap (chars)", id.name="theme_y_val_wrap", min=0, max=100, initial=0)
      ))
  )

  device_tab <- rk.XML.col(
    rk.XML.dropdown(label = "Device type", id.name = "device_type", options = list("PNG" = list(val = "PNG", chk = TRUE), "SVG" = list(val = "SVG"))),
    rk.XML.spinbox(label = "Width (px)", id.name = "dev_width", min = 100, max = 4000, initial = 1024),
    rk.XML.spinbox(label = "Height (px)", id.name = "dev_height", min = 100, max = 4000, initial = 724),
    rk.XML.dropdown(label = "Background", id.name = "dev_bg", options = list("Transparent" = list(val = "transparent", chk = TRUE), "White" = list(val = "white")))
  )

  js_printout_shared <- '
    if(!is_preview){
      var graph_options = [];
      graph_options.push("device.type=\\"" + getValue("device_type") + "\\"");
      graph_options.push("width=" + getValue("dev_width"));
      graph_options.push("height=" + getValue("dev_height"));
      graph_options.push("bg=\\"" + getValue("dev_bg") + "\\"");
      echo("try(rk.graph.on(" + graph_options.join(", ") + "))\\n");
    }
    echo("try(print(p))\\n");
    if(!is_preview){ echo("try(rk.graph.off())\\n"); }
  '

  js_apply_theme <- '
    var labs = [];
    var xl = getValue("plot_xlab"); var xlw = getValue("plot_xlab_wrap");
    if(xl) { if(xlw > 0) xl = "scales::label_wrap(" + xlw + ")(\\\"" + xl + "\\\")"; else xl = "\\\"" + xl + "\\\""; labs.push("x=" + xl); }
    var yl = getValue("plot_ylab"); var ylw = getValue("plot_ylab_wrap");
    if(yl) { if(ylw > 0) yl = "scales::label_wrap(" + ylw + ")(\\\"" + yl + "\\\")"; else yl = "\\\"" + yl + "\\\""; labs.push("y=" + yl); }
    var leg = getValue("plot_legend_title"); var legw = getValue("legend_title_wrap_width");
    if(leg) { if(legw > 0) leg = "scales::label_wrap(" + legw + ")(\\\"" + leg + "\\\")"; else leg = "\\\"" + leg + "\\\""; labs.push("fill=" + leg); }
    if(getValue("plot_title")) labs.push("title=\\"" + getValue("plot_title") + "\\"");
    if(getValue("plot_subtitle")) labs.push("subtitle=\\"" + getValue("plot_subtitle") + "\\"");
    if(getValue("plot_caption")) labs.push("caption=\\"" + getValue("plot_caption") + "\\"");
    if(labs.length > 0) echo("p <- p + ggplot2::labs(" + labs.join(",") + ")\\n");

    if(getValue("theme_x_val_wrap") > 0) echo("p <- p + ggplot2::scale_x_discrete(labels = scales::label_wrap(" + getValue("theme_x_val_wrap") + "))\\n");
    if(getValue("theme_y_val_wrap") > 0) echo("p <- p + ggplot2::scale_y_discrete(labels = scales::label_wrap(" + getValue("theme_y_val_wrap") + "))\\n");

    var thm = [];
    if(getValue("theme_text_rel") != 1) thm.push("text=ggplot2::element_text(size=ggplot2::rel(" + getValue("theme_text_rel") + "))");
    if(getValue("theme_legend_pos") != "right") thm.push("legend.position=\\"" + getValue("theme_legend_pos") + "\\"");
    if(getValue("theme_x_angle") != 0) thm.push("axis.text.x=ggplot2::element_text(angle=" + getValue("theme_x_angle") + ", hjust=" + getValue("theme_x_hjust") + ")");
    if(thm.length > 0) echo("p <- p + ggplot2::theme(" + thm.join(",") + ")\\n");
  '

  svy_selector <- rk.XML.varselector(id.name = "svy_selector", label = "Select survey object")

  # =========================================================================================
  # --- COMPONENT 1: Survey Bar Chart (questionr) ---
  # =========================================================================================

  help_bar <- rk.rkh.doc(
    title = rk.rkh.title("Survey Bar Chart (questionr)"),
    summary = rk.rkh.summary("Create a bar chart for categorical variables from a complex survey design object, using the 'questionr' and 'ggsurvey' packages."),
    usage = rk.rkh.usage("Select a survey design object and a categorical variable. Optionally select a Fill variable and Facet variable."),
    settings = rk.rkh.settings(
        rk.rkh.setting(id = "svy_object", text = "The survey design object (created with the 'survey' or 'srvyr' package)."),
        rk.rkh.setting(id = "x_var", text = "The main categorical variable to plot on the X-axis."),
        rk.rkh.setting(id = "fill_var", text = "(Optional) A second categorical variable to determine the bar colors.")
    )
  )

  bar_svy <- rk.XML.varslot(label = "Survey Design", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  bar_x <- rk.XML.varslot(label = "Variable", source = "svy_selector", required = TRUE, id.name = "x_var")
  bar_fill <- rk.XML.varslot(label = "Fill", source = "svy_selector", id.name = "fill_var")
  bar_facet <- rk.XML.varslot(label = "Facet", source = "svy_selector", id.name = "facet_var")
  bar_data_tab <- rk.XML.col(bar_svy, bar_x, bar_fill, bar_facet, rk.XML.cbox(label = "Omit NA cases from selected variables", id.name = "omit_na", value = "1", chk = TRUE))
  ordering_frame <- rk.XML.frame(label = "X-axis Ordering", child = rk.XML.col(rk.XML.cbox(label = "Order X-axis by frequency", id.name = "order_x_freq", value = "1"), rk.XML.cbox(label = "Invert final order", id.name = "invert_order", value = "1"), rk.XML.input(label = "Order by level of Fill var (optional)", id.name = "order_by_level_input")))
  bar_opts_tab <- rk.XML.col(rk.XML.dropdown(label = "Frequency type", id.name = "freq_type", options = list("Absolute" = list(val = "abs", chk = TRUE), "Relative" = list(val = "rel"))), rk.XML.dropdown(label = "Bar position", id.name = "bar_pos", options = list("Stack" = list(val = "stack", chk = TRUE), "Dodge" = list(val = "dodge"), "Fill (Prop)" = list(val = "fill"))), ordering_frame, rk.XML.cbox(label = "Flip coordinates", id.name = "coord_flip", value = "1"), rk.XML.dropdown(label="Facet Layout", id.name="facet_layout", options=list("Wrap"=list(val="wrap", chk=TRUE), "Row"=list(val="row"), "Col"=list(val="col"))), color_palette_dropdown)
  value_labels_tab <- rk.XML.col(rk.XML.cbox(label="Show Labels", id.name="show_value_labels", value="1"), rk.XML.dropdown(label="Type", id.name="label_style", options=list("Plain Text"=list(val="text", chk=TRUE), "Label (Bg)"=list(val="label"), "Repelled Text"=list(val="text_repel"), "Repelled Label"=list(val="label_repel"))), rk.XML.dropdown(label="Color Preset", id.name="label_color_preset", options=list("Black"=list(val="black", chk=TRUE), "White"=list(val="white"), "Grey"=list(val="grey50"), "Blue"=list(val="blue"), "Custom"=list(val="custom"))), rk.XML.input(label="Custom Color", id.name="label_color_custom"), rk.XML.spinbox(label="Size", id.name="label_size", min=1, max=20, initial=3, real=TRUE), rk.XML.spinbox(label="Decimals", id.name="label_decimals", min=0, max=5, initial=1), rk.XML.spinbox(label="Max Overlaps", id.name="label_max_overlaps", min=0, max=1000, initial=10))

  dialog_bar <- rk.XML.dialog(label = "Survey Bar Chart (questionr)", child = rk.XML.row(svy_selector, rk.XML.col(rk.XML.tabbook(tabs = list("Data" = bar_data_tab, "Options" = bar_opts_tab, "Value Labels" = value_labels_tab, "Labels" = labels_tab, "Theme" = theme_tab, "Output" = device_tab)), rk.XML.preview(id.name="plot_preview"))))

  js_bar_calc <- paste(js_helpers, '
    var svy = getValue("svy_object"); var x_full = getValue("x_var"); var fill_full = getValue("fill_var"); var facet_full = getValue("facet_var");
    var x = getColumnName(x_full); var fill = getColumnName(fill_full); var facet = getColumnName(facet_full);
    var processed_svy = svy;
    if (getValue("omit_na") == "1") {
        var conds = [];
        if(x) conds.push("!is.na(" + x + ")");
        if(fill) conds.push("!is.na(" + fill + ")");
        if(facet) conds.push("!is.na(" + facet + ")");
        if(conds.length > 0) {
            echo("svy_clean <- subset(" + svy + ", " + conds.join(" & ") + ")\\n");
            processed_svy = "svy_clean";
        }
    }
    var freq = getValue("freq_type"); var pos = getValue("bar_pos"); var ord = getValue("order_x_freq");
    var inv = getValue("invert_order"); var ord_lvl = getValue("order_by_level_input");
    var pal = getValue("palette_input"); var flip = getValue("coord_flip");

    if(freq == "rel") {
        echo("plot_data <- " + processed_svy + " %>% survey::svytable(~" + x + (fill ? "+"+fill : "") + (facet ? "+"+facet : "") + ", design=.) %>% as.data.frame()\\n");
        echo("plot_data <- plot_data %>% group_by(" + x + (facet ? ","+facet : "") + ") %>% mutate(Prop = Freq/sum(Freq)) %>% ungroup()\\n");
        if(ord == "1") {
            var ord_metric = "Freq";
            if(fill && ord_lvl) {
                echo("plot_data <- plot_data %>% group_by(" + x + ") %>% mutate(ord_val = sum(Prop[" + fill + "==\\"" + ord_lvl + "\\"])) %>% ungroup()\\n");
                ord_metric = "ord_val";
            } else {
                 echo("plot_data <- plot_data %>% group_by(" + x + ") %>% mutate(ord_val = sum(Freq)) %>% ungroup()\\n");
                 ord_metric = "ord_val";
            }
            var fct = "fct_reorder(" + x + ", " + ord_metric + ", .desc=TRUE)";
            if(inv == "1") fct = "fct_rev(" + fct + ")";
            echo("plot_data$" + x + " <- " + fct + "\\n");
        }
        echo("p <- ggplot(plot_data, aes(x=" + x + ", y=Prop" + (fill ? ", fill="+fill : "") + ")) + geom_col(position=\\"" + pos + "\\") + scale_y_continuous(labels=scales::percent)\\n");
    } else {
        if(ord == "1") {
             echo("tmp_counts <- svytable(~" + x + ", " + processed_svy + ")\\n");
             echo("lvls <- names(sort(tmp_counts, decreasing=" + (inv=="1"?"FALSE":"TRUE") + "))\\n");
             echo(processed_svy + "$variables[[" + "\\"" + x + "\\"]] <- factor(" + processed_svy + "$variables[[" + "\\"" + x + "\\"]], levels=lvls)\\n");
        }
        echo("p <- questionr::ggsurvey(" + processed_svy + ") + geom_bar(aes(x=" + x + ", weight=.weights" + (fill ? ", fill="+fill : "") + "), position=\\"" + pos + "\\")\\n");
    }
    if(fill) {
        var legw = getValue("legend_wrap_width");
        var pal_opts = "palette=\\"" + pal + "\\"";
        if(legw > 0) pal_opts += ", labels=scales::label_wrap(" + legw + ")";
        echo("p <- p + scale_fill_brewer(" + pal_opts + ")\\n");
    }
    if(flip == "1") echo("p <- p + coord_flip()\\n");
    if(facet) {
        var lay = getValue("facet_layout");
        var lay_opt = "";
        if(lay == "row") lay_opt = ", nrow=1";
        if(lay == "col") lay_opt = ", ncol=1";
        echo("p <- p + facet_wrap(~" + facet + lay_opt + ")\\n");
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
       var opts = ", color=\\"" + col + "\\", size=" + size;
       if(style.includes("repel")) opts += ", max.overlaps=" + getValue("label_max_overlaps");
       if(style.includes("label")) opts += ", fill=\\"white\\"";
       var pos_func = "position_stack(vjust=0.5)";
       if(pos == "dodge") pos_func = "position_dodge(width=0.9)";
       if(pos == "fill") pos_func = "position_fill(vjust=0.5)";
       if(freq == "rel") {
           echo("p <- p + " + geom + "(aes(label=" + aes_lbl + "), position=" + pos_func + opts + ")\\n");
       } else {
           echo("p <- p + " + geom + "(aes(label=" + aes_lbl + ", weight=.weights), stat=\\"count\\", position=" + pos_func + opts + ")\\n");
       }
    }
    ', js_apply_theme
  )

  # =========================================================================================
  # --- COMPONENT 2: Survey Histogram (questionr) ---
  # =========================================================================================
  help_hist <- rk.rkh.doc(
    title = rk.rkh.title("Survey Histogram (questionr)"),
    summary = rk.rkh.summary("Create a weighted histogram for numeric variables from a survey design."),
    usage = rk.rkh.usage("Select a survey design object and a numeric variable.")
  )
  hist_svy <- rk.XML.varslot(label = "Survey Design", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  hist_x <- rk.XML.varslot(label = "Numeric Variable", source = "svy_selector", required = TRUE, id.name = "x_var", classes = c("numeric", "integer"))
  hist_facet <- rk.XML.varslot(label = "Facet Variable", source = "svy_selector", id.name = "facet_var", classes = c("factor", "character"))
  hist_opts <- rk.XML.col(rk.XML.spinbox(label = "Bins", id.name = "bins", min = 1, max = 100, initial = 30), rk.XML.input(label = "Fill", id.name = "fill_col", initial = "steelblue"), rk.XML.cbox(label = "Density Curve", id.name = "show_dens", value = "1"))
  dialog_hist <- rk.XML.dialog(label = "Survey Histogram (questionr)", child = rk.XML.row(svy_selector, rk.XML.col(rk.XML.tabbook(tabs = list("Data" = rk.XML.col(hist_svy, hist_x, hist_facet), "Options" = hist_opts, "Labels" = labels_tab, "Theme" = theme_tab, "Output" = device_tab)), rk.XML.preview(id.name="plot_preview"))))
  js_hist_calc <- paste(js_helpers, '
    var svy = getValue("svy_object"); var x = getColumnName(getValue("x_var")); var facet = getColumnName(getValue("facet_var"));
    var bins = getValue("bins"); var fill = getValue("fill_col"); var dens = getValue("show_dens");
    echo("p <- questionr::ggsurvey(" + svy + ") + \\n");
    if(dens == "1") {
       echo("  ggplot2::geom_histogram(aes(x=" + x + ", weight=.weights, y=..density..), bins=" + bins + ", fill=\\"" + fill + "\\", color=\\"white\\") + \\n");
       echo("  ggplot2::geom_density(aes(x=" + x + ", weight=.weights), alpha=0.3, fill=\\"grey50\\")\\n");
    } else {
       echo("  ggplot2::geom_histogram(aes(x=" + x + ", weight=.weights), bins=" + bins + ", fill=\\"" + fill + "\\", color=\\"white\\")\\n");
    }
    if(facet) echo("p <- p + ggplot2::facet_wrap(~" + facet + ")\\n");
    ', js_apply_theme
  )
  comp_hist <- rk.plugin.component("Histogram (questionr)", xml=list(dialog=dialog_hist), js=list(require=c("questionr", "ggplot2"), calculate=js_hist_calc, printout=js_printout_shared), hierarchy=list("Survey", "Graphs", "ggGraphs"), rkh=list(help=help_hist))

  # =========================================================================================
  # --- COMPONENT 3: Survey Boxplot (questionr) ---
  # =========================================================================================
  help_box <- rk.rkh.doc(
    title = rk.rkh.title("Survey Boxplot (questionr)"),
    summary = rk.rkh.summary("Create weighted boxplots to compare numeric distributions across groups."),
    usage = rk.rkh.usage("Select a survey design object, a numeric variable (Y), and a grouping variable (X).")
  )
  box_svy <- rk.XML.varslot(label = "Survey Design", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  box_y <- rk.XML.varslot(label = "Numeric Variable (Y)", source = "svy_selector", required = TRUE, id.name = "y_var", classes = c("numeric", "integer"))
  box_x <- rk.XML.varslot(label = "Grouping Variable (X)", source = "svy_selector", id.name = "x_var", classes = c("factor", "character"))
  box_opts <- rk.XML.col(rk.XML.cbox(label = "Fill by Group", id.name = "fill_by_group", value = "1", chk = TRUE), color_palette_dropdown, rk.XML.cbox(label = "Flip Coordinates", id.name = "coord_flip", value = "1"))
  dialog_box <- rk.XML.dialog(label = "Survey Boxplot (questionr)", child = rk.XML.row(svy_selector, rk.XML.col(rk.XML.tabbook(tabs = list("Data" = rk.XML.col(box_svy, box_y, box_x), "Options" = box_opts, "Labels" = labels_tab, "Theme" = theme_tab, "Output" = device_tab)), rk.XML.preview(id.name="plot_preview"))))
  js_box_calc <- paste(js_helpers, '
    var svy = getValue("svy_object"); var y = getColumnName(getValue("y_var")); var x = getColumnName(getValue("x_var"));
    var fill_grp = getValue("fill_by_group"); var pal = getValue("palette_input");
    echo("p <- questionr::ggsurvey(" + svy + ") + \\n");
    var x_aes = (x == "") ? "factor(1)" : x;
    var fill_aes = (fill_grp == "1" && x != "") ? ", fill=" + x : "";
    echo("  ggplot2::geom_boxplot(aes(x=" + x_aes + ", y=" + y + ", weight=.weights" + fill_aes + "))\\n");
    if(fill_grp == "1" && x != "") echo("p <- p + ggplot2::scale_fill_brewer(palette=\\"" + pal + "\\")\\n");
    if(getValue("coord_flip") == "1") echo("p <- p + ggplot2::coord_flip()\\n");
    if(x == "") echo("p <- p + ggplot2::theme(axis.text.x = element_blank(), axis.ticks.x = element_blank()) + labs(x=NULL)\\n");
    ', js_apply_theme
  )
  comp_box <- rk.plugin.component("Boxplot (questionr)", xml=list(dialog=dialog_box), js=list(require=c("questionr", "ggplot2"), calculate=js_box_calc, printout=js_printout_shared), hierarchy=list("Survey", "Graphs", "ggGraphs"), rkh=list(help=help_box))

  # =========================================================================================
  # --- COMPONENT 4: Survey Frequency Table (questionr) ---
  # =========================================================================================
  help_freq <- rk.rkh.doc(
    title = rk.rkh.title("Survey Frequency Table (questionr)"),
    summary = rk.rkh.summary("Generate a weighted frequency table with percentages."),
    usage = rk.rkh.usage("Select a survey design object and a categorical variable.")
  )
  freq_svy <- rk.XML.varslot(label = "Survey Design", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  freq_var <- rk.XML.varslot(label = "Variable", source = "svy_selector", required = TRUE, id.name = "x_var")
  freq_opts <- rk.XML.col(rk.XML.cbox(label = "Show Cumulative %", id.name = "cumul", value = "1", chk = TRUE), rk.XML.cbox(label = "Show Total Row", id.name = "total", value = "1", chk = TRUE), rk.XML.dropdown(label = "Sort", id.name = "sort", options = list("Decreasing (Freq)" = list(val = "dec", chk=TRUE), "Increasing (Freq)" = list(val = "inc"), "None (Levels)" = list(val = "none"))), rk.XML.cbox(label = "Exclude NAs from calculation", id.name = "na_exclude", value = "1", chk = TRUE))
  dialog_freq <- rk.XML.dialog(label = "Survey Frequency Table (questionr)", child = rk.XML.row(svy_selector, rk.XML.col(freq_svy, freq_var, freq_opts)))
  js_freq_calc <- paste(js_helpers, '
      var svy = getValue("svy_object"); var x = getColumnName(getValue("x_var"));
      var cumul = (getValue("cumul") == "1") ? "TRUE" : "FALSE";
      var total = (getValue("total") == "1") ? "TRUE" : "FALSE";
      var sort = getValue("sort");
      var na_ex = (getValue("na_exclude") == "1") ? "NA" : "NULL";
      echo("var_vec <- " + svy + "$variables[[" + "\\"" + x + "\\"]]\\n");
      echo("wt_vec <- weights(" + svy + ")\\n");
      echo("freq_tab <- questionr::freq(var_vec, w = wt_vec, cumul = " + cumul + ", total = " + total + ", sort = \\"" + sort + "\\", exclude = " + na_ex + ")\\n");
  ')
  js_freq_print <- paste(js_helpers, '
      var x = getColumnName(getValue("x_var"));
      echo("rk.header(\\"Weighted Frequency Table: " + x + " (questionr)\\")\\n");
      echo("rk.results(freq_tab)\\n");
  ')
  comp_freq <- rk.plugin.component("Frequency Table (questionr)", xml=list(dialog=dialog_freq), js=list(require="questionr", calculate=js_freq_calc, printout=js_freq_print), hierarchy=list("Survey", "Descriptive"), rkh=list(help=help_freq))

  # =========================================================================================
  # Final SKELETON (Fixing Duplicate Declaration)
  # =========================================================================================
  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    # Define Main Component (Bar Chart) here as ENTRY POINT
    xml = list(dialog = dialog_bar),
    js = list(calculate = js_bar_calc, printout = js_printout_shared),
    rkh = list(help = help_bar),

    # Define SUB-COMPONENTS here
    components = list(
        # comp_bar, # <-- REMOVED to prevent duplicate declaration
        comp_hist,
        comp_box,
        comp_freq
    ),

    # Map the Main Component to the Menu
    pluginmap = list(
        name = "Bar Chart (questionr)",
        hierarchy = list("Survey", "Graphs", "ggGraphs")
    ),

    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE, overwrite = TRUE, show = FALSE
  )
})
