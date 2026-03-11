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
Tunnel.bindInterface("codes",Creative) 
vKEYBOARD = Tunnel.getInterface("keyboard")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local CodesList = {}
-----------------------------------------------------------------------------------------------------------------------------------------
-- CODES:LIST 
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Codes()
    local source = source
    local Passport = vRP.Passport(source) 

    if vRP.HasGroup(Passport,"Admin",1) then 
        return CodesList
    end

    return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- DATABASE:SYNC
-----------------------------------------------------------------------------------------------------------------------------------------
function SyncCodes()
    local Consult = exports.oxmysql:querySync("SELECT * FROM codes_creative ORDER BY id DESC LIMIT 20")
    CodesList = {} 
    if Consult then
        for k,v in pairs(Consult) do
            local Rewards = json.decode(v.Rewards) or {}
            local ItemCount = 0
            for _ in pairs(Rewards) do ItemCount = ItemCount + 1 end

            local blue = "<font color='#5dade2'>"
            local red = "<font color='#e74c3c'>" 
            local close = "</font>"

            CodesList[tostring(v.id)] = {
                Name = "Cupom: " .. v.Code,
                Info = "Resgate(s): "..blue..v.Used..close.." | Entregue(s): "..red.."0"..close.." | Item(s): "..blue..ItemCount..close.."<br>Remover Codiguin"
            }
        end
    end
end

CreateThread(function()
    SyncCodes()
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CODES:DYNAMIC
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("codes:Dynamic")
AddEventHandler("codes:Dynamic",function()
    local source = source
    local Passport = vRP.Passport(source)
        TriggerClientEvent("dynamic:Close",source)

        local Keyboard = vKEYBOARD.Codigo(source,"Código","Usos","Item","Quantidade")
        if Keyboard then
            local Code = string.upper(tostring(Keyboard[1]))
            local Max = tonumber(Keyboard[2])
            local Item = tostring(Keyboard[3])
            local Amount = tonumber(Keyboard[4])

            if Code ~= "" and Max and Max > 0 then
                local Rewards = { { Item = Item, Amount = Amount } }
                exports.oxmysql:insertSync("INSERT INTO codes_creative (Code,Rewards,Max,Used,CreatedAt) VALUES (?,?,?,?,?)",
                { Code, json.encode(Rewards), Max, 0, os.time() })
                
                SyncCodes()
                TriggerClientEvent("Notify",source,"Sucesso","Código <b>"..Code.."</b> criado.","verde",5000)

                SetTimeout(500,function()
                TriggerClientEvent("codes:Dynamic",source)
            end)
        end
    end
end)

-----------------------------------------------------------------------------------------------------------------------------------------
-- CODES:REMOVE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterServerEvent("codes:Remove")
AddEventHandler("codes:Remove",function(ID)
    local source = source
    local Passport = vRP.Passport(source)
        exports.oxmysql:querySync("DELETE FROM codes_creative WHERE id = ?",{ ID })
        
        SyncCodes()
        TriggerClientEvent("dynamic:Close",source)
        TriggerClientEvent("Notify",source,"Sucesso","Código removido com sucesso.","verde",5000)

        SetTimeout(500,function()
        TriggerClientEvent("codes:Dynamic",source)
    end)
end)