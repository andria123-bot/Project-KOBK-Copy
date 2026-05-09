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

function InventoryFunctions.SplitItem(inventory, slot, amount)
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
    end):catch(function(err)
        warn("Drop error:", err)
    end)

    return true
end

function InventoryFunctions.FindItem(inventory, itemName)
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
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {player.Character}

    local result = workspace:Raycast(origin, direction * RAY_DISTANCE, raycastParams)

    if result and result.Instance then
        local hitPart = result.Instance
        local droppedItem = hitPart:FindFirstAncestorWhichIsA("Model") or hitPart

        if droppedItem:GetAttribute("IsDroppedItem") then
            local itemName = droppedItem:GetAttribute("ItemName") or droppedItem.Name
            local dropId = droppedItem:GetAttribute("DropID")

            if not dropId then
                warn("PickupItem: dropped item has no DropID")
                return
            end

            print("Attempting pickup:", itemName, "DropID:", dropId)

            local InventoryService = Knit.GetService("InventoryService")

            -- Send only itemName and dropId — server finds the real position itself
            -- NEVER send position from client or destroy item on client
            InventoryService:PickupItem(itemName, dropId):andThen(function(success, message)
                if success then
                    print("Successfully picked up:", itemName)
                    -- DO NOT destroy here — server handles destruction
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
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
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

function InventoryFunctions.GetOccupiedSlots(inventory, returnCount)
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