-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("vrp","lib/Tunnel")
local Proxy = module("vrp","lib/Proxy")
vRPC = Tunnel.getInterface("vRP")
vRP = Proxy.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- MARRIAGE:REQUEST
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("marriage:Request")
AddEventHandler("marriage:Request",function(OtherSource)
    local source = source
    local Passport = vRP.Passport(source)
    local OtherPassport = vRP.Passport(OtherSource)
    if Passport and OtherPassport then
        local Model = vRP.ModelPlayer(OtherSource)
        local Sex = (Model == "mp_f_freemode_01") and "F" or "M"
        vRPC.playAnim(source,false,{"ultra@propose","propose"},true)
        vRPC.CreateObjects(source,"","","ultra_ringcase",49,28422,0.08,0.01,-0.055,0.0,180.0,-90.0)
        if vRP.Request(OtherSource,"Casamento","Aceita se casar com <b>"..vRP.FullName(Passport).."</b>?") then
            vRP.RemoveItem(Passport,"dollar",20000,true)
            vRP.GenerateItem(Passport,"alliance-"..OtherPassport.."-"..vRP.FullName(OtherPassport),1,true)
            vRP.GenerateItem(OtherPassport,"alliance-"..Passport.."-"..vRP.FullName(Passport),1,true)

            TriggerClientEvent("marriage:Accept",source,Sex,vRP.FullName(OtherPassport))
        else
            TriggerClientEvent("marriage:Reject",source,vRP.FullName(OtherPassport))
        end
    end
end)