local resourceNames = {
    { 'qbx_core', 'qbx' },
    { 'es_extended', 'esx' }
}

local function checkCore()
    local core = nil

    for i = 1, #resourceNames do
        if GetResourceState(resourceNames[i][1]) == 'started' then
            core = resourceNames[i][2]
            break
        end
    end

    return core
end


local jobHelper = {}

function jobHelper.getJob(source)
    local core = checkCore()

    if core == 'qbx' then
        return exports['qbx_core']:GetPlayer(source).PlayerData.job
    elseif core == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return nil end
        return xPlayer.getJob()
    else
        return nil
    end
end

function jobHelper.getJobName(source)
    local job = jobHelper.getJob(source)
    return job and job.name or ''
end

function jobHelper.isPlayerGroupBlacklistedForUse(playerId)
    local jobName = jobHelper.getJobName(playerId)
    return Config.BlacklistedGroups[jobName] ~= nil or false
end

function jobHelper.isJobBlacklistedForUse(name)
    return Config.BlacklistedGroups[name] ~= nil or false
end


return jobHelper
