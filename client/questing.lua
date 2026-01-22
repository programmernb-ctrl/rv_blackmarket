local quest = {
    idx = 0,
    description = nil,
    type = 'unknown'
}

---@param index number
---@param type QuestTypes
---@param description string
local function setQuestData(index, type, description)
    quest.idx = index
    quest.type = type
    quest.description = description
end

local function pickAnim()
    lib.playAnim(cache.ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 8.0, -4.0, 8000)
end

local function pickupItem()
    if IsControlJustReleased(0, 38) then
        lib.hideTextUI()

        pickAnim()

        while IsEntityPlayingAnim(cache.ped, 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', 'machinic_loop_mechandplayer', 3) do
            Wait(0)
        end

        ShowSubtitle('~g~Erfolgreich~s~ Gegenstände beschaffen', 10000)

        return 'finish'
    end

    return nil
end

local function startQuestThread()
    CreateThread(function()
        local state = LocalPlayer.state
        local time = GetGameTimer()
        local maxTime = (1000 * 60) * 30 -- 30 minutes

        while state.isquesting do
            Wait(1000)

            if GetGameTimer() - time >= maxTime then
                lib.notify({
                    title = 'Quest',
                    description = 'Zeit um die Quest abzuschließen ist abgelaufen!',
                    type = 'error'
                })

                state:set('isquesting', nil, true)

                break
            end

        end
    end)
end

---@param idx number quest index
local function getQuestReward(idx)
    lib.callback('rv_blackmarket:server:getReward', false, function (success, response)
        if not success then
            lib.print.error(response.message)

            lib.notify({
                title = 'Quest',
                description = 'Fehler beim Erhalten der Belohnung',
                type = 'error'
            })

            return
        end

        lib.notify({
            title = 'Quest',
            description = 'Belohnung erfolgreich erhalten!',
            type = 'success'
        })

        return success
    end, idx)
end

RegisterNetEvent('rv_blackmarket:client:setupQuest', function (index, data)
    print('Quest: ', json.encode(quest, { indent = true }))
    setQuestData(index, data.type, data.description)
    startQuestThread()
end)

AddStateBagChangeHandler('isquesting', ('player:%d'):format(cache.serverId), function (_, _, value, _, _)
    if value then
        ShowSubtitle(quest.description, 10000)
    else
        quest.idx = 0
        quest.type = QuestTypes.UNKNOWN
        quest.description = nil
    end
end)
