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
Tunnel.bindInterface("referrals",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- CHECK
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Check()
  local source = source
  local Passport = vRP.Passport(source)
  local Referral = vRP.AccountInformation(Passport,"Referral")

  return Passport and not Referral
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONFIRM
-----------------------------------------------------------------------------------------------------------------------------------------
function Creative.Confirm(Origin,Code)
  local source = source
  local Passport = vRP.Passport(source)
  local License = vRP.License(Passport)
  local Referral = vRP.AccountInformation(Passport,"Referral")
  local Rewards = Codes[Code]
  
  if Passport and License and not Referral and Rewards then
    for Item, Amount in pairs(Rewards) do
      if Item:find("Vehicle:") then
        vRP.Query("vehicles/addVehicles",{ Passport = Passport, Vehicle = Item:match("^Vehicle:(.+)$"), Plate = vRP.GeneratePlate(), Weight = VehicleWeight(Item:match("^Vehicle:(.+)$")), Work = 0 })
        TriggerClientEvent("Notify",source,"Sucesso","Veículo <b>"..VehicleName(Item:match("^Vehicle:(.+)$")).."</b> recebido.","verde",5000)
      else
        vRP.GenerateItem(Passport, Item, Amount, true)
      end
    end
  end
  
  exports.oxmysql:execute_async("UPDATE accounts SET Referral = ? WHERE License = ?", { Origin, License })
  exports.discord:Embed("Referral","**[PASSAPORTE]:** "..Passport.."\n**[REFERÊNCIA]:** "..Origin.."\n**[CÓDIGO]:** "..Code)
  TriggerClientEvent("Notify",source,ServerName,"Seja bem-vindo(a) à nossa comunidade. Sua referência foi devidamente registrada em nosso banco de dados e caso o código informado seja validado, sua recompensa estará com você.","default",20000,"bottom-center")
  return true
end