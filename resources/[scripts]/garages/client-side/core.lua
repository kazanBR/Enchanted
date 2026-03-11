-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
local vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("garages",Creative)
vSERVER = Tunnel.getInterface("garages")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIAVEIS
-----------------------------------------------------------------------------------------------------------------------------------------
local Respawns = {}
local Opened = false
local Searched = nil
local Hotwired = false
local Spam = GetGameTimer()
local Anim = "machinic_loop_mechandplayer"
local Dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
local R,G,B = HexToRGB(Theme.main)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWNPOSITION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SpawnPosition(Select)
	local Checks = 0
	local Selected,Position

	repeat
		Checks = Checks + 1
		local Slot = tostring(Checks)

		if Garages[Select] and Garages[Select].Spawns[Slot] then
			Selected = vec4(Garages[Select].Spawns[Slot][1],Garages[Select].Spawns[Slot][2],Garages[Select].Spawns[Slot][3],Garages[Select].Spawns[Slot][4])
			Position = GetClosestVehicle(Garages[Select].Spawns[Slot][1],Garages[Select].Spawns[Slot][2],Garages[Select].Spawns[Slot][3],2.75,0,127)
		end
	until not DoesEntityExist(Position) or not Garages[Select].Spawns[tostring(Checks)]

	if not Garages[Select].Spawns[tostring(Checks)] then
		TriggerEvent("Notify","Atenção","Todas as vagas estão ocupadas.","default",5000)

		return false
	end

	SendNUIMessage({ Action = "Close" })
	SetNuiFocus(false,false)
	Opened = false

	return Selected
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateVehicle(Model,Network,Engine,Health,Customize,Windows,Tyres)
	if not NetworkDoesNetworkIdExist(Network) then
		return false
	end

	local Vehicle = NetToEnt(Network)
	if not DoesEntityExist(Vehicle) then
		return false
	end

	SetVehicleEngineHealth(Vehicle,Engine + 0.0)
	SetVehicleHasBeenOwnedByPlayer(Vehicle,true)
	SetEntityAsMissionEntity(Vehicle,true,true)
	SetVehicleNeedsToBeHotwired(Vehicle,false)
	SetEntityCleanupByEngine(Vehicle,true)
	SetVehicleOnGroundProperly(Vehicle)
	SetVehRadioStation(Vehicle,"OFF")
	SetEntityHealth(Vehicle,Health)

	if Windows then
		local DecodedWindows = json.decode(Windows)
		if DecodedWindows then
			for Index,v in pairs(DecodedWindows) do
				if not v then
					RemoveVehicleWindow(Vehicle,tonumber(Index))
				end
			end
		end
	end

	if Tyres then
		local DecodedTyres = json.decode(Tyres)
		if DecodedTyres then
			for Index,Burst in pairs(DecodedTyres) do
				if Burst then
					SetVehicleTyreBurst(Vehicle,tonumber(Index),true,1000.0)
				end
			end
		end
	end

	TriggerEvent("lscustoms:Apply",Vehicle,Customize)
	SetModelAsNoLongerNeeded(Model)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("garages:Delete")
