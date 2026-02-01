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
Tunnel.bindInterface("party",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local AmountRooms = 0
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIG
-----------------------------------------------------------------------------------------------------------------------------------------
local Config = {
	Room = {},
	Users = {}
}
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETROOMS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetRooms()
	local Rooms = {}
	local source = source
	local Passport = vRP.Passport(source)
	if Passport then
		for Index,v in pairs(Config.Room) do
			table.insert(Rooms,{
				Value = "",
				Id = v.Id,
				Created = Index,
				Name = v.Name,
				Identity = v.Identity,
				Password = v.Password or false,
				Users = CountTable(v.Users)
			})
		end
	end

	return {
		group = Config.Users[Passport] or false,
		room = Rooms
	}
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMEMBERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetMembers(Number)
	local source = source
	local Number = parseInt(Number)
	local Passport = vRP.Passport(source)
	if Passport and Config.Room[Number] and Config.Room[Number].Users then
		local Table = {}
		for OtherPassport in pairs(Config.Room[Number].Users) do
			table.insert(Table,{
				Passport = OtherPassport,
				Name = vRP.FullName(OtherPassport)
			})
		end

		return {
			Id = Number,
			Members = Table,
			Name = Config.Room[Number].Name,
			Created = Config.Room[Number].Created,
			Identity = Config.Room[Number].Identity,
			Users = CountTable(Config.Room[Number].Users)
		}
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEROOM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateRoom(Name,Password)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and not Config.Users[Passport] then
		AmountRooms = AmountRooms + 1

		Config.Room[AmountRooms] = {
			Id = AmountRooms,
			Created = Passport,
			Identity = vRP.FullName(Passport),
			Name = Name,
			Password = Password,
			Users = {
				[Passport] = source
			}
		}

		Config.Users[Passport] = AmountRooms

		return {
			group = AmountRooms,
			room = {
				Name = Name,
				Id = AmountRooms,
				Created = Passport,
				Password = Password,
				Identity = Config.Room[AmountRooms].Identity,
				Users = CountTable(Config.Room[AmountRooms].Users)
			}
		}
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- LEAVEROOM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.LeaveRoom()
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and Config.Users[Passport] then
		local Number = Config.Users[Passport]
		if Config.Room[Number] and Config.Room[Number].Users and Config.Room[Number].Users[Passport] then
			for _,Sources in pairs(Config.Room[Number].Users) do
				async(function()
					TriggerClientEvent("party:Dismiss",Sources,source)
				end)
			end

			Config.Users[Passport] = nil
			Config.Room[Number].Users[Passport] = nil
			TriggerClientEvent("party:Clear",source)

			if Config.Room[Number].Created == Passport then
				for OtherPassport,v in pairs(Config.Room[Number].Users) do
					TriggerClientEvent("party:ResetNui",v)
					Config.Users[OtherPassport] = nil
				end

				Config.Room[Number] = nil
			elseif CountTable(Config.Room[Number].Users) <= 0 then
				Config.Room[Number] = nil
			end

			return true
		end
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- KICKROOM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.KickRoom(Number,OtherPassport)
	local source = source
	local Number = parseInt(Number)
	local Passport = vRP.Passport(source)
	local OtherSource = vRP.Source(OtherPassport)
	if Passport and Config.Users[OtherPassport] and Config.Room[Number] and Config.Room[Number].Created == Passport and Config.Room[Number].Created ~= OtherPassport and Config.Room[Number].Users and Config.Room[Number].Users[OtherPassport] then
		if OtherSource then
			TriggerClientEvent("party:Clear",OtherSource)
			TriggerClientEvent("party:ResetNui",OtherSource)

			for _,Sources in pairs(Config.Room[Number].Users) do
				async(function()
					TriggerClientEvent("party:Dismiss",Sources,OtherSource)
				end)
			end
		end

		Config.Users[OtherPassport] = nil
		Config.Room[Number].Users[OtherPassport] = nil

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ENTERROOM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.EnterRoom(Number,Password)
	local source = source
	local Number = parseInt(Number)
	local Passport = vRP.Passport(source)
	if Passport and not Config.Users[Passport] and Config.Room[Number] and Config.Room[Number].Users and CountTable(Config.Room[Number].Users) <= 9 and not Config.Room[Number].Users[Passport] then
		if Config.Room[Number].Password and Config.Room[Number].Password ~= Password then
			return false
		end

		Config.Users[Passport] = Number
		Config.Room[Number].Users[Passport] = source

		for Passports,Sources in pairs(Config.Room[Number].Users) do
			TriggerClientEvent("party:Invite",source,Sources,vRP.LowerName(Passports))

			async(function()
				TriggerClientEvent("party:Invite",Sources,source,vRP.LowerName(Passport))
			end)
		end

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ROOM
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Room",function(Passport,source,Radius,Max)
	local Members = {}
	local Number = Config.Users[Passport]

	if not (Number and Config.Room[Number]) then
		return Members,0
	end

	if not vRP.DoesEntityExist(source) then
		return Members,0
	end

	local Coords = vRP.GetEntityCoords(source)
	for OtherPassport,OtherSource in pairs(Config.Room[Number].Users) do
		if vRP.DoesEntityExist(OtherSource) and #(Coords - vRP.GetEntityCoords(OtherSource)) <= Radius then
			table.insert(Members, { Passport = OtherPassport, Source = OtherSource })

			if Max and #Members >= Max then
				break
			end
		end
	end

	return Members,#Members
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DOESEXIST
-----------------------------------------------------------------------------------------------------------------------------------------
exports("DoesExist",function(Passport,Players)
	if not Config.Users[Passport] then
		return false
	end

	if Players then
		local source = vRP.Source(Passport)
		local Members = exports.party:Room(Passport,source,25)

		return #Members >= Players and Members or false
	end

	return Config.Users[Passport]
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport,source)
	local Number = Config.Users[Passport]
	if not Number then
		return false
	end

	for _,OtherSource in pairs(Config.Room[Number].Users or {}) do
		async(function()
			TriggerClientEvent("party:Dismiss",OtherSource,source)
		end)
	end

	Config.Users[Passport] = nil
	Config.Room[Number].Users[Passport] = nil

	if CountTable(Config.Room[Number].Users) == 0 then
		Config.Room[Number] = nil
	end
end)