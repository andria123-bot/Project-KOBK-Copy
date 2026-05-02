local InventoryFunctions = require(script.Parent.InventoryFunctions)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropItem = ReplicatedStorage.Shared.Remotes.InventoryFunctionEvents:WaitForChild("DropItem")
local PickupItem = ReplicatedStorage.Shared.Remotes.InventoryFunctionEvents:WaitForChild("PickupItem")

local SendServerInventoryBindable = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("SendServerInventory")

local playerInventoryData = {}
local lastDropTime = {}

SendServerInventoryBindable.Event:Connect(function(player, inventoryData)
    playerInventoryData[player] = inventoryData
end)

DropItem.OnServerEvent:Connect(function(player, itemName, slotNumber)
    -- if player and inventory data exists
    if not player or not playerInventoryData[player] then 
        warn("Drop failed: No inventory for", player and player.Name)
        return 
    end
    
    -- if slot is in valid range
    -- local maxSlots = playerInventoryData[player].SlotCount
    -- if type(slotNumber) ~= "number" or slotNumber < 1 or slotNumber > maxSlots then
    --     warn("Drop failed: Invalid slot number", slotNumber)
    --     return
    -- end
    
    -- if slot matches the item name
    -- if playerInventoryData[player][slotNumber] ~= itemName then
    --     warn(string.format("Drop failed: Item mismatch for %s. Slot %d has %s, claimed %s",
    --         player.Name, slotNumber, playerInventoryData[player][slotNumber] or "nil", itemName))
    --     return
    -- end
    
    -- if item exists in the game
    local itemTemplate = ReplicatedStorage.Weapons:FindFirstChild(itemName)
    if not itemTemplate then
        warn("Drop failed: Item doesn't exist:", itemName)
        return
    end
    
    -- rate limit
    local now = tick()
    if lastDropTime[player] and now - lastDropTime[player] < 0.2 then
        return 
    end
    lastDropTime[player] = now
    
    -- if player is alive
    local character = player.Character
    if not character or not character.Parent then
        warn("Drop failed: Player is dead or has no character")
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        warn("Drop failed: Player is dead")
        return
    end

    playerInventoryData[player][slotNumber] = ""
    print(string.format("%s dropped %s from slot %d", player.Name, itemName, slotNumber))

    InventoryFunctions.CreateItemClone(itemName, player)
end)

PickupItem.OnServerEvent:Connect(function(player, item)
    local character = player.Character
    if not character or not character.Parent then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local distance = (item.PrimaryPart.Position - root.Position).Magnitude

    print(distance)

    if distance > 10 then
        warn("Pickup failed: Item too far away")
        return
    end

    InventoryFunctions.TakeItem(player, playerInventoryData[player], item)
end)