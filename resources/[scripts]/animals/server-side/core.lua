-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Animal = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:REGISTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("animals:Register")
AddEventHandler("animals:Register",function(Network)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Animal[Passport] then
		Animal[Passport] = Network
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:CLEARNER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("animals:Cleaner")
AddEventHandler("animals:Cleaner",function()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Animal[Passport] then
		TriggerEvent("DeletePed",Animal[Passport])
		Animal[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANIMALS:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("animals:Delete",function(source,Passport)
	if Animal[Passport] then
		TriggerClientEvent("animals:Delete",source)
		TriggerEvent("DeletePed",Animal[Passport])
		Animal[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Animal[Passport] then
		TriggerEvent("DeletePed",Animal[Passport])
		Animal[Passport] = nil
	end
end)