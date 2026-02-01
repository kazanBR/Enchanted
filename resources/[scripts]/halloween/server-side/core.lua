-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
GlobalState["Hallobox"] = 0
GlobalState["Halloween"] = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
for Index in pairs(Locations) do
	GlobalState["Halloween:"..Index] = false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HALLOWEEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("halloween",function(source,Args)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") or GlobalState["Halloween"] then
		return false
	end

	local Multiplier = { 1, 2 }
	
	for Index in pairs(Locations) do
		local LootRandom = math.random(Multiplier[1],Multiplier[2])
		if vRP.MountContainer(1,"Halloween:"..Index,Loots,LootRandom) then
			GlobalState["Halloween:"..Index] = true
		end
	end

	TriggerClientEvent("Notify",-1,"Doces ou Travessuras","Começou a caça as abóboras.","halloween",30000)
	GlobalState["Hallobox"] = CountTable(Locations)
	GlobalState["Halloween"] = true

	local EventDuration = 30 * 60000
	SetTimeout(EventDuration,function()
		if GlobalState["Halloween"] then
			TriggerClientEvent("Notify",-1,"Doces ou Travessuras","Terminou a caça as abóboras.","halloween",10000)
			GlobalState["Halloween"] = false
			
			for Index in pairs(Locations) do
				GlobalState["Halloween:"..Index] = false
			end
		end
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Hallobox",nil,function(Name,Key,Value)
	if Value <= 0 and GlobalState["Halloween"] then
		TriggerClientEvent("Notify",-1,"Doces ou Travessuras","Terminou a caça as abóboras.","halloween",10000)
		GlobalState["Halloween"] = false
		
		for Index in pairs(Locations) do
			GlobalState["Halloween:"..Index] = false
		end
	end
end)