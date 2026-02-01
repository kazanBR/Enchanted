-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("barbershop",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOCATIONS
-----------------------------------------------------------------------------------------------------------------------------------------
local Locations = {
	{ Coords = vec3(-813.37,-183.85,37.57) },
	{ Coords = vec3(138.13,-1706.46,29.3) },
	{ Coords = vec3(-1280.92,-1117.07,7.0) },
	{ Coords = vec3(1930.54,3732.06,32.85) },
	{ Coords = vec3(1214.2,-473.18,66.21) },
	{ Coords = vec3(-33.61,-154.52,57.08) },
	{ Coords = vec3(-276.65,6226.76,31.7) }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Update(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		vRP.Query("playerdata/SetData",{ Passport = Passport, Name = "Barbershop", Information = json.encode(Table) })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MODE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Mode()
	local source = source
	local Passport = vRP.Passport(source)
	local Identity = vRP.Identity(Passport)

	return Passport and Identity and Identity["Created"] >= os.time() and true or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINITSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	local Consult = vRP.Query("entitydata/GetData",{ Name = "Barbershop" })
	local Result = Consult and Consult[1] and json.decode(Consult[1].Information) or {}

	for _,v in pairs(Result) do
		table.insert(Locations,v)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADD
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Add",function(Table)
	local Consult = vRP.Query("entitydata/GetData",{ Name = "Barbershop" })
	local Result = Consult and Consult[1] and json.decode(Consult[1].Information) or {}

	table.insert(Result,Table)
	table.insert(Locations,Table)

	TriggerClientEvent("barbershop:Insert",-1,Table)
	vRP.Query("entitydata/SetData",{ Name = "Barbershop", Information = json.encode(Result) })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	TriggerClientEvent("barbershop:Init",source,Locations)
end)