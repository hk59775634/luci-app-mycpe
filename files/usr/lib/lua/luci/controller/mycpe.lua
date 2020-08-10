module("luci.controller.mycpe", package.seeall)
 function index()
     entry({"admin", "mycpe"}, firstchild(), "CPE", 60).dependent=false
	 entry({"admin", "mycpe", "cpestatus"}, template("cpestatus"), "status", 1)
     entry({"admin", "mycpe", "cpeconfig"}, cbi("cpeconfig"), "CONFIG", 2)

end
