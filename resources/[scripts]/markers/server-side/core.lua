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
Tunnel.bindInterface("markers",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Timers = {}
local Players = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- USERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Users()
    local Markers = {}

    for Source,v in pairs(Players) do
        local playerTimer = Timers[v.Passport]
        if playerTimer and not playerTimer.Stop and os.time() >= playerTimer.Timer then
            exports.markers:Exit(Source,v.Passport)
        else
            local Ped = GetPlayerPed(Source)
            if DoesEntityExist(Ped) then
                Markers[Source] = {
                    Vehicle = GetVehiclePedIsIn(Ped),
                    Coords = GetEntityCoords(Ped),
                    Permission = v.Permission,
                    Level = v.Level
                }
            end
        end
    end

    return Markers
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTER
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Enter",function(source,Permission,Level,Passport,Timed)
	if not Players[source] then
		Players[source] = {
			Passport = Passport,
			Permission = Permission,
			Level = vRP.NameHierarchy(Permission,Level)
		}

		if Timed then
			Timers[Passport] = {
				Permission = Permission,
				Timer = os.time() + Timed,
				Level = Level or 1,
				Stop = false
			}
		end

		local Service = vRP.NumPermission("Policia")
		for _,Sources in pairs(Service) do
			TriggerClientEvent("markers:Add",Sources,source,Players[source])
		end

		TriggerClientEvent("markers:Full",source,Players)
	else
		local Data = Timers[Passport]
		if Timed and Data then
			local CurrentTimer = os.time()
			if CurrentTimer > Data.Timer then
				Data.Timer = CurrentTimer + Timed
			else
				Data.Timer = Data.Timer + Timed
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXIT
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Exit",function(source,Passport)
	if Players[source] then
		Players[source] = nil

		local Service = vRP.NumPermission("Policia")
		for _,Sources in pairs(Service) do
			TriggerClientEvent("markers:Remove",Sources,source)
		end
	end

	local Data = Timers[Passport]
	if Data then
		local CurrentTimer = os.time()
		if Data.Timer > CurrentTimer then
			Data.Stop = true
			Data.Timer = Data.Timer - CurrentTimer
		else
			Timers[Passport] = nil
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	exports.markers:Exit(source,Passport)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	local Data = Timers[Passport]
	if Data then
		exports.markers:Enter(source,Data.Permission,Data.Level,Passport,Data.Timer)
	end
end)