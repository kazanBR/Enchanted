-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEDROP
-----------------------------------------------------------------------------------------------------------------------------------------
local function RemoveDrop(Route,Number)
	if Drops[Route] and Drops[Route][Number] then
		TriggerClientEvent("inventory:DropsRemover",-1,Route,Number)
		Drops[Route][Number] = nil

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HANDLEDROPREMOVAL
-----------------------------------------------------------------------------------------------------------------------------------------
local function HandleDropRemoval(Route,Number,v)
	if RemoveDrop(Route,Number) and v.key and ItemUnique(v.key) then
		local Unique = SplitUnique(v.key)
		if Unique then
			vRP.RemSrvData(Unique)
		end
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVESERVER
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("SaveServer",function(Silenced)
	if Silenced then
		return false
	end

	for Route,List in pairs(Drops) do
		for Number,v in pairs(List) do
			HandleDropRemoval(Route,Number,v)
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADREMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		Wait(60000)

		local CurrentTimer = os.time()
		for Route,List in pairs(Drops) do
			for Number,v in pairs(List) do
				if v.created and v.created < CurrentTimer then
					HandleDropRemoval(Route,Number,v)
				end
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Drops(Item,Slot,Amount)
	local source = source
	Amount = parseInt(Amount,true)
	local Passport = vRP.Passport(source)
	if not (Passport and Amount >= 1) then
		return false
	end

	if Active[Passport] or Player(source).state.Handcuff or exports.hud:Wanted(Passport) or vRP.InsideVehicle(source) then
		TriggerClientEvent("inventory:Update",source)

		return false
	end

	if vRP.TakeItem(Passport,Item,Amount,false,Slot) then
		return exports.inventory:Drops(Passport,source,Item,Amount,true)
	else
		TriggerClientEvent("inventory:Update",source)
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DROPS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Drops",function(Passport,source,Item,Amount,Force,Coords)
	Amount = parseInt(Amount)
	if Amount < 1 then
		return false
	end

	Active[Passport] = true
	local Route = GetPlayerRoutingBucket(source)
	Drops[Route] = Drops[Route] or {}

	local Selected
	repeat
		Selected = GenerateString("DDDDDD")
	until not Drops[Route][Selected]

	local Provisory = {
		route = Route,
		id = Selected,
		amount = Amount,
		created = os.time() + 600,
		coords = Coords or vRP.GetEntityCoords(source),
		key = Force and Item or vRP.SortNameItem(Passport,Item)
	}

	local Split = splitString(Provisory.key)
	local NameItem = Split[1]

	if not Provisory.desc then
		if NameItem == "vehiclekey" and Split[3] then
			local Consult = exports.oxmysql:single_async("SELECT * FROM vehicles WHERE Plate = ? LIMIT 1",{ Split[3] })
			if Consult and VehicleExist(Consult.Vehicle) then
				Provisory.desc = ("Proprietário: <common>%s</common><br>Modelo: <common>%s</common><br>Placa: <common>%s</common>"):format(vRP.FullName(Consult.Passport),VehicleName(Consult.Vehicle),Split[3])
			end
		elseif NameItem == "propertys" and Split[2] then
			local Consult = exports.oxmysql:single_async("SELECT * FROM propertys WHERE Serial = ? LIMIT 1",{ Split[2] })
			if Consult then
				Provisory.desc = "Proprietário: <common>"..vRP.FullName(Consult.Passport).."</common>"
			end
		elseif ItemNamed(NameItem) and Split[2] and vRP.Identity(Split[2]) then
			if NameItem == "identity" then
				Provisory.desc = ("Passaporte: <rare>%s</rare><br>Nome: <rare>%s</rare><br>Telefone: <rare>%s</rare>"):format(Dotted(Split[2]),vRP.FullName(Split[2]),vRP.Phone(Split[2]))
			else
				Provisory.desc = "Proprietário: <common>"..vRP.FullName(Split[2]).."</common>"
			end
		end
	end

	if Split[2] then
		local Loaded = ItemLoads(Provisory.key)
		if Loaded then
			Provisory.charges = parseInt(Split[2] * (100 / Loaded))
		end

		local Durability = ItemDurability(Provisory.key)
		if Durability then
			Provisory.durability = parseInt(os.time() - Split[2])
			Provisory.days = Durability
		end
	end

	Active[Passport] = nil
	Drops[Route][Selected] = Provisory
	TriggerClientEvent("inventory:DropsAdicionar",-1,Route,Selected,Provisory)

	return true
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PICKUP
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Pickup(Number,Route,Target,Amount)
	local source = source
	Amount = parseInt(Amount,true)
	local Target = tostring(Target)
	local Passport = vRP.Passport(source)
	local Info = Drops[Route] and Drops[Route][Number]
	if not (Passport and Info and Info.key and Amount >= 1) or Active[Passport] then
		return false
	end

	Active[Passport] = true

	if vRP.CheckWeight(Passport,Info.key,Amount) then
		local Inv = vRP.Inventory(Passport)
		if not Info.amount or Info.amount < Amount or (Inv[target] and Inv[target].item ~= Info.key) or vRP.MaxItens(Passport,Info.key,Amount) then
			TriggerClientEvent("inventory:Notify",source,"Aviso","Mochila Sobrecarregada.","amarelo")
		elseif vRP.GiveItem(Passport,Info.key,Amount,false,Target) then
			Info.amount = Info.amount - Amount

			if Info.amount <= 0 then
				RemoveDrop(Route,Number)
			else
				TriggerClientEvent("inventory:DropsAtualizar",-1,Route,Number,Info.amount)
			end

			Active[Passport] = nil

			return true
		end
	else
		TriggerClientEvent("inventory:Notify",source,"Aviso","Mochila Sobrecarregada.","amarelo")
	end

	TriggerClientEvent("inventory:Update",source)
	Active[Passport] = nil

	return false
end