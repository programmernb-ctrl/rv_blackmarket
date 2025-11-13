if not lib.checkDependency('rv_blackmarket', '1.0.0') then
    lib.print.warn('You need atleast version 1.0.0. download it on github: https://github.com/programmernb-ctrl/rv_blackmarket')
end

local config = require 'config.server'
local buyItems = config.DealerItems.buyable
local sellItems = config.DealerItems.sellable

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

---@type table <number, number>
SellCooldowns = {}

AddEventHandler('playerDropped', function (_, _, _)
    if not source then return end
    if SellCooldowns[source] then
        SellCooldowns[source] = nil
    end
end)

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
        local itemName = Items(key).label
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
        local itemName = Items(key).label
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
    if not isNearDealer(source) then return end

    local item = data[1]
    local price = buyItems[item] -- returns the price

    if not item or not price then return end
    if price <= 0 then return end

    local count = GetItemCount(source, config.blackmoney)

    if count <= price then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('misc.insufficient_funds')
        })
        return
    end

    if RemoveItem(source, config.blackmoney, price) then
        local success = AddItem(source, item, 1)
        if not success then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = locale('misc.not_added_item')
            })
        end
    end

end)

RegisterNetEvent('rv_blackmarket:server:sellItem', function (item)
    local src = tonumber(source)

    if not src then return end
    if not item then return end
    if not isNearDealer(src) then return end

    local itemName = item[1]
    local price = sellItems[itemName]

    local amount, err = lib.callback.await('rv_blackmarket:client:choosedSellAmount', src)
    local count = GetItemCount(src, itemName)

    assert(amount > 0, err)

    if count < amount then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            locale('misc.not_enough_items')
        })
        return
    end

    if not SellCooldowns[src] then
        SellCooldowns[src] = 0
    end

    local currentTime = GetGameTimer()
    if currentTime - SellCooldowns[source] >= config.Cooldowns.sell then
        SellCooldowns[src] = currentTime

        if RemoveItem(src, itemName, amount) then
            local money = amount * price
            local reason = ('Blackmarket Sell for $%d (%dx %s)'):format(money, amount, itemName)
            exports['qbx_core']:AddMoney(src, 'cash', money, reason)
        end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'warn',
            description = locale('misc.on_cooldown')
        })

        local cooldown = config.Cooldowns.sell and config.Cooldowns.sell or 3000

        SetTimeout(cooldown, function()
            SellCooldowns[src] = nil
        end)
    end
end)


lib.callback.register('rv_blackmarket:server:getItemPrices', function(source)
    local prices = getBuyPrices()
    return prices
end)

exports.qbx_core:CreateUseableItem('hacking_laptop', function (source, item)
    TriggerClientEvent('rv_blackmarket:client:useHackingLaptop', source)
    print("Item", json.encode(item))
end)