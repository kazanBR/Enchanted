-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Answers = {}
local Mugshot = false
local CurrentPromise = false
local IsTakingMugshot = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- SAFEUNREGISTER
-----------------------------------------------------------------------------------------------------------------------------------------
function SafeUnregister()
	if Mugshot then
		UnregisterPedheadshot(Mugshot)
		Mugshot = false
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- GETMUGSHOTBASE64
-----------------------------------------------------------------------------------------------------------------------------------------
function GetMugShotBase64()
	local Ped = PlayerPedId()
	if IsTakingMugshot then
		return false
	end

	IsTakingMugshot = true

	local Cooldown = GetGameTimer() + 5000
	while (IsPedHuman(Ped) and not HasPedHeadBlendFinished(Ped) and GetGameTimer() < Cooldown) do
		Wait(50)
	end

	SafeUnregister()

	local Timeout = GetGameTimer() + 3000
	local Handle = RegisterPedheadshot(Ped)
	while (not Handle or not IsPedheadshotReady(Handle) or not IsPedheadshotValid(Handle)) and GetGameTimer() < Timeout do
        Wait(10)
    end

	local Texture = "none"
	if Handle and IsPedheadshotReady(Handle) and IsPedheadshotValid(Handle) then
		Mugshot = Handle
		Texture = GetPedheadshotTxdString(Handle)
	end

	SendNUIMessage({
		id = Ped,
		type = "convert",
		pMugShotTxd = Texture,
		removeImageBackGround = false
	})

	CurrentPromise = promise.new()
	Answers[Ped] = CurrentPromise

	local Result = Citizen.Await(CurrentPromise)

	SafeUnregister()
	IsTakingMugshot = false

	return Result
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ANSWER
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Answer",function(Data,Callback)
    local id = Data.Id
    local p = Answers[id]

    if p then
        SafeUnregister()
        p:resolve(Data.Answer)
        Answers[id] = nil
    end

    if Callback then
    	Callback("Ok")
    end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- AVATAR
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNUICallback("Avatar",function(Data,Callback)
    Callback(GetMugShotBase64())
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- ONRESOURCESTOP
-----------------------------------------------------------------------------------------------------------------------------------------
AddEventHandler("onResourceStop",function(Resource)
    if Resource == GetCurrentResourceName() then
        SafeUnregister()
        Answers = {}
    end
end)