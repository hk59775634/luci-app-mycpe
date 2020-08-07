module("luci.controller.mycpe", package.seeall)
 function index()
     entry({"admin", "mycpe"}, firstchild(), "mycpe", 60).dependent=false
	 entry({"admin", "mycpe", "mystatus"}, template("mystatus"), "mystatus", 1)
     entry({"admin", "mycpe", "myconfig"}, cbi("myconfig"), "myconfig", 2)

end
 