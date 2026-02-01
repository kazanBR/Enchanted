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
Tunnel.bindInterface("races",Creative)
vCLIENT = Tunnel.getInterface("races")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Players = {}
local Cooldown = {}
local Paymented = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADINIT
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	for Mode,v in pairs(Races) do
		Players[Mode] = {}
		Paymented[Mode] = {}

		for Selected in pairs(v.Routes) do
			Players[Mode][Selected] = {}
			Paymented[Mode][Selected] = 0

			if v.Global then
				GlobalState["Races:"..Mode..":"..Selected] = false
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISH
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Finish(Mode,Selected,Points)
	local source = source
	local Passport = vRP.Passport(source)
	if not (Passport and Races[Mode] and Races[Mode].Routes and Races[Mode].Routes[Selected]) then
		return false
	end

	if Active[Passport] then
		Active[Passport] = nil

		if Paymented[Mode][Selected] and Paymented[Mode][Selected] > 0 then
			Paymented[Mode][Selected] = math.max(0,Paymented[Mode][Selected] - 1)

			if Paymented[Mode][Selected] == 0 and Races[Mode].Global and GlobalState["Races:"..Mode..":"..Selected] then
				GlobalState["Races:"..Mode..":"..Selected] = false
			end
		end

		local GainExperience = 8
		local Experience,Level = vRP.GetExperience(Passport,"Race")
		local MinCalculate = math.floor(Races[Mode].Routes[Selected].Payment * 0.75)
		local MaxCalculate = math.floor(Races[Mode].Routes[Selected].Payment * 1.25)
		local Amount = math.random(MinCalculate,MaxCalculate)
		local Valuation = Amount + (Amount * (0.025 * Level))

		if exports.inventory:Buffs("Dexterity",Passport) then
			Valuation = Valuation + (Valuation * 0.1)
		end

		for Permission,Multiplier in pairs({ Ouro = 0.1, Prata = 0.075, Bronze = 0.05 }) do
			if vRP.HasService(Passport,Permission) then
				Valuation = Valuation + (Valuation * Multiplier)
				GainExperience = GainExperience + 2
			end
		end

		vRP.UpgradeStress(Passport,10)
		exports.markers:Exit(source,Passport)
		vRP.BattlepassPoints(Passport,GainExperience)
		vRP.PutExperience(Passport,"Race",GainExperience)
		vRP.GenerateItem(Passport,ExchangeItem,Valuation,true)
	end

	local Vehicle = vRPC.VehicleName(source)
	local Consult = exports.oxmysql:single_async("SELECT * FROM races WHERE Race = ? AND Mode = ? AND Passport = ?",{ Selected,Mode,Passport })
	if Consult then
		if Points < Consult.Points then
			exports.oxmysql:query_async("UPDATE races SET Points = ?,Vehicle = ? WHERE Race = ? AND Mode = ? AND Passport = ?",{ Points,Vehicle,Selected,Mode,Passport })
		end
	else
		exports.oxmysql:insert_async("INSERT INTO races (Mode,Race,Passport,Vehicle,Points) VALUES (?,?,?,?,?)",{ Mode,Selected,Passport,Vehicle,Points })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RUNNERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Runners(Mode,Selected)
	Paymented[Mode][Selected] = Paymented[Mode][Selected] or 0
	if Paymented[Mode][Selected] < Races[Mode].Routes[Selected].Runners then
		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- START
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Start(Mode,Selected)
	local Return = false
	local source = source
	local Passport = vRP.Passport(source)
	if not (Passport and Races[Mode] and Races[Mode].Routes and Races[Mode].Routes[Selected]) then
		return false
	end

	if Races[Mode].Global and GlobalState["Races:"..Mode..":"..Selected] then
		TriggerClientEvent("Notify",source,"Atenção","Circuito em andamento.","amarelo",5000)

		return false
	end

	local CooldownTime = Cooldown[Passport] and Cooldown[Passport][Mode] and Cooldown[Passport][Mode][Selected]
	if CooldownTime and CooldownTime >= os.time() then
		TriggerClientEvent("Notify",source,"Atenção","Aguarde "..CompleteTimers(CooldownTime - os.time())..".","amarelo",10000)

		return false
	end

	if not vRP.RemoveCharges(Passport,"racesticket") then return false end

	Cooldown[Passport] = Cooldown[Passport] or {}
	Cooldown[Passport][Mode] = Cooldown[Passport][Mode] or {}
	Cooldown[Passport][Mode][Selected] = os.time() + CooldownRaces

	Players[Mode][Selected] = Players[Mode][Selected] or {}

	exports.markers:Enter(source,"Corredor")
	Paymented[Mode][Selected] = (Paymented[Mode][Selected] or 0) + 1
	Active[Passport] = { Mode = Mode, Selected = Selected }

	for _,Sources in pairs(vRP.NumPermission("Policia")) do
		async(function()
			vRPC.PlaySound(Sources,"ATM_WINDOW","HUD_FRONTEND_DEFAULT_SOUNDSET")
			TriggerClientEvent("Notify",Sources,"Circuitos","Encontramos um veículo participando de uma corrida clandestina e todos os policiais foram avisados.","policia",10000)
		end)
	end

	return Races[Mode].Routes[Selected].Time
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CANCEL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Cancel()
	local source = source
	local Passport = vRP.Passport(source)
	if not (Passport and Active[Passport]) then
		return false
	end

	exports.markers:Exit(source,Passport)

	local Mode = Active[Passport].Mode
	local Selected = Active[Passport].Selected
	if not Players[Mode][Selected][Passport] then
		return false
	end

	Players[Mode][Selected][Passport] = nil

	if Paymented[Mode][Selected] < 1 then
		return false
	end

	Paymented[Mode][Selected] = Paymented[Mode][Selected] - 1
	if Paymented[Mode][Selected] > 0 then
		return false
	end

	Paymented[Mode][Selected] = 0
	if Races[Mode] and Races[Mode].Global and GlobalState["Races:"..Mode..":"..Selected] then
		GlobalState["Races:"..Mode..":"..Selected] = false
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GlobalState(Mode,Selected)
	if Races[Mode] and Races[Mode].Global and not GlobalState["Races:"..Mode..":"..Selected] then
		TriggerClientEvent("races:Start",-1,Mode,Selected)
		GlobalState["Races:"..Mode..":"..Selected] = true
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RANKING
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Ranking(Mode,Route)
    local Query = exports.oxmysql:query_async("SELECT * FROM races WHERE Race = ? AND Mode = ? ORDER BY Points ASC LIMIT ?",{ Route,Mode,RankingTablet })
    local Ranking = { {}, false }

    if #Query > 0 then
        Ranking[2] = {}
        for k, v in ipairs(Query) do
            table.insert(Ranking[1], { Name = vRP.FullName(v["Passport"]), Time = tonumber(Dotted(v["Points"])), Vehicle = VehicleName(v["Vehicle"]) })

            if k == 1 then
                Ranking[2] = { Name = vRP.FullName(v["Passport"]), Position = v["Race"], Time = tonumber(Dotted(v["Points"])), Vehicle = VehicleName(v["Vehicle"]) }
            end
        end
    end

    return Ranking
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEPOSITION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdatePosition(Mode,Selected,Checkpoint,Distance)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Players[Mode] then return false end

	Players[Mode][Selected] = Players[Mode][Selected] or {}
	if not Players[Mode][Selected][Passport] then
		Players[Mode][Selected][Passport] = { Name = vRP.FullName(Passport), Distance = Distance, Checkpoint = Checkpoint }
	else
		Players[Mode][Selected][Passport].Distance = Distance
		Players[Mode][Selected][Passport].Checkpoint = Checkpoint
	end

	local Positions = {}
	for Passports,v in pairs(Players[Mode][Selected]) do
		table.insert(Positions,{ Passport = Passports, Name = v.Name, Distance = v.Distance, Checkpoint = v.Checkpoint })
	end

	table.sort(Positions,function(a,b)
		if a.Checkpoint == b.Checkpoint then
			return a.Distance < b.Distance
		else
			return a.Checkpoint > b.Checkpoint
		end
	end)

	local CurrentPosition = 1
	for Line,Entry in pairs(Positions) do
		if Entry.Passport == Passport then
			CurrentPosition = Line
			break
		end
	end

	vCLIENT.UpdatePosition(source,CurrentPosition,Positions)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INFORMATION
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Information()
    local source = source
    local Passport = vRP.Passport(source)
    if not Passport then return false end

    local Experience = { Xp = vRP.GetExperience(Passport,"Race"), Levels = TableLevel() }

    return Experience
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RANKINGGLOBAL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RankingGlobal()
    local Ranking = {}

    local Query = exports.oxmysql:query_async("SELECT * FROM races ORDER BY Race ASC, Points DESC")

    if not Query or #Query == 0 then
        return {}
    end

    for _, v in ipairs(Query) do
        local Race = v.Race
        Ranking[Race] = Ranking[Race] or {}
        Ranking[Race][#Ranking[Race] + 1] = { Passport = v.Passport, Name = vRP.FullName(v.Passport), Vehicle = v.Vehicle, Points = v.Points }
    end

    return Ranking
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- VEHICLESHOP
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.VehicleShop()
    local source = source
    local Passport = vRP.Passport(source)
    if not Passport then return false end

    local Vehicles = {}
    for k,v in pairs(VehicleList()) do
        local Class = VehicleClass(k)
        if Class == "Exclusivos" then
            Vehicles[k] = { Name = v.Name, Stock = v.Stock, Price = v.Price }
        end
    end

    return { vRP.ItemAmount(Passport,ExchangeItem), Vehicles }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- RENTALVEHICLE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RentalVehicle(Model)
    local source = source
    local Passport = vRP.Passport(source)
    if not Passport then return false end

    if vRP.SelectVehicle(Passport,Model) then
        return TriggerClientEvent("races:Notify",source,"Aviso","Já possui um <b>"..VehicleName(Model).."</b>.","amarelo")
    end

    local StockVehicle = VehicleStock(Model)
    if StockVehicle and vRP.Scalar("vehicles/Count",{ Vehicle = Model }) >= StockVehicle then
        return TriggerClientEvent("races:Notify",source,"Aviso","Estoque insuficiente.","amarelo")
    end

    local VehiclePrice = VehicleGemstone(Model)
    if VehiclePrice and vRP.TakeItem(Passport,"platinum",VehiclePrice) then
        vRP.Query("vehicles/rentalVehicles",{ Passport = Passport, Vehicle = Model, Plate = vRP.GeneratePlate(), Days = 30, Weight = VehicleWeight(Model), Work = 0 })
        TriggerClientEvent("races:Notify",source,"Sucesso","Aluguel do veículo <b>"..VehicleName(Model).."</b> concluído.","verde")
        Active[Passport] = nil

        return true
    end

    TriggerClientEvent("races:Notify",source,"Aviso","Platina insuficiente.","amarelo")

    return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if not Active[Passport] then
		return false
	end

	local Mode = Active[Passport].Mode
	local Selected = Active[Passport].Selected
	if not Players[Mode] or not Players[Mode][Selected] or not Players[Mode][Selected][Passport] then
		return false
	end

	Players[Mode][Selected][Passport] = nil

	if Paymented[Mode][Selected] and Paymented[Mode][Selected] > 0 then
		Paymented[Mode][Selected] = math.max(0,Paymented[Mode][Selected] - 1)

		if Paymented[Mode][Selected] == 0 and Races[Mode] and Races[Mode].Global and GlobalState["Races:"..Mode..":"..Selected] then
			GlobalState["Races:"..Mode..":"..Selected] = false
		end
	end
end)