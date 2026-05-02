local InventoryFunctions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DropItem = ReplicatedStorage.Shared.Remotes.InventoryFunctionEvents:WaitForChild("DropItem")
local PickupItem = ReplicatedStorage.Shared.Remotes.InventoryFunctionEvents:WaitForChild("PickupItem")

local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

function InventoryFunctions.MoveItem(inventory, fromSlot, toSlot)
    local fromItem = inventory[fromSlot]
    local toItem = inventory[toSlot]
    
    inventory[fromSlot] = toItem
    inventory[toSlot] = fromItem

    return inventory
end

function InventoryFunctions.SplitItem(inventory, slot, amount) -- unfinished, for future use
    local item = inventory[slot]
    if not item or item == "" then return false end

    return true
end

function InventoryFunctions.DropItem(inventory, slot)
    local item = inventory[slot]
    if not item then return end

    DropItem:FireServer(item)
    return true
end

function InventoryFunctions.HasItem(inventory, slot)
    local item = inventory[slot]
    return item and item ~= ""
end

function InventoryFunctions.FindItem(inventory, itemName) -- for search
    for i, item in pairs(inventory) do
        local name = type(item) == "table" and item.name or item
        if name == itemName then
            return i, item
        end
    end
    return nil, nil
end

function InventoryFunctions.FindEmptySlot(inventory)
    for i, v in pairs(inventory) do
        if v == nil or v == "" then
            return i
        end
    end

    return nil
end

function InventoryFunctions.HasSpace(inventory)
    return InventoryFunctions.FindEmptySlot(inventory) ~= nil
end

function InventoryFunctions.PickupItem(inventory)
    local emptySlot = InventoryFunctions.FindEmptySlot(inventory)
    if emptySlot then
        local origin = camera.CFrame.Position
        local direction = camera.CFrame.LookVector
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {player.Character}

        local result = workspace:Raycast(origin, direction * 5, raycastParams)
        if result then
            local hit = result.Instance
            local droppedItem = hit:FindFirstAncestorWhichIsA("Model")
            if droppedItem and droppedItem:GetAttribute("IsDroppedItem") then
                PickupItem:FireServer(droppedItem.Name)
            end
        end
    end

    return false
end

function InventoryFunctions.GetOccupiedSlots(inventory, returnCount) -- usage: local count = InventoryFunctions.GetOccupiedSlots(inventory, true)  -- Returns number, true means number
    local occupied = {}
    for i = 1, #inventory do
        if inventory[i] and inventory[i] ~= "" then
            table.insert(occupied, i)
        end
    end
    
    if returnCount then
        return #occupied
    end

    return occupied
end

return InventoryFunctions