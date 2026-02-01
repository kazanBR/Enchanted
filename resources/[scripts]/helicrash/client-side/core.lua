-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("helicrash")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Fire = {}
local Blip = nil
local Alpha = nil
local Objects = {}
local Active = false
local InsideMarked = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATECRASHOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function CreateCrashObject(Model,Coords,Heading)
	local Object = CreateObjectNoOffset(Model,Coords.xyz,false,false,false)
	SetEntityLodDist(Object,0xFFFF)
	FreezeEntityPosition(Object,true)
	PlaceObjectOnGroundProperly(Object)
	SetEntityHeading(Object,Heading)

	return Object
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVECRASHOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
function RemoveCrashObjects()
	for Index,Entitys in pairs(Objects) do
		if Index ~= "Helicopter" then
			exports.target:RemCircleZone("Helicrash:"..Index)
		end

		if DoesEntityExist(Entitys) then
			DeleteEntity(Entitys)
		end

		if Fire[Index] then
			RemoveScriptFire(Fire[Index])
			Fire[Index] = nil
		end

		Objects[Index] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SETUPTARGETZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function SetupTargetZone(Index,Coords,Heading)
	exports.target:AddBoxZone("Helicrash:"..Index,Coords.xyz,1.25,2.25,{
		name = "Helicrash:"..Index,
		maxZ = Coords.z + 1.0,
		heading = Heading,
		minZ = Coords.z
	},{
		shop = "Helicrash:"..Index,
		Distance = 2.0,
		options = {
			{
				event = "chest:Open",
				label = "Abrir",
				tunnel = "client",
				service = "Custom"
			}
		}
	})
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEBLIP
-----------------------------------------------------------------------------------------------------------------------------------------
function UpdateBlip()
	if DoesBlipExist(Blip) then
		RemoveBlip(Blip)
		Blip = nil
	end

	if DoesBlipExist(Alpha) then
		RemoveBlip(Alpha)
		Alpha = nil
	end

	if Active and Components[Active] then
		Blip = AddBlipForCoord(Components[Active].Center.xyz)
		SetBlipSprite(Blip,43)
		SetBlipDisplay(Blip,4)
		SetBlipAsShortRange(Blip,true)
		SetBlipColour(Blip,49)
		SetBlipScale(Blip,1.0)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Helicrash")
		EndTextCommandSetBlipName(Blip)

		Alpha = AddBlipForRadius(Components[Active].Center.xyz,Components[Active].Survival)
		SetBlipColour(Alpha,49)
		SetBlipAlpha(Alpha,150)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	LoadModel("prop_crashed_heli")
	LoadModel("m23_1_prop_m31_crate_cd_01a")

	if GlobalState.Helicrash then
		Active = GlobalState.Helicrash
		UpdateBlip()
	end

	while true do
		local TimeDistance = 9999
		if Active and Components[Active] then
			local Ped = PlayerPedId()
			local Select = Components[Active]
			local Coords = GetEntityCoords(Ped)

			if #(Coords - Select.Center.xyz) <= Select.Survival then
				if not InsideMarked then
					InsideMarked = true
					vSERVER.Progress("Enter")
				end

				if not Objects.Helicopter then
					Objects.Helicopter = CreateCrashObject("prop_crashed_heli",Select.Center)
				end

				for Index,OtherCoords in pairs(Select.Coords) do
					if not Objects[Index] then
						Objects[Index] = CreateCrashObject("m23_1_prop_m31_crate_cd_01a",OtherCoords,OtherCoords.w)
						SetupTargetZone(Index,OtherCoords,OtherCoords.w)

						if GlobalState.Work <= GlobalState.Helifire then
							Fire[Index] = StartScriptFire(OtherCoords.xyz,20,false)
						end
					else
						if Fire[Index] and #(Coords - OtherCoords.xyz) <= 5 then
							ApplyDamageToPed(Ped,5,false)
						end

						if Fire[Index] and GlobalState.Work > GlobalState.Helifire then
							RemoveScriptFire(Fire[Index])
							Fire[Index] = nil
						end

						TimeDistance = 2500
					end
				end

				if GetEntityHealth(Ped) <= 100 then
					TriggerServerEvent("player:Survival")
					exports.survival:FinishSurvival()
				end
			else
				if Objects.Helicopter then
					RemoveCrashObjects()
				end

				if InsideMarked then
					InsideMarked = false
					vSERVER.Progress("Exit")
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Helicrash",nil,function(_,_,Value)
	Active = Value
	UpdateBlip()

	if Objects.Helicopter then
		RemoveCrashObjects()
	end

	if InsideMarked then
		InsideMarked = false
		vSERVER.Progress("Exit")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GAMEEVENTTRIGGERED
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("gameEventTriggered",function(Event,Message)
	if Event ~= "CEventNetworkEntityDamage" or not InsideMarked or LocalPlayer.state.Arena or LocalPlayer.state.Death then
		return false
	end

	local Victim = Message[1]
	local Attacker = Message[2]
	if Victim ~= PlayerPedId() or Victim == Attacker or not IsEntityAPed(Victim) or GetEntityHealth(Victim) > 100 then
		return false
	end

	local CurrentTimer = GetGameTimer()
	local Index = NetworkGetPlayerIndexFromPed(Attacker)
	if Index and NetworkIsPlayerConnected(Index) and FeedCooldown < CurrentTimer then
		FeedCooldown = CurrentTimer + 1000
		vSERVER.KillFeed(GetPlayerServerId(Index))
	end
end)