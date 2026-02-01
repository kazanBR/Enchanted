-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("boosting",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Pendings = {}
local Cooldowns = {}
local ActiveMax = {}
local MaxContracts = 0
local TotalContracts = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONTRACTS
-----------------------------------------------------------------------------------------------------------------------------------------
local Contracts = {
	[1] = {
		{
			Vehicle = "gt500",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "toros",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "sheava",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "surano",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "rapidgt",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "feltzer2",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "alpha",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "gp1",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "infernus",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "bullet",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "freecrawler",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "turismo2",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "zr350",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "locust",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "seven70",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "caracara2",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "ruffian",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		},{
			Vehicle = "enduro",
			Timer = 3600,
			Value = 150,
			Plate = "",
			Class = 1,
			Exp = 5
		}
	},
	[2] = {
		{
			Vehicle = "specter",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "rebla",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "ruston",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "jester",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "banshee",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "cypher",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "voltic",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "rt3000",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "sc1",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "carbonizzare",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "infernus2",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "imorgon",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "sultan2",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "elegy2",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "yosemite2",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "ninef",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "everon",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		},{
			Vehicle = "double",
			Timer = 3600,
			Value = 175,
			Plate = "",
			Class = 2,
			Exp = 4
		}
	},
	[3] = {
		{
			Vehicle = "jackal",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "sugoi",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "penumbra",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "paragon",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "nero",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "komoda",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "ninef2",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "futo",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "buffalo3",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "banshee2",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "adder",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "schlagen",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "bestiagts",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "jester3",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "elegy",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "cheetah2",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "khamelion",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "sanchez",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		},{
			Vehicle = "diablous2",
			Timer = 3600,
			Value = 200,
			Plate = "",
			Class = 3,
			Exp = 4
		}
	},
	[4] = {
		{
			Vehicle = "omnis",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "massacro",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "euros",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "cheetah",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "tyrus",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "kuruma",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "nero2",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "ardent",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "sultan3",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "autarch",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "fmj",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "jester2",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "carbonrs",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		},{
			Vehicle = "reever",
			Timer = 3600,
			Value = 225,
			Plate = "",
			Class = 4,
			Exp = 3
		}
	},
	[5] = {
		{
			Vehicle = "gb200",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "sultanrs",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "pariah",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "vacca",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "zentorno",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "t20",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "issi7",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "penetrator",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "emerus",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "revolter",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "sentinel3",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "bati",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		},{
			Vehicle = "bf400",
			Timer = 3600,
			Value = 250,
			Plate = "",
			Class = 5,
			Exp = 3
		}
	},
	[6] = {
		{
			Vehicle = "flashgt",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		},{
			Vehicle = "dominator7",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		},{
			Vehicle = "osiris",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		},{
			Vehicle = "turismor",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		},{
			Vehicle = "jester4",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		},{
			Vehicle = "pfister811",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		},{
			Vehicle = "italigtb2",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		},{
			Vehicle = "akuma",
			Timer = 3600,
			Value = 275,
			Plate = "",
			Class = 6,
			Exp = 2
		}
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- MINIMALS
-----------------------------------------------------------------------------------------------------------------------------------------
local Minimals = {
	[1] = {
		Min = 300,
		Max = 900,
		Item = "blue_essence"
	},
	[2] = {
		Min = 600,
		Max = 1200,
		Item = "purple_essence"
	},
	[3] = {
		Min = 900,
		Max = 1500,
		Item = "green_essence"
	},
	[4] = {
		Min = 1200,
		Max = 1800,
		Item = "red_essence"
	},
	[5] = {
		Min = 1500,
		Max = 2100,
		Item = "pink_essence"
	},
	[6] = {
		Min = 1800,
		Max = 2700,
		Item = "pink_essence"
	}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- LEVELS
-----------------------------------------------------------------------------------------------------------------------------------------
local Levels = { 0,1000,2000,3500,5000,7500 }
-----------------------------------------------------------------------------------------------------------------------------------------
-- ABOUTCLASSES
-----------------------------------------------------------------------------------------------------------------------------------------
function AboutClasses(Experience)
	local Return = 1

	for Table = 1,#Levels do
		if Experience >= Levels[Table] then
			Return = Table
		end
	end

	return Return
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADTICK
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Citizen.Wait(60000)

		for Passport,Pending in pairs(Pendings) do
			local source = vRP.Source(Passport)
			if source then
				local Experience = vRP.GetExperience(Passport,"Boosting")
				local Level = AboutClasses(Experience)
				local Tier = math.random(Level)

				Cooldowns[Passport] = Cooldowns[Passport] or {}

				if Cooldowns[Passport][Tier] == nil then
					Cooldowns[Passport][Tier] = 0
				end

				local Cooldown = os.time() >= Cooldowns[Passport][Tier]
				local Slotable = CountTable(Pendings[Passport]) < 3
				local MaxContract = (Tier == 6)

				if Cooldown and Slotable and (not MaxContract or (MaxContracts < 3 and not ActiveMax[Passport])) then
					if MaxContract then
						MaxContracts = MaxContracts + 1
						ActiveMax[Passport] = true
					end

					TotalContracts = TotalContracts + 1

					local TierContracts = Contracts[Tier]
					if TierContracts and #TierContracts > 0 then
						local Selected = math.random(#TierContracts)
						Pendings[Passport][TotalContracts] = TierContracts[Selected]

						local Rand = Minimals[Tier]
						if Rand then
							Cooldowns[Passport][Tier] = os.time() + math.random(Rand.Min,Rand.Max)
						end
					end
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPERIENCE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Experience()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	return { vRP.GetExperience(Passport,"Boosting"),Levels }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACTIVES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Actives()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Data = Active[Passport]
	if not Data then
		return false
	end

	if os.time() >= Data.Timer then
		Cooldowns[Passport] = Cooldowns[Passport] or {}

		local Class = Data.Class
		local Rand = Minimals[Class]
		if Rand then
			Cooldowns[Passport][Class] = os.time() + math.random(Rand.Min,Rand.Max)
		end

		Active[Passport] = nil

		return false
	end

	return {
		Number = Data.Number,
		Vehicle = VehicleName(Data.Vehicle),
		Timer = Data.Timer - os.time(),
		Class = Data.Class,
		Value = Data.Value,
		Exp = Data.Exp
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PENDINGS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Pendings()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return {}
	end

	Pendings[Passport] = Pendings[Passport] or {}
	Cooldowns[Passport] = Cooldowns[Passport] or {}

	for i = 1,6 do
		Cooldowns[Passport][i] = Cooldowns[Passport][i] or os.time()
	end

	local Results = {}
	for Number,Data in pairs(Pendings[Passport]) do
		Results[#Results + 1] = {
			Number = Number,
			Vehicle = VehicleName(Data.Vehicle),
			Timer = Data.Timer,
			Class = Data.Class,
			Value = Data.Value,
			Exp = Data.Exp,
			Scratch = false
		}
	end

	return Results
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ACCEPT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Accept(Selected)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	local Data = Pendings[Passport] and Pendings[Passport][Selected]
	if not Data or not vRP.TakeItem(Passport,"platinum",Data.Value) then
		return false
	end

	Active[Passport] = {
		Vehicle = Data.Vehicle,
		Class = Data.Class,
		Value = Data.Value,
		Exp = Data.Exp,
		Timer = os.time() + Data.Timer,
		Number = Selected
	}

	TriggerClientEvent("boosting:Active",source,Data.Vehicle,Data.Class)
	Pendings[Passport][Selected] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SCRATCH
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Scratch(Selected)
	local source = source
	return vRP.Passport(source)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Transfer(Selected,OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Selected or not OtherPassport then
		return false
	end

	local SenderPendings = Pendings[Passport]
	local ReceiverPendings = Pendings[OtherPassport]
	if not SenderPendings or not ReceiverPendings then
		return false
	end

	local Contract = SenderPendings[Selected]
	if not Contract or CountTable(ReceiverPendings) >= 3 then
		return false
	end

	Cooldowns[Passport] = Cooldowns[Passport] or {}

	local Class = Contract.Class
	local Rand = Minimals[Class]
	if Rand then
		Cooldowns[Passport][Class] = os.time() + math.random(Rand.Min,Rand.Max)
	end

	ReceiverPendings[#ReceiverPendings + 1] = Contract
	SenderPendings[Selected] = nil

	TriggerClientEvent("Notify",source,"Sucesso","Transferência concluída.","verde",5000)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DECLINE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Decline(Selected)
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Data = Pendings[Passport]
	local Contract = Data and Data[Selected]
	if not Contract then
		return false
	end

	Cooldowns[Passport] = Cooldowns[Passport] or {}

	local Class = Contract.Class
	local Rand = Minimals[Class]
	if Rand then
		Cooldowns[Passport][Class] = os.time() + math.random(Rand.Min,Rand.Max)
	end

	Data[Selected] = nil

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Remove",function(Passport,Plate)
	local Actived = Active[Passport]
	if not Actived or Actived.Plate ~= Plate then
		return false
	end

	Cooldowns[Passport] = Cooldowns[Passport] or {}

	local Class = Actived.Class
	local Rand = Minimals[Class]
	if Rand then
		Cooldowns[Passport][Class] = os.time() + math.random(Rand.Min,Rand.Max)
	end

	Active[Passport] = nil
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateVehicle(Model,Class,Coords)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return false
	end

	local Vehicle = CreateVehicle(Model,Coords,true,false)

	while not DoesEntityExist(Vehicle) or NetworkGetNetworkIdFromEntity(Vehicle) == 0 do
		Wait(100)
	end

	local State = Entity(Vehicle).state
	local Plate = exports.inventory:GeneratePlate()
	SetVehicleNumberPlateText(Vehicle,Plate)

	Active[Passport] = Active[Passport] or {}
	Active[Passport].Plate = Plate

	State:set("Nitro",2000,true)
	State:set("Fuel",100.0,true)
	State:set("Tower",true,true)
	State:set("Drift",false,true)
	State:set("Seatbelt",false,true)

	TriggerEvent("inventory:Boosting",Plate,{ Amount = 0, Source = source, Passport = Passport, Class = Class })
	TriggerClientEvent("NotifyPush",source,{ code = 31, title = "Informações do Veículo", x = Coords.x, y = Coords.y, z = Coords.z, vehicle = VehicleName(Model).." - "..Plate, color = 44 })

	return NetworkGetNetworkIdFromEntity(Vehicle)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Payment",function(source,Passport)
	if Active[Passport] then
		if Active[Passport].Timer >= os.time() then
			local Class = Active[Passport].Class
			local GainExperience = Active[Passport].Exp
			local Valuation = Active[Passport].Value * 3
			local Total = math.random(Minimals[Class].Min,Minimals[Class].Max)

			local Consult,Members = exports.party:Room(Passport,source,25,2)
			if Consult and Members >= 2 then
				for Number = 1,Members do
					if vRP.Passport(Consult[Number].Source) then
						local OtherPassport = Consult[Number].Passport

						vRP.GenerateItem(OtherPassport,Minimals[Class].Item,1,true)
						vRP.PutExperience(OtherPassport,"Boosting",GainExperience)
						vRP.GenerateItem(OtherPassport,"platinum",Valuation,true)
						Cooldowns[OtherPassport][Class] = os.time() + Total
						vRP.BattlepassPoints(OtherPassport,GainExperience)
						Active[OtherPassport] = nil
					end
				end
			else
				vRP.GenerateItem(Passport,Minimals[Class].Item,1,true)
				vRP.PutExperience(Passport,"Boosting",GainExperience)
				vRP.GenerateItem(Passport,"platinum",Valuation,true)
				Cooldowns[Passport][Class] = os.time() + Total
				vRP.BattlepassPoints(Passport,GainExperience)
			end
		end

		Active[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(passport)
	Pendings[passport] = Pendings[passport] or {}

	if not Cooldowns[passport] then
		Cooldowns[passport] = {}

		for i = 1,6 do
			Cooldowns[passport][i] = os.time()
		end
	end
end)