AddEventHandler("garages:Delete",function(Vehicle)
	if not Vehicle or Vehicle == "" then
		Vehicle = vRP.ClosestVehicle(15)
	end

	if IsEntityAVehicle(Vehicle) and (not Entity(Vehicle).state.Tow or LocalPlayer.state.Admin) then
		local Doors = {}
		for Number = 0,5 do
			Doors[Number] = IsVehicleDoorDamaged(Vehicle,Number)
		end

		local Tyres = {}
		for Number = 0,7 do
			Tyres[Number] = (GetTyreHealth(Vehicle,Number) ~= 1000.0 and true or false)
		end

		vSERVER.Delete(NetworkGetNetworkIdFromEntity(Vehicle),Doors,Tyres,GetVehicleNumberPlateText(Vehicle),Opened or "1")
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SEARCHBLIP
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SearchBlip(Coords)
	if DoesBlipExist(Searched) then
		RemoveBlip(Searched)
		Searched = nil
	end

	if type(Coords) == "string" then
		Coords = Garages[Coords].Coords
	end

	if not Coords then
		return false
	end

	Searched = AddBlipForCoord(Coords.x,Coords.y,Coords.z)
	SetBlipSprite(Searched,225)
	SetBlipColour(Searched,77)
	SetBlipScale(Searched,0.6)
	SetBlipAsShortRange(Searched,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Veículo")
	EndTextCommandSetBlipName(Searched)

	SetTimeout(30000,function()
		if DoesBlipExist(Searched) then
			RemoveBlip(Searched)
		end

		Searched = nil
	end)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTHOTWIRED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.StartHotwired()
	local Ped = PlayerPedId()
	if not Hotwired and LoadAnim(Dict) then
		TaskPlayAnim(Ped,Dict,Anim,8.0,8.0,-1,49,1,0,0,0)
		Hotwired = true
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOPHOTWIRED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.StopHotwired()
	local Ped = PlayerPedId()
	if Hotwired and LoadAnim(Dict) then
		StopAnimTask(Ped,Dict,Anim,8.0)
		Hotwired = false
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEHOTWIRED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateHotwired(Status)
	Hotwired = Status
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REGISTERDECORS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RegisterDecors(Vehicle)
	SetVehicleHasBeenOwnedByPlayer(Vehicle,true)
	SetVehicleNeedsToBeHotwired(Vehicle,false)
	SetVehRadioStation(Vehicle,"OFF")
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LOOPHOTWIRED
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 999
		local Ped = PlayerPedId()
		if IsPedInAnyVehicle(Ped) then
			local Vehicle = GetVehiclePedIsUsing(Ped)
			if Vehicle then
				local Plate = GetVehicleNumberPlateText(Vehicle)
				if GetPedInVehicleSeat(Vehicle,-1) == Ped and Plate ~= "PDMSPORT" and not Entity(Vehicle).state.Lockpick then
					SetVehicleEngineOn(Vehicle,false,true,true)
					DisablePlayerFiring(Ped,true)
					TimeDistance = 1
				end

				if Hotwired and Vehicle then
					DisableControlAction(0,75,true)
					DisableControlAction(0,20,true)
					TimeDistance = 1
				end
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADOPEN
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
    while true do
        local TimeDistance = 999
        local Ped = PlayerPedId()
        if not IsPedInAnyVehicle(Ped) then
            local Coords = GetEntityCoords(Ped)

            for Number,v in pairs(Garages) do
                if v.Coords then
                    local Distance = #(Coords - v.Coords)
                    if Distance <= 25.0 then
                        TimeDistance = 1
                        DrawMarker(v.Marker or 36,v.Coords.x,v.Coords.y,v.Coords.z,0,0,0,0,0,0,1.0,1.0,1.0,R,G,B,155,1,1,1,1)
                        DrawMarker(27,v.Coords.x,v.Coords.y,v.Coords.z-0.97,0,0,0,0,0,0,1.0,1.0,0.5,R,G,B,155,0,0,0,1)

                        if Distance <= 1.25 and IsControlJustPressed(1,38) and not exports.hud:Wanted() then
                            if not UseLbPhone or not exports["lb-phone"]:IsOpen() then
                                local Vehicles = vSERVER.Vehicles(Number)
                                if Vehicles then
                                    Opened = Number
                                    SetNuiFocus(true,true)
                                    TriggerEvent("target:Debug")
                                    SendNUIMessage({ Action = "Open", Payload = Vehicles })
                                end
                            end
                        end
                    elseif Opened and Opened == Number then
                        TriggerEvent("garages:Close")
                    end
                end
            end

            for Plate,v in pairs(Respawns) do
                if v then
                    local Distance = #(Coords - (v.xyz or v))
                    if Distance <= 25.0 then
                        TimeDistance = 1
                        DrawMarker(36,v.x,v.y,v.z,0.0,0.0,0.0,0.0,0.0,0.0,1.75,1.75,1.75,R,G,B,175,0,0,0,1)

                        if Distance <= 1.25 and IsControlJustPressed(1,38) and Spam <= GetGameTimer() then
                            Spam = GetGameTimer() + 5000
                            TriggerServerEvent("garages:Respawns",Plate)
                        end
                    end
                end
            end
        end
        Wait(TimeDistance)
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Spawn",function(Data,Callback)
	TriggerServerEvent("garages:Spawn",Data.Model,Opened)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DELETE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Delete",function(Data,Callback)
	TriggerEvent("garages:Delete")

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAX
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Tax",function(Data,Callback)
	TriggerServerEvent("garages:Tax",Data.Model)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SELL
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Sell",function(Data,Callback)
	TriggerServerEvent("garages:Sell",Data.Model)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Transfer",function(Data,Callback)
	TriggerServerEvent("garages:Transfer",Data.Model)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Close",function(Data,Callback)
	SetNuiFocus(false,false)
	Opened = false

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("garages:Close")
AddEventHandler("garages:Close",function()
	SendNUIMessage({ Action = "Close" })
	SetNuiFocus(false,false)
	Opened = false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:PROPERTYS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("garages:Propertys")
AddEventHandler("garages:Propertys",function(GaragesTable,RespawnsTable)
	for Name,v in pairs(GaragesTable) do
		Garages[Name] = v
	end

	if RespawnsTable then
		Respawns = RespawnsTable
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:CLEAN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("garages:Clean")
AddEventHandler("garages:Clean",function(Name)
	if Garages[Name] then
		Garages[Name] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GARAGES:CLOSE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("garages:Respawn")
AddEventHandler("garages:Respawn",function(Mode,Plate,Coords)
	if Mode == "Add" then
		Respawns[Plate] = Coords
	elseif Mode == "Remove" then
		Respawns[Plate] = nil
	end
end)