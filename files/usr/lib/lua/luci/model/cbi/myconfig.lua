local utl = require "luci.util"
local sys = require "luci.sys"
local fs  = require "nixio.fs"
local ip  = require "luci.ip"
local nw  = require "luci.model.network"

local s, m, Protocol, selectroute, subnets, routes

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

Protocol = s:taboption("general", ListValue, "_Protocol", translate("Protocol"))

Protocol:value("openconnect", translate("OpenConnect"))

Protocol.write = function(self, cfg, val)
	if Protocol:formvalue(cfg) == "openconnect" then
		m:set(cfg, "Protocol", "openconnect")
	else
		m:set(cfg, "Protocol", "openvpn")
	end
end

Protocol.cfgvalue = function(self, cfg)
	local val = m:get(cfg, "Protocol") or ""
	if val:match("openvpn") then
		return "openvpn"
	end
	return "openconnect"
end

enable = s:taboption("general", Flag, "enable", translate("Bring up on boot"))
enable.default = enable.disabled

server = s:taboption("general", Value, "server", translate("VPN Server"))
server.placeholder = "Server Name or Server IP Address"

port = s:taboption("general", Value, "port", translate("VPN Server port"))
port.placeholder = "443"

certificate = s:taboption("general", Value, "certificate", translate("VPN Server's certificate"))

group = s:taboption("general", Value, "group", translate("User Group"))

username = s:taboption("general", Value, "username", translate("Username"))
username.placeholder = "username"

password = s:taboption("general", Value, "password", translate("Password"))
password.password=true;

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


if luci.sys.call("dnsmasq --help|grep chnroute > /dev/null") == 0 then
	cusdns = s:taboption("general", Flag, "cusdns", translate("Use smart DNS resolution."))
	cusdns.default = enable.enabled
	
	Global_dns = s:taboption("general", Value, "global_dns", translate("Global DNS"))
	Global_dns:depends("cusdns", "1")
	Global_dns.placeholder = "1.1.1.1"

	China_dns = s:taboption("general", Value, "china_dns", translate("China DNS"))
	China_dns:depends("cusdns", "1")
	China_dns.placeholder = "114.114.114.114"

else
	cusdns = s:taboption("general", Flag, "cusdns", translate("Use custom DNS servers"), 
	translate("Your system does not support the chnroute plug-in for dnsmasq.<br>Only custom DNS servers can be used.<br><a href=\"http://www.google.com\" target=\"_blank\">View installation instructions</a>"))
	cusdns.default = enable.disable
	Global_dns = s:taboption("general", Value, "global_dns", translate("custom DNS servers"))
	Global_dns:depends("cusdns", "1")
	Global_dns.placeholder = "1.1.1.1"

end

mtu = s:taboption("general", Value, "mtu", translate("Override MTU"))
mtu.placeholder = "1406"
-- advanced
subnets = s:taboption("advanced", DynamicList, "subnets", translate("Local subnets"),
	translate("Filter the intranet address. The address listed will not be forwarded by VPN server."))
subnets.datatype = "ipaddr"


if luci.sys.call("/usr/sbin/mycpe checkupdate > /dev/null ") == 0 then
	version = s:taboption("advanced", DummyValue, "version", translate("版本信息:"), translate("<font color=#378a00>未发现新版本.</font>"))
else
	version = s:taboption("advanced", DummyValue, "version", translate("版本信息:"), translate("<font color=#378a00>发现新版本.</font>"))
		checkupdate = s:taboption("advanced", Button, "checkupdate", translate("版本升级")) 
		checkupdate.inputtitle = translate("开始升级")
		checkupdate.inputstyle = "apply"
	checkupdate.write = function(self, section)
		if luci.sys.call("/usr/sbin/mycpe upgrade > /dev/null ") == 0 then
			updatend = s:taboption("advanced", DummyValue, "version", translate("更新完成:"), translate("<font color=#378a00>更新完成后建议重启设备.</font>"))
		else
			updatend = s:taboption("advanced", DummyValue, "version", translate("更新失败:"), translate("<font color=#378a00>请再次更新或稍后再试.</font>"))
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