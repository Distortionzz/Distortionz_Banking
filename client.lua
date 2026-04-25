local QBCore = exports['qb-core']:GetCoreObject()

local isOpen = false
local bankBlips = {}

local function Notify(message, notifyType, duration)
    if not message then return end

    notifyType = notifyType or 'primary'
    duration = duration or 5000

    if notifyType == 'inform' then
        notifyType = 'info'
    end

    if GetResourceState(Config.Notify.resource) == 'started' then
        exports[Config.Notify.resource]:Notify(
            message,
            notifyType,
            duration,
            Config.Notify.title
        )
        return
    end

    lib.notify({
        title = Config.Notify.title,
        description = message,
        type = notifyType,
        duration = duration
    })
end

local function RefreshBankData()
    local data = lib.callback.await('distortionz_banking:server:getBankData', false)

    if not data then
        Notify('Unable to load banking data.', 'error', 5000)
        return
    end

    SendNUIMessage({
        action = 'setBankData',
        data = data
    })
end

local function OpenBank()
    if isOpen then return end

    local data = lib.callback.await('distortionz_banking:server:getBankData', false)

    if not data then
        Notify('Unable to load banking data.', 'error', 5000)
        return
    end

    isOpen = true

    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'openBank',
        data = data
    })
end

local function CloseBank()
    if not isOpen then return end

    isOpen = false

    SetNuiFocus(false, false)

    SendNUIMessage({
        action = 'closeBank'
    })
end

local function CreateBankBlips()
    if not Config.Blips.enabled then return end

    for _, coords in ipairs(Config.BankLocations) do
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

        SetBlipSprite(blip, Config.Blips.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blips.scale)
        SetBlipColour(blip, Config.Blips.color)
        SetBlipAsShortRange(blip, Config.Blips.shortRange)

        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Blips.label)
        EndTextCommandSetBlipName(blip)

        bankBlips[#bankBlips + 1] = blip
    end
end

local function SetupTargets()
    if not Config.Target.enabled then return end

    if GetResourceState('ox_target') ~= 'started' then
        print('[distortionz_banking] ox_target is not started. Bank targets were not created.')
        return
    end

    for index, coords in ipairs(Config.BankLocations) do
        exports.ox_target:addSphereZone({
            coords = vec3(coords.x, coords.y, coords.z),
            radius = 1.2,
            debug = false,
            options = {
                {
                    name = ('distortionz_bank_%s'):format(index),
                    label = 'Open Distortionz Bank',
                    icon = 'fa-solid fa-building-columns',
                    distance = Config.Target.distance,
                    onSelect = function()
                        OpenBank()
                    end
                }
            }
        })
    end

    exports.ox_target:addModel(Config.ATMModels, {
        {
            name = 'distortionz_bank_atm',
            label = 'Use ATM',
            icon = 'fa-solid fa-credit-card',
            distance = Config.Target.distance,
            onSelect = function()
                OpenBank()
            end
        }
    })
end

RegisterNetEvent('distortionz_banking:client:openBank', function()
    OpenBank()
end)

RegisterNetEvent('distortionz_banking:client:notify', function(message, notifyType, duration)
    Notify(message, notifyType, duration)
end)

RegisterNUICallback('closeBank', function(_, cb)
    CloseBank()
    cb({ success = true })
end)

RegisterNUICallback('refreshBank', function(_, cb)
    RefreshBankData()
    cb({ success = true })
end)

RegisterNUICallback('deposit', function(data, cb)
    local amount = tonumber(data and data.amount)
    local note = data and data.note or ''

    local result = lib.callback.await('distortionz_banking:server:deposit', false, amount, note)

    if result and result.message then
        Notify(result.message, result.success and 'success' or 'error', 5000)
    end

    cb(result or { success = false, message = 'Deposit failed.' })

    if result and result.success then
        RefreshBankData()
    end
end)

RegisterNUICallback('withdraw', function(data, cb)
    local amount = tonumber(data and data.amount)
    local note = data and data.note or ''

    local result = lib.callback.await('distortionz_banking:server:withdraw', false, amount, note)

    if result and result.message then
        Notify(result.message, result.success and 'success' or 'error', 5000)
    end

    cb(result or { success = false, message = 'Withdraw failed.' })

    if result and result.success then
        RefreshBankData()
    end
end)

RegisterNUICallback('transfer', function(data, cb)
    local amount = tonumber(data and data.amount)
    local targetCitizenId = data and data.targetCitizenId or ''
    local note = data and data.note or ''

    local result = lib.callback.await('distortionz_banking:server:transfer', false, targetCitizenId, amount, note)

    if result and result.message then
        Notify(result.message, result.success and 'success' or 'error', 5000)
    end

    cb(result or { success = false, message = 'Transfer failed.' })

    if result and result.success then
        RefreshBankData()
    end
end)

CreateThread(function()
    Wait(1500)

    CreateBankBlips()
    SetupTargets()
end)

if Config.Commands.enabled then
    RegisterCommand(Config.Commands.openBank, function()
        OpenBank()
    end, false)
end

CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 322, true)

            if IsControlJustPressed(0, 322) then
                CloseBank()
            end

            Wait(0)
        else
            Wait(750)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    SetNuiFocus(false, false)

    for _, blip in ipairs(bankBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end)
