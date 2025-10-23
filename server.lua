if not lib.checkDependency('rv_blackmarket', '1.0.0') then
    lib.print.warn('You need atleast version 1.0.0. download it on github: https://github.com/programmernb-ctrl/rv_blackmarket')
end

local config = require 'config.server'
local buyItems = config.DealerItems.buyable
local sellItems = config.DealerItems.sellable
local ox_inventory = exports['ox_inventory']

local function getBuyPrices()
    local items = lib.table.deepclone(buyItems)
    return items
end

local function getSellPrices()
    local items = lib.table.deepclone(sellItems)
    return items
end

local function isNearDealer(source)
    return lib.callback.await('rv_blackmarket:client:isNearDealer', source)
end


RegisterNetEvent('rv_blackmarket:server:openPurchaseMenu', function()
    if not isNearDealer(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('misc.not_allowed'),
        })
        return
    end

    local options = {}
    local itemPrices = getBuyPrices()

    for key, value in pairs(itemPrices) do
        local itemName = ox_inventory:Items(key).label
        options[#options+1] = {
            title = itemName,
            description = locale('misc.price', value),
            serverEvent = 'rv_blackmarket:server:buyItem',
            args = {key}
        }
    end

    TriggerClientEvent('rv_blackmarket:client:onMenuOpenedPurchase', source, options)
end)

RegisterNetEvent('rv_blackmarket:server:openSellMenu', function ()
    if not isNearDealer(source) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('misc.not_allowed'),
        })
        return
    end

    local options = {}
    local itemPrices = getSellPrices()

    for key, value in pairs(itemPrices) do
        local itemName = ox_inventory:Items(key).label
        options[#options+1] = {
            title = itemName,
            description = locale('misc.price', value),
            serverEvent = 'rv_blackmarket:server:sellItem',
            args = {key}
        }
    end

    TriggerClientEvent('rv_blackmarket:client:onMenuOpenedSell', source, options)
end)

RegisterNetEvent('rv_blackmarket:server:buyItem', function(data)
    local item = data[1]
    local price = buyItems[item]

    if not item or not price then return end
    if not isNearDealer(source) then return end

    local count = ox_inventory:GetItemCount(source, config.blackmoney)

    if count <= price then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('misc.insufficient_funds')
        })
        return
    end

    if ox_inventory:RemoveItem(source, config.blackmoney, price) then
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
    local prices = getBuyPrices()
    return prices
end)
