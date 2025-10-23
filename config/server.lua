return {

    -- ox_inventory blackmoney item name
    blackmoney = 'black_money',

    -- ADD AS MUCH ITEMS YOU LIKE, OR CHANGE PRICES
    DealerItems = {

        buyable = {
            lockpick = math.random(100, 150),
            armour = math.random(600, 900),
            weapon_crowbar = math.random(200, 300)
        },

        sellable = {
            --
        }
    }

}
