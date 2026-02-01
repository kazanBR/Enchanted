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
Tunnel.bindInterface("helicrash",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- TUNNEL
-----------------------------------------------------------------------------------------------------------------------------------------
vKEYBOARD = Tunnel.getInterface("keyboard")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local ActivePlayers = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
GlobalState.Helibox = 0
GlobalState.Helifire = 0
GlobalState.Helicrash = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- HELICRASH
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("helicrash",function(source)
	local Passport = vRP.Passport(source)
	if not Passport or not vRP.HasGroup(Passport,"Admin") or GlobalState.Helicrash then
		return false
	end

	local Options = {}
	for Name in pairs(Components) do
		Options[#Options + 1] = Name
	end

	local Keyboard = vKEYBOARD.Instagram(source,Options)
	if not Keyboard or not Keyboard[1] then
		return false
	end

	local Selected = Keyboard[1]
	local Table = Components[Selected]
	if not Table then
		TriggerClientEvent("Notify",source,"Erro","Componente inválido selecionado.","vermelho",5000)
		return false
	end

	local Loots = Table.Loots
	local MultRange = Table.Multiplier
	local MultiBox = CountTable(Table.Coords)

	for Number = 1,MultiBox do
		local Multiplier = math.random(MultRange.Min,MultRange.Max)
		if vRP.MountContainer(Passport,"Helicrash:"..Number,Loots,Multiplier) then
			TriggerEvent("chest:Cooldown","Helicrash:"..Number)
		end
	end

	TriggerClientEvent("Notify",-1,"Queda da Aeronave","Mayday! Mayday! Tivemos problemas técnicos em nossos motores e estamos em queda livre.","verde",30000)

	GlobalState.Helibox = MultiBox
	GlobalState.Helifire = GlobalState.Work + 60
	GlobalState.Helicrash = Selected
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- PROGRESS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Progress(Mode)
	if not GlobalState.Helicrash then
		return false
	end

	local source = source
	local Passport = vRP.Passport(source)
	if not Passport or not GlobalState.Helicrash then
		return false
	end

	if Mode == "Enter" then
		if ActivePlayers[Passport] then
			return false
		end

		ActivePlayers[Passport] = { Source = source, Name = vRP.FullName(Passport) }
	elseif Mode == "Exit" then
		local Active = ActivePlayers[Passport]
		if not Active then
			return false
		end

		ActivePlayers[Passport] = nil
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HELICRASH:KILLFEED
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.KillFeed(OtherSource)
	if not GlobalState.Helicrash then
		return false
	end

	local source = source
	local Passport = vRP.Passport(source)
	local OtherPassport = vRP.Passport(OtherSource)
	if not (Passport and OtherPassport and Passport ~= OtherPassport) then
		return false
	end

	local VictimActive = ActivePlayers[Passport]
	local AttackerActive = ActivePlayers[OtherPassport]
	if not (AttackerActive and VictimActive) then
		return false
	end

	ActivePlayers[Passport] = nil

	local VictimName = VictimActive.Name
	local AttackerName = AttackerActive.Name

	for _,v in pairs(ActivePlayers) do
		async(function()
			TriggerClientEvent("domination:KillFeed",v.Source,AttackerName,VictimName)
		end)
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Helibox",nil,function(_,_,Value)
	if Value <= 0 then
		GlobalState.Helicrash = false
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	local Active = ActivePlayers[Passport]
	if not Active then
		return false
	end

	ActivePlayers[Passport] = nil
end)