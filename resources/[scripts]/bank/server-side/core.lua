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
Tunnel.bindInterface("bank",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Active = {}
local Cooldown = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- THREADACTIVES
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		if os.time() >= Cooldown then
			Cooldown = os.time() + 3600
			vRP.Update("investments/Actives")
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HOME
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Home()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		local Yield = 0
		local Identity = vRP.Identity(Passport)

		local InvestmentCheck = vRP.Query("investments/Check",{ Passport = Passport })
		if InvestmentCheck[1] then
			Yield = InvestmentCheck[1].Monthly
		end

		return {
			yield = Yield,
			balance = Identity.Bank,
			cardnumber = "0000 0000 0000 "..1000 + Passport,
			transactions = Transactions(Passport),
			dependents = Dependents(Passport)
		}
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDDEPENDENTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AddDependents(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and OtherPassport ~= Passport then
		Active[Passport] = true

		local Check = vRP.Query("dependents/Check",{ Passport = Passport, Dependent = OtherPassport })
		if not Check[1] then
			local OtherSource = vRP.Source(OtherPassport)
			if OtherSource then
				if vRP.Request(OtherSource,"Banco","<b>"..vRP.FullName(Passport).."</b> deseja convida-lo para sua lista de dependentes bancário, você aceita esse convite?") then
					vRP.Query("dependents/Add",{ Passport = Passport, Dependent = OtherPassport, Name = vRP.FullName(OtherPassport) })
					vRP.GiveItem(OtherPassport,"creditcard-"..Passport,1,true)
					Active[Passport] = nil

					return vRP.FullName(OtherPassport)
				end
			end
		end

		Active[Passport] = nil
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVEDEPENDENTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveDependents(OtherPassport)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] then
		Active[Passport] = true

		local Consult = vRP.Query("dependents/Check",{ Passport = Passport, Dependent = OtherPassport })
		if Consult[1] then
			vRP.Query("dependents/Remove",{ Passport = Passport, Dependent = OtherPassport })
			Active[Passport] = nil

			return true
		end

		Active[Passport] = nil
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSACTIONHISTORIY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.TransactionHistory()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		return Transactions(Passport,50)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEPOSIT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Deposit(Valuation)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and parseInt(Valuation) > 0 then
		Active[Passport] = true

		if vRP.ConsultItem(Passport,"dollar",Valuation) and vRP.TakeItem(Passport,"dollar",Valuation) then
			vRP.GiveBank(Passport,Valuation)
		end

		Active[Passport] = nil

		return {
			balance = vRP.Identity(Passport).Bank,
			transactions = Transactions(Passport)
		}
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- WITHDRAW
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Withdraw(Valuation)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and vRP.GetBank(Passport) >= Valuation then
		Active[Passport] = true

		if not exports.bank:CheckTaxs(Passport) and not exports.bank:CheckFines(Passport) and vRP.WithdrawCash(Passport,Valuation) then
			Active[Passport] = nil
		end

		return {
			balance = vRP.Identity(Passport).Bank,
			transactions = Transactions(Passport)
		}
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSFER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Transfer(OtherPassport,Valuation)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and OtherPassport ~= Passport and parseInt(Valuation) > 0 and not exports.bank:CheckTaxs(Passport) and not exports.bank:CheckFines(Passport) then
		Active[Passport] = true

		if vRP.Identity(OtherPassport) and vRP.PaymentBank(Passport,Valuation,true) then
			vRP.GiveBank(OtherPassport,Valuation)
		end

		Active[Passport] = nil
	end

	return {
		balance = vRP.Identity(Passport).Bank,
		transactions = Transactions(Passport)
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TRANSACTIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Transactions(Passport,Limit)
	local Transaction = {}
	local TransactionList = vRP.Query("transactions/List",{ Passport = Passport, Limit = Limit or 4 })
	if #TransactionList > 0 then
		for _,v in pairs(TransactionList) do
			Transaction[#Transaction + 1] = {
				type = v.Type,
				date = v.Date,
				value = v.Price,
				balance = v.Balance
			}
		end
	end

	return Transaction
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEPENDENTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Dependents(Passport)
	local Dependents = {}
	local DependentList = vRP.Query("dependents/List",{ Passport = Passport })
	if #DependentList > 0 then
		for _,v in pairs(DependentList) do
			Dependents[#Dependents + 1] = {
				name = v.Name,
				passport = v.Dependent
			}
		end
	end

	return Dependents
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINES
-----------------------------------------------------------------------------------------------------------------------------------------
function Fines(Passport)
	local Table = {}
	local Consult = exports.oxmysql:query_async("SELECT id,Officer,Fine,Date,Hour,Description FROM mdt_creative_fines WHERE Passport = ? AND Paid = 0",{ Passport })
	if Consult[1] then
		for _,v in ipairs(Consult) do
			table.insert(Table,{
				id = v.id,
				name = ("Multa recebida por %s"):format(vRP.FullName(v.Officer)),
				value = v.Fine,
				date = v.Date,
				hour = v.Hour,
				message = v.Description
			})
		end
	end

	return Table
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINELIST
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.FineList()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport then
		return {}
	end

	return Fines(Passport)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINEPAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.FinePayment(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	Active[Passport] = true

	local Success = false
	local Consult = exports.oxmysql:single_async("SELECT id,Fine FROM mdt_creative_fines WHERE Passport = @Passport AND Paid = 0 AND id = @Number LIMIT 1",{ Passport = Passport, Number = Number })
	if Consult and vRP.PaymentBank(Passport,Consult.Fine) then
		exports.oxmysql:update_async("UPDATE mdt_creative_fines SET Paid = 1 WHERE Passport = @Passport AND id = @Number",{ Passport = Passport, Number = Number })
		Success = true
	end

	Active[Passport] = nil

	return Success
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- FINEPAYMENTALL
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.FinePaymentAll()
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return {}
	end

	Active[Passport] = true

	local Consult = exports.oxmysql:query_async("SELECT id, Fine FROM mdt_creative_fines WHERE Passport = @Passport AND Paid = 0",{ Passport = Passport })
	for _,v in ipairs(Consult or {}) do
		if vRP.PaymentBank(Passport,v.Fine) then
			exports.oxmysql:update_async("UPDATE mdt_creative_fines SET Paid = 1 WHERE Passport = @Passport AND id = @id",{ Passport = Passport, id = v.id })
		end
	end

	Active[Passport] = nil

	return Fines(Passport)
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAXS
-----------------------------------------------------------------------------------------------------------------------------------------
function Taxs(Passport)
	local Taxs = {}
	local TaxList = vRP.Query("taxs/List",{ Passport = Passport })
	for _,v in ipairs(TaxList or {}) do
		table.insert(Taxs,{
			id = v.id,
			name = v.Name,
			value = v.Price,
			date = v.Date,
			hour = v.Hour,
			message = v.Message
		})
	end

	return Taxs
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAXLIST
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.TaxList()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		return Taxs(Passport)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAXPAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.TaxPayment(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or Active[Passport] then
		return false
	end

	Active[Passport] = true

	local Success = false
	local Consult = vRP.SingleQuery("taxs/Check",{ Passport = Passport, id = Number })
	if Consult and vRP.PaymentBank(Passport,Consult.Price) then
		vRP.Query("taxs/Remove",{ Passport = Passport, id = Number })
		Success = true
	end

	Active[Passport] = nil

	return Success
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVOICELIST
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.InvoiceList()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		return Invoices(Passport)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MAKEINVOICE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.MakeInvoice(OtherPassport,Valuation,Reason)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and OtherPassport ~= Passport and parseInt(Valuation) > 0 then
		Active[Passport] = true

		local OtherSource = vRP.Source(OtherPassport)
		if OtherSource then
			if vRP.Request(OtherSource,"Banco","<b>"..vRP.FullName(Passport).."</b> lhe enviou uma fatura de <b>R$"..Dotted(Valuation).."</b>, deseja aceita-la?") then
				vRP.Query("invoices/Add",{ Passport = OtherPassport, Received = Passport, Type = "received", Reason = Reason, Holder = vRP.FullName(Passport), Price = Valuation })
				vRP.Query("invoices/Add",{ Passport = Passport, Received = OtherPassport, Type = "sent", Reason = Reason, Holder = "Você", Price = Valuation })
				Active[Passport] = nil

				return Invoices(Passport)
			end
		end

		Active[Passport] = nil
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVOICEPAYMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.InvoicePayment(Number)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] then
		Active[Passport] = true

		local Invoice = vRP.Query("invoices/Check",{ id = Number })
		if Invoice[1] then
			if vRP.PaymentBank(Passport,Invoice[1].Price) then
				vRP.GiveBank(Invoice[1].Received,Invoice[1].Price)
				vRP.Query("invoices/Remove",{ id = Number })
				Active[Passport] = nil

				return true
			end
		end

		Active[Passport] = nil
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVOICES
-----------------------------------------------------------------------------------------------------------------------------------------
function Invoices(Passport)
	local Invoices = {}
	local InvoiceList = vRP.Query("invoices/List",{ Passport = Passport })
	if #InvoiceList > 0 then
		for _,v in pairs(InvoiceList) do
			local Type = v.Type

			if not Invoices[Type] then
				Invoices[Type] = {}
			end

			Invoices[Type][#Invoices[Type] + 1] = {
				id = v.id,
				reason = v.Reason,
				holder = v.Holder,
				value = v.Price
			}
		end
	end

	return Invoices
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVESTMENTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Investments()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		local Total,Brute,Liquid,Deposit = 0,0,0,0
		local InvestmentCheck = vRP.Query("investments/Check",{ Passport = Passport })
		if InvestmentCheck[1] then
			Total = InvestmentCheck[1].Deposit + InvestmentCheck[1].Liquid
			Brute = InvestmentCheck[1].Deposit
			Liquid = InvestmentCheck[1].Liquid
			Deposit = InvestmentCheck[1].Deposit
		end

		return {
			total = Total,
			brute = Brute,
			liquid = Liquid,
			deposit = Deposit
		}
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVEST
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Invest(Valuation)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] and parseInt(Valuation) > 0 then
		Active[Passport] = true

		if vRP.PaymentBank(Passport,Valuation,true) then
			local InvestmentCheck = vRP.Query("investments/Check",{ Passport = Passport })
			if InvestmentCheck[1] then
				vRP.Update("investments/Invest",{ Passport = Passport, Price = Valuation })
			else
				vRP.Query("investments/Add",{ Passport = Passport, Deposit = Valuation })
			end

			Active[Passport] = nil

			return true
		end

		Active[Passport] = nil
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVESTRESCUE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.InvestRescue()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Active[Passport] then
		Active[Passport] = true

		local InvestmentCheck = vRP.Query("investments/Check",{ Passport = Passport })
		if InvestmentCheck[1] then
			local Valuation = InvestmentCheck[1].Deposit + InvestmentCheck[1].Liquid
			vRP.Query("investments/Remove",{ Passport = Passport })
			vRP.GiveBank(Passport,Valuation)
		end

		Active[Passport] = nil
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDTAXS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("AddTaxs",function(Passport,source,Name,Valuation,Message)
	local Valuation = Valuation * 0.1
	for Permission,Multiplier in pairs({ Ouro = 0.65, Prata = 0.75, Bronze = 0.85 }) do
		if vRP.HasService(Passport,Permission) then
			Valuation = Valuation * Multiplier
		end
	end

	if Valuation > 1 then
		vRP.Query("taxs/Add",{ Passport = Passport, Name = Name, Date = os.date("%d/%m/%Y"), Hour = os.date("%H:%M"), Price = Valuation, Message = Message })
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKTAXS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("CheckTaxs",function(Passport)
	local Passport = Passport
	local source = vRP.Source(Passport)
	if Passport and source and exports.oxmysql:single_async("SELECT * FROM taxs WHERE Passport = ? AND CURDATE() >= DATE_ADD(STR_TO_DATE(`Date`,'%d/%m/%Y'),INTERVAL 1 DAY) LIMIT 1",{ Passport }) then
		TriggerClientEvent("Notify",source,"Impostos","Você possui débitos bancários.","amarelo",5000)
		return true
	end

	return false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECKFINES
-----------------------------------------------------------------------------------------------------------------------------------------
exports("CheckFines",function(Passport)
	local Passport = Passport
	local source = vRP.Source(Passport)
	if Passport and source and exports.oxmysql:single_async("SELECT * FROM mdt_creative_fines WHERE Passport = ? AND (Timestamp + 86400) < UNIX_TIMESTAMP() AND Paid = 0 LIMIT 1",{ Passport }) then
		TriggerClientEvent("Notify",source,"Multas","Você possui débitos bancários.","amarelo",5000)
		return true
	end

	return false
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDTAXS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("AddTransactions",function(Passport,Type,Valuation)
	vRP.Query("transactions/Add",{ Passport = Passport, Type = Type, Date = os.date("%d/%m/%Y"), Price = Valuation, Balance = vRP.GetBank(Passport) })
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Active[Passport] then
		Active[Passport] = nil
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- EXPORTS
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Taxs",Taxs)
exports("Fines",Fines)
exports("Invoices",Invoices)
exports("Dependents",Dependents)
exports("Transactions",Transactions)