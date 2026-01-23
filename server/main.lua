local serverConfig = require 'config.server'
local jobHelper = require 'server.helpers.jobHelper'
--local QuestService = require 'server.services.questService'

if serverConfig.versionCheck and not lib.checkDependency('rv_blackmarket', '1.0.0') then
    lib.print.warn('You need atleast version 1.0.0 of the script! get the script on github: https://github.com/programmernb-ctrl/rv_blackmarket')
    return
end

---@type table <number, number>
SellCooldowns = {}
---@type table <number, number>
BuyCooldowns = {}
---@type table<number, number>
PlayerIsQuesting = {}

local function notifyPlayer(source, ...)
    if serverConfig.notify == 'qbx' and GetResourceState('qbx_core') == 'started' then
        TriggerClientEvent('QBCore:Client:Notify', source, ...)
    elseif serverConfig.notify == 'esx' and GetResourceState('es_extended') == 'started' then
        TriggerClientEvent('esx:showNotification', source, ...)
    elseif serverConfig.notify == 'ox_lib' and GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', source, ...)
    end
end

local function getBuyPrices()
    local prices = lib.table.deepclone(serverConfig.DealerItems.buyable)
    return prices
end

local function getSellPrices()
    local prices = lib.table.deepclone(serverConfig.DealerItems.sellable)
    return prices
end

local function getBuyOptions()
    local prices = getBuyPrices()
    local options = {}

    for key, value in pairs(prices) do
        local item = Items(key).label
        options[#options + 1] = {
            title = item,
            description = locale('misc.price', value),
            serverEvent = 'rv_blackmarket:server:buyItem',
            args={key}
        }
    end

    return options
end

local function getSellOptions()
    local prices = getSellPrices()
    local options = {}

    for key, value in pairs(prices) do
        local item = Items(key).label
        options[#options + 1] = {
            title = item,
            description = locale('misc.price', value),
            serverEvent = 'rv_blackmarket:server:sellItem',
            args={key}
        }
    end

    return options
end

local function isNearDealer(source)
    return lib.callback.await('rv_blackmarket:client:isNearDealer', source)
end

local function onPurchaseMenuOpen(source)
    if jobHelper.isPlayerGroupBlacklistedForUse(source) then return end
    if not isNearDealer(source) then
        notifyPlayer(source, {
            type = 'error',
            description = locale('misc.not_allowed')
        })
        return
    end

    local options = getBuyOptions()
    TriggerClientEvent('rv_blackmarket:client:onMenuOpenedPurchase', source, options)
end

local function onSellMenuOpen(source)
    if jobHelper.isPlayerGroupBlacklistedForUse(source) then return end
    if not isNearDealer(source) then
        notifyPlayer(source, {
            type = 'error',
            description = locale('misc.not_allowed')
        })
        return
    end

    local options = getSellOptions()
    TriggerClientEvent('rv_blackmarket:client:onMenuOpenedSell', source, options)
end


function DoesQuestTypeExist(type)
    for _, value in pairs(QuestTypes) do
        if value == type then
            return true
        end
    end
end


lib.callback.register('rv_blackmarket:server:getItemPrices', function(source)
    local prices = getBuyPrices()
    return prices
end)

lib.callback.register('rv_blackmarket:server:isGroupBlacklisted', function(source, group)
    local blacklisted = jobHelper.isJobBlacklistedForUse(group)
    return blacklisted
end)


AddEventHandler('playerDropped', function (_, _, _)
    if SellCooldowns[source] then SellCooldowns[source] = nil end
    if BuyCooldowns[source] then BuyCooldowns[source] = nil end
end)


RegisterNetEvent('rv_blackmarket:server:openPurchaseMenu', function()
    onPurchaseMenuOpen(source)
end)

RegisterNetEvent('rv_blackmarket:server:openSellMenu', function ()
    onSellMenuOpen(source)
end)

