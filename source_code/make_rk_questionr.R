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
      version = "0.4.7", # Frozen
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
    rk.XML.spinbox(label = "Resolution (ppi)", id.name = "dev_res", min = 50, max = 600, initial = 150),
    rk.XML.dropdown(label = "Background", id.name = "dev_bg", options = list("Transparent" = list(val = "transparent", chk = TRUE), "White" = list(val = "white")))
  )

  js_printout_shared <- '
    if(!is_preview){
      var graph_options = [];
      graph_options.push("device.type=\\"" + getValue("device_type") + "\\"");
      graph_options.push("width=" + getValue("dev_width"));
      graph_options.push("height=" + getValue("dev_height"));
      graph_options.push("res=" + getValue("dev_res"));
      graph_options.push("bg=\\"" + getValue("dev_bg") + "\\"");
      echo("rk.graph.on(" + graph_options.join(", ") + ")\\n");
    }
    echo("try({\\n");
    echo("  print(p)\\n");
    echo("})\\n");
    if(!is_preview){ echo("rk.graph.off()\\n"); }
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
    if(labs.length > 0) echo("p <- p + labs(" + labs.join(",") + ")\\n");

    if(getValue("theme_x_val_wrap") > 0) echo("p <- p + scale_x_discrete(labels = scales::label_wrap(" + getValue("theme_x_val_wrap") + "))\\n");
    if(getValue("theme_y_val_wrap") > 0) echo("p <- p + scale_y_discrete(labels = scales::label_wrap(" + getValue("theme_y_val_wrap") + "))\\n");

    var thm = [];
    if(getValue("theme_text_rel") != 1) thm.push("text=element_text(size=rel(" + getValue("theme_text_rel") + "))");
    if(getValue("theme_legend_pos") != "right") thm.push("legend.position=\\"" + getValue("theme_legend_pos") + "\\"");
    if(getValue("theme_x_angle") != 0) thm.push("axis.text.x=element_text(angle=" + getValue("theme_x_angle") + ", hjust=" + getValue("theme_x_hjust") + ")");
    if(thm.length > 0) echo("p <- p + theme(" + thm.join(",") + ")\\n");
  '

  svy_selector <- rk.XML.varselector(id.name = "svy_selector", label = "Select survey object")

  # =========================================================================================
  # GRAPH HIERARCHY
  # =========================================================================================
  h_graphs <- list("Survey", "Graphs", "questionr")

  # =========================================================================================
  # --- COMPONENT 1: Survey Bar Chart ---
  # =========================================================================================

  help_bar <- rk.rkh.doc(
    title = rk.rkh.title("Bar Chart"),
    summary = rk.rkh.summary("Create a bar chart for categorical variables from a complex survey design object, using the 'questionr' and 'ggsurvey' packages."),
    usage = rk.rkh.usage("Select a survey design object and a categorical variable. Optionally select a Fill variable and Facet variable.")
  )

  bar_svy <- rk.XML.varslot(label = "Survey Design", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  bar_x <- rk.XML.varslot(label = "Variable", source = "svy_selector", required = TRUE, id.name = "x_var")
  bar_fill <- rk.XML.varslot(label = "Fill", source = "svy_selector", id.name = "fill_var")
  bar_facet <- rk.XML.varslot(label = "Facet", source = "svy_selector", id.name = "facet_var")
  bar_data_tab <- rk.XML.col(bar_svy, bar_x, bar_fill, bar_facet, rk.XML.cbox(label = "Omit NA cases from selected variables", id.name = "omit_na", value = "1", chk = TRUE))
  ordering_frame <- rk.XML.frame(label = "X-axis Ordering", child = rk.XML.col(rk.XML.cbox(label = "Order X-axis by frequency", id.name = "order_x_freq", value = "1"), rk.XML.cbox(label = "Invert final order", id.name = "invert_order", value = "1"), rk.XML.input(label = "Order by level of Fill var (optional)", id.name = "order_by_level_input")))
  bar_opts_tab <- rk.XML.col(rk.XML.dropdown(label = "Frequency type", id.name = "freq_type", options = list("Absolute" = list(val = "abs", chk = TRUE), "Relative" = list(val = "rel"))), rk.XML.dropdown(label = "Bar position", id.name = "bar_pos", options = list("Stack" = list(val = "stack", chk = TRUE), "Dodge" = list(val = "dodge"), "Fill (Prop)" = list(val = "fill"))), ordering_frame, rk.XML.cbox(label = "Flip coordinates", id.name = "coord_flip", value = "1"), rk.XML.dropdown(label="Facet Layout", id.name="facet_layout", options=list("Wrap"=list(val="wrap", chk=TRUE), "Row"=list(val="row"), "Col"=list(val="col"))), color_palette_dropdown)
  value_labels_tab <- rk.XML.col(rk.XML.cbox(label="Show Labels", id.name="show_value_labels", value="1"), rk.XML.dropdown(label="Type", id.name="label_style", options=list("Plain Text"=list(val="text", chk=TRUE), "Label (Bg)"=list(val="label"), "Repelled Text"=list(val="text_repel"), "Repelled Label"=list(val="label_repel"))), rk.XML.dropdown(label="Color Preset", id.name="label_color_preset", options=list("Black"=list(val="black", chk=TRUE), "White"=list(val="white"), "Grey"=list(val="grey50"), "Blue"=list(val="blue"), "Custom"=list(val="custom"))), rk.XML.input(label="Custom Color", id.name="label_color_custom"), rk.XML.spinbox(label="Size", id.name="label_size", min=1, max=20, initial=3, real=TRUE), rk.XML.spinbox(label="Decimals", id.name="label_decimals", min=0, max=5, initial=1), rk.XML.spinbox(label="Max Overlaps", id.name="label_max_overlaps", min=0, max=1000, initial=10))

  dialog_bar <- rk.XML.dialog(label = "Bar Chart", child = rk.XML.row(svy_selector, rk.XML.col(rk.XML.tabbook(tabs = list("Data" = bar_data_tab, "Options" = bar_opts_tab, "Value Labels" = value_labels_tab, "Labels" = labels_tab, "Theme" = theme_tab, "Output" = device_tab)), rk.XML.preview(id.name="plot_preview"))))

  # Rewritten Bar Chart Logic for Robustness (Fixes object not found in relative freq)
  js_bar_calc <- paste(js_helpers, '
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
            echo("svy_clean <- subset(" + svy + ", " + conds.join(" & ") + ")\\n");
            processed_svy = "svy_clean";
        }
    }

    var freq = getValue("freq_type"); var pos = getValue("bar_pos"); var ord = getValue("order_x_freq");
    var inv = getValue("invert_order"); var ord_lvl = getValue("order_by_level_input");
    var pal = getValue("palette_input"); var flip = getValue("coord_flip");

    // --- RELATIVE FREQUENCY LOGIC ---
    if(freq == "rel") {
        echo("plot_data <- " + processed_svy + " %>% survey::svytable(~" + x + (fill ? "+"+fill : "") + (facet ? "+"+facet : "") + ", design=.) %>% as.data.frame()\\n");
        // Calculate Proportions
        echo("plot_data <- plot_data %>% group_by(" + x + (facet ? ","+facet : "") + ") %>% mutate(Prop = Freq/sum(Freq)) %>% ungroup()\\n");

        // Ordering (Using mutate to ensure variable scope)
        if(ord == "1") {
            var metric_val = "Freq"; // default total
            if(fill && ord_lvl) {
                echo("plot_data <- plot_data %>% group_by(" + x + ") %>% mutate(ord_val = sum(Prop[" + fill + "==\\"" + ord_lvl + "\\"])) %>% ungroup()\\n");
                metric_val = "ord_val";
            } else {
                 echo("plot_data <- plot_data %>% group_by(" + x + ") %>% mutate(ord_val = sum(Freq)) %>% ungroup()\\n");
                 metric_val = "ord_val";
            }
            var desc_arg = (inv == "1") ? "" : ", .desc=TRUE"; // Invert logic for fct_reorder is opposite to sort()
            echo("plot_data <- plot_data %>% mutate(" + x + " = fct_reorder(" + x + ", " + metric_val + desc_arg + "))\\n");
        }

        echo("p <- ggplot(plot_data, aes(x=" + x + ", y=Prop" + (fill ? ", fill="+fill : "") + ")) + geom_col(position=\\"" + pos + "\\") + scale_y_continuous(labels=scales::percent)\\n");

    // --- ABSOLUTE FREQUENCY LOGIC ---
    } else {
        if(ord == "1") {
             if(fill && ord_lvl) {
                 // Sort by specific fill level
                 echo("ord_stats <- svytable(~" + x + "+" + fill + ", " + processed_svy + ")\\n");
                 echo("target_col <- which(colnames(ord_stats) == \\"" + ord_lvl + "\\")\\n");
                 echo("ord_vals <- if(length(target_col) > 0) ord_stats[, target_col] else margin.table(ord_stats, 1)\\n");
             } else {
                 // Sort by total count
                 echo("ord_vals <- svytable(~" + x + ", " + processed_svy + ")\\n");
             }
             echo("lvls <- names(sort(ord_vals, decreasing=" + (inv=="1"?"FALSE":"TRUE") + "))\\n");
             // Update design using update() which is safer
             echo(processed_svy + " <- update(" + processed_svy + ", " + x + " = factor(" + x + ", levels=lvls))\\n");
        }
        echo("p <- questionr::ggsurvey(" + processed_svy + ") + geom_bar(aes(x=" + x + ", weight=.weights" + (fill ? ", fill="+fill : "") + "), position=\\"" + pos + "\\")\\n");
    }

    // --- COMMON STYLING ---
    if(fill) {
        var legw = getValue("legend_wrap_width");
        var lab_opt = (legw > 0) ? ", labels=scales::label_wrap(" + legw + ")" : "";
        echo("n_colors <- length(unique(na.omit(" + processed_svy + "$variables[[" + "\\"" + fill + "\\"]])))\\n");
        echo("if(n_colors > 8) {\\n");
        echo("  p <- p + scale_fill_manual(values = colorRampPalette(RColorBrewer::brewer.pal(8, \\"" + pal + "\\"))(n_colors)" + lab_opt + ")\\n");
        echo("} else {\\n");
        echo("  p <- p + scale_fill_brewer(palette=\\"" + pal + "\\"" + lab_opt + ")\\n");
        echo("}\\n");
    }

    if(flip == "1") echo("p <- p + coord_flip()\\n");

    if(facet) {
        var lay = getValue("facet_layout");
        var lay_opt = "";
        if(lay == "row") lay_opt = ", nrow=1";
        if(lay == "col") lay_opt = ", ncol=1";
        echo("p <- p + facet_wrap(~" + facet + lay_opt + ")\\n");
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

       var opts = ", color=\\"" + col + "\\", size=" + size;
       if(style.includes("repel")) opts += ", max.overlaps=" + getValue("label_max_overlaps");
       if(style.includes("label")) opts += ", fill=\\"white\\"";

       var pos_func = "position_stack(vjust=0.5)";
       if(pos == "dodge") pos_func = "position_dodge(width=0.9)";
       if(pos == "fill") pos_func = "position_fill(vjust=0.5)";

       var aes_extras = "";
       if(fill) aes_extras = ", group=" + fill;

       if(freq == "rel") {
           echo("p <- p + " + geom + "(aes(label=" + aes_lbl + aes_extras + "), position=" + pos_func + opts + ")\\n");
       } else {
           // Explicit mapping of X is required for stat_count to work in this layer
           echo("p <- p + " + geom + "(aes(x=" + x + ", label=" + aes_lbl + ", weight=.weights" + aes_extras + "), stat=\\"count\\", position=" + pos_func + opts + ")\\n");
       }
    }
    ', js_apply_theme
  )

  # =========================================================================================
  # --- COMPONENT 2: Survey Histogram ---
  # =========================================================================================
  help_hist <- rk.rkh.doc(title = rk.rkh.title("Histogram"), summary = rk.rkh.summary("Create a weighted histogram."), usage = rk.rkh.usage("Select survey and numeric variable."))
  hist_svy <- rk.XML.varslot(label = "Survey Design", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  hist_x <- rk.XML.varslot(label = "Numeric Variable", source = "svy_selector", required = TRUE, id.name = "x_var", classes = c("numeric", "integer"))
  hist_facet <- rk.XML.varslot(label = "Facet Variable", source = "svy_selector", id.name = "facet_var", classes = c("factor", "character"))
  hist_opts <- rk.XML.col(rk.XML.spinbox(label = "Bins", id.name = "bins", min = 1, max = 100, initial = 30), rk.XML.input(label = "Fill", id.name = "fill_col", initial = "steelblue"), rk.XML.cbox(label = "Density Curve", id.name = "show_dens", value = "1"))
  dialog_hist <- rk.XML.dialog(label = "Histogram", child = rk.XML.row(svy_selector, rk.XML.col(rk.XML.tabbook(tabs = list("Data" = rk.XML.col(hist_svy, hist_x, hist_facet), "Options" = hist_opts, "Labels" = labels_tab, "Theme" = theme_tab, "Output" = device_tab)), rk.XML.preview(id.name="plot_preview"))))

  js_hist_calc <- paste(js_helpers, '
    var svy = getValue("svy_object"); var x = getColumnName(getValue("x_var")); var facet = getColumnName(getValue("facet_var"));
    var bins = getValue("bins"); var fill = getValue("fill_col"); var dens = getValue("show_dens");
    echo("p <- questionr::ggsurvey(" + svy + ") + \\n");
    if(dens == "1") {
       echo("  geom_histogram(aes(x=" + x + ", weight=.weights, y=after_stat(density)), bins=" + bins + ", fill=\\"" + fill + "\\", color=\\"white\\") + \\n");
       echo("  geom_density(aes(x=" + x + ", weight=.weights), alpha=0.3, fill=\\"grey50\\")\\n");
    } else {
       echo("  geom_histogram(aes(x=" + x + ", weight=.weights), bins=" + bins + ", fill=\\"" + fill + "\\", color=\\"white\\")\\n");
    }
    if(facet) echo("p <- p + facet_wrap(~" + facet + ")\\n");
    ', js_apply_theme
  )
  comp_hist <- rk.plugin.component("Histogram", xml=list(dialog=dialog_hist), js=list(require=c("questionr", "ggplot2"), calculate=js_hist_calc, printout=js_printout_shared), hierarchy=h_graphs, rkh=list(help=help_hist))

  # =========================================================================================
  # --- COMPONENT 3: Survey Boxplot ---
  # =========================================================================================
  help_box <- rk.rkh.doc(title = rk.rkh.title("Boxplot"), summary = rk.rkh.summary("Create weighted boxplots."), usage = rk.rkh.usage("Select survey, numeric Y, and grouping X."))
  box_svy <- rk.XML.varslot(label = "Survey Design", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  box_y <- rk.XML.varslot(label = "Numeric Variable (Y)", source = "svy_selector", required = TRUE, id.name = "y_var", classes = c("numeric", "integer"))
  box_x <- rk.XML.varslot(label = "Grouping Variable (X)", source = "svy_selector", id.name = "x_var", classes = c("factor", "character"))

  box_opts <- rk.XML.col(
      rk.XML.cbox(label = "Fill by Group", id.name = "fill_by_group", value = "1", chk = TRUE),
      color_palette_dropdown,
      rk.XML.cbox(label = "Flip Coordinates", id.name = "coord_flip", value = "1"),
      rk.XML.cbox(label = "Varwidth", id.name = "varwidth", value = "1"),
      rk.XML.frame(label="Ordering", child=rk.XML.col(
          rk.XML.cbox(label = "Order X by Median Y", id.name = "order_median", value = "1"),
          rk.XML.cbox(label = "Invert Order", id.name = "invert_order", value = "1")
      ))
  )
  dialog_box <- rk.XML.dialog(label = "Boxplot", child = rk.XML.row(svy_selector, rk.XML.col(rk.XML.tabbook(tabs = list("Data" = rk.XML.col(box_svy, box_y, box_x), "Options" = box_opts, "Labels" = labels_tab, "Theme" = theme_tab, "Output" = device_tab)), rk.XML.preview(id.name="plot_preview"))))

  js_box_calc <- paste(js_helpers, '
    var svy = getValue("svy_object"); var y = getColumnName(getValue("y_var")); var x = getColumnName(getValue("x_var"));
    var fill_grp = getValue("fill_by_group"); var pal = getValue("palette_input");
    var processed_svy = svy;

    echo("options(survey.lonely.psu=\\"adjust\\")\\n");

    var ord = getValue("order_median");
    var inv = getValue("invert_order");

    if (ord == "1" && x != "") {
        echo("design_for_ord <- subset(" + processed_svy + ", is.finite(" + y + "))\\n");
        echo("med_df <- survey::svyby(formula = ~" + y + ", by = ~" + x + ", design = design_for_ord, FUN = survey::svyquantile, quantiles = 0.5, na.rm = TRUE, ci = FALSE, keep.var = FALSE)\\n");
        echo("ordered_levels <- as.character(med_df[order(med_df[[ncol(med_df)]]), 1])\\n");
        if (inv == "1") echo("ordered_levels <- rev(ordered_levels)\\n");
        echo(processed_svy + " <- update(" + processed_svy + ", " + x + " = factor(" + x + ", levels = ordered_levels))\\n");
    }

    echo("p <- questionr::ggsurvey(" + processed_svy + ") + \\n");
    var x_aes = (x == "") ? "factor(1)" : x;
    var fill_aes = (fill_grp == "1" && x != "") ? ", fill=" + x : "";
    var vw = (getValue("varwidth") == "1") ? "TRUE" : "FALSE";
    echo("  geom_boxplot(aes(x=" + x_aes + ", y=" + y + ", weight=.weights" + fill_aes + "), varwidth=" + vw + ")\\n");

    if(fill_grp == "1" && x != "") {
        echo("n_colors <- length(unique(na.omit(" + svy + "$variables[[" + "\\"" + x + "\\"]])))\\n");
        echo("if(n_colors > 8) {\\n");
        echo("  p <- p + scale_fill_manual(values = colorRampPalette(RColorBrewer::brewer.pal(8, \\"" + pal + "\\"))(n_colors))\\n");
        echo("} else {\\n");
        echo("  p <- p + scale_fill_brewer(palette=\\"" + pal + "\\")\\n");
        echo("}\\n");
    }

    if(getValue("coord_flip") == "1") echo("p <- p + coord_flip()\\n");
    if(x == "") echo("p <- p + theme(axis.text.x = element_blank(), axis.ticks.x = element_blank()) + labs(x=NULL)\\n");
    ', js_apply_theme
  )
  comp_box <- rk.plugin.component("Boxplot", xml=list(dialog=dialog_box), js=list(require=c("questionr", "ggplot2", "RColorBrewer", "survey"), calculate=js_box_calc, printout=js_printout_shared), hierarchy=h_graphs, rkh=list(help=help_box))

  # =========================================================================================
  # --- COMPONENT 4: Survey Frequency Table ---
  # =========================================================================================
  help_freq <- rk.rkh.doc(title = rk.rkh.title("Frequency Table"), summary = rk.rkh.summary("Generate weighted freq table."), usage = rk.rkh.usage("Select survey and variable."))
  freq_svy <- rk.XML.varslot(label = "Survey Design", source = "svy_selector", required = TRUE, id.name = "svy_object", classes = c("survey.design", "svyrep.design"))
  freq_var <- rk.XML.varslot(label = "Variable", source = "svy_selector", required = TRUE, id.name = "x_var")
  freq_opts <- rk.XML.col(rk.XML.cbox(label = "Show Cumulative %", id.name = "cumul", value = "1", chk = TRUE), rk.XML.cbox(label = "Show Total Row", id.name = "total", value = "1", chk = TRUE), rk.XML.dropdown(label = "Sort", id.name = "sort", options = list("Decreasing (Freq)" = list(val = "dec", chk=TRUE), "Increasing (Freq)" = list(val = "inc"), "None (Levels)" = list(val = "none"))), rk.XML.cbox(label = "Exclude NAs from calculation", id.name = "na_exclude", value = "1", chk = TRUE))
  freq_save <- rk.XML.saveobj(label = "Save Frequency Table", initial = "freq_res", id.name = "save_freq")

  dialog_freq <- rk.XML.dialog(label = "Frequency Table", child = rk.XML.row(svy_selector, rk.XML.col(freq_svy, freq_var, freq_opts, freq_save)))

  js_freq_calc <- paste(js_helpers, '
      var svy = getValue("svy_object"); var x = getColumnName(getValue("x_var"));
      var cumul = (getValue("cumul") == "1") ? "TRUE" : "FALSE";
      var total = (getValue("total") == "1") ? "TRUE" : "FALSE";
      var sort = getValue("sort");
      var na_ex = (getValue("na_exclude") == "1") ? "no" : "always";

      echo("svy_tab <- survey::svytable(~" + x + ", design = " + svy + ")\\n");
      echo("freq_res <- questionr::freq(svy_tab, cum = " + cumul + ", total = " + total + ", sort = \\"" + sort + "\\")\\n");
  ')
  js_freq_print <- paste(js_helpers, '
      var x = getColumnName(getValue("x_var"));
      echo("rk.header(\\"Weighted Frequency Table: " + x + "\\")\\n");
      echo("rk.results(freq_res)\\n");
  ')
  comp_freq <- rk.plugin.component("Frequency Table", xml=list(dialog=dialog_freq), js=list(require="questionr", calculate=js_freq_calc, printout=js_freq_print), hierarchy=list("Survey", "Descriptive"), rkh=list(help=help_freq))

  # =========================================================================================
  # Final SKELETON
  # =========================================================================================
  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    xml = list(dialog = dialog_bar),
    js = list(
        require = c("questionr", "ggplot2", "survey", "ggrepel", "scales", "dplyr", "forcats", "RColorBrewer"),
        calculate = js_bar_calc,
        printout = js_printout_shared
    ),
    rkh = list(help = help_bar),
    components = list(
        comp_hist,
        comp_box,
        comp_freq
    ),
    pluginmap = list(name = "Bar Chart", hierarchy = h_graphs),
    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE, overwrite = TRUE, show = FALSE
  )
})
