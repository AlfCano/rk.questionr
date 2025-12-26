// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(questionr)\n");
}

function calculate(is_preview){
	// read in variables from dialog
	var cumul = getValue("cumul");
	var total = getValue("total");
	var sort = getValue("sort");

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
   
      var svy = getValue("svy_object"); var x = getColumnName(getValue("x_var"));
      var cumul = (getValue("cumul") == "1") ? "TRUE" : "FALSE";
      var total = (getValue("total") == "1") ? "TRUE" : "FALSE";
      var sort = getValue("sort");
      var na_ex = (getValue("na_exclude") == "1") ? "NA" : "NULL";
      echo("var_vec <- " + svy + "$variables[[" + "\"" + x + "\"]]\n");
      echo("wt_vec <- weights(" + svy + ")\n");
      echo("freq_tab <- questionr::freq(var_vec, w = wt_vec, cumul = " + cumul + ", total = " + total + ", sort = \"" + sort + "\", exclude = " + na_ex + ")\n");
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Frequency Table (questionr) results")).print();

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
   
      var x = getColumnName(getValue("x_var"));
      echo("rk.header(\"Weighted Frequency Table: " + x + " (questionr)\")\n");
      echo("rk.results(freq_tab)\n");
  

}

