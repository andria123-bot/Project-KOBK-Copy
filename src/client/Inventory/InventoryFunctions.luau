local InventoryFunctions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Packages.Knit)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local RAY_DISTANCE = 10

function InventoryFunctions.HasItem(playerInventoryData, itemName)
    for _, item in pairs(playerInventoryData) do
        if item == itemName then
            return true
        end
    end
    return false
end

function InventoryFunctions.SplitItem(inventory, slot, amount) -- unfinished, for future use
    local item = inventory[slot]
    if not item or item == "" then return false end

    return true
end

function InventoryFunctions.DropItem(inventory, slot)
    local item = inventory[slot]
    if not item then return end
    
    local InventoryService = Knit.GetService("InventoryService")
    
    InventoryService:DropItem(slot):andThen(function(success, droppedItem)
        if success then
            print("Dropped:", droppedItem)
        end
    end)
    
    return true
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

function InventoryFunctions.PickupItem()
    local mouseLocation = player:GetMouse().UnitRay
    local origin = camera.CFrame.Position
    local direction = mouseLocation.Direction
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local result = workspace:Raycast(origin, direction * RAY_DISTANCE, raycastParams)
    
    if result and result.Instance then
        local hitPart = result.Instance
        
        -- Get the actual model (could be the part's parent or the part itself)
        local droppedItem = hitPart:FindFirstAncestorWhichIsA("Model") or hitPart
        
        -- Check if the model has the attribute
        if droppedItem:GetAttribute("IsDroppedItem") then
            print("Found dropped item:", droppedItem.Name)
            local itemName = droppedItem.Name or droppedItem:GetAttribute("ItemName")
            
            local dropId = droppedItem:GetAttribute("DropID") or tostring(droppedItem)
            
            local InventoryService = Knit.GetService("InventoryService")
            InventoryService:PickupItem(itemName, dropId):andThen(function(success, message)
                if success then
                    print("Successfully picked up:", itemName)
                    droppedItem:Destroy() -- Destroy the model
                else
                    warn("Failed to pick up:", message)
                end
            end):catch(function(err)
                warn("Pickup error:", err)
            end)
        end
    end
end

function InventoryFunctions.GetLookedAtItem()
    local mouseLocation = player:GetMouse().UnitRay
    local origin = camera.CFrame.Position
    local direction = mouseLocation.Direction
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {player.Character}
    
    local result = workspace:Raycast(origin, direction * RAY_DISTANCE, raycastParams)
    
    if result and result.Instance then
        local hitItem = result.Instance
        if hitItem:GetAttribute("IsDroppedItem") then
            return hitItem, result.Distance
        end
    end
    
    return nil, nil
end

function InventoryFunctions.ReturnAvailableSlot(inventory)
    for slot = 1, #inventory do
        if inventory[slot] == "" then
            return slot
        end
    end
    return nil
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