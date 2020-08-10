local utl = require "luci.util"
local sys = require "luci.sys"
local fs  = require "nixio.fs"
local ip  = require "luci.ip"
local nw  = require "luci.model.network"

local s, m, Node, selectroute, subnets, routes
luci.sys.call("/etc/init.d/mycpe start > /dev/null")
m = Map("mycpe", translate("mycpe - Configuration"),
	translate("mycpe is a lightweight and efficient intelligent VPN management tool."))

s = m:section(TypedSection, "mycpe")
s.anonymous = true
s.addremove = false
s:tab("general", translate("General Settings"))
s:tab("advanced", translate("Advanced Settings"))
s:tab("route", translate("custom routes"),
	translate("Custom routing table. The following routing tables are automatically loaded into the VPN interface."))
--general
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



licence = s:taboption("general", Value, "licence", translate("CPE licence"))
licence.placeholder = "licence"


--password = s:taboption("general", Value, "password", translate("Password"))
--password.password=true;

gate = s:taboption("general", Flag, "gate", translate("Default gateway"))
if luci.sys.call("dnsmasq --help|grep chnroute > /dev/null") == 0 then
	gate.default = enable.disabled
else
	gate.default = enable.enabled
end

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
routes.rows = 50

routes.cfgvalue = function(self, cfg)
	return fs.readfile("/etc/chnroute_custom")
end

routes.write = function(self, cfg, value)
	fs.writefile("/etc/chnroute_custom", (value or ""):gsub("\r\n", "\n"))
end

routes.remove = routes.write

return m