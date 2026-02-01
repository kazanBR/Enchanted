-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("towed")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Blip = nil
local Destiny = 1
local Vehicle = nil
local Locale = false
local Service = false
local ModelSelected = ""
local VehiclePlate = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSERVERSTART
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Name,v in pairs(Init) do
		exports.target:AddBoxZone("Towed:"..Name,v.xyz,0.75,0.75,{
			name = "Towed:"..Name,
			heading = v.w,
			minZ = v.z - 1.0,
			maxZ = v.z + 1.0
		},{
			shop = Name,
			Distance = 1.75,
			options = {
				{
					event = "towed:Init",
					label = "Iniciar Expediente",
					tunnel = "client"
				}
			}
		})
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOWED:INIT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("towed:Init",function(Data)
	if DoesBlipExist(Blip) then
		RemoveBlip(Blip)
		Blip = nil
	end

	if Service then
		TriggerEvent("Notify","Central de Empregos","Você acaba finalizar sua jornada de trabalho, esperamos que você tenha aprendido bastante hoje.","default",5000)
		exports.target:LabelText("Towed:"..Data,"Iniciar Expediente")
		Service = false
		Locale = false
	else
		Locale = Data
		TriggerEvent("Notify","Central de Empregos","Você acaba de dar inicio a sua jornada de trabalho, lembrando que a sua vida não se resume só a isso.","default",5000)
		exports.target:LabelText("Towed:"..Data,"Finalizar Expediente")
		ModelSelected = Models[math.random(#Models)]
		Destiny = math.random(#Locations[Locale])
		VehiclePlate = nil
		MarkedVehicle()
		Service = true
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TOWED:INATIVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("towed:Inative")
AddEventHandler("towed:Inative",function(Plate)
	if VehiclePlate == Plate then
		ModelSelected = Models[math.random(#Models)]
		Destiny = math.random(#Locations[Locale])
		VehiclePlate = false
		MarkedVehicle()
		Vehicle = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local TimeDistance = 999

		if Service then
			if not Vehicle and Locale and Locations[Locale] and Destiny and Locations[Locale][Destiny] then
				local Ped = PlayerPedId()
				local Coords = GetEntityCoords(Ped)
				if #(Coords - Locations[Locale][Destiny].xyz) <= 50 then
					local Networked,Plate = vSERVER.Vehicle(ModelSelected,Locale,Destiny)
					if not Networked then return end

					local Entity = LoadNetwork(Networked)
					while not DoesEntityExist(Entity) do
						Wait(100)
					end

					if DoesBlipExist(Blip) then
						RemoveBlip(Blip)
						Blip = nil
					end

					Vehicle = Entity
					VehiclePlate = Plate

					SetVehicleHasBeenOwnedByPlayer(Vehicle,true)
					SetVehicleNeedsToBeHotwired(Vehicle,false)
					SetVehicleEngineHealth(Vehicle,10.0)
					SetVehicleOnGroundProperly(Vehicle)
					SetVehRadioStation(Vehicle,"OFF")
				end
			elseif DoesEntityExist(Vehicle) and not Entity(Vehicle).state.Tow then
				TimeDistance = 1

				local OtherCoords = GetEntityCoords(Vehicle)
				DrawMarker(22,OtherCoords.x,OtherCoords.y,OtherCoords.z + 2.5,0.0,0.0,0.0,0.0,180.0,0.0,2.5,2.5,1.5,88,101,242,175,false,false,0,true)
			end
		end

		Wait(TimeDistance)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARKEDPASSENGER
-----------------------------------------------------------------------------------------------------------------------------------------
function MarkedVehicle()
	if DoesBlipExist(Blip) then
		RemoveBlip(Blip)
		Blip = nil
	end

	Blip = AddBlipForCoord(Locations[Locale][Destiny].xyz)
	SetBlipSprite(Blip,1)
	SetBlipDisplay(Blip,4)
	SetBlipAsShortRange(Blip,true)
	SetBlipColour(Blip,77)
	SetBlipScale(Blip,0.75)
	SetBlipRoute(Blip,true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString("Veiculo")
	EndTextCommandSetBlipName(Blip)
end