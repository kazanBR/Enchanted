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
Tunnel.bindInterface("luckywheel",Creative)
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Spinning = {}
local Cooldown = 60
-----------------------------------------------------------------------------------------------------------------------------------------
-- LUCKYWHEEL:TARGET
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("luckywheel:Target")
AddEventHandler("luckywheel:Target", function()
    local source = source
    local Passport = vRP.Passport(source)

    if not Passport then
        return
    end

    if Spinning[Passport] and os.time() - Spinning[Passport] < Cooldown then
        local Time = Cooldown - (os.time() - Spinning[Passport])
        TriggerClientEvent("Notify",source,"Aviso","Você deve esperar "..math.ceil(Time).." segundos para girar novamente.","amarelo",5000)
        return
    end

    if vRP.ConsultItem(Passport,ItemNecessary,AmountNecessary) then
        if vRP.TakeItem(Passport,ItemNecessary,AmountNecessary) then
            local Amount = 0
            
            for _, Reward in pairs(Rewards) do
                Amount += Reward.Chance
            end

            local Random = math.random() * Amount
            local Chance = 0
            local Index, Reward
            
            for i, R in pairs(Rewards) do
                Chance = Chance + R.Chance
                if Random <= Chance then
                    Index = i
                    Reward = R
                    break
                end
            end

            if not Index then
                Index = 1
                Reward = Rewards[1]
            end

            Spinning[Passport] = os.time()
            vRPC.playAnim(source,false,{"anim_casino_a@amb@casino@games@lucky7wheel@female", "armraisedidle_to_spinningidle_high"},false)
            TriggerClientEvent("luckywheel:Start",source,Index)
            SetTimeout(8000,function()
                vRP.GenerateItem(Passport,Reward.Item,Reward.Amount,true)
                vRPC.Destroy(source)
                TriggerClientEvent("Notify",source,"Sucesso","Você ganhou "..Reward.Amount.."x "..ItemName(Reward.Item),"verde",5000)
                exports.discord:Embed("LuckyWheel","**[PASSAPORTE]:** "..Passport.."\\n" .."**[RESULTADO]:** "..Reward.Amount.."\\n" .."**[ITEM]:** "..Reward.Amount.."x "..ItemName(Reward.Item))
            end)
        end
    else
        TriggerClientEvent("Notify",source,"Aviso","Você precisa de "..AmountNecessary.."x "..ItemName(ItemNecessary).." para girar a roleta.","vermelho",5000)
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- DISCONNECT
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("Disconnect",function()
    local source = source
    local Passport = vRP.Passport(source)
    if Passport then
        Spinning[Passport] = nil
    end
end)