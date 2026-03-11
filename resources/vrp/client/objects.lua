-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Init = {}
local Sprays = {}
local Objects = {}
local Switch = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- SPRAYEXIST
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.SprayExist(Distance)
	local Ped = PlayerPedId()
	local Coords = GetEntityCoords(Ped)

	for _,Spray in pairs(Sprays) do
		if #(Coords - GetBlipCoords(Spray.Blip)) <= (Distance or 250) then
			return Spray.Permission
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:TABLE
-----------------------------------------------------------------------------------------------------------------------------------------
local ObjectsBlips = {}

RegisterNetEvent("objects:Table")
AddEventHandler("objects:Table",function(Data)
	Objects = Data or {}
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:BLIPS
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Blips")
AddEventHandler("objects:Blips",function()
	local Colors = {
		LootMedics = 76,
		LootWeapons = 52,
		LootSupplies = 56,
		LootLegendary = 81
	}

	if next(ObjectsBlips) ~= nil then
		for Number,Blip in pairs(ObjectsBlips) do
			if DoesBlipExist(Blip) then
				RemoveBlip(Blip)
			end

			if Sprays and Sprays[Number] then
				Sprays[Number].Blip = nil
			end
		end

		ObjectsBlips = {}
		TriggerEvent("Notify","Caixas","Marcações desativadas.","default",10000)
	else
		for Number,Data in pairs(Objects) do
			local Mode = Data.Mode
			if not Mode then
				goto continue
			end

			local x,y,z = Data.Coords[1],Data.Coords[2],Data.Coords[3]

			local Color = Colors[Mode]
			if Color then
				local Blip = AddBlipForRadius(x,y,z,25.0)
				SetBlipAlpha(Blip,200)
				SetBlipColour(Blip,Color)
				ObjectsBlips[Number] = Blip
			elseif Mode == "Sprays" then
				Sprays[Number] = Sprays[Number] or {}
				local Blip = AddBlipForRadius(x,y,z,250.0)

				SetBlipColour(Blip,Data.Color)
				SetBlipAlpha(Blip,150)

				Sprays[Number].Blip = Blip
				Sprays[Number].Permission = Data.Permission
				ObjectsBlips[Number] = Blip
			end

			::continue::
		end

		TriggerEvent("Notify","Caixas","Marcações ativadas.","default",10000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:ADICIONAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Adicionar")
AddEventHandler("objects:Adicionar",function(Number,Data)
	if not Data then
		return false
	end

	Objects[Number] = Data

	if Data.Mode ~= "Sprays" then
		return false
	end

	Sprays[Number] = Sprays[Number] or {}

	local x,y,z = Data.Coords[1],Data.Coords[2],Data.Coords[3]
	local Blip = AddBlipForRadius(x,y,z,250.0)

	SetBlipColour(Blip,Data.Color)
	SetBlipAlpha(Blip,150)

	Sprays[Number].Blip = Blip
	Sprays[Number].Permission = Data.Permission
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTS:REMOVER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("objects:Remover")
AddEventHandler("objects:Remover",function(Number)
	local Data = Objects[Number]
	local Entitys = Init[Number]

	if Entitys then
		if DoesEntityExist(Entitys) then
			DeleteEntity(Entitys)
		end

		if Data and Data.Mode then
			exports.target:RemCircleZone("Objects:"..Number)
		end

		Init[Number] = nil
	end

	if Data and Data.Active == "Spikes" then
		TriggerEvent("spikes:Remover",Number)
	end

	local Spray = Sprays[Number]
	if Spray then
		local Blip = Spray.Blip
		if Blip and DoesBlipExist(Blip) then
			RemoveBlip(Blip)
		end

		Sprays[Number] = nil
	end

	if Data then
		Objects[Number] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDTARGETZONE
-----------------------------------------------------------------------------------------------------------------------------------------
function AddTargetZone(Number,Coords,mode,Weight,Options,Size,Box)
	if not Coords or not Size or not Options then
		return false
	end

	local Zone = "Objects:"..Number
	local Heading = Coords[4] or 0.0
	local Params = { name = Zone, heading = Heading }
	local Center = vec3(Coords[1],Coords[2],Coords[3] + (Weight or 0.0))

	if Box then
		Params.minZ = Coords[3]
		Params.maxZ = Coords[3] + (Size.maxZ or 1.5)

		exports.target:AddBoxZone(Zone,Center,Size.width or 1.0,Size.height or 1.0,Params,Options)
	else
		Params.useZ = true
		exports.target:AddCircleZone(Zone,Center,Size.radius or 1.0,Params,Options)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TARGETLABEL
-----------------------------------------------------------------------------------------------------------------------------------------
function TargetLabel(Number,Coords,Mode,Weight,Item)
	local Modes = {
		Store = {
			isBox = false,
			size = { radius = 0.75 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Camera = {
			isBox = false,
			size = { radius = 0.25 },
			options = {
				shop = Number,
				Distance = 5.0,
				options = {
					{ event = "inventory:StoreObjects", label = "Retirar", tunnel = "server" }
				}
			}
		},
		Destroy = {
			isBox = false,
			size = { radius = 0.75 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:StoreObjects", label = "Destruir", tunnel = "server" }
				}
			}
		},
		Craftings = {
			isBox = false,
			size = { radius = 0.25 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "crafting:Open", label = "Abrir", tunnel = "products", service = Item and SplitOne(Item) or "" },
					{ event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Shops = {
			isBox = false,
			size = { radius = 0.45 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "shops:Open", label = "Abrir", tunnel = "products", service = Item and SplitOne(Item) or "" },
					{ event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Chests = {
			isBox = true,
			size = { width = 0.65, height = 0.95, maxZ = 0.5 },
			options = {
				shop = Number,
				Distance = 1.75,
				options = {
					{ event = "chest:Item", label = "Abrir", tunnel = "products", service = Item },
					LocalPlayer.state.Admin and { event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Personal = {
			isBox = true,
			size = { width = 0.6, height = 0.9, maxZ = 0.5 },
			options = {
				shop = Number,
				Distance = 1.75,
				options = {
					{ event = "chest:Item", label = "Abrir", tunnel = "products", service = Item },
					LocalPlayer.state.Admin and { event = "inventory:StoreObjects", label = "Guardar", tunnel = "server" }
				}
			}
		},
		Sprays = {
			isBox = false,
			size = { radius = 1.0 },
			options = {
				shop = Number,
				Distance = 2.5,
				options = {
					{ event = "inventory:StoreObjects", label = "Violar", tunnel = "server" }
				}
			}
		},
		Recycle = {
			isBox = true,
			size = { width = 1.5, height = 3.75, maxZ = 2.0 },
			options = {
				shop = Number,
				Distance = 2.25,
				options = {
					{ event = "chest:Recycle", label = "Abrir", tunnel = "client" }
				}
			}
		},
		LootLegendary = {
			isBox = true,
			size = { width = 1.15, height = 2.15, maxZ = 0.8 },
			options = {
				shop = Number,
				Distance = 2.0,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		},
		LootSupplies = {
			isBox = true,
			size = { width = 0.5, maxZ = 0.55 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		},
		LootWeapons = {
			isBox = true,
			size = { width = 0.9, height = 1.5, maxZ = 0.65 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		},
		LootMedics = {
			isBox = true,
			size = { width = 0.75, maxZ = 0.55 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		},
		LootCode = {
			isBox = true,
			size = { maxZ = 1.75 },
			options = {
				shop = Number,
				Distance = 1.5,
				options = {
					{ event = "inventory:Loot", label = "Abrir", tunnel = "server", service = Mode }
				}
			}
		}
	}

	if Modes[Mode] then
		AddTargetZone(Number,Coords,Mode,Weight,Modes[Mode].options,Modes[Mode].size,Modes[Mode].isBox)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEANDMANAGEOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function CreateAndManageObject(Number,v,Coords)
	if not v or not v.Coords then
		return false
	end

	local ObjectCoords = vec3(v.Coords[1], v.Coords[2], v.Coords[3])
	if #(Coords - ObjectCoords) <= (v.Distance or 100) then
		if not Init[Number] and LoadModel(v.Object) then
			local Entitys = CreateObjectNoOffset(v.Object,ObjectCoords.x,ObjectCoords.y,ObjectCoords.z,false,false,false)
			Init[Number] = Entitys

			SetEntityHeading(Entitys,v.Coords[4])
			FreezeEntityPosition(Entitys,true)
			SetEntityLodDist(Entitys,0xFFFF)

			if not v.Ground then
				PlaceObjectOnGroundProperly(Entitys)
			end

			if v.Mode then
				if v.Mode == "Personal" and v.Passport and v.Passport ~= LocalPlayer.state.Passport then
					goto Continue
				end

				if v.Mode == "Chests" and v.Permission then
					local Hierarchy = SplitTwo(v.Permission)
					local Permission = SplitOne(v.Permission)

					if not LocalPlayer.state[Permission] or LocalPlayer.state[Permission] > parseInt(Hierarchy) then
						goto Continue
					end
				end

				TargetLabel(Number,v.Coords,v.Mode,v.Weight or 0.0,v.Item)

				::Continue::
			end

			if v.Active == "Spikes" then
				local MaxOffset = GetOffsetFromEntityInWorldCoords(Entitys,0.0,1.84,0.1)
				local MinOffset = GetOffsetFromEntityInWorldCoords(Entitys,0.0,-1.84,-0.1)
				TriggerEvent("spikes:Adicionar",Number,v.Coords,MinOffset,MaxOffset)
			end
		end
	elseif Init[Number] then
		DestroyObject(Number,v)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADOBJECTS
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		local Ped = PlayerPedId()
		local Coords = GetEntityCoords(Ped)
		local Route = LocalPlayer.state.Route
		for Number,v in pairs(Objects) do
			local Bucket = v.Bucket
			if not Bucket or Bucket == Route then
				CreateAndManageObject(Number,v,Coords)
			elseif Init[Number] then
				DestroyObject(Number,v)
			end
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYOBJECT
-----------------------------------------------------------------------------------------------------------------------------------------
function DestroyObject(Number,Data)
	local Entitys = Init[Number]
	if not Entitys then
		return false
	end

	if Data.Mode then
		exports.target:RemCircleZone("Objects:"..Number)
	end

	if DoesEntityExist(Entitys) then
		DeleteEntity(Entitys)
	end

	if Data.Active == "Spikes" then
		TriggerEvent("spikes:Remover",Number)
	end

	Init[Number] = nil
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OBJECTCONTROLLING
-----------------------------------------------------------------------------------------------------------------------------------------
function tvRP.ObjectControlling(Model,Rotate,Align)
	local Switch = false
	local Aplication = false
	local OtherCoords = false

	if LoadModel(Model) then
		local Progress = true
		local Ped = PlayerPedId()
		local Heading = GetEntityHeading(Ped)
		local Coords = GetOffsetFromEntityInWorldCoords(Ped,0.0,Align or 1.0,0.0)
		local NextObject = CreateObjectNoOffset(Model,Coords.x,Coords.y,Coords.z,false,false,false)

		SetEntityAlpha(NextObject,200,false)
		PlaceObjectOnGroundProperly(NextObject)
		SetEntityCollision(NextObject,false,false)
		SetEntityHeading(NextObject,Heading + (Rotate or 0.0))

		local DefaultButtons = {
			{ "F","Cancelar" },
			{ "H","Posicionar" },
			{ "Q","Rotacionar Esquerda" },
			{ "E","Rotacionar Direita" },
			{ "Z","Trocar Modo" }
		}

		local ExtendedButtons = {
			{ "F","Cancelar" },
			{ "H","Posicionar" },
			{ "Q","Rotacionar Esquerda" },
			{ "E","Rotacionar Direita" },
			{ "-","Descer" },
			{ "+","Subir" },
			{ "↑","Movimentar para Frente" },
			{ "←","Movimentar para Esquerda" },
			{ "↓","Movimentar para Baixo" },
			{ "→","Movimentar para Direita" },
			{ "Z","Trocar Modo" }
		}

		TriggerEvent("inventory:Buttons",DefaultButtons)

		while Progress do
			local controlPressed = GetMovementControls(NextObject)
			if controlPressed then
				MoveObject(NextObject,controlPressed)
			end

			RotateObject(NextObject)
			DrawGraphOutline(NextObject)

			if not Switch then
				local Cam = GetGameplayCamCoord()
				local Handle = StartExpensiveSynchronousShapeTestLosProbe(Cam,GetCoordsFromCam(10.0,Cam),-1,Ped,4)
				local _,_,Coords = GetShapeTestResult(Handle)
				SetEntityCoords(NextObject,Coords.x,Coords.y,Coords.z,false,false,false,false)
			end

			if IsControlJustPressed(0,48) then
				Switch = not Switch
				TriggerEvent("inventory:Buttons",Switch and ExtendedButtons or defaultButtons)
			elseif IsControlJustPressed(1,74) then
				TriggerEvent("inventory:CloseButtons")
				Aplication = true
				Progress = false
				Switch = false
			elseif IsControlJustPressed(0,49) then
				TriggerEvent("inventory:CloseButtons")
				Aplication = false
				Progress = false
				Switch = false
			end

			Wait(1)
		end

		if DoesEntityExist(NextObject) then
			local oCoords = GetEntityCoords(NextObject)
			local oHeading = GetEntityHeading(NextObject)
			OtherCoords = { Optimize(oCoords.x),Optimize(oCoords.y),Optimize(oCoords.z),Optimize(oHeading) }

			DeleteEntity(NextObject)
		end
	end

	if not OtherCoords or (OtherCoords and OtherCoords[1] == 0.0 and OtherCoords[2] == 0.0) then
		Aplication = false
	end

	return Aplication,OtherCoords
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMOVEMENTCONTROLS
-----------------------------------------------------------------------------------------------------------------------------------------
function GetMovementControls(NextObject)
	local controls = false

	if IsDisabledControlPressed(1,314) then
		controls = {}
		controls.zMoveUp = true
	elseif IsDisabledControlPressed(1,315) then
		controls = {}
		controls.zMoveDown = true
	end

	if IsDisabledControlPressed(1,172) then
		controls = {}
		controls.xMoveRight = true
	elseif IsDisabledControlPressed(1,173) then
		controls = {}
		controls.xMoveLeft = true
	end

	if IsDisabledControlPressed(1,174) then
		controls = {}
		controls.yMoveBackward = true
	elseif IsDisabledControlPressed(1,175) then
		controls = {}
		controls.yMoveForward = true
	end

	return controls
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
	if IsControlPressed(0,38) then
		SetEntityHeading(NextObject,GetEntityHeading(NextObject) + 0.25)
	elseif IsControlPressed(0,52) then
		SetEntityHeading(NextObject,GetEntityHeading(NextObject) - 0.25)
	end
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
-- GETCOORDSFROMCAM
-----------------------------------------------------------------------------------------------------------------------------------------
function GetCoordsFromCam(Distance,Coords)
    local Rotation = GetGameplayCamRot()
    local pitch = math.rad(Rotation.x)
    local yaw = math.rad(Rotation.y)
    local roll = math.rad(Rotation.z)

    local direction = vec3(
        -math.sin(roll) * math.abs(math.cos(pitch)),
        math.cos(roll) * math.abs(math.cos(pitch)),
        math.sin(pitch)
    )

    return vec3(
        Coords.x + direction.x * Distance,
        Coords.y + direction.y * Distance,
        Coords.z + direction.z * Distance
    )
end