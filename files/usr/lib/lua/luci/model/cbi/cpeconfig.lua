local utl = require "luci.util"
local sys = require "luci.sys"
local fs  = require "nixio.fs"
local ip  = require "luci.ip"
local nw  = require "luci.model.network"

local s, m, Node, selectroute, subnets, routes
luci.sys.call("/etc/init.d/mycpe start > /dev/null")
m = Map("mycpe", translate("mycpe - Configuration"),
	translate("mycpe is a lightweight and efficient intelligent CPE management tool."))

s = m:section(TypedSection, "mycpe")
s.anonymous = true
s.addremove = false
s:tab("general", translate("General Settings"))
s:tab("advanced", translate("Advanced Settings"))
s:tab("route", translate("Custom Routing Table"), translate("The following routing tables are automatically loaded."))
--general
uuid = s:taboption("general", DummyValue, "uuid", translate("Device UUID:"), translate("Sign in website:   <a href=# target=_blank>http://www.demo.com</a>"))

license = s:taboption("general", Value, "license", translate("License"))
license.placeholder = "license..."

enable = s:taboption("general", Flag, "enable", translate("Enable"))
enable.default = enable.disabled

Node = s:taboption("general", ListValue, "_Node", translate("Node"))
Node:value("auto", translate("Auto"))
Node:value("china", translate("China"))
Node:value("hongkong", translate("HongKong"))

Node.write = function(self, cfg, val)
	if Node:formvalue(cfg) == "china" then
		m:set(cfg, "Node", "china")
	elseif Node:formvalue(cfg) == "hongkong" then
		m:set(cfg, "Node", "hongkong")
	else
		m:set(cfg, "Node", "auto")
	end
end

Node.cfgvalue = function(self, cfg)
	local val = m:get(cfg, "Node") or ""
	if val:match("hongkong") then
		return "hongkong"
	end
	if val:match("china") then
		return "china"
	end
	return "auto"
end

globalrouting = s:taboption("general", Flag, "blobalrouting", translate("Global Routing"))
globalrouting.default = enable.disabled
--[[
selectroute = s:taboption("general", ListValue, "selectroute", translate("Select Route"))
selectroute:depends("gate", "")
selectroute:value("1", translate("To Global"))
selectroute:value("2", translate("To China"))
selectroute.write = function(self, cfg, val)
	if selectroute:formvalue(cfg) == "1" then
		m:set(cfg, "selectroute", "1")
	else
		m:set(cfg, "selectroute", "2")
	end
end
selectroute.cfgvalue = function(self, cfg)
	local val = m:get(cfg, "selectroute") or ""
	if val:match("2") then
		return "2"
	end
	return "1"
end


-- advanced

router = s:taboption("advanced", Flag, "router", translate("Router Config"))
router.default = enable.disabled

routerbgp = s:taboption("advanced", Flag, "routerbgp", translate("BGP"))
routerbgp.default = enable.disabled
routerbgp:depends("router", "1")

routerospf = s:taboption("advanced", Flag, "routerospf", translate("OSPF"))
routerospf.default = enable.disabled
routerospf:depends("router", "1")

bgp = s:taboption("advanced", ListValue, "bgp", translate("Select Route"))
bgp:depends("router", "1")
bgp:value("1", translate("To Global"))
bgp:value("2", translate("To China"))
bgp.write = function(self, cfg, val)
	if bgp:formvalue(cfg) == "1" then
		m:set(cfg, "bgp", "1")
	else
		m:set(cfg, "bgp", "2")
	end
end
bgp.cfgvalue = function(self, cfg)
	local val = m:get(cfg, "bgp") or ""
	if val:match("2") then
		return "2"
	end
	return "1"
end
]]

subnets = s:taboption("advanced", DynamicList, "subnets", translate("Local subnets"),
	translate("Filter the intranet address. The address listed will not be forwarded by VPN server."))
subnets.datatype = "ipaddr"

-- update
if luci.sys.call("/usr/sbin/mycpe checkupdate > /dev/null ") == 1 then
	s:tab("update", translate("CPE Update"))
	version = s:taboption("update", DummyValue, "update", translate("New Version:"), translate("<font color=#378a00>New version detected.</font>"))
	checkupdate = s:taboption("update", Button, "checkupdate", translate("Version upgrade")) 
	checkupdate.inputtitle = translate("Start upgrade")
	checkupdate.inputstyle = "apply"
		
	checkupdate.write = function(self, section)
		if luci.sys.call("/usr/sbin/mycpe upgrade > /dev/null ") == 0 then
			updatend = s:taboption("update", DummyValue, "version", translate("Update complete:"), translate("<font color=#378a00>Suggestion: restart CPE device after the update is completed. ..</font>"))
		else
			updatend = s:taboption("update", DummyValue, "version", translate("Update failed:"), translate("<font color=#378a00>Please try to update again later.</font>"))
		end
	end
end


--route
routes = s:taboption("route", TextValue, "_routes")
routes.rows = 30

routes.cfgvalue = function(self, cfg)
	return fs.readfile("/etc/chnroute_custom")
end

routes.write = function(self, cfg, value)
	fs.writefile("/etc/chnroute_custom", (value or ""):gsub("\r\n", "\n"))
end

routes.remove = routes.write


--[[
s:tab("zebra", translate("custom zebra"), translate("Custom zebra"))
zebra = s:taboption("zebra", TextValue, "_zebra")
zebra.rows = 30

zebra.cfgvalue = function(self, cfg)
	return fs.readfile("/etc/quagga/zebra.conf")
end

zebra.write = function(self, cfg, value)
	fs.writefile("/etc/quagga/zebra.conf", (value or ""):gsub("\r\n", "\n"))
end

zebra.remove = zebra.write
]]

return m