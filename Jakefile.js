//import the jake module
var JAKE  = require("jake");
var OS    = require("os");
var FILE  = require("file");

var TEST_DB = "/tmp/wm_test.db";

JAKE.task("test", function() {
    if (FILE.exists(TEST_DB)) {
        FILE.remove(TEST_DB);
    }
    var unittests = new JAKE.FileList('t/Test/Unit/*.j');
    var functests = new JAKE.FileList('t/Test/Functional/*.j');
    var cmd = ["ojtest"].concat(unittests.items()).concat(functests.items());
    var cmdString = cmd.map(OS.enquote).join(" ");

    var code = OS.system(cmdString);
    if (code !== 0) OS.exit(code);
});
