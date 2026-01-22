return {

    versionCheck = true,

    -- Switch between ox_lib notify or core's default notifaction system
    -- { 'ox_lib', 'qbx', 'esx' }
    notify = 'ox_lib',

    -- blackmoney item name
    blackmoney = 'black_money',

    -- add items here to sell or buy at the dealer.
    -- find items in ox_inventory/data/items.lua
    DealerItems = {

        -- ITEMS TO BUY AT THE DEALER
        buyable = {
            lockpick = 150,
            armour = 250,
            weapon_crowbar = 90,
            weapon_knuckle = 290
        },

        -- ITEMS TO SELL AT THE DEAlER
        sellable = {
            phone = 150
        }
    },

    -- cooldown time on buying and selling items
    Cooldowns = {
        buy = 3000,   -- default: 3000
        sell = 15000, -- default: 15000
    },

    -- add money to player account
    ---@param playerId number
    ---@param moneyType string look up framework addMoney function
    ---@param amount number
    ---@param reason string?
    addMoney = function(playerId, moneyType, amount, reason)
        if GetResourceState('qbx_core') == 'started' then
            exports['qbx_core']:AddMoney(playerId, moneyType, amount, reason)
        elseif GetResourceState('es_extended') == 'started' then
            if moneyType == "cash" then moneyType = "money" end
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if not xPlayer then return end
            xPlayer.addAccountMoney(moneyType, amount, reason)
        end
    end

}
