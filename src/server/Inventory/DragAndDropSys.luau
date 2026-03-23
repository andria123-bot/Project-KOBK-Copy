local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DragAndDropSys = {}

local MoveItem = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("MoveItem")
local defaultInventory = require(script.Parent.Parent.DataSave.loadStarterInventory)
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

local PlayerInventories = {}


MoveItem.OnServerEvent:Connect(function(player, fromSlot, toSlot)
    local inventory = PlayerInventories[player]
    local item = inventory[fromSlot]

    -- if typeof(fromSlot) ~= "number" or typeof(toSlot) ~= "number" then return end
    -- if not inventory[fromSlot] then return end
    -- if fromSlot < 1 or toSlot < 1 then return end

    if not fromSlot or not toSlot then return end
    if not item or item == "" then return end
    if fromSlot == toSlot then return end

    if inventory[toSlot] and inventory[toSlot] ~= "" then
        local temp = inventory[fromSlot]
        inventory[fromSlot] = inventory[toSlot]
        inventory[toSlot] = temp
    else
        inventory[toSlot] = item
        inventory[fromSlot] = ""
    end 

    defaultInventory.saveInventory(player, {weaponSystem = {inventory = inventory}})
    SendInventory:FireClient(player, inventory)
end)


return DragAndDropSys