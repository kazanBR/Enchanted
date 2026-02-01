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
Tunnel.bindInterface("towed",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Impound = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPS
-----------------------------------------------------------------------------------------------------------------------------------------
local Drops = {
	{ Item = "plastic", Chance = 75, Min = 25, Max = 45, Addition = 0.050 },
	{ Item = "glass", Chance = 75, Min = 25, Max = 45, Addition = 0.050 },
	{ Item = "rubber", Chance = 75, Min = 25, Max = 45, Addition = 0.050 },
	{ Item = "aluminum", Chance = 25, Min = 15, Max = 25, Addition = 0.025 },
	{ Item = "copper", Chance = 25, Min = 15, Max = 25, Addition = 0.025 }
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- VEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Vehicle(Model,Locale,Destiny)
	local source = source
	local CurrentTimer = os.time() + 10
	local Vehicle = CreateVehicle(Model,Locations[Locale][Destiny],true,false)

	while not DoesEntityExist(Vehicle) or NetworkGetNetworkIdFromEntity(Vehicle) == 0 do
		if os.time() >= CurrentTimer then
			return false
		end

		Wait(100)
	end

	local Plate = vRP.GeneratePlate()
	local Network = NetworkGetNetworkIdFromEntity(Vehicle)

	SetVehicleBodyHealth(Vehicle,10.0)
	SetVehicleNumberPlateText(Vehicle,Plate)

	Entity(Vehicle).state:set("Fuel",0,true)
	Entity(Vehicle).state:set("Nitro",0,true)

	Impound[Plate] = {
		Source = source,
		Network = Network
	}

	return Network,Plate
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("garages:Delete")
AddEventHandler("garages:Delete",function(Network,Plate)
	if Network and Plate and Impound[Plate] then
		if vRP.Passport(Impound[Plate].Source) then
			TriggerClientEvent("towed:Inative",Impound[Plate].Source,Plate)
		end

		Impound[Plate] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOWED:PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("towed:Payment")
AddEventHandler("towed:Payment",function(Plate)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and Impound[Plate] then
		Active[Passport] = true

		local GainExperience = 2
		local Result = RandPercentage(Drops)
		local _,Level = vRP.GetExperience(Passport,"Towed")
		local Valuation = Result.Valuation + Result.Valuation * (Result.Addition * Level)

		if exports.inventory:Buffs("Dexterity",Passport) then
			Valuation = Valuation + (Valuation * 0.1)
		end

		for Permission,Multiplier in pairs({ Ouro = 0.1, Prata = 0.075, Bronze = 0.05 }) do
			if vRP.HasService(Passport,Permission) then
				Valuation = Valuation + (Valuation * Multiplier)
				GainExperience = GainExperience + 3
			end
		end

		TriggerEvent("garages:Deleted",Impound[Plate].Network,Plate)
		vRP.GenerateItem(Passport,Result.Item,Valuation,true)
		vRP.PutExperience(Passport,"Towed",GainExperience)
		vRP.BattlepassPoints(Passport,GainExperience)
		vRP.GenerateItem(Passport,"dollar",250,true)
		vRP.UpgradeStress(Passport,5)

		Active[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOWED:IMPOUND
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("towed:Impound")
AddEventHandler("towed:Impound",function(Table)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasService(Passport,"Policia") then
		TriggerEvent("garages:Deleted",Table[4],Table[1])
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	if Active[Passport] then
		Active[Passport] = nil
	end
end)