RegisterNetEvent('rv_blackmarket:server:buyItem', function(data)
    if not isNearDealer(source) then return end

    local item = data[1]
    if not item then return end

    local amount = lib.callback.await('rv_blackmarket:client:choosedAmount', source, locale('misc.purchase'))
    if not amount then return end

    local price = serverConfig.DealerItems.buyable[item] -- returns the price
    if not price or price <= 0 then return end

    local newPrice = amount * price

    local count = GetItemCount(source, serverConfig.blackmoney)
    if count <= newPrice then
        notifyPlayer(source, {
            type = 'error',
            description = locale('misc.insufficient_funds')
        })
        return
    end

    if not BuyCooldowns[source] then
        BuyCooldowns[source] = 0
    end

    local time = GetGameTimer()
    if time - BuyCooldowns[source] >= serverConfig.Cooldowns.buy then
        BuyCooldowns[source] = GetGameTimer()

        if RemoveItem(source, serverConfig.blackmoney, newPrice) then
            local success = AddItem(source, item, amount)
            if not success then
                notifyPlayer(source, {
                    type = 'error',
                    description = locale('misc.not_added_item')
                })
            end
        end
    else
        notifyPlayer(source, {
            type = 'warn',
            description = locale('misc.on_cooldown')
        })

        local cooldown = serverConfig.Cooldowns.buy and serverConfig.Cooldowns.buy or 3000
        SetTimeout(cooldown, function()
            BuyCooldowns[source] = nil
        end)
    end
end)

RegisterNetEvent('rv_blackmarket:server:sellItem', function (item)
    if not isNearDealer(source) then return end
    if not item then return end

    local amount = lib.callback.await('rv_blackmarket:client:choosedAmount', source, locale('misc.sale'))

    if not amount then return end

    local itemName = item[1]
    local count = GetItemCount(source, itemName)

    if count < amount then
        notifyPlayer(source, {
            type = 'error',
            description = locale('misc.not_enough_items')
        })
        return
    end

    if not SellCooldowns[source] then SellCooldowns[source] = 0 end
    if GetGameTimer() - SellCooldowns[source] >= serverConfig.Cooldowns.sell then
        SellCooldowns[source] = GetGameTimer()

        if RemoveItem(source, itemName, amount) then
            local price = serverConfig.DealerItems.sellable[itemName]
            local money = amount * price
            local reason = ('Blackmarket Sell for $%d (%dx %s)'):format(money, amount, itemName)

            serverConfig.addMoney(source, 'cash', money, reason)
        end
    else
        notifyPlayer(source, {
            type = 'warn',
            description = locale('misc.on_cooldown')
        })

        local cooldown = serverConfig.Cooldowns.sell or 3000

        SetTimeout(cooldown, function()
            SellCooldowns[source] = nil
        end)
    end
end)

/**
RegisterNetEvent('rv_blackmarket:server:getQuest', function (arguments)
    QuestService.startQuest(source, arguments?.idx)
end)

RegisterNetEvent('rv_blackmarket:server:removeQuestItems', function ()
    -- todo: implement removing quest items after quest is done
    -- local playerItems = exports.ox_inventory:GetInventoryItems(source)
    -- for i = 1, #playerItems do
    --     print(('remove quest item: %s'):format(json.encode(playerItems[i], { indent = true })))
    -- end
end)

lib.callback.register('rv_blackmarket:server:getReward', function (source, idx)
    if not Config.Quests[idx] then
        return nil, {
            code = 'invalid_index',
            message = 'Invalid quest index'
        }
    end

    if not QuestService.getActiveQuest(source) then
        return nil, {
            code = 'no_active_quest',
            message = 'No active quest found'
        }
    end

    QuestService.stopActiveQuest(source)

    local rewards = Config.Quests[idx].rewards

    for i = 1, #rewards do
        local success, response = AddItem(source, rewards[i].item, rewards[i].amount, { type = locale('misc.title') })
        assert(success, response)
    end

    return 'received_reward', nil
end)
**/
