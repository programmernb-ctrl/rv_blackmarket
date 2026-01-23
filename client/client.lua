local questOptions = {}
---@type table <number, { ped: integer, zone: CZone? }>
local activeDealers = {}

local CreatePed = CreatePed
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local SetPedConfigFlag = SetPedConfigFlag
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded

for i = 1, #Config.Quests do
    local quest = Config.Quests[i]
    questOptions[i] = {
        title = quest.title,
        description = quest.description,
        serverEvent = 'rv_blackmarket:server:getQuest',
        args = {
            idx = i,
            type = quest.type
        }
    }
end

lib.registerContext({
    id = 'blackmarket_quests',
    menu = 'blackmarket_main',
    title = locale('misc.title_quests'),
    options = questOptions
})

lib.registerContext({
    id = 'blackmarket_main',
    title = locale('misc.title'),
    options = {
        {
            title = 'Quests',
            menu = 'blackmarket_quests',
            disabled = true
        },
        {
            title = locale('misc.purchase'),
            description = locale('misc.purchase_illegal_goods'),
            arrow = true,
            serverEvent = 'rv_blackmarket:server:openPurchaseMenu',
            args = {}
        },
        {
            title = locale('misc.sale'),
            description = locale('misc.sell_illegal_goods'),
            arrow = true,
            serverEvent = 'rv_blackmarket:server:openSellMenu',
        },
        {
            title = 'Gegenstände abgeben',
            description = 'Gebe deine Questgegenstände ab',
            icon = 'fa-solid fa-hand',
            serverEvent = 'rv_blackmarket:server:removeQuestItems',
            disabled = true
        }
    }
})

local function createDealers()

    local peds = Config.Dealer and table.type(Config.Dealer) == "array" and Config.Dealer or { Config.Dealer }

    for _, ped in pairs(peds) do
        local x, y, z, w = table.unpack(ped.pos)
        local model = lib.requestModel(ped.model)
        local cPed = CreatePed(4, model, x, y, z, w, false, true)

        lib.waitFor(function()
            if DoesEntityExist(cPed) then
                return true
            end
        end)

        SetBlockingOfNonTemporaryEvents(cPed, true)
        SetEntityInvincible(cPed, true)
        SetEntityProofs(cPed, true, true, true, true, true, true, 1, true)
        FreezeEntityPosition(cPed, true)
        SetPedConfigFlag(cPed, 14, true)
        SetPedConfigFlag(cPed, 16, true)
        SetPedConfigFlag(cPed, 40, false)
        SetPedConfigFlag(cPed, 48, true)

        if ped.scenario then
            TaskStartScenarioInPlace(cPed, ped.scenario, -1, false)
        end

        activeDealers[#activeDealers+1] = { ped=cPed, zone=nil }
        SetModelAsNoLongerNeeded(model)
    end
end

local function createZones()
    for i = 1, #activeDealers do
        activeDealers[i].zone = lib.zones.box({
            coords = GetEntityCoords(activeDealers[i].ped),
            onEnter = function ()
                lib.showTextUI(locale('misc.action_label'))
            end,
            inside = function (self)
                local coords = GetEntityCoords(cache.ped)

                if self:contains(coords) then
                    if IsControlJustPressed(0, 38) or IsControlJustReleased(0, 38) then
                        TriggerEvent('rv_blackmarket:openBlackMarket')
                    end
                end
            end,
            onExit = function ()
                lib.hideTextUI()
            end
        })
    end
end

local function deletePeds()
    for i = #activeDealers, 1, -1 do
        if DoesEntityExist(activeDealers[i].ped) then
            DeletePed(activeDealers[i].ped)
        end

        activeDealers[i].zone:remove()
    end

    lib.table.wipe(activeDealers)
end

local function init()
    createDealers()
    createZones()
end

local function onPlayerLoad()
    if GetResourceState("qbx_core") == "started" then
        AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
            init()
        end)
    elseif GetResourceState("es_extended") == "started" then
        AddEventHandler("esx:playerLoaded", function()
            init()
        end)
    else
        lib.print.error("No supported core found. Script may behave not as exptected!")
    end
end

-- show default GTAV subtitle on screen
---@param text string subtitle
---@param time number ms
function ShowSubtitle(text, time)
    BeginTextCommandPrint("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandPrint(time, false)
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == "ox_inventory" then
        init()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == "ox_inventory" then
        deletePeds()
    end
end)

AddEventHandler('rv_blackmarket:openBlackMarket', function ()
    local jobType = (GetResourceState("qbx_core") == "started" and exports['qbx_core']:GetPlayerData()?.job?.type) or (GetResourceState("es_extended") == "started" and ESX.GetPlayerData()?.job?.name)
    if jobType == "leo" or jobType == "police" then return end
    lib.showContext('blackmarket_main')
end)

RegisterNetEvent('rv_blackmarket:client:onMenuOpenedPurchase', function(options)
    lib.registerContext({
        id = 'blackmarket_purchase',
        menu = 'blackmarket_main',
        title = locale('misc.title'),
        options = options
    })

    lib.showContext('blackmarket_purchase')
end)

RegisterNetEvent('rv_blackmarket:client:onMenuOpenedSell', function (options)
    lib.registerContext({
        id = 'blackmarket_sell',
        menu = 'blackmarket_main',
        title = locale('misc.title'),
        options = options
    })

    lib.showContext('blackmarket_sell')
end)

lib.callback.register('rv_blackmarket:client:isNearDealer', function()
    local coords = GetEntityCoords(cache.ped)

    for i = 1, #activeDealers do
        local dealerCoords = GetEntityCoords(activeDealers[i].ped)
        if #coords - #dealerCoords <= 3.0 then
            return true
        end
    end
end)

lib.callback.register('rv_blackmarket:client:choosedAmount', function(title)
    local input = lib.inputDialog(title, {
        {
            type = 'slider',
            label = locale('misc.amount'),
            icon = 'fa-solid fa-hashtag',
            required = true,
            min = 1,
            max = 25,
            default = 1
        }
    })

    local amount = input and input[1] --[[@as number]] or nil
    return amount
end)

onPlayerLoad()
