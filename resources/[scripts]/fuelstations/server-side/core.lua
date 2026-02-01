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
Tunnel.bindInterface("fuelstations", Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Seconds = 86400
local Interval = 600000
local Division = {}
local Permissions = {}
local ActiveShipments = {}
local PlayerShipments = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADSYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
    for Permission,_ in pairs(Locations) do
        local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?", { Permission })
        if not Consult then
            exports.oxmysql:insert_async("INSERT INTO fuelstations_creative (Permission,Name,Color,Blip,Stock,FuelPrice) VALUES (?,?,?,?,?,?)", { Permission, Config.DefaulName, Config.DefaultColor, Config.DefaultIcon, 0, Config.DefaultPricePerLiter })
        end
        local Datatable = vRP.GetSrvData("FuelStations:"..Permission,true)
        Datatable.Upgrades = Datatable.Upgrades or { Stock = 0, Truck = 0, Relationship = 0 }
        Datatable.Historical = Datatable.Historical or {}
        vRP.SetSrvData("FuelStations:"..Permission,Datatable,true)
    end

    for Permission,_ in pairs(Locations) do
        CreateThread(function()
            while true do
                local Now = os.time()
                local Datatable = vRP.GetSrvData("FuelStations:"..Permission,true)
                Datatable.EmptyLastCheck = Datatable.EmptyLastCheck or Now
                local Processed = false

                while (Now - Datatable.EmptyLastCheck) >= Seconds do
                    Datatable.EmptyLastCheck = Datatable.EmptyLastCheck + Seconds
                    Processed = true
                    if Config.EmptyDaysStock <= 0 then
                        return
                    end

                    local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Permission })
                    if not Consult then
                        return
                    end

                    if (Consult.Stock or 0) <= 0 then
                        local NewValue = (Consult.Empty or 0) + 1
                        exports.oxmysql:update_async("UPDATE fuelstations_creative SET Empty = ? WHERE Permission = ?", { NewValue, Permission })
                    
                        local Players = vRP.NumPermission(Permission)
                        if Players then
                            for _, Source in pairs(Players) do
                                if Source then
                                    TriggerClientEvent("fuelstations:Notify",Source,"Central", string.format("Seu posto está sem combustível há %d dia(s).", NewValue),"amarelo")
                                end
                            end
                        end

                        if Config.EmptyDaysStock > 0 and NewValue >= Config.EmptyDaysStock then
                            local Players = vRP.NumPermission(Permission)
                            if Players then
                                for _, Source in pairs(Players) do
                                    if Source then
                                        TriggerClientEvent("fuelstations:Notify",Source,"Central","O governo retomou este posto por falta de combustível.","vermelho")
                                    end
                                end
                            end

                            local Members = vRP.DataGroups(Permission)
                            if Members then
                                for PassportStr, _ in pairs(Members) do
                                    local Passport = tonumber(PassportStr)
                                    local Source = vRP.Source(Passport)
                                    if Passport then
                                        local Job = ActiveShipments[Division[Passport]]
                                        if Job and Job.Passport == Passport then
                                            ActiveShipments[Division[Passport]] = nil
                                        end
                                        PlayerShipments[Passport] = nil
                                        Division[Passport] = nil
                                        vRP.RemovePermission(Passport,Permission)
                                        TriggerClientEvent("fuelstations:Notify",Source,"Central","Você perdeu o posto por ficar dias sem combustível.","vermelho")
                                    end
                                end
                            end

                            Datatable.Upgrades = { Stock = 0, Truck = 0, Relationship = 0 }
                            Datatable.Historical = {}
	                        Datatable.EmptyLastCheck = os.time()
                            vRP.SetSrvData("FuelStations:"..Permission,Datatable,true)

                            local Balance = vRP.Permissions(Permission,"Bank")
                            if Balance > 0 then
                                vRP.PermissionsUpdate(Permission,"Bank","-",Balance)
                            end

                            local MaxStock = Config.DefaultMaxStock + SumUpgrade(Config.Upgrades.Stock,Datatable.Upgrades.Stock)
                            exports.oxmysql:update_async("UPDATE fuelstations_creative SET Name = ?, Color = ?, Blip = ?, Stock = ?, FuelPrice = ?, MoneyEarned = 0, MoneySpent = 0, FuelImported = 0, Visits = 0, Empty = 0 WHERE Permission = ?",{ Config.DefaulName, Config.DefaultColor, Config.DefaultIcon, math.max(math.floor(MaxStock * 0.25), 0), Config.DefaultPricePerLiter, Permission })
                            TriggerClientEvent("fuelstations:Blip",-1,Permission,Config.DefaulName,Config.DefaultColor,Config.DefaultIcon)
                        end
                    end
                end

                if Processed then
                    vRP.SetSrvData("FuelStations:"..Permission,Datatable,true)
                end
                Wait(Interval)
            end
        end)
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HASPERMISSION
-----------------------------------------------------------------------------------------------------------------------------------------
function HasPermission(Level,Permission)
	if not Permission or Permission == -1 then
		return false
	end

	if Permission == 0 then
		return true
	end

	return Level and Level <= Permission
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SUMUPGRADE
-----------------------------------------------------------------------------------------------------------------------------------------
function SumUpgrade(List,Level)
	if not List or not Level or Level <= 0 then
		return 0
	end

	local Total = 0
	for Index = 1, Level do
		if List[Index] and List[Index].Amount then
			Total = Total + List[Index].Amount
		end
	end

	return Total
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTATION:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("fuelstations:Open")
AddEventHandler("fuelstations:Open",function(Permission)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not Permission or not Locations[Permission] then
		return false
	end

    local Level = vRP.HasPermission(Passport,Permission)
    if not Level then
        local Location = Locations[Permission]
        local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Permission })
        if not Location or not Consult then
			return
		end

        if vRP.AmountGroups(Permission) > 0 then
			TriggerClientEvent("fuelstations:Notify",source,"Central","Este posto já possui um proprietário.","amarelo")
			return
		end

		local Price = Location.Price or 0
		if Price <= 0 then
			TriggerClientEvent("fuelstations:Notify",source,"Central","Este posto não está disponível para compra.","amarelo")
			return
		end

		if not vRP.Request(source,"Posto de Combustível",string.format("Comprar estabelecimento por <b>$%s</b>?",tostring(Price))) then
			return
		end

		if not vRP.PaymentFull(Passport,Price,true) then
			TriggerClientEvent("fuelstations:Notify",source,"Central","Dinheiro insuficiente.","amarelo")
			return
		end

        vRP.SetPermission(Passport,Permission,1)
		Level = vRP.HasPermission(Passport,Permission)

		if Level then
			TriggerClientEvent("fuelstations:Notify",source,"Central","Você agora é o proprietário deste posto.","verde")
		else
			TriggerClientEvent("fuelstations:Notify",source,"Central","Não foi possível finalizar a compra.","amarelo")
			return
		end
    end

	Division[Passport] = Permission
	Permissions[Passport] = Config.OtherPermissions[Permission] or Config.Permissions
	TriggerClientEvent("fuelstations:Opened",source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTATION:GALLON
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("fuelstations:Gallon")
AddEventHandler("fuelstations:Gallon", function(Departmenty)
	local source = source
	local Passport = vRP.Passport(source)
	
	if not Passport or not Departmenty or not Locations[Departmenty] then
		return
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })
	if not Consult then
		return
	end

	if Consult.Stock < Config.StockGallon then
		TriggerClientEvent("Notify", source, "Central", "Estoque insuficiente para vender galão.", "amarelo")
		return
	end

	if vRP.MaxItens(Passport,Config.ItemGallon,1) then
		TriggerClientEvent("Notify",source,"Central","Você já possui este item.","amarelo")
		return
	end

	if not vRP.CheckWeight(Passport,Config.ItemGallon, 1) or not vRP.CheckWeight(Passport,Config.ItemGallonFuel,Config.GallonFuelAmount) then
		TriggerClientEvent("Notify",source,"Central","Verifique o peso da mochila.","amarelo")
		return
	end

	if not vRP.PaymentFull(Passport,Config.PriceGallon,true) then
		TriggerClientEvent("Notify",source,"Central","Dinheiro insuficiente.","amarelo")
		return
	end

	vRP.GenerateItem(Passport,Config.ItemGallon,1,true)
	vRP.GenerateItem(Passport,Config.ItemGallonFuel,Config.GallonFuelAmount,true)

	exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = GREATEST(Stock - ?,0) WHERE Permission = ?",{ Config.StockGallon, Departmenty })

    vRP.PermissionsUpdate(Departmenty,"Bank","+",Config.PriceGallon)

    local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty,true)
    table.insert(Datatable.Historical, { Type = "Fuel", Player = { Passport = Passport, Name = vRP.FullName(Passport) }, Value = Config.PriceGallon, Amount = Config.StockGallon })
	vRP.SetSrvData("FuelStations:"..Departmenty,Datatable,true)

	TriggerClientEvent("Notify",source,"Central","Galão adquirido com sucesso.","verde")
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Player()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)

	return {
		MaxGroup = vRP.Permissions(Departmenty, "Members"),
		Player = {
			Passport = Passport,
			Name = vRP.FullName(Passport),
			Level = Level
		},
		Permissions = {
            Stock = {
				View = HasPermission(Level,Permissions[Passport].Stock.View),
				Edit = HasPermission(Level,Permissions[Passport].Stock.Edit)
			},
			Replenishment = {
				View = HasPermission(Level,Permissions[Passport].Replenishment.View),
				Import = HasPermission(Level,Permissions[Passport].Replenishment.Import),
				Export = HasPermission(Level,Permissions[Passport].Replenishment.Export)
			},
			OfferJobs = {
				View = HasPermission(Level,Permissions[Passport].OfferJobs.View),
				Create = HasPermission(Level,Permissions[Passport].OfferJobs.Create),
				Edit = HasPermission(Level,Permissions[Passport].OfferJobs.Edit),
				Destroy = HasPermission(Level,Permissions[Passport].OfferJobs.Destroy)
			},
			Bank = {
				View = HasPermission(Level,Permissions[Passport].Bank.View),
				Deposit = HasPermission(Level,Permissions[Passport].Bank.Deposit),
				Withdraw = HasPermission(Level,Permissions[Passport].Bank.Withdraw),
				Transfer = HasPermission(Level,Permissions[Passport].Bank.Transfer)
			},
			Update = HasPermission(Level,Permissions[Passport].Update),
			Upgrades = HasPermission(Level,Permissions[Passport].Upgrades),
			Employees = {
				View = HasPermission(Level,Permissions[Passport].Employees.View),
				Create = HasPermission(Level,Permissions[Passport].Employees.Create),
				Edit = HasPermission(Level,Permissions[Passport].Employees.Edit),
				Dismiss = HasPermission(Level,Permissions[Passport].Employees.Dismiss)
			}
		},
		Hierarchy = vRP.Hierarchy(Departmenty)
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOME
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Home()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })
    local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty, true)

	return { Name = Consult.Name, Color = Consult.Color, Icon = Consult.Blip, Statistics = { MoneyEarned = Consult.MoneyEarned, MoneySpent = Consult.MoneySpent, FuelImported = Consult.FuelImported, Visits = Consult.Visits }, Stock = Consult.Stock, MaxStock = Config.DefaultMaxStock + SumUpgrade(Config.Upgrades.Stock,Datatable.Upgrades.Stock) }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Update(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Update) then
		return false
	end

	exports.oxmysql:update_async("UPDATE fuelstations_creative SET Name = ?, Color = ?, Blip = ? WHERE Permission = ?",{ Data.Name,Data.Color,Data.Icon,Departmenty })
	TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Informações atualizadas.","verde")
	TriggerClientEvent("fuelstations:Blip",-1,Departmenty,Data.Name,Data.Color,Data.Icon)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STOCK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Stock()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Stock.View) then
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })
    local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty, true)

	return { Price = Consult.FuelPrice, MinPrice = Config.MinPricePerLiter, MaxPrice = Config.MaxPricePerLiter, Stock = Consult.Stock, MaxStock = Config.DefaultMaxStock + SumUpgrade(Config.Upgrades.Stock,Datatable.Upgrades.Stock) }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FUELSTOCK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.FuelStock(Permission)
    local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?", { Permission})
    if not Consult then
        return false
    end

    return { Stock = Consult.Stock or 0, FuelPrice = Consult.FuelPrice or Config.DefaultPricePerLiter, Name = Consult.Name or Config.DefaulName }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATESTOCK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateStock(Price)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty or Price > Config.MaxPricePerLiter or Price < Config.MinPricePerLiter then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Stock.Edit) then
		return false
	end

	exports.oxmysql:update_async("UPDATE fuelstations_creative SET FuelPrice = ? WHERE Permission = ?",{ Price,Departmenty })
	TriggerClientEvent("fuelstation:Notify",source,"Sucesso","Preço por litro atualizado.","verde")

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Bank()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Bank.View) then
		return false
	end

  	local Consult = exports.oxmysql:query_async("SELECT * FROM painel_creative_transactions WHERE Permission = @Permission LIMIT 50", { Permission = Departmenty })

  	local Transactions = {}
  	for _, v in ipairs(Consult) do
    	table.insert(Transactions, { Player = { Passport = v.Passport, Name = vRP.FullName(v.Passport) }, To = { Passport = v.Transfer, Name = vRP.FullName(v.Transfer) }, Type = v.Type, Value = v.Value, Date = v.Timestamp })
  	end

	return { Balance = vRP.Permissions(Departmenty,"Bank"), Historical = Transactions }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEPOSITBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DepositBank(Value)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Bank.Deposit) then
		return false
	end

	if vRP.PaymentBank(Passport,Value) then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Deposit", Passport = Passport, Value = Value, Timestamp = os.time(), Permission = Departmenty })
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Deposito realizado.","verde")
		vRP.PermissionsUpdate(Departmenty,"Bank","+",Value)
		return true
	end


	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WITHDRAWBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.WithdrawBank(Value)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Bank.Withdraw) then
		return false
	end


	if vRP.Permissions(Departmenty,"Bank") >= Value then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Permission)",{ Type = "Withdraw", Passport = Passport, Value = Value, Timestamp = os.time(), Permission = Departmenty })
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Saque realizado.","verde")
		vRP.GiveBank(Passport,Value * Config.BankTaxWithdraw)
		vRP.PermissionsUpdate(Departmenty,"Bank","-",Value)
		return true
	end


	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFERBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.TransferBank(OtherPassport,Value)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then
		return false
	end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Bank.Transfer) then
		return false
	end


	local Identity = vRP.Identity(OtherPassport)
	if Identity and vRP.Permissions(Departmenty,"Bank") >= Value then
		exports.oxmysql:insert_async("INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Transfer,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Transfer,@Permission)",{ Type = "Transfer", Passport = Passport, Value = Value, Timestamp = os.time(), Transfer = OtherPassport, Permission = Departmenty })
		TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Transferência realizada.","verde")
		vRP.GiveBank(OtherPassport,Value * Config.BankTaxTransfer,true)
		vRP.PermissionsUpdate(Departmenty,"Bank","-",Value)

		return { Passport = OtherPassport, Name = vRP.FullName(Passport) }
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REPLENISHMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Replenishment()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	
	if not Passport or not Departmenty then return false end
	
	local Active = ActiveShipments[Departmenty]
	local Payload = Active and { Index = Active.Index, Mode = Active.Mode } or false
	
	return Payload
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTSHIPMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.StartShipment(Index,Mode)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then return false end
	
	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level, Permissions[Passport].Replenishment[Mode]) then
		return false
	end
	
	if ActiveShipments[Departmenty] then
		TriggerClientEvent("fuelstations:Notify",source,"Central","Já existe uma carga ativa para este posto.","amarelo")
		return false
	end
	
	local ShipmentData = Config.Replenishments[Index]
	
	if Mode == "Import" then
		local Balance = vRP.Permissions(Departmenty,"Bank")
		
		if Balance < ShipmentData.Import then
			TriggerClientEvent("fuelstations:Notify",source,"Central","Saldo insuficiente no banco do posto.","amarelo")
			return false
		end
	end
		
	local Location = Locations[Departmenty]
	local Destination = Location.Packages[ShipmentData.Package]
	local Routes = { Destination, Location.Delivery }
	
	local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty,true)
	local TruckBonus = SumUpgrade(Config.Upgrades.Truck,Datatable.Upgrades.Truck)
	local RelationshipBonus = SumUpgrade(Config.Upgrades.Relationship,Datatable.Upgrades.Relationship)
	local Amount = math.floor(ShipmentData.Amount + (ShipmentData.Amount * (TruckBonus / 100)))
	local Factor = Amount / ShipmentData.Amount
	
	local MaxStock = Config.DefaultMaxStock + SumUpgrade(Config.Upgrades.Stock,Datatable.Upgrades.Stock)
	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })
		
	if Mode == "Import" and (Consult.Stock + Amount) > MaxStock then
		TriggerClientEvent("fuelstations:Notify",source,"Central","Organize o estoque antes de importar esta carga.","amarelo")
		return false
	end
		
	if Mode == "Export" and Consult.Stock < Amount then
		TriggerClientEvent("fuelstations:Notify",source,"Central","Combustível insuficiente para exportar.","amarelo")
		return false
	end
		
	ActiveShipments[Departmenty] = { Passport = Passport, Index = Index, Mode = Mode, Amount = Amount, ImportCost = math.floor(ShipmentData.Import * Factor * (1 - (RelationshipBonus / 100))), ExportValue = math.floor(ShipmentData.Export * Factor) }
		
	PlayerShipments[Passport] = Departmenty 
		
	TriggerClientEvent("fuelstations:Init",source,Routes)
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISHSHIPMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.FinishShipment()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local Job = ActiveShipments[Departmenty]
		
	if not Passport or not Departmenty or not Job then return false end
		
	if Job and Job.Passport == Passport then
		ActiveShipments[Departmenty] = nil
	end
		
	PlayerShipments[Passport] = nil
		
	TriggerClientEvent("fuelstations:Finish",source)
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Payment()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	local Job = ActiveShipments[Departmenty]
		
	if not Passport or not Job or Job.Passport ~= Passport then return false end
		
	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })
	local Stock = parseInt(Consult.Stock) or 0
	local Delivered = Job.Amount
	local Payout = 0
		
	local function ProcessShipment()
		if Job.Mode == "Import" then
			local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty,true)
			local MaxStock = Config.DefaultMaxStock + SumUpgrade(Config.Upgrades.Stock,Datatable.Upgrades.Stock)
			local Available = math.max(MaxStock - Stock, 0)
				
			if Available <= 0 then
				TriggerClientEvent("fuelstations:Notify",source,"Central","O estoque está cheio. Utilize/ou esvazie antes de importar.","amarelo")
				return false
			end
				
			Delivered = math.min(Delivered, Available)
			local UnitCost = Job.ImportCost / Job.Amount
			local Cost = math.floor(Delivered * UnitCost)
				
			exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = Stock + ?, MoneySpent = MoneySpent + ?, FuelImported = FuelImported + ? WHERE Permission = ?",{ Delivered, Cost, Delivered, Departmenty })

			vRP.PermissionsUpdate(Departmenty,"Bank","-",Cost)
				
			table.insert(Datatable.Historical,{ Type = "Import", Player = { Passport = Passport, Name = vRP.FullName(Passport) }, Value = Cost, Amount = Delivered })
			vRP.SetSrvData("FuelStations:"..Departmenty,Datatable,true)
			return true
		elseif Job.Mode == "Export" then
			if Stock <= 0 then
				TriggerClientEvent("fuelstations:Notify",source,"Central","Não há combustível suficiente em estoque.","amarelo")
				return false
			end
				
			Delivered = math.min(Delivered, Stock)
			local UnitValue = Job.ExportValue / Job.Amount
			Payout = math.floor(Delivered * UnitValue)
				
			Consult.Stock = math.max(Stock - Delivered, 0)
			Consult.MoneyEarned = (parseInt(Consult.MoneyEarned) or 0) + Payout
			exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = GREATEST(Stock - ?,0), MoneyEarned = MoneyEarned + ? WHERE Permission = ?",{ Delivered, Payout, Departmenty })
				
			local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty,true)
			vRP.PermissionsUpdate(Departmenty,"Bank","+",Payout)
				
			table.insert(Datatable.Historical,{ Type = "Export", Player = { Passport = Passport, Name = vRP.FullName(Passport) }, Value = Payout, Amount = Delivered })
			vRP.SetSrvData("FuelStations:"..Departmenty,Datatable,true)
			return true
		else
			return false
		end
	end
		
	local shipmentSuccess = ProcessShipment()
	if not shipmentSuccess then
		if Job and Job.Passport == Passport then
			ActiveShipments[Departmenty] = nil
		end
			
		PlayerShipments[Passport] = nil
			
		TriggerClientEvent("fuelstations:Finish",source)
	end
		
	local Valuation = math.floor(Delivered * 2)
	if Valuation <= 0 then return end
		
	if exports.inventory:Buffs("Dexterity",Passport) then
		local OldValuation = Valuation
		Valuation = Valuation + math.floor(Valuation * 0.1)
	end
		
	vRP.GenerateItem(Passport,"dollar",Valuation,true)
	TriggerClientEvent("fuelstations:Notify",source,"Central","Pagamento no valor de $"..Valuation.." recebido ("..Job.Mode..").","verde")
		
	if Job and Job.Passport == Passport then
		ActiveShipments[Departmenty] = nil
	end
		
	PlayerShipments[Passport] = nil
		
	TriggerClientEvent("fuelstations:Finish",source)
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- OFFERJOBS
-----------------------------------------------------------------------------------------------------------------------------------------
-- TODO
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEJOB
-----------------------------------------------------------------------------------------------------------------------------------------
-- TODO
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEJOB
-----------------------------------------------------------------------------------------------------------------------------------------
-- TODO
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYJOB
-----------------------------------------------------------------------------------------------------------------------------------------
-- TODO
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Upgrades()
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then return false end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Upgrades) then
		return false
	end

	local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty,true)
	Datatable.Upgrades = Datatable.Upgrades or { Stock = 0, Truck = 0, Relationship = 0 }
	Datatable.Historical = Datatable.Historical or {}
	vRP.SetSrvData("FuelStations:"..Departmenty,Datatable,true)

	return {
		Stock = { Level = Datatable.Upgrades.Stock or 0, List = Config.Upgrades.Stock },
		Truck = { Level = Datatable.Upgrades.Truck or 0, List = Config.Upgrades.Truck },
		Relationship = { Level = Datatable.Upgrades.Relationship or 0, List = Config.Upgrades.Relationship }
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPGRADE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Upgrade(Mode)
	local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

	if not Passport or not Departmenty then return false end

	local Level = vRP.HasPermission(Passport,Departmenty)
	if not HasPermission(Level,Permissions[Passport].Upgrades) then
		return false
	end

	if not Mode or not Config.Upgrades[Mode] then
		return false
	end

	local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty,true)
	Datatable.Upgrades = Datatable.Upgrades or { Stock = 0, Truck = 0, Relationship = 0 }
	Datatable.Historical = Datatable.Historical or {}

	local CurrentLevel = Datatable.Upgrades[Mode] or 0
	local UpgradeData = Config.Upgrades[Mode][CurrentLevel + 1]

	if not UpgradeData then
		TriggerClientEvent("fuelstations:Notify",source,"Central","Todas as melhorias dessa categoria já foram adquiridas.","amarelo")
		return false
	end

	local Balance = vRP.Permissions(Departmenty,"Bank")
	if Balance < UpgradeData.Price then
		TriggerClientEvent("fuelstations:Notify",source,"Central","Saldo insuficiente no banco do posto.","amarelo")
		return false
	end

	vRP.PermissionsUpdate(Departmenty,"Bank","-",UpgradeData.Price)
	Datatable.Upgrades[Mode] = CurrentLevel + 1

	table.insert(Datatable.Historical,{ Type = "Upgrade", Player = { Passport = Passport, Name = vRP.FullName(Passport) }, Value = UpgradeData.Price, Upgrade = Mode, Level = CurrentLevel + 1 })
	vRP.SetSrvData("FuelStations:"..Departmenty,Datatable,true)

	TriggerClientEvent("fuelstations:Notify",source,"Sucesso","Melhoria aplicada com sucesso.","verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- EMPLOYEES
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Employees()
    local source = source
    local Passport = vRP.Passport(source)
    local Departmenty = Division[Passport]

    if not Passport or not Departmenty then
        return false
    end

    local Level = vRP.HasPermission(Passport,Departmenty)
    if not HasPermission(Level,Permissions[Passport].Employees.View) then
        return false
    end

    local Members = vRP.DataGroups(Departmenty) or {}
    local List = {}

    for Employee,Hierarchy in pairs(Members) do
        Employee = tonumber(Employee)
		local Calculated = CompleteTimers(vRP.Playing(Employee,Departmenty) or 0)
		local Status = (vRP.Source(Employee) and "Ativo há " or "Inativo há ") .. Calculated

        List[#List + 1] = { Passport = Employee, Name = vRP.FullName(Employee), Hierarchy = Hierarchy or 1, Status = Status }
    end

    return List
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVITEEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.InviteEmployee(TargetPassport)
    local source = source
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	
    local Level = vRP.HasPermission(Passport,Departmenty)
	if not Departmenty or not HasPermission(Level,Permissions[Passport].Employees.Create) then
		return false
	end

	TargetPassport = tonumber(TargetPassport)
	if not TargetPassport or vRP.HasPermission(TargetPassport,Departmenty) then
		return false
	end

	if vRP.AmountGroups(Departmenty) >= vRP.Permissions(Departmenty,"Members") then
		TriggerClientEvent("fuelstations:Notify",source,"Central","Limite de membros atingido.","amarelo")
		return false
	end

	local TargetSource = vRP.Source(TargetPassport)
	if not TargetSource then
		TriggerClientEvent("fuelstations:Notify",Source,"Central","Passaporte offline.","amarelo")
		return false
	end

	if vRP.Request(TargetSource,"Postos","Você foi convidado para o posto "..Departmenty..". Deseja aceitar?") then
		vRP.SetPermission(TargetPassport,Departmenty)
		TriggerClientEvent("fuelstations:Notify",source,"Central","Funcionário adicionado.","verde")
		return true
	end

	TriggerClientEvent("fuelstations:Notify",source,"Central","Convite recusado.","amarelo")
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HIERARCHYEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.HierarchyEmployee(Data)
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]
	
    local Level = vRP.HasPermission(Passport,Departmenty)
	if not Departmenty or not HasPermission(Level,Permissions[Passport].Employees.Edit) then
		return false
	end

	local Target = tonumber(Data.Passport)
	local Mode = Data.Mode == "Promote" and "Promote" or "Demote"
	
	if not Target or Target == Passport then
		return false
	end

	local TargetLevel = vRP.HasPermission(Target,Departmenty)
	if not TargetLevel then
		return false
	end

	if Mode == "Promote" and TargetLevel <= Level + 1 then
		return false
	end

	if Mode == "Demote" and not (Level < TargetLevel and TargetLevel < #vRP.Hierarchy(Departmenty)) then
		return false
	end

	vRP.SetPermission(Target,Departmenty,nil,Mode)
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISMISSEMPLOYEE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DismissEmployee(TargetPassport)
	local Passport = vRP.Passport(source)
	local Departmenty = Division[Passport]

    local Level = vRP.HasPermission(Passport,Departmenty)
	if not Departmenty or not HasPermission(Level,Permissions[Passport].Employees.Dismiss) then
		return false
	end

	TargetPassport = tonumber(TargetPassport)
	if not TargetPassport or TargetPassport == Passport then
		return false
	end

	local TargetLevel = vRP.HasPermission(TargetPassport,Departmenty)
	if not TargetLevel or TargetLevel <= Level then
		return false
	end

	vRP.RemovePermission(TargetPassport,Departmenty)
	PlayerShipments[TargetPassport] = nil
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- JOBS
-----------------------------------------------------------------------------------------------------------------------------------------
-- TODO
-----------------------------------------------------------------------------------------------------------------------------------------
-- STARTJOB
-----------------------------------------------------------------------------------------------------------------------------------------
-- TODO
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINISHJOB
-----------------------------------------------------------------------------------------------------------------------------------------
-- TODO
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPORTS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("UpdateStock", function(Departmenty,Amount,Mode,Value,Customer)
	local Consult = exports.oxmysql:single_async("SELECT * FROM fuelstations_creative WHERE Permission = ?",{ Departmenty })
	if not Consult or not Amount or Amount <= 0 then
		return false
	end

	if Mode == "-" and Consult.Stock < Amount then
		return false
	end

    local Datatable = vRP.GetSrvData("FuelStations:"..Departmenty,true)

	if Mode == "-" then
		exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = GREATEST(Stock - ?,0), MoneyEarned = MoneyEarned + ?, Visits = Visits + 1 WHERE Permission = ?",{ Amount, Value or 0, Departmenty })

		if Value and Value > 0 then

            table.insert(Datatable.Historical, { Type = "Fuel", Player = { Passport = Customer or 0, Name = Customer and vRP.FullName(Customer) or "Cliente" }, Value = Value, Amount = Amount })
            vRP.SetSrvData("FuelStations:"..Departmenty,Datatable,true)
		end
	else
        local MaxStock = Config.DefaultMaxStock + SumUpgrade(Config.Upgrades.Stock,Datatable.Upgrades.Stock)
		
		exports.oxmysql:update_async("UPDATE fuelstations_creative SET Stock = LEAST(Stock + ?, ?) WHERE Permission = ?",{ Amount, MaxStock, Departmenty })
	end

	return true
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Connect",function(Passport,source)
	local Result = {}
	local Consult = exports.oxmysql:query_async("SELECT * FROM fuelstations_creative")

	for _,v in ipairs(Consult) do
		Result[v.Permission] = { Name = v.Name, Color = v.Color, Blip = v.Blip, Model = Locations[v.Permission].Model, Coords = Locations[v.Permission].Coords, Anim = Locations[v.Permission].Anim, BlipCoords = Locations[v.Permission].BlipCoords }
	end

	TriggerClientEvent("fuelstations:Connect",source,Result)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Division[Passport] then
		Division[Passport] = nil
	end

	if Permissions[Passport] then
		Permissions[Passport] = nil
	end

    if PlayerShipments[Passport] then
        PlayerShipments[Passport] = nil
    end
end)