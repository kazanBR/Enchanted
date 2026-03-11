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
Tunnel.bindInterface("painel",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Permission = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- PAINEL:OPEN
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("painel:Open")
AddEventHandler("painel:Open",function(Group)
	local source = source
	local Passport = vRP.Passport(source)
	if Passport and vRP.HasPermission(Passport,Group) then
		Permission[Passport] = Group
	else
		Permission[Passport] = nil
	end

	TriggerClientEvent("dynamic:Close",source)
	TriggerClientEvent("painel:Opened",source)
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEPARTMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Department()
	local source = source
	local Passport = vRP.Passport(source)
	return Passport and Permission[Passport] or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PLAYER
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Player()
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local Disabled = Config.Disabled[Group] or {}
	local GroupInfo = Groups[Group] or {}
	local Hierarchy = vRP.Hierarchy(Group)
	local DefaultPermission = tonumber(Level) == 1
	local Permissions = {
		Management = { View = DefaultPermission, Create = DefaultPermission, Edit = DefaultPermission, Dismiss = DefaultPermission },
		Announcements = { Create = DefaultPermission, Edit = DefaultPermission, Delete = DefaultPermission },
		Tags = { View = DefaultPermission, Create = DefaultPermission, Assign = DefaultPermission, Edit = DefaultPermission, Delete = DefaultPermission },
		Bank = { View = DefaultPermission, Deposit = DefaultPermission, Withdraw = DefaultPermission, Transfer = DefaultPermission },
		Goals = { MyGoals = DefaultPermission, All = DefaultPermission, Edit = DefaultPermission },
		Perks = DefaultPermission
	}

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			for Key,Value in pairs(LevelData) do
				if type(Permissions[Key]) == "table" and type(Value) == "table" then
					for SubKey,SubValue in pairs(Value) do
						if type(Permissions[Key][SubKey]) == "boolean" then
							Permissions[Key][SubKey] = SubValue and true or false
						end
					end
				elseif type(Permissions[Key]) == "boolean" then
					Permissions[Key] = Value and true or false
				end
			end
		end
	end

	return { Group = Group, Disabled = Disabled, Player = { Name = vRP.FullName(Passport), Level = Level, Passport = Passport }, GroupData = { Name = GroupInfo.Name or Group, Hierarchy = Hierarchy }, Permissions = Permissions }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANNOUNCEMENTS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Announcements()
    local source = source
    local Passport = vRP.Passport(source)
    local Group = Passport and Permission[Passport]
    if not Passport or not Group then
        return {}
    end

    if not vRP.HasPermission(Passport,Group) then
        return {}
    end

    local Result = exports.oxmysql:query_async("SELECT id AS Id, Title, Description, Timestamp AS Date, Updated, Permission FROM painel_creative_announcements WHERE LOWER(Permission) = LOWER(@Permission) ORDER BY COALESCE(Updated, Timestamp) DESC, id DESC",{ Permission = Group })
    return Result
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATEANNOUNCEMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateAnnouncement(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Data then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = tonumber(Level) == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Announcements
			if type(Category) == "table" then
				local Value = Category.Create
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Count = exports.oxmysql:scalar_async("SELECT COUNT(*) FROM painel_creative_announcements WHERE LOWER(Permission) = LOWER(@Permission)",{ Permission = Group }) or 0
	local Max = vRP.Permissions(Group,"Announces") or 0
	if Count >= Max then
		TriggerClientEvent("painel:Notify",source,"Atencao","Limite de anuncios atingido.","amarelo")
		return false
	end

	local Inserted = exports.oxmysql:insert_async( "INSERT INTO painel_creative_announcements (Title,Description,Timestamp,Permission) VALUES (?,?,?,?)", { Data.Title,Data.Description,os.time(),Group } )
	TriggerClientEvent("painel:Notify",source,"Sucesso","Aviso criado.","verde")
	TriggerClientEvent("painel:Close",source)
	return Inserted or false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATEANNOUNCEMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateAnnouncement(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Data or not (Data.Id or Data.id) then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = tonumber(Level) == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Announcements
			if type(Category) == "table" then
				local Value = Category.Edit
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local RawId = Data.Id or Data.id
	local Id = tonumber(RawId) or tonumber((tostring(RawId or "")):match("%d+"))
	if not Id then
		TriggerClientEvent("painel:Notify",source,"Erro","Identificador inválido.","vermelho")
		return false
	end
	local Exists = exports.oxmysql:single_async("SELECT id FROM painel_creative_announcements WHERE id = ? AND LOWER(Permission) = LOWER(?)",{ Id,Group })
	if not Exists then
		TriggerClientEvent("painel:Notify",source,"Erro","Aviso não localizado ou sem permissão.","vermelho")
		return false
	end

	local Affected = exports.oxmysql:update_async( "UPDATE painel_creative_announcements SET Title = ?, Description = ?, Updated = ? WHERE id = ? AND LOWER(Permission) = LOWER(?)", { Data.Title,Data.Description,os.time(),Id,Group } )
	local Success = (Affected ~= nil and Affected ~= false)
	TriggerClientEvent("painel:Close",source)
	TriggerClientEvent("painel:Notify",source, Success and "Sucesso" or "Erro", Success and "Aviso atualizado." or "Falha ao atualizar.", Success and "verde" or "vermelho")
	return Success
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYANNOUNCEMENT
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyAnnouncement(Identifier)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Identifier then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = tonumber(Level) == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Announcements
			if type(Category) == "table" then
				local Value = Category.Delete
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local RawId = Identifier
	local Id = tonumber(RawId) or tonumber((tostring(RawId or "")):match("%d+"))
	if not Id then
		TriggerClientEvent("painel:Notify",source,"Erro","Identificador inválido.","vermelho")
		return false
	end

	exports.oxmysql:execute_async("DELETE FROM painel_creative_announcements WHERE id = ? AND LOWER(Permission) = LOWER(?)",{ Id,Group })
	local ExistsAfter = exports.oxmysql:single_async("SELECT id FROM painel_creative_announcements WHERE id = ? AND LOWER(Permission) = LOWER(?)",{ Id,Group })
	if not ExistsAfter then
		TriggerClientEvent("painel:Notify",source,"Sucesso","Aviso removido.","verde")
		TriggerClientEvent("painel:Close",source)
		return true
	else
		TriggerClientEvent("painel:Notify",source,"Erro","Aviso não localizado ou sem permissão.","vermelho")
		return false
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Permissions()
    local source = source
    local Passport = vRP.Passport(source)
    local Group = Passport and Permission[Passport]
    if not Passport or not Group then
        return false
    end

    local Level = vRP.HasPermission(Passport,Group)
    if not Level or Level ~= 1 then
        return false
    end

    local Hierarchy = vRP.Hierarchy(Group)
    local Stored = vRP.GetSrvData("Painel:Permissions:"..Group, true) or {}
    local MetaData = type(Stored) == "table" and Stored.__Meta
    local Version = type(MetaData) == "table" and MetaData.Version or 0
    local Response = {}

    for Index = 1,#Hierarchy do
        local Key = tostring(Index)
        local DefaultPermission = Index == 1
        local Template = {
            Management = { View = DefaultPermission, Create = DefaultPermission, Edit = DefaultPermission, Dismiss = DefaultPermission },
            Announcements = { Create = DefaultPermission, Edit = DefaultPermission, Delete = DefaultPermission },
            Tags = { View = DefaultPermission, Create = DefaultPermission, Assign = DefaultPermission, Edit = DefaultPermission, Delete = DefaultPermission },
            Bank = { View = DefaultPermission, Deposit = DefaultPermission, Withdraw = DefaultPermission, Transfer = DefaultPermission },
            Goals = { MyGoals = DefaultPermission, All = DefaultPermission, Edit = DefaultPermission },
            Perks = DefaultPermission
        }
		
        if Version >= 1 and type(Stored[Key]) == "table" then
            for Category,Value in pairs(Stored[Key]) do
                if type(Template[Category]) == "table" and type(Value) == "table" then
                    for SubKey,SubValue in pairs(Value) do
                        if type(Template[Category][SubKey]) == "boolean" then
                            Template[Category][SubKey] = SubValue and true or false
                        end
                    end
                elseif type(Template[Category]) == "boolean" then
                    Template[Category] = Value and true or false
                end
            end
        end

        Response[Key] = Template
    end

    return Response
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAVEPERMISSIONS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.SavePermissions(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	
	if not Passport or not Group or not Data or type(Data) ~= "table" then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level or Level ~= 1 then
		return false
	end

	local Hierarchy = vRP.Hierarchy(Group)
	local Result = {}

	for Index = 1,#Hierarchy do
		local Key = tostring(Index)
		local DefaultPermission = Index == 1
		local Template = {
			Management = { View = DefaultPermission, Create = DefaultPermission, Edit = DefaultPermission, Dismiss = DefaultPermission },
			Announcements = { Create = DefaultPermission, Edit = DefaultPermission, Delete = DefaultPermission },
			Tags = { View = DefaultPermission, Create = DefaultPermission, Assign = DefaultPermission, Edit = DefaultPermission, Delete = DefaultPermission },
			Bank = { View = DefaultPermission, Deposit = DefaultPermission, Withdraw = DefaultPermission, Transfer = DefaultPermission },
			Goals = { MyGoals = DefaultPermission, All = DefaultPermission, Edit = DefaultPermission },
			Perks = DefaultPermission
		}

		if type(Data[Key]) == "table" then
			for Category,Value in pairs(Data[Key]) do
				if type(Template[Category]) == "table" and type(Value) == "table" then
					for SubKey,SubValue in pairs(Value) do
						if type(Template[Category][SubKey]) == "boolean" then
							Template[Category][SubKey] = SubValue and true or false
						end
					end
				elseif type(Template[Category]) == "boolean" then
					Template[Category] = Value and true or false
				end
			end
		end

		Result[Key] = Template
	end

	Result.__Meta = { Version = 1 }
	vRP.SetSrvData("Painel:Permissions:"..Group,Result,true)
	TriggerClientEvent("painel:Notify",source,"Sucesso","Permissões atualizadas.","verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- MEMBERS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Members(Ranking)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = (tonumber(Level) == 1) or (Group == "Admin")
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Management
			if type(Category) == "table" then
				local Value = Category.View
				if type(Value) == "boolean" then
					Allowed = Value or (Group == "Admin")
				end
			elseif type(Category) == "boolean" then
				Allowed = Category or (Group == "Admin")
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Members = {}
	local Groups = vRP.DataGroups(Group)
	local Service = vRP.NumPermission(Group)

	local Tags = exports.oxmysql:query_async("SELECT Image, Name, Members FROM painel_creative_tags WHERE Permission = ?",{ Group }) or {}
	for _,Tag in ipairs(Tags) do
		Tag.Decoded = Tag.Members and json.decode(Tag.Members) or {}
	end

	for Target in pairs(Groups) do
		local Identity = vRP.Identity(Target)
		local Hierarchy = vRP.HasPermission(Target,Group)
		if Identity and Hierarchy then
			local Assigned = {}
			for _,Tag in ipairs(Tags) do
				for _,Number in ipairs(Tag.Decoded) do
					if tonumber(Number) == tonumber(Target) then
						Assigned[#Assigned + 1] = { Image = Tag.Image, Name = Tag.Name }
						break
					end
				end
			end

			local Played = vRP.Playing(Target,Group) or 0
			local TimerLabel = CompleteTimers(Played)
			local Status = vRP.Source(Target) and ("Ativo a "..TimerLabel) or ("Inativo a "..TimerLabel)

			Members[#Members + 1] = { Passport = Target, Name = vRP.FullName(Target), Hierarchy = Hierarchy, Tags = Assigned, Service = Service[Target] and 1 or 0, Hours = Played, Status = Status }
		end
	end

	if Ranking then
		table.sort(Members,function(a,b)
			return a.Hours > b.Hours
		end)
	end

	return { Members = Members, Max = vRP.Permissions(Group,"Members") }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- INVITE
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Invite(Target)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Management
			if type(Category) == "table" then
				local Value = Category.Create
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	Target = parseInt(Target)
	if Target <= 0 or Target == Passport then
		return true
	end

	if not vRP.GetUserType(Target,"Work") then
		local TargetSource = vRP.Source(Target)
		if TargetSource and vRP.Request(TargetSource,"Grupos","Você foi convidado(a) para participar do grupo <b>"..Group.."</b>, deseja entrar?") then
			vRP.SetPermission(Target,Group)
			TriggerClientEvent("painel:Notify",source,"Sucesso","Passaporte adicionado.","verde")
		end
	end

	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- HIERARCHY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Hierarchy(Data)
    local source = source
    local Passport = vRP.Passport(source)
    local Group = Passport and Permission[Passport]
    if not Passport or not Group or not Data or not Data.Passport or not Data.Mode then
        return false
    end

    local Level = vRP.HasPermission(Passport,Group)
    if not Level then
        return false
    end

    local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
    local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
    local Version = type(MetaData) == "table" and MetaData.Version or 0
    local Allowed = Level == 1
    if Version >= 1 then
        local LevelData = StoredPermissions[tostring(Level)]
        if type(LevelData) == "table" then
            local Category = LevelData.Management
            if type(Category) == "table" then
                local Value = Category.Edit
                if type(Value) == "boolean" then
                    Allowed = Value
                end
            elseif type(Category) == "boolean" then
                Allowed = Category
            end
        end
    end

    if not Allowed then
        TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
        return false
    end

    local Text = Data.Mode == "Promote" and "promovido" or "rebaixado"
    vRP.SetPermission(Data.Passport,Group,Passport,Data.Mode)
    local TargetSource = vRP.Source(Data.Passport)
    if TargetSource then
        TriggerClientEvent("Notify",TargetSource,Group,"Você foi <b>"..Text.."</b> do seu cargo atual.","verde",5000)
    end

    return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISMISS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Dismiss(Target)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Target then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Management
			if type(Category) == "table" then
				local Value = Category.Dismiss
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	if vRP.HasGroup(Target,Group) then
		vRP.RemovePermission(Target,Group)
		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- BANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Bank()
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Bank
			if type(Category) == "table" then
				local Value = Category.View
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM painel_creative_transactions WHERE Permission = @Permission LIMIT 50",{ Permission = Group }) or {}
	local Transactions = {}

	for _,Row in ipairs(Consult) do
		Transactions[#Transactions + 1] = { Player = { Passport = Row.Passport, Name = vRP.FullName(Row.Passport) }, To = Row.Transfer and { Passport = Row.Transfer, Name = vRP.FullName(Row.Transfer) } or false, Type = Row.Type, Value = Row.Value, Date = Row.Timestamp }
	end

	return { Balance = vRP.Permissions(Group,"Bank"), Historical = Transactions }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DEPOSITBANK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DepositBank(Value)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	Value = parseInt(Value)
	if not Passport or not Group or Value <= 0 then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Bank
			if type(Category) == "table" then
				local ValuePerm = Category.Deposit
				if type(ValuePerm) == "boolean" then
					Allowed = ValuePerm
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	if vRP.PaymentBank(Passport,Value) then
		exports.oxmysql:insert_async( "INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Transfer,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Transfer,@Permission)", { Type = "Deposit", Passport = Passport, Value = Value, Timestamp = os.time(), Transfer = nil, Permission = Group } )
		vRP.PermissionsUpdate(Group,"Bank","+",Value)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Deposito realizado.","verde")
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
	local Group = Passport and Permission[Passport]
	Value = parseInt(Value)
	if not Passport or not Group or Value <= 0 then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Bank
			if type(Category) == "table" then
				local ValuePerm = Category.Withdraw
				if type(ValuePerm) == "boolean" then
					Allowed = ValuePerm
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	if vRP.Permissions(Group,"Bank") >= Value then
		exports.oxmysql:insert_async( "INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Transfer,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Transfer,@Permission)", { Type = "Withdraw", Passport = Passport, Value = Value, Timestamp = os.time(), Transfer = nil, Permission = Group } )
		vRP.GiveBank(Passport,Value * (Config.BankTaxWithdraw or 1))
		vRP.PermissionsUpdate(Group,"Bank","-",Value)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Saque realizado.","verde")
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
	local Group = Passport and Permission[Passport]
	Value = parseInt(Value)
	OtherPassport = parseInt(OtherPassport)
	if not Passport or not Group or Value <= 0 or OtherPassport <= 0 then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Bank
			if type(Category) == "table" then
				local ValuePerm = Category.Transfer
				if type(ValuePerm) == "boolean" then
					Allowed = ValuePerm
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Identity = vRP.Identity(OtherPassport)
	if Identity and vRP.Permissions(Group,"Bank") >= Value then
		exports.oxmysql:insert_async( "INSERT INTO painel_creative_transactions (Type,Passport,Value,Timestamp,Transfer,Permission) VALUES (@Type,@Passport,@Value,@Timestamp,@Transfer,@Permission)", { Type = "Transfer", Passport = Passport, Value = Value, Timestamp = os.time(), Transfer = OtherPassport, Permission = Group } )
		vRP.GiveBank(OtherPassport,Value * (Config.BankTaxTransfer or 1),true)
		vRP.PermissionsUpdate(Group,"Bank","-",Value)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Transferencia realizada.","verde")
		return { Passport = OtherPassport, Name = Identity.Name .. " " .. Identity.Lastname }
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- TAGS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Tags()
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1 or Group == "Admin"
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Tags
			if type(Category) == "table" then
				local Value = Category.View
				if type(Value) == "boolean" then
					Allowed = Value or Group == "Admin"
				end
			elseif type(Category) == "boolean" then
				Allowed = Category or Group == "Admin"
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Consult = exports.oxmysql:query_async("SELECT * FROM painel_creative_tags WHERE LOWER(Permission) = LOWER(?)",{ Group }) or {}
	local Tags = {}

	for _,Row in ipairs(Consult) do
		Tags[#Tags + 1] = { Id = Row.id, Image = Row.Image, Members = json.decode(Row.Members) or {}, Name = Row.Name }
	end

	return Tags
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETTAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.GetTag(Identifier)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Identifier then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1 or Group == "Admin"
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Tags
			if type(Category) == "table" then
				local Value = Category.Assign
				if type(Value) == "boolean" then
					Allowed = Value or Group == "Admin"
				end
			elseif type(Category) == "boolean" then
				Allowed = Category or Group == "Admin"
			end
		end
	end

	if not Allowed then
		local DefaultPermissions = tonumber(Level) == 1 or Group == "Admin"
		if DefaultPermissions then
			Allowed = true
		else
			TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
			return false
		end
	end

	local Consult = exports.oxmysql:single_async("SELECT id, Image, Name, Members FROM painel_creative_tags WHERE Id = ? AND LOWER(Permission) = LOWER(?)",{ Identifier,Group })
	if not Consult then
		return false
	end

	local Members = {}
	local List = json.decode(Consult.Members) or {}
	for _,Passport in ipairs(List) do
		Members[#Members + 1] = { Passport = Passport, Name = vRP.FullName(Passport) }
	end

	return { Id = Consult.id, Image = Consult.Image, Name = Consult.Name, Members = Members }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CREATETAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.CreateTag(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Data then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Tags
			if type(Category) == "table" then
				local Value = Category.Create
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Count = exports.oxmysql:scalar_async("SELECT COUNT(*) FROM painel_creative_tags WHERE Permission = ?",{ Group }) or 0
	local Max = vRP.Permissions(Group,"Tags") or 0
	if Count >= Max then
		TriggerClientEvent("painel:Notify",source,"Atencao","Limite de tags atingido.","amarelo")
		return true
	end

	exports.oxmysql:insert_async("INSERT INTO painel_creative_tags (Name,Image,Permission) VALUES (?,?,?)",{ Data.Name,Data.Image,Group })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Tag criada.","verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- UPDATETAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.UpdateTag(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Data or not Data.Id then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Tags
			if type(Category) == "table" then
				local Value = Category.Edit
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	exports.oxmysql:execute_async("UPDATE painel_creative_tags SET Name = ?, Image = ? WHERE Id = ? AND Permission = ?",{ Data.Name,Data.Image,Data.Id,Group })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Tag atualizada.","verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ASSIGNTAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.AssignTag(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Data or not Data.Id or not Data.Passport then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = tonumber(Level) == 1 or Group == "Admin"
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Tags
			if type(Category) == "table" then
				local Value = Category.Assign
				if type(Value) == "boolean" then
					Allowed = Value or Group == "Admin"
				end
			elseif type(Category) == "boolean" then
				Allowed = Category or Group == "Admin"
			end
		end
	end

	if not Allowed then
		local DefaultPermissions = tonumber(Level) == 1 or Group == "Admin"
		if DefaultPermissions then
			Allowed = true
		else
			TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
			return false
		end
	end

	local Consult = exports.oxmysql:single_async("SELECT id, Image, Name, Members FROM painel_creative_tags WHERE Id = ? AND LOWER(Permission) = LOWER(?)",{ Data.Id,Group })
	if not Consult then
		return false
	end

	local Members = json.decode(Consult.Members) or {}
	for _,Member in ipairs(Members) do
		if Member == Data.Passport then
			return false
		end
	end

	Members[#Members + 1] = Data.Passport
	exports.oxmysql:execute_async("UPDATE painel_creative_tags SET Members = ? WHERE Id = ?",{ json.encode(Members),Data.Id })

	TriggerClientEvent("painel:Notify",source,"Sucesso","Tag atribuida.","verde")
	local TargetSource = vRP.Source(Data.Passport)
	if TargetSource then
		TriggerClientEvent("Notify",TargetSource,Consult.Name,"Você recebeu uma tag.","verde")
	end
	return { Passport = Data.Passport, Name = vRP.FullName(Data.Passport) }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- REMOVETAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.RemoveTag(Data)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Data or not Data.Id or not Data.Passport then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1 or Group == "Admin"
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Tags
			if type(Category) == "table" then
				local Value = Category.Assign
				if type(Value) == "boolean" then
					Allowed = Value or Group == "Admin"
				end
			elseif type(Category) == "boolean" then
				Allowed = Category or Group == "Admin"
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Consult = exports.oxmysql:single_async("SELECT id, Image, Name, Members FROM painel_creative_tags WHERE Id = ? AND LOWER(Permission) = LOWER(?)",{ Data.Id,Group })
	if not Consult then
		return false
	end

	local Members = json.decode(Consult.Members) or {}
	for Index,Member in ipairs(Members) do
		if Member == Data.Passport then
			table.remove(Members,Index)
			break
		end
	end

	exports.oxmysql:execute_async("UPDATE painel_creative_tags SET Members = ? WHERE Id = ?",{ json.encode(Members),Data.Id })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Tag removida.","verde")
	return { Passport = Data.Passport }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DESTROYTAG
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.DestroyTag(Identifier)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group or not Identifier then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Tags
			if type(Category) == "table" then
				local Value = Category.Delete
				if type(Value) == "boolean" then
					Allowed = Value
				end
			elseif type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	exports.oxmysql:execute_async("DELETE FROM painel_creative_tags WHERE id = ? AND Permission = ?",{ Identifier,Group })
	TriggerClientEvent("painel:Notify",source,"Sucesso","Tag removida.","verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERKS
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Perks()
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Perks
			if type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Informations = {}
	local Default = 30
	local MembersLimit = vRP.Permissions(Group,"Members")
	local Premium = vRP.Permissions(Group,"Premium") or 0

	for _,Perk in ipairs(Config.Perks) do
		local Info = {}
		for Key,Value in pairs(Perk) do
			Info[Key] = Value
		end

		if Perk.Type == "Members" then
			Info.Price = Perk.Price[MembersLimit] or Perk.Price[#Perk.Price]
			local GroupInfo = Groups[Group] or {}
			local MaxMembers = GroupInfo.Max or MembersLimit or Default
			Info.Active = MembersLimit >= MaxMembers or MembersLimit >= #Perk.Price
		elseif Perk.Type == "Premium" then
			Info.Price = Perk.Price
			Info.Active = Premium >= os.time()
		else
			Info.Price = Perk.Price
			Info.Active = false
		end

		Informations[#Informations + 1] = Info
	end

	return { Levels = TableLevelPainel(), List = Informations, Xp = vRP.Permissions(Group,"Experience") }
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- PERKSBUY
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.PerksBuy(Identifier)
	local source = source
	local Passport = vRP.Passport(source)
	local Group = Passport and Permission[Passport]
	if not Passport or not Group then
		return false
	end

	local Level = vRP.HasPermission(Passport,Group)
	if not Level then
		return false
	end

	local StoredPermissions = vRP.GetSrvData("Painel:Permissions:"..Group,true) or {}
	local MetaData = type(StoredPermissions) == "table" and StoredPermissions.__Meta
	local Version = type(MetaData) == "table" and MetaData.Version or 0
	local Allowed = Level == 1
	if Version >= 1 then
		local LevelData = StoredPermissions[tostring(Level)]
		if type(LevelData) == "table" then
			local Category = LevelData.Perks
			if type(Category) == "boolean" then
				Allowed = Category
			end
		end
	end

	if not Allowed then
		TriggerClientEvent("painel:Notify",source,"Atencao","Você não possui permissão.","amarelo")
		return false
	end

	local Perk = Config.Perks[Identifier]
	if not Perk then
		return false
	end

	local Balance = vRP.Permissions(Group,"Bank")
	if Perk.Type == "Members" then
		local MembersAmount = vRP.Permissions(Group,"Members")
		local Cost = Perk.Price[MembersAmount] or Perk.Price[#Perk.Price]

		if not Cost or Balance < Cost then
			TriggerClientEvent("painel:Notify",source,"Erro","Saldo insuficiente.","vermelho")
		 return false
		end

		vRP.PermissionsUpdate(Group,"Bank","-",Cost)
		vRP.PermissionsUpdate(Group,"Members","+",Perk.Increase)
		TriggerClientEvent("painel:Notify",source,"Sucesso","Vantagem adquirida.","verde")
		return true
	end

	if Perk.Level and PainelCategory(vRP.Permissions(Group,"Experience")) < Perk.Level then
		TriggerClientEvent("painel:Notify",source,"Atencao","Level <b>"..Perk.Level.."</b> necessario.","amarelo")
		return false
	end

	local Cost = type(Perk.Price) == "table" and Perk.Price[1] or Perk.Price
	if Balance < Cost then
		TriggerClientEvent("painel:Notify",source,"Erro","Saldo insuficiente.","vermelho")
		return false
	end

	vRP.PermissionsUpdate(Group,"Bank","-",Cost)
	
	if Perk.Type == "Premium" then
		local Current = vRP.Permissions(Group, "Premium") or 0
		local Now = os.time()
		local NewExpire = (Current > Now and Current or Now) + Perk.Increase
		exports.oxmysql:execute_async("UPDATE permissions SET Premium = ? WHERE Permission = ?", { NewExpire, Group })
	elseif Perk.Type == "Tags" then
		exports.oxmysql:execute_async("UPDATE permissions SET Tags = Tags + ? WHERE Permission = ?", { Perk.Increase, Group })
	elseif Perk.Type == "Announces" then
		exports.oxmysql:execute_async("UPDATE permissions SET Announces = Announces + ? WHERE Permission = ?", { Perk.Increase, Group })
	else
		vRP.PermissionsUpdate(Group,Perk.Type,"+",Perk.Increase)
	end
	
	TriggerClientEvent("painel:Notify",source,"Sucesso","Vantagem adquirida.","verde")
	return true
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function(Passport)
	if Passport and Permission[Passport] then
		Permission[Passport] = nil
	end
end)