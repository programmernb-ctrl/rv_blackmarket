Config = {}

---BLACKLISTED GROUPS FOR BLACKMARKET
---@type table <string>
Config.BlacklistedGroups = {
    'mechanic',
    'police',
    'leo'
}

---@class ConfigDealer
---@field model string|integer
---@field pos vector3|vector4
---@field scenario string

---DEALER
---@type ConfigDealer[]
Config.Dealer = {
    {
        model = `G_M_M_ChiCold_01`,
        pos = vec4(-1724.65, 234.59, 57.47, 26.2),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', -- default: nil, if none ped will not start any scenario
    },
}

---@class ConfigReward
---@field item string
---@field amount number

---@type table<number, ConfigReward>
Config.Rewards = {
    [1] = { item = 'lighter', amount = 1 },
    [2] = { item = 'ammo-9', amount = 10 },
    [3] = { item = 'joint', amount = 3 },
    [4] = { item = 'weed_lemonhaze_seed', amount = 5 },
    [5] = { item = 'fertilizer', amount = 4 },
    [6] = { item = 'papers', amount = 11 },
    [7] = { item = 'joint', amount = 6 },
    [8] = { item = 'cash', amount = 500 },
    [9] = { item = 'usb_cable', amount = 1 },
    [10] = { item = 'cash', amount = 1000 },
}

---@class ConfigQuest
---@field type QuestTypes
---@field title string
---@field description string
---@field rewards ConfigReward[]
---@field coords? vector3

-- DONT TOUCH ANYTHING BELOW THIS LINE! NOT IMPLEMENTED YET!!!
---@type table <number, ConfigQuest>
Config.Quests = {

    [1] = {
        type = QuestTypes.STEAL,
        title = 'Beschaffe Ware',
        description = 'Hole 1x Gestohlene Kiste Arzeneimittel (Apotheke)',
        coords = vec3(0, 0, 0),
        rewards = {
            { item = Config.Rewards[4].item, amount = Config.Rewards[4].amount }
        }
    },

    [2] = {
        type = QuestTypes.STEAL,
        title = 'Beschaffe Ware',
        description = 'Hole 3x Gestohlene Kisten Bier (Liquor Store)',
        rewards = {
            { item = Config.Rewards[2].item, amount = Config.Rewards[2].amount }
        }
    },

    [3] = {
        type = QuestTypes.STEAL,
        title = 'Beschaffe Ware',
        description = 'Hole 5x Gestohlene Kisten Munition (Ammunation)',
        rewards = {
            { item = 'cash', amount = 250 }
        }
    }

}

-- Sets questing state on client
Config.startQuest = function ()
    local state = LocalPlayer.state
    local isQuesting = state.isquesting
    if isQuesting then return end
    state:set('isquesting', true, false)
end
