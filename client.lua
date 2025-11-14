lib.registerContext({
    id = 'blackmarket_main',
    title = locale('misc.title'),
    options = {
        {
            title = locale('misc.choose_action'),
            readOnly = true
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
        }
    }
})

local CreatePed = CreatePed
local DoesEntityExist = DoesEntityExist
local GetEntityCoords = GetEntityCoords
local SetPedConfigFlag = SetPedConfigFlag
local SetModelAsNoLongerNeeded = SetModelAsNoLongerNeeded

local activeDealers = {}

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

        if ped.scenario then
            TaskStartScenarioInPlace(cPed, ped.scenario, -1, false)
        end

        SetModelAsNoLongerNeeded(model)

        activeDealers[#activeDealers+1]={ped=cPed, zone=nil}
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
                if self:contains(GetEntityCoords(cache.ped)) then
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

local function deleteSpawnedPeds()
    for i = #activeDealers, 1, -1 do
        local ped = activeDealers[i]

        if DoesEntityExist(ped.ped) then
            DeletePed(ped.ped)
        end

        ped.zone:remove()
    end

    lib.table.wipe(activeDealers)
end

local function initScript()
    createDealers()
    createZones()()
end

local function onPlayerLoad()
    if GetResourceState("qbx_core") ~= "missing" then
        AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
            initScript()
        end)
    elseif GetResourceState("es_extended") ~= "missing" then
        AddEventHandler("esx:playerLoaded", function()
            initScript()
        end)
    else
        lib.print.warn("No supported core found.")
    end
end
onPlayerLoad()


AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == "ox_inventory" then initScript() end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == "ox_inventory" then deleteSpawnedPeds() end
end)

AddEventHandler('rv_blackmarket:openBlackMarket', function ()
    local jobType = (GetResourceState("qbx_core") ~= "missing" and exports['qbx_core']:GetPlayerData()?.job?.type) or (GetResourceState("es_extended") and ESX.GetPlayerData()?.job?.name)
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


lib.callback.register('rv_blackmarket:client:isNearDealer', function ()
    for i = 1, #activeDealers do
        if #GetEntityCoords(cache.ped) - #GetEntityCoords(activeDealers[i].ped) <= 2.0 then
            return true
        end
    end
end)
