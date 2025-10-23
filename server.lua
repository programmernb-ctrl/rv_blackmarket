if not lib.checkDependency('rv_blackmarket', '1.0.0') then
    lib.print.warn('You need atleast version 1.0.0. download it on github: https://github.com/programmernb-ctrl/rv_blackmarket')
end

local dealerItems = require 'config.server'.DealerItems
local ox_inventory = exports['ox_inventory']

local function getItemPrices()
    local items = lib.table.deepclone(dealerItems)
    return items
end


RegisterNetEvent('rv_blackmarket:server:openPurchaseMenu', function()
    local items = lib.table.deepclone(dealerItems)
    local options = {}

    for key, value in pairs(items) do
        local itemName = ox_inventory:Items(key).label
        options[#options+1] = {
            title = itemName,
            description = locale('misc.price', value),
            serverEvent = 'rv_blackmarket:server:buyItem',
            args = {
                key
            }
        }
    end

    lib.callback('rv_blackmarket:client:isNearDealer', source, function (isNear)
        if isNear then
            TriggerClientEvent('rv_blackmarket:client:onMenuOpenedPurchase', source, options)
        else
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = locale('misc.not_allowed'),
            })
        end
    end)
end)

RegisterNetEvent('rv_blackmarket:server:buyItem', function(data)
    local item = data[1]
    local price = dealerItems[item]
    if not dealerItems then return end


    local isNearDealer = lib.callback.await('rv_blackmarket:client:isNearDealer', source)
    if not isNearDealer then return end

    local count = ox_inventory:Search(source, 'count', 'black_money')

    if count <= price then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('misc.insufficient_funds')
        })
        return
    end

    if ox_inventory:RemoveItem(source, 'black_money', count) then
        local success = ox_inventory:AddItem(source, item, 1)
        if not success then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = locale('misc.not_added_item')
            })
        end
    end

end)


lib.callback.register('rv_blackmarket:server:getItemPrices', function(source)
    local prices = getItemPrices()
    return prices
end)
