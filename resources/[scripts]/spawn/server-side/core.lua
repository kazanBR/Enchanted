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
Tunnel.bindInterface("spawn",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Playing = {}
local Creating = {}
local Connected = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Characters()
	local List = {}
	local source = source

	local License = vRP.Identities(source)
	if not License or Connected[License] then
		DropPlayer(source,"Não foi possível efetuar conexão com a "..(BaseMode == "steam" and "Steam" or "Rockstar")..".")

		return List
	end

	exports.vrp:Bucket(source,"Enter",50000 + source)

	local Consult = vRP.Query("characters/Characters",{ License = License })
	for _,v in ipairs(Consult) do
		local Passport = tonumber(v.id)

		local Sex = (v.Skin == "mp_f_freemode_01") and "F" or "M"

		if tonumber(v.SkinMontly) ~= 0 and tonumber(v.SkinMontly) <= os.time() then
			vRP.SkinCharacter(Passport,v.Sex == "M" and "mp_m_freemode_01" or "mp_f_freemode_01")
		end

		table.insert(List,{
			Passport = Passport,
			Skin = v.Skin,
			Name = v.Name.." "..v.Lastname,
			Sexo = Sex,
			Bank = v.Bank,
			Playing = vRP.Playing(Passport,"Online"),
			LastLogin = v.Login,
			CreatedAt = v.Created,
			Ped = v.SkinMontly,
			Blood = Sanguine(v.Blood),
			Clothes = vRP.UserData(Passport,"Clothings"),
			Barber = vRP.UserData(Passport,"Barbershop"),
			Tattoos = vRP.UserData(Passport,"Tattooshop")
		})
	end

	return List
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Config()
    local source = source    
	local License = vRP.Identities(source)

	if not License or Connected[License] then
		DropPlayer(source,"Não foi possível efetuar conexão com a "..(BaseMode == "steam" and "Steam" or "Rockstar")..".")
		return {}
	end
	
	return { Slots = vRP.Account(License).Characters, Gemstone = vRP.UserGemstone(License) }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PURCHASESLOT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PurchaseSlot()
	local source = source

	local License = vRP.Identities(source)
	if not License or Connected[License] then
		DropPlayer(source,"Não foi possível efetuar conexão com a "..(BaseMode == "steam" and "Steam" or "Rockstar")..".")

		return false
	end

	local CurrentGemstone = vRP.UserGemstone(License)

	if parseInt(CurrentGemstone) < SlotPrice then
		return false
	end
	
	vRP.Query("accounts/RemoveGemstone",{ License = License, Gemstone = SlotPrice })
	vRP.Query("accounts/UpdateCharacters",{ License = License })
	TriggerClientEvent("spawn:Notify",source,"Sucesso","Compra concluida.","verde")
	TriggerClientEvent("hud:RemoveGemstone",source,SlotPrice)

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHARACTERCHOSEN
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CharacterChosen(Passport)
	local source = source
	if not Playing[source] and Passport then
		Playing[source] = true

		local License = vRP.Identities(source)
		if not License or Connected[License] then
			DropPlayer(source,"Não foi possível efetuar conexão com a "..(BaseMode == "steam" and "Steam" or "Rockstar")..".")

			return false
		end

		local Consult = vRP.SingleQuery("characters/UserLicense",{ Passport = Passport, License = License })
		if Consult and not Connected[Consult.License] then
			vRP.CharacterChosen(source,Passport)
			Connected[Consult.License] = true

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- NEWCHARACTER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.NewCharacter(Name,Lastname,Sex)
	local source = source
	if not Creating[source] then
		Creating[source] = true

		local License = vRP.Identities(source)
		if not License or Connected[License] then
			DropPlayer(source,"Não foi possível efetuar conexão com a "..(BaseMode == "steam" and "Steam" or "Rockstar")..".")
			Creating[source] = nil

			return false
		end

		local Account = vRP.Account(License)
		if Account and Account.Characters <= vRP.Scalar("characters/Count",{ License = License }) then
			TriggerClientEvent("Notify",source,"Atenção","Limite de personagem atingido.","amarelo",5000)
			Creating[source] = nil

			return false
		end

		local Name = FirstName(Name)
		local Lastname = FirstName(Lastname)
		local Consult = exports.oxmysql:insert_async("INSERT INTO characters (License,Name,Lastname,Skin,Blood,Created) VALUES (@License,@Name,@Lastname,@Skin,@Blood,UNIX_TIMESTAMP())",{ License = License, Name = Name, Lastname = Lastname, Skin = Sex, Blood = math.random(4) })
		if Consult then
			Creating[source] = nil
			vRPC.DoScreenFadeOut(source)
			vRP.CharacterChosen(source,Consult,Sex)

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source,License)
	Connected[License] = nil
	Creating[source] = nil
end)