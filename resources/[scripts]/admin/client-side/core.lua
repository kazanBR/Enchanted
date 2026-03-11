-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRP = Proxy.getInterface("vRP")
local GarageSpawnVehicles = {}
local BedPreviewPeds = {}
local CurrentRotationObject = nil
local R,G,B = HexToRGB(Theme.main)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
Creative = {}
Tunnel.bindInterface("admin",Creative)
vSERVER = Tunnel.getInterface("admin")
-----------------------------------------------------------------------------------------------------------------------------------------
-- TELEPORTWAY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.teleportWay()
	local Ped = PlayerPedId()
	if IsPedInAnyVehicle(Ped) then
		Ped = GetVehiclePedIsUsing(Ped)
	end

	local Waypoint = GetFirstBlipInfoId(8)
	if not DoesBlipExist(Waypoint) then
		return false
	end

	local Coords = GetBlipCoords(Waypoint)
	for Height = 1,1000 do
		SetEntityCoordsNoOffset(Ped,Coords.x,Coords.y,Height + 0.0,true,false,false)

		RequestCollisionAtCoord(Coords.x,Coords.y,Coords.z)
		while not HasCollisionLoadedAroundEntity(Ped) do
			Wait(1)
		end

		local Found,GroundZ = GetGroundZFor_3dCoord(Coords.x,Coords.y,Height + 0.0)
		if Found then
			SetEntityCoordsNoOffset(Ped,Coords.x,Coords.y,GroundZ + 1.0,true,false,false)
			break
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:TUNING
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:Tuning",function()
	local Ped = PlayerPedId()
	if not IsPedInAnyVehicle(Ped) then
		return false
	end

	local Vehicle = GetVehiclePedIsUsing(Ped)

	SetVehicleModKit(Vehicle,0)
	ToggleVehicleMod(Vehicle,18,true)

	for _,Mod in ipairs({ 11,12,13,15 }) do
		SetVehicleMod(Vehicle,Mod,GetNumVehicleMods(Vehicle,Mod) - 1,false)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BUTTONCOORDS
