local QuestService = {}

---@param source Source identifier
---@param idx integer Config.Quests[idx] Quest Index
function QuestService.startQuest(source, idx)
    local state = Player(source).state
    local isQuesting = state.isquesting

    if QuestService.getActiveQuest(source) or isQuesting then
        TriggerClientEvent('ox_lib:notify', source {
            type = 'warn',
            title = 'Quest',
            description = locale('misc.already_on_quest')
        })
        return
    end

    local quest = Config.Quests[idx]

    if not quest then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            title = 'Quest',
            description = locale('misc.failed_receive_quest')
        })
        return
    end

    PlayerIsQuesting[source] = source

    TriggerClientEvent('rv_blackmarket:client:setupQuest', source, idx, quest)

    state:set('isquesting', true, true)
end

---@param source Source
function QuestService.getActiveQuest(source)
    return PlayerIsQuesting[source] ~= nil
end

---@param source Source
function QuestService.stopActiveQuest(source)
    local state = Player(source).state
    local isQuesting = state.isquesting
    if QuestService.getActiveQuest(source) and isQuesting then
        PlayerIsQuesting[source] = nil
        state:set('isquesting', nil, true)
    end
end

return QuestService
