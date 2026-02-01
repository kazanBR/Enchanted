-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
vSERVER = Tunnel.getInterface("spawn")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Camera = nil
local Characters = {}
local Cooldown = GetGameTimer()
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Config",function(Data,Callback)
	local Pid = PlayerId()
	local Model = 1885233650
	local Ped = PlayerPedId()

	RequestModel(Model)
	while not HasModelLoaded(Model) do
		Wait(100)
	end

	SetPlayerModel(Pid,Model)
	SetModelAsNoLongerNeeded(Model)

	local Ped = PlayerPedId()
	SetEntityCoords(Ped,149.64,-157.97,-24.99,false,false,false,false)
	NetworkSetFriendlyFireOption(false)
	FreezeEntityPosition(Ped,true)
	SetEntityInvincible(Ped,true)
	ClearPedTasksImmediately(Ped)
	SetEntityHeading(Ped,306.15)
	SetEntityVisible(Ped,false)
	SetEntityHealth(Ped,100)
	DisplayRadar(false)
	DoScreenFadeIn(0)

	Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA",true)
	RenderScriptCams(true,false,0,false,false)
	SetCamCoord(Camera,151.6,-156.61,-23.99)
	SetCamRot(Camera,0.0,0.0,125.0,2)
	SetCamActive(Camera,true)

	Characters = vSERVER.Characters()
	if CountTable(Characters) > 0 then
		Customization(Characters[1])
	end

	ShutdownLoadingScreen()
	ShutdownLoadingScreenNui()
	SetNuiFocus(true,true)

	local Config = vSERVER.Config()

	Callback({ Characters = Characters, Gemstone = Config.Gemstone, SlotPrice = SlotPrice, Slots = Config.Slots })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PURCHASESLOT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("PurchaseSlot",function(Data,Callback)
	Callback(vSERVER.PurchaseSlot())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERCHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("CharacterChosen",function(Data,Callback)
	if Cooldown < GetGameTimer() then
		Cooldown = GetGameTimer() + 1000

		if vSERVER.CharacterChosen(Data.Passport) then
			SendNUIMessage({ Action = "Close" })
		end
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- REQUEST
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Request",function(Data,Callback)
	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- NEWCHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("NewCharacter",function(Data,Callback)
	Callback(vSERVER.NewCharacter(Data["Name"],Data["Lastname"],Data["Gender"]))
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SWITCHCHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("SwitchCharacter",function(Data,Callback)
	for _,v in pairs(Characters) do
		if v.Passport == Data.Passport then
			Customization(v,true)

			break
		end
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN:FINISH
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("spawn:Finish")
AddEventHandler("spawn:Finish",function(Coords,Creation)
	local Ped = PlayerPedId()

	if Coords then
		Locate[1] = { Coords = Coords, Name = "Última Localização" }

		for Number,v in pairs(Locate) do
			local Road = GetStreetNameAtCoord(v.Coords.x,v.Coords.y,v.Coords.z)
			Locate[Number].Name = Locate[Number].Name == "" and GetStreetNameFromHashKey(Road) or Locate[Number].Name
		end

		if not Creation then
			SetEntityVisible(Ped,false)
		end

		SetCamCoord(Camera,Locate[1].Coords.x,Locate[1].Coords.y,Locate[1].Coords.z + 1)
		SendNUIMessage({ Action = "Location", Payload = Locate })
		SetCamRot(Camera,0.0,0.0,0.0,2)
	else
		if Creation then
			exports.barbershop:Creation(Creation)
		else
			local Ped = PlayerPedId()
			SetEntityVisible(Ped,false)
			SetEntityInvincible(Ped,true)
			FreezeEntityPosition(Ped,true)
			SetTimeout(5000,function()
				SetEntityVisible(Ped,true)
				SetEntityInvincible(Ped,false)
				FreezeEntityPosition(Ped,false)
			end)
			TriggerEvent("hud:Active",true)
			TriggerServerEvent("vRP:WaitCharacters")
			TriggerEvent("referrals:Open")
		end

		SendNUIMessage({ Action = "Close" })
		SetNuiFocus(false,false)

		if DoesCamExist(Camera) then
			RenderScriptCams(false,false,0,false,false)
			SetCamActive(Camera,false)
			DestroyCam(Camera,false)
			Camera = nil
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Spawn",function(Data,Callback)
	local Ped = PlayerPedId()

	if DoesCamExist(Camera) then
		RenderScriptCams(false,false,0,false,false)
		SetCamActive(Camera,false)
		DestroyCam(Camera,false)
		Camera = nil
	end

	if not LocalPlayer.state.Creation then
		SetEntityVisible(Ped,false)
	end
	
	SetEntityInvincible(Ped,true)
	FreezeEntityPosition(Ped,true)
	SetTimeout(5000,function()
		if not LocalPlayer.state.Creation then
			SetEntityVisible(Ped,true)
		end

		SetEntityInvincible(Ped,false)
		FreezeEntityPosition(Ped,false)
	end)

	SendNUIMessage({ Action = "Close" })
	TriggerEvent("hud:Active",true)
	TriggerEvent("referrals:Open")
	SetNuiFocus(false,false)

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Chosen",function(Data,Callback)
	local Ped = PlayerPedId()
	local Index = Data.Index
	
	SetEntityCoords(Ped,Locate[Index].Coords.x,Locate[Index].Coords.y,Locate[Index].Coords.z - 1)
	SetCamCoord(Camera,Locate[Index].Coords.x,Locate[Index].Coords.y,Locate[Index].Coords.z + 1)
	SetCamRot(Camera,0.0,0.0,0.0,2)

	if not LocalPlayer.state.Creation then
		SetEntityVisible(Ped,false)
	end

	Callback("Ok")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CUSTOMIZATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Customization(Table,Check)
	local Pid = PlayerId()
	local Ped = PlayerPedId()
	local Model = GetHashKey(Table.Skin)

	RequestModel(Model)
	while not HasModelLoaded(Model) do
		Wait(100)
	end

	if not Check or (Check and GetEntityModel(Ped) ~= Model) then
		SetPlayerModel(Pid,Model)
		SetModelAsNoLongerNeeded(Model)
	end

	local Ped = PlayerPedId()
	local Random = math.random(#Anims)
	if LoadAnim(Anims[Random].Dict) then
		TaskPlayAnim(Ped,Anims[Random].Dict,Anims[Random].Name,8.0,8.0,-1,1,1,0,0,0)
	end

	exports.skinshop:Apply(Table.Clothes,Ped)
	exports.barbershop:Apply(Table.Barber,Ped)
	exports.tattooshop:Apply(Table.Tattoos,Ped)

	ClearPedTasksImmediately(Ped)
	SetEntityInvincible(Ped,true)
	SetEntityVisible(Ped,true)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN:INCREMENT
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("spawn:Increment")
AddEventHandler("spawn:Increment",function(Tables)
	for _,v in pairs(Tables) do
		Locate[#Locate + 1] = { ["Coords"] = v, ["Name"] = "" }
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPAWN:NOTIFY
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("spawn:Notify")
AddEventHandler("spawn:Notify",function(Title,Message,Type)
	SendNUIMessage({ Action = "Notify", Payload = { Title = Title, Message = Message, Type = Type } })
end)