-----------------------------------------------------------------------------------------------------------------------------------------
-- CreateThread(function()
-- 	while true do
-- 		if IsControlJustPressed(1,38) then
-- 			vSERVER.buttonTxt()
-- 		end
-- 		Wait(1)
-- 	end
-- end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Markers = {}
local DefaultLeft = 2.0
local ConfigRace = false
local DefaultRight = -2.0
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIGRACE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("configrace",function(_,Message)
	if not LocalPlayer.state.Admin then
		return false
	end

	for _,v in pairs(Markers) do
		if DoesBlipExist(v.Blip) then
			RemoveBlip(v.Blip)
		end
	end

	local RaceName = Message[1] or "nulled"
	DefaultLeft, DefaultRight = 2.0, -2.0
	ConfigRace = not ConfigRace
	Markers = {}

	while ConfigRace do
		Wait(1)

		local Ped = PlayerPedId()
		local Vehicle = GetVehiclePedIsUsing(Ped)
		if not Vehicle or not DoesEntityExist(Vehicle) then
			ConfigRace = false
			break
		end

		local Center = GetOffsetFromEntityInWorldCoords(Vehicle,0.0,5.0,0.0)
		local Left = GetOffsetFromEntityInWorldCoords(Vehicle,DefaultLeft,5.0,0.0)
		local Right = GetOffsetFromEntityInWorldCoords(Vehicle,DefaultRight,5.0,0.0)

		if IsDisabledControlPressed(1,10) then
			DefaultLeft += 0.1
			DefaultRight -= 0.1
		elseif IsDisabledControlPressed(1,11) then
			DefaultLeft -= 0.1
			DefaultRight += 0.1
		end

		DefaultLeft = math.max(DefaultLeft,2.0)
		DefaultRight = math.min(DefaultRight,-2.0)

		if IsControlJustPressed(1,38) then
			local Number = #Markers + 1
			vSERVER.RaceConfig(Left,Center,Right,DefaultLeft * 0.8,RaceName)

			local Blip = AddBlipForCoord(Center.x,Center.y,Center.z)
			SetBlipSprite(Blip,1)
			SetBlipColour(Blip,2)
			SetBlipScale(Blip,0.85)
			ShowNumberOnBlip(Blip,Number)
			SetBlipAsShortRange(Blip,true)

			Markers[Number] = { Left = Left, Right = Right, Blip = Blip }
		end

		DrawMarker(1,Left.x,Left.y,Left.z - 100,0,0,0,0,0,0,1.75,1.75,200.0,88,101,242,175,false,false,0,false)
		DrawMarker(1,Right.x,Right.y,Right.z - 100,0,0,0,0,0,0,1.75,1.75,200.0,88,101,242,175,false,false,0,false)
		DrawMarker(1,Center.x,Center.y,Center.z - 100,0,0,0,0,0,0,0.75,0.75,200.0,255,255,255,25,false,false,0,false)

		for _,v in pairs(Markers) do
			DrawMarker(1,v.Left.x,v.Left.y,v.Left.z - 100,0,0,0,0,0,0,1.75,1.75,200.0,0,255,0,100,false,false,0,false)
			DrawMarker(1,v.Right.x,v.Right.y,v.Right.z - 100,0,0,0,0,0,0,1.75,1.75,200.0,0,255,0,100,false,false,0,false)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:INITSPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:initSpectate",function(OtherSource)
	if NetworkIsInSpectatorMode() then
		return false
	end

	local TargetPlayer = GetPlayerFromServerId(OtherSource)
	if TargetPlayer == -1 then
		return false
	end

	local TargetPed = GetPlayerPed(TargetPlayer)
	LocalPlayer.state:set("Spectate",true,false)
	NetworkSetInSpectatorMode(true,TargetPed)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:RESETSPECTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:resetSpectate",function()
	if not NetworkIsInSpectatorMode() then
		return false
	end

	NetworkSetInSpectatorMode(false)
	LocalPlayer.state:set("Spectate",false,false)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Quake",nil,function(Name,Key,Value)
	ShakeGameplayCam("SKY_DIVING_SHAKE",1.0)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- LIMPAREA
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Limparea(Coords)
	local Radius = 100.0
	local x,y,z = Coords.x,Coords.y,Coords.z

	ClearAreaOfPeds(x,y,z,Radius,0)
	ClearAreaOfCops(x,y,z,Radius,0)
	ClearAreaOfObjects(x,y,z,Radius,0)
	ClearAreaOfProjectiles(x,y,z,Radius,0)
	ClearArea(x,y,z,Radius,true,false,false,false)
	ClearAreaOfVehicles(x,y,z,Radius,false,false,false,false,false)
	ClearAreaLeaveVehicleHealth(x,y,z,Radius,false,false,false,false)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADMIN:GARAGEBUTTONS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("admin:GarageButtons")
AddEventHandler("admin:GarageButtons",function(HasSpawns)
	local ButtonText = HasSpawns and "Finalizar" or "Cancelar"
	
	local GarageButtons = {
		{ "F", ButtonText },
		{ "H","Posicionar" },
		{ "Q","Rotacionar Esquerda" },
		{ "E","Rotacionar Direita" },
		{ "R","Definir Rotação" },
		{ "Z","Trocar Modo" }
	}
	
	SetTimeout(100,function()
		TriggerEvent("inventory:Buttons",GarageButtons)
	end)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- POSITIONGARAGESPAWN
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PositionGarageSpawn(Model)
	CurrentRotationObject = nil
	
	if not LoadModel(Model) then
		return false,nil
	end
	
	local Progress = true
	local Aplication = false
	local Switch = false
	local DesiredHeading = GetEntityHeading(PlayerPedId())
	local Ped = PlayerPedId()
	local Heading = GetEntityHeading(Ped)
	local Coords = GetOffsetFromEntityInWorldCoords(Ped,0.0,5.0,0.0)
	local NextObject = CreateObjectNoOffset(Model,Coords.x,Coords.y,Coords.z,false,false,false)
	
	SetEntityAlpha(NextObject,200,false)
	PlaceObjectOnGroundProperly(NextObject)
	SetEntityCollision(NextObject,false,false)
	SetEntityHeading(NextObject,Heading)
	DesiredHeading = Heading
	
	CurrentRotationObject = NextObject
	
	local DefaultButtons = {
		{ "F", "Cancelar" },
		{ "H", "Posicionar" },
		{ "Q", "Rotacionar Esquerda" },
		{ "E", "Rotacionar Direita" },
		{ "R", "Definir Rotação" },
		{ "Z", "Trocar Modo" }
	}
	
	local ExtendedButtons = {
		{ "F", "Cancelar" },
		{ "H", "Posicionar" },
		{ "Q", "Rotacionar Esquerda" },
		{ "E", "Rotacionar Direita" },
		{ "R", "Definir Rotação" },
		{ "-", "Descer" },
		{ "+", "Subir" },
		{ "↑", "Movimentar para Frente" },
		{ "←", "Movimentar para Esquerda" },
		{ "↓", "Movimentar para Baixo" },
		{ "→", "Movimentar para Direita" },
		{ "Z", "Trocar Modo" }
	}
	
	TriggerEvent("inventory:Buttons",DefaultButtons)
	
	while Progress do
		local controlPressed = GetMovementControls(NextObject)
		if controlPressed and Switch then
			MoveObject(NextObject,controlPressed)
		end
		
		RotateObject(NextObject)
		DrawGraphOutline(NextObject)
		
		if not Switch then
			local Cam = GetGameplayCamCoord()
			local Rotation = GetGameplayCamRot()
			local Pitch = math.rad(Rotation.x)
			local Roll = math.rad(Rotation.z)
			
			local Direction = vec3( -math.sin(Roll) * math.abs(math.cos(Pitch)), math.cos(Roll) * math.abs(math.cos(Pitch)), math.sin(Pitch) )
			
			local TargetCoords = vec3( Cam.x + Direction.x * 10.0, Cam.y + Direction.y * 10.0, Cam.z + Direction.z * 10.0 )
			
			local Handle = StartExpensiveSynchronousShapeTestLosProbe(Cam.x,Cam.y,Cam.z,TargetCoords.x,TargetCoords.y,TargetCoords.z,-1,Ped,4)
			local _,_,HitCoords = GetShapeTestResult(Handle)
			
			local CurrentCoords = GetEntityCoords(NextObject)
			local CurrentHeading = GetEntityHeading(NextObject)
			
			SetEntityCoordsNoOffset(NextObject,HitCoords.x,HitCoords.y,HitCoords.z,false,false,false)
			SetEntityHeading(NextObject,DesiredHeading)
		else
			SetEntityHeading(NextObject,DesiredHeading)
		end
		
		if IsControlJustPressed(0,48) then
			Switch = not Switch
			TriggerEvent("inventory:Buttons",Switch and ExtendedButtons or DefaultButtons)
		elseif IsControlPressed(1,44) then
			DesiredHeading = DesiredHeading - 0.5
			if DesiredHeading < 0 then
				DesiredHeading = DesiredHeading + 360
			end
			SetEntityHeading(NextObject,DesiredHeading)
		elseif IsControlPressed(1,38) then
			DesiredHeading = DesiredHeading + 0.5
			if DesiredHeading >= 360 then
				DesiredHeading = DesiredHeading - 360
			end
			SetEntityHeading(NextObject,DesiredHeading)
		elseif IsControlJustPressed(0,140) then
			local CurrentHeading = GetEntityHeading(NextObject)
			local Keyboard = exports.keyboard:Keyboard({
				{ Mode = "text", Placeholder = "Rotação (-360 a 360)", Value = tostring(math.floor(CurrentHeading)) }
			},"Definir Rotação","Digite o valor da rotação")
			
			if Keyboard and Keyboard[1] then
				local Rotation = tonumber(Keyboard[1])
				if Rotation then
					local FinalRotation = Rotation
					
					if FinalRotation < 0 then
						FinalRotation = FinalRotation + 360
					end
					
					if FinalRotation >= 360 then
						FinalRotation = FinalRotation % 360
					end
					
					if FinalRotation < 0 then
						FinalRotation = 0
					end
					
					if FinalRotation >= 360 then
						FinalRotation = 359.99
					end
					
					DesiredHeading = FinalRotation
					SetEntityHeading(NextObject,DesiredHeading)
				end
			end
		elseif IsControlJustPressed(1,74) then
			TriggerEvent("inventory:CloseButtons")
			Aplication = true
			Progress = false
		elseif IsControlJustPressed(0,49) then
			TriggerEvent("inventory:CloseButtons")
			Aplication = false
			Progress = false
		end
		
		Wait(1)
	end
	
	CurrentRotationObject = nil
	
	local OtherCoords = nil
	if DoesEntityExist(NextObject) then
		local oCoords = GetEntityCoords(NextObject)
		local oHeading = GetEntityHeading(NextObject)
		OtherCoords = { oCoords.x,oCoords.y,oCoords.z,oHeading }
		DeleteEntity(NextObject)
	end
	
	if Aplication and OtherCoords then
		local Hash = GetHashKey(Model)
		
		RequestModel(Hash)
		while not HasModelLoaded(Hash) do
			Wait(10)
		end
		
		local Vehicle = CreateVehicle(Hash,OtherCoords[1],OtherCoords[2],OtherCoords[3],OtherCoords[4],false,false)
		SetVehicleNumberPlateText(Vehicle,"PDMSPORT")
		SetEntityAlpha(Vehicle,150,false)
		SetEntityCollision(Vehicle,false,false)
		FreezeEntityPosition(Vehicle,true)
		SetVehicleDoorsLocked(Vehicle,2)
		SetEntityAsMissionEntity(Vehicle,true,true)
		SetEntityCanBeDamaged(Vehicle,false)
		SetEntityInvincible(Vehicle,true)
		SetBlockingOfNonTemporaryEvents(Vehicle,true)
		
		table.insert(GarageSpawnVehicles,Vehicle)
		
		SetModelAsNoLongerNeeded(Hash)
		
		return true,OtherCoords
	end
	
	return false,nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARGARAGESPAWNS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ClearGarageSpawns()
	for _,Vehicle in pairs(GarageSpawnVehicles) do
		if DoesEntityExist(Vehicle) then
			DeleteEntity(Vehicle)
		end
	end
	GarageSpawnVehicles = {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CLEARBEDPREVIEWS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.ClearBedPreviews()
	for _,ped in pairs(BedPreviewPeds) do
		if DoesEntityExist(ped) then
			SetEntityAsMissionEntity(ped,false,false)
			DeleteEntity(ped)
		end
	end
	BedPreviewPeds = {}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMOVEMENTCONTROLS
-----------------------------------------------------------------------------------------------------------------------------------------
function GetMovementControls(NextObject)
	local Controls = false
	if IsControlPressed(1,249) or IsDisabledControlPressed(1,249) then
		Controls = {}
		Controls.zMoveUp = true
	elseif IsControlPressed(1,244) or IsDisabledControlPressed(1,244) then
		Controls = {}
		Controls.zMoveDown = true
	end
	if IsDisabledControlPressed(1,172) then
		Controls = Controls or {}
		Controls.xMoveRight = true
	elseif IsDisabledControlPressed(1,173) then
		Controls = Controls or {}
		Controls.xMoveLeft = true
	end
	if IsDisabledControlPressed(1,174) then
		Controls = Controls or {}
		Controls.yMoveBackward = true
	elseif IsDisabledControlPressed(1,175) then
		Controls = Controls or {}
		Controls.yMoveForward = true
	end
	return Controls
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MOVEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function MoveObject(NextObject,controls)
	local Coords = GetEntityCoords(NextObject)

	if controls.zMoveUp then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.0,0.0,0.005)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	elseif controls.zMoveDown then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.0,0.0,-0.005)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	end
	if controls.xMoveRight then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.0,0.005,0.0)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	elseif controls.xMoveLeft then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.0,-0.005,0.0)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	end
	if controls.yMoveBackward then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,-0.005,0.0,0.0)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	elseif controls.yMoveForward then
		Coords = GetOffsetFromEntityInWorldCoords(NextObject,0.005,0.0,0.0)
		SetEntityCoordsNoOffset(NextObject,Coords.x,Coords.y,Coords.z,false,false,false)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROTATEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function RotateObject(NextObject)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DRAWGRAPHOUTLINE
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawGraphOutline(Object)
	local Coords = GetEntityCoords(Object)

	local offsetX = GetOffsetFromEntityInWorldCoords(Object,2.0,0.0,0.0)
	local offsetY = GetOffsetFromEntityInWorldCoords(Object,0.0,2.0,0.0)
	local offsetZ = GetOffsetFromEntityInWorldCoords(Object,0.0,0.0,2.0)

	local x1,x2 = Coords.x - offsetX.x,Coords.x + offsetX.x
	local y1,y2 = Coords.y - offsetY.y,Coords.y + offsetY.y
	local z1,z2 = Coords.z - offsetZ.z,Coords.z + offsetZ.z

	DrawLine(x1,Coords.y,Coords.z,x2,Coords.y,Coords.z,255,0,0,255)
	DrawLine(Coords.x,y1,Coords.z,Coords.x,y2,Coords.z,0,0,255,255)
	DrawLine(Coords.x,Coords.y,z1,Coords.x,Coords.y,z2,0,255,0,255)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- POSITIONBED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PositionBed()
	local PreviewPed = nil
	
	local function CleanupPreview()
		if PreviewPed and DoesEntityExist(PreviewPed) then
			SetEntityAsMissionEntity(PreviewPed,false,false)
			DeleteEntity(PreviewPed)
			PreviewPed = nil
		end
	end
	
	local PED_MODEL = "s_m_m_doctor_01"
	local PED_MODEL_HASH = GetHashKey(PED_MODEL)
	
	if not LoadModel(PED_MODEL) then
		return false,nil
	end
	
	local Progress = true
	local Aplication = false
	local Ped = PlayerPedId()
	local Heading = GetEntityHeading(Ped)
	local Coords = GetOffsetFromEntityInWorldCoords(Ped,0.0,5.0,0.0)
	
	local DesiredHeading = Heading
	local DefaultButtons = {
		{ "F", "Cancelar" },
		{ "H", "Posicionar" },
		{ "Q", "Rotacionar Esquerda" },
		{ "E", "Rotacionar Direita" },
		{ "R", "Definir Rotação" },
		{ "Z", "Trocar Modo" }
	}
	
	local ExtendedButtons = {
		{ "F", "Cancelar" },
		{ "H", "Posicionar" },
		{ "Q", "Rotacionar Esquerda" },
		{ "E", "Rotacionar Direita" },
		{ "R", "Definir Rotação" },
		{ "M", "Descer" },
		{ "N", "Subir" },
		{ "↑", "Movimentar para Frente" },
		{ "←", "Movimentar para Esquerda" },
		{ "↓", "Movimentar para Baixo" },
		{ "→", "Movimentar para Direita" },
		{ "Z", "Trocar Modo" }
	}
	
	TriggerEvent("inventory:Buttons",DefaultButtons)
	
	local Switch = false
	
	while Progress do
		local LineCenter = Coords
		local LineZ = LineCenter.z
		
		local radHeading = math.rad(DesiredHeading)
		local cosH = math.cos(radHeading)
		local sinH = math.sin(radHeading)
		
		local offsetXPos = vec3(LineCenter.x + 2.0 * cosH, LineCenter.y + 2.0 * sinH, LineZ - 0.5)
		local offsetXNeg = vec3(LineCenter.x - 2.0 * cosH, LineCenter.y - 2.0 * sinH, LineZ - 0.5)
		
		local offsetYPos = vec3(LineCenter.x - 2.0 * sinH, LineCenter.y + 2.0 * cosH, LineZ - 0.5)
		local offsetYNeg = vec3(LineCenter.x + 2.0 * sinH, LineCenter.y - 2.0 * cosH, LineZ - 0.5)
		
		local offsetZPos = vec3(LineCenter.x, LineCenter.y, LineZ + 0.1)
		local offsetZNeg = vec3(LineCenter.x, LineCenter.y, LineZ - 0.5)
		
		DrawLine(offsetXNeg.x, offsetXNeg.y, offsetXNeg.z, offsetXPos.x, offsetXPos.y, offsetXPos.z, 255, 0, 0, 255)
		DrawLine(offsetYNeg.x, offsetYNeg.y, offsetYNeg.z, offsetYPos.x, offsetYPos.y, offsetYPos.z, 0, 0, 255, 255)
		DrawLine(offsetZNeg.x, offsetZNeg.y, offsetZNeg.z, offsetZPos.x, offsetZPos.y, offsetZPos.z, 0, 255, 0, 255)

		if not PreviewPed or not DoesEntityExist(PreviewPed) then

			local PedZ = LineCenter.z + 0.5
			
			if HasModelLoaded(PED_MODEL_HASH) then
				PreviewPed = CreatePed(26,PED_MODEL,LineCenter.x,LineCenter.y,PedZ,DesiredHeading,false,false)
				
				if DoesEntityExist(PreviewPed) then
					SetEntityInvincible(PreviewPed,true)
					FreezeEntityPosition(PreviewPed,true)
					SetEntityCollision(PreviewPed,false,false)
					ResetEntityAlpha(PreviewPed)
					SetEntityAlpha(PreviewPed,150,false)
					SetBlockingOfNonTemporaryEvents(PreviewPed,true)
					SetEntityAsMissionEntity(PreviewPed,true,true)
					SetPedCanRagdoll(PreviewPed,false)
					SetPedFleeAttributes(PreviewPed,0,0)
					SetPedCombatAttributes(PreviewPed,46,true)
					
					local AnimDict = "amb@world_human_sunbathe@female@back@idle_a"
					local AnimName = "idle_a"
					
					if LoadAnim(AnimDict) then
						TaskPlayAnim(PreviewPed,AnimDict,AnimName,8.0,8.0,-1,1,0,0,0,0)
					end
					
					table.insert(BedPreviewPeds,PreviewPed)
				end
			else
				if LoadModel(PED_MODEL) then
					Wait(100)
				end
			end
		else
			local PedZ = LineCenter.z + 0.5
			SetEntityCoordsNoOffset(PreviewPed,LineCenter.x,LineCenter.y,PedZ,false,false,false)
			SetEntityHeading(PreviewPed,DesiredHeading)
			SetEntityAlpha(PreviewPed,150,false)
		end
		
		local controlPressed = GetMovementControls(nil)
		if controlPressed and Switch then
			local radH = math.rad(DesiredHeading)
			local cosH = math.cos(radH)
			local sinH = math.sin(radH)
			
			if controlPressed.zMoveUp then
				Coords = vec3(Coords.x, Coords.y, Coords.z + 0.005)
			elseif controlPressed.zMoveDown then
				Coords = vec3(Coords.x, Coords.y, Coords.z - 0.005)
			end
			
			if controlPressed.xMoveRight then
				Coords = vec3(Coords.x + 0.005 * cosH, Coords.y + 0.005 * sinH, Coords.z)
			elseif controlPressed.xMoveLeft then
				Coords = vec3(Coords.x - 0.005 * cosH, Coords.y - 0.005 * sinH, Coords.z)
			end
			
			if controlPressed.yMoveBackward then
				Coords = vec3(Coords.x - 0.005 * sinH, Coords.y + 0.005 * cosH, Coords.z)
			elseif controlPressed.yMoveForward then
				Coords = vec3(Coords.x + 0.005 * sinH, Coords.y - 0.005 * cosH, Coords.z)
			end
		end
		
		if not Switch then
			local Cam = GetGameplayCamCoord()
			local Rotation = GetGameplayCamRot()
			local Pitch = math.rad(Rotation.x)
			local Roll = math.rad(Rotation.z)
			
			local Direction = vec3( -math.sin(Roll) * math.abs(math.cos(Pitch)), math.cos(Roll) * math.abs(math.cos(Pitch)), math.sin(Pitch) )
			
			local TargetCoords = vec3( Cam.x + Direction.x * 10.0, Cam.y + Direction.y * 10.0, Cam.z + Direction.z * 10.0 )
			
			local Handle = StartExpensiveSynchronousShapeTestLosProbe(Cam.x,Cam.y,Cam.z,TargetCoords.x,TargetCoords.y,TargetCoords.z,-1,Ped,4)
			local _,_,HitCoords = GetShapeTestResult(Handle)
			
			if HitCoords then
				Coords = HitCoords
			end
		end
		
		if IsControlJustPressed(0,48) then
			Switch = not Switch
			TriggerEvent("inventory:Buttons",Switch and ExtendedButtons or DefaultButtons)
		elseif IsControlPressed(1,44) then
			DesiredHeading = DesiredHeading - 0.5
			if DesiredHeading < 0 then
				DesiredHeading = DesiredHeading + 360
			end
		elseif IsControlPressed(1,38) then
			DesiredHeading = DesiredHeading + 0.5
			if DesiredHeading >= 360 then
				DesiredHeading = DesiredHeading - 360
			end
		elseif IsControlJustPressed(0,140) then
			local Keyboard = exports.keyboard:Keyboard({
				{ Mode = "text", Placeholder = "Rotação (-360 a 360)", Value = tostring(math.floor(DesiredHeading)) }
			},"Definir Rotação","Digite o valor da rotação")
			
			if Keyboard and Keyboard[1] then
				local Rotation = tonumber(Keyboard[1])
				if Rotation then
					local FinalRotation = Rotation
					
					if FinalRotation < 0 then
						FinalRotation = FinalRotation + 360
					end
					
					if FinalRotation >= 360 then
						FinalRotation = FinalRotation % 360
					end
					
					if FinalRotation < 0 then
						FinalRotation = 0
					end
					
					if FinalRotation >= 360 then
						FinalRotation = 359.99
					end
					
					DesiredHeading = FinalRotation
				end
			end
		elseif IsControlJustPressed(1,74) then
			TriggerEvent("inventory:CloseButtons")
			Aplication = true
			Progress = false
		elseif IsControlJustPressed(0,49) then
			TriggerEvent("inventory:CloseButtons")
			Aplication = false
			Progress = false
		end
		
		Wait(1)
	end
	
	local BedCoords = nil
	if Aplication then
		local BedZ = Coords.z - 0.5
		BedCoords = { Coords.x,Coords.y,BedZ,DesiredHeading,0.0 }
		return true,BedCoords
	end
	
	CleanupPreview()
	return false,nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETPLAYERS
