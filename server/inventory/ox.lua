if GetResourceState('ox_inventory') ~= 'started' then
    return
end

local ox_inventory = exports['ox_inventory']

Items = function(name)
    local item = ox_inventory:Items(name)
    return item
end

GetItemCount = function(source, item)
    local count = ox_inventory:GetItemCount(source, item, nil, true)
    return count
end

AddItem = function(source, item, count, metadata)
    metadata = metadata or nil
    return ox_inventory:AddItem(source, item, count, metadata)
end

RemoveItem = function(source, item, count)
    return ox_inventory:RemoveItem(source, item, count)
end
