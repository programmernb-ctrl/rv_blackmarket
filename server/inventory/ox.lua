if GetResourceState('ox_inventory') ~= 'started' then
    return
end

local inventory = exports['ox_inventory']

Items = function(name)
    local item = inventory:Items(name)
    return item
end

GetItemCount = function(source, item)
    local count = inventory:GetItemCount(source, item, nil, true)
    return count
end

AddItem = function(source, item, count)
    return inventory:AddItem(source, item, count)
end

RemoveItem = function(source, item, count)
    return inventory:RemoveItem(source, item, count)
end