-----------------------------------------------------------------------------------------------------------------------------------------
local function GetPlayers()
	local Voip,Selected = {},{}
	local GamePool = GetGamePool("CPed")
	for _,Entitys in pairs(GamePool) do
		local Index = NetworkGetPlayerIndexFromPed(Entitys)
		if Index and IsPedAPlayer(Entitys) and NetworkIsPlayerConnected(Index) then
			Selected[Entitys] = GetPlayerServerId(Index)
			Voip[Entitys] = Index
		end
	end

	return Selected,Voip
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DRAWTEXT
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawText(Coords,Text)
	local Lines = {}
	for Line in string.gmatch(Text,"[^\n]+") do
		table.insert(Lines,Line)
	end

	local LineHeight = 0.025
	local R,G,B,A = 255,255,255,200

	for k,v in ipairs(Lines) do
		SetDrawOrigin(Coords.x,Coords.y,Coords.z + 0.75)
		SetTextFont(6)
		SetTextDropShadow()
		SetTextCentre(true)
		SetTextProportional(true)
		SetTextScale(0.30,0.30)
		SetTextColour(R,G,B,A)

		BeginTextCommandDisplayText("STRING")
		AddTextComponentSubstringPlayerName(v)
		EndTextCommandDisplayText(0,0 + ((k - 1) * LineHeight))

		ClearDrawOrigin()
	end

end