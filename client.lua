math.randomseed(GetGameTimer())


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
            disabled = true
        }
    }
})


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

local function addDealerZones()
    for i = 1, #activeDealers do

        activeDealers[i].zone = lib.zones.box({
            coords = GetEntityCoords(activeDealers[i].ped),
            onEnter = function (self)
                lib.showTextUI('[E] - Schwarzmarkt öffnen')
            end,
            inside = function (self)
                if self:contains(GetEntityCoords(cache.ped)) then

                    if IsControlJustPressed(0, 38) or IsControlJustReleased(0, 38) then
                        TriggerEvent('rv_blackmarket:openBlackMarket')
                    end

                end
            end,
            onExit = function (self)
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
    addDealerZones()
end


AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        initScript()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() or resourceName == "rv_blackmarket" then
        deleteSpawnedPeds()
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function ()
    initScript()
end)

AddEventHandler('rv_blackmarket:openBlackMarket', function ()
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

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    deleteSpawnedPeds()
end)


lib.callback.register('rv_blackmarket:client:isNearDealer', function ()
    for i = 1, #activeDealers do
        if #GetEntityCoords(cache.ped) - #GetEntityCoords(activeDealers[i].ped) <= 5.0 then
            return true
        end
    end
end)