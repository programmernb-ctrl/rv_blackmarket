return {

    -- blackmoney item name
    blackmoney = 'black_money',
    
    Cooldowns = {
        buy = 5000,
        sell = 15000,
    },

    -- Add items here to either sell or buy at the Dealer
    -- find item names of ox_inventory in ox_inventory/data/items.lua
    DealerItems = {

        -- ADD ITEMS HERE TO BUY AT THE DEALER
        buyable = {
            lockpick = math.random(100, 150),
            armour = math.random(600, 900),
            weapon_crowbar = math.random(200, 300),
            weapon_knuckle = math.random(600, 800)
        },

        -- ADD ITEMS YOU'D LIKE TO SELL AT THE DEAlER
        sellable = {
            phone = 150
        }
    }

}
