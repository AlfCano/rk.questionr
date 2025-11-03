# The Golden Rules of RKWard Plugin Development (Revised & Expanded)

*Based on `rkwarddev` versions `0.8` to `0.10` and lessons learned from rigorous debugging.*

### 1. The R Script is the Single Source of Truth
Your sole output will be a single R script that defines all plugin components as R objects and uses `rk.plugin.skeleton()` to write the final files. This script **must** be wrapped in `local({})` to avoid polluting the user's global environment. The script must begin with `require(rkwarddev)` and a `rkwarddev.required()` check.

### 2. The Mandate of Explicit IDs (For Widgets Only)
**Every interactive UI element** (`varslot`, `input`, `cbox`, `dropdown`, `saveobj`, `preview`, etc.) **must** be assigned a unique, hard-coded `id.name`. This is the primary defense against "Can't find an ID!" and "subscript out of bounds" errors. **Do not** assign an `id.name` to layout containers (`rk.XML.col`, `rk.XML.row`, `rk.XML.frame`).

### 3. The Inflexible One-`varselector`-to-Many-`varslot`s Pattern
The `source` argument of every `varslot` that depends on a selection **must** be the same `id.name` from the parent `varselector`. To select variables from a data frame *inside* another object (like a `svydesign` object), you **must** set the property *after* creating the object: `attr(my_varslot, "source_property") <- "variables"`.

### 4. The `<logic>` Section is Forbidden
The `<logic>` section, including `rk.XML.connect()`, is fragile and highly sensitive to the `rkwarddev` version. **All conditional behavior must be handled inside the `calculate` JavaScript string.** It is always better to have a slightly less "slick" UI (e.g., an input field that is always enabled) than a plugin that fails to load due to an incompatible `<logic>` tag.

### 5. The Immutable Raw JavaScript String Paradigm
You **must avoid programmatic JavaScript generation** and write self-contained, multi-line R character strings. Master `getValue()` by declaring a JavaScript variable for every UI component's `id.name` at the start of your script block.

### 6. The Sacred `is_preview` Pattern for Plots
Plotting device commands (`rk.graph.on()`, `rk.graph.off()`) **must** be wrapped in an `if(!is_preview){...}` block to ensure they only run on final submission. The `print(p)` call, however, should run in both modes. This is the only correct way to implement a plot preview.

### 7. The `calculate`/`printout` Separation and Contract
These two sections operate in completely separate scopes. They form a contract based on hard-coded object names.
*   **The `calculate` Block:** Generates the R code for the **entire computation sequence**. It **must** assign the final result object to a hard-coded, predictable name (e.g., `p <- ggplot(...)` for plots, `map <- get_osmdata(...)` for data objects).
*   **CRITICAL:** **Do not** use the value from a `saveobj` widget to name the object in the `calculate` block (e.g., `var save_name = getValue("save_obj"); code += save_name + " <- ..."` is **wrong**). RKWard handles the saving automatically based on the hard-coded object name.
*   **The `printout` Block:** Its **only** purpose is to display the result created in the `calculate` block. It **must** refer to the same hard-coded name (e.g., `print(p)` or `print(summary(map))`).
*   **Scope Isolation:** JavaScript variables are **not** shared between `calculate` and `printout`. A variable defined in one is undefined in the other.

### 8. Precision in `rkwarddev` Function Calls
*   **Function Signatures Vary:** Be aware that `rk.plugin.skeleton()` has different signatures in different `rkwarddev` versions. If you get an `"arguments not used"` error, you must bundle all plugin properties (`name`, `hierarchy`, `xml`, `js`, etc.) into a single `list` object and pass that as the sole argument. Older versions may accept them as named arguments.
*   **Trust But Verify Arguments:** Always check the documentation for the specific function you are calling. Do not assume a wrapper function accepts the same arguments as its base function.

### 9. Correct Component Architecture and Hierarchy
*   **Menu IDs are Specific:** The `hierarchy` list uses exact, **case-sensitive** strings for RKWard's menus. The main plot menu is `"plots"`, not `"plot"`. The main analysis menu is `"analysis"`.
*   **Debug with a Known-Good Menu:** If your plugin doesn't appear where you expect, temporarily change its hierarchy to a simple, known-good location like `list("analysis", "My Test Plugin")` and restart RKWard. If it appears there, the problem is the menu name; if it doesn't, there is another error preventing the plugin from loading at all.

### 10. The Sanctity of XML and R String Quoting
*   When defining R objects that generate XML, the R string literal should use single quotes (`'...'`). The XML attributes within that string must use double quotes (`"`). If the R code *inside* an attribute (like `initial`) needs its own string quotes, it **must** use single quotes again.
*   **Valid:** `rk.XML.input(initial = 'list(val = "A")')`
*   **Invalid:** `rk.XML.input(initial = "list(val = "A")")` will fail to parse.

### 11. The Two-Level Escaping Rule for JavaScript Strings
When writing JavaScript code inside an R string, you must satisfy two parsers: first R, then the JavaScript engine.
*   **R Parser First:** If you define your JS string with single quotes (e.g., `js_code <- '...'`), any literal single quotes *inside* the JavaScript **must** be escaped for R: `\'`.
    *   **Error:** `'var text = 'hello';'` will break R.
    *   **Correct:** `'var text = \'hello\';'`
*   **JavaScript Parser Second:** Remember that backslashes for JavaScript's own special characters (like in regular expressions) must be escaped for R. To produce a single `\` for the JS engine, you must write `\\` in the R string. To get `\.` in the final R code, the JS string must contain `\\\\.`.

### 12. The Mandate of Mandatory Metadata
Some plugin skeletons, especially those creating a full package, require a metadata object. If you receive an error like `Error: 'about' must be a character string or XiMpLe.node`, it is not optional. You **must** create an `about` object using `rk.XML.about()` and pass it to your `rk.plugin.skeleton()` call.
