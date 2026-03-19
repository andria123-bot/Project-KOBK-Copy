local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

script.Parent.Parent.Inventory.Parent = player.PlayerGui:WaitForChild("Menu").MainParent

-- local moduleFinder = require(game:GetService("StarterPlayer").StarterCharacterScripts.WeaponSystem.LoadModule)
local RequestModule = ReplicatedStorage.Shared.Remotes:WaitForChild("RequestModule")

local SlotInitializer = require(script.Parent.SlotInitializer)
local DragAndDropSys = require(script.Parent.DragAndDropSys)
SlotInitializer:InitSys()
SlotInitializer:ApplyParentSize()
SlotInitializer:ApplyRows()

local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

local templateSlot = ReplicatedStorage.GUIS:WaitForChild("Slot")

local slots = SlotInitializer.slots


function createSlotForBackpack(index, parent)
	local newSlot = templateSlot:Clone()
    newSlot.Name = "Slot" .. index
    newSlot.Parent = parent
    return newSlot
end

SendInventory.OnClientEvent:Connect(function(inventory)
    if not inventory then return end
    
    local toolbarCount = #slots.toolbar
    local utilsCount = #slots.utils
    local gearCount = 3 -- Armor, TShirt, Pants
    
    for i = 1, toolbarCount do
        local itemName = inventory[i]
        local slot = slots.toolbar[i]
        if slot then
            if itemName and itemName ~= "" then
                task.spawn(function()
                    local weaponModule = RequestModule:InvokeServer(itemName)
                    if weaponModule then
                        slot.ItemIcon.Image = weaponModule.imageIconId
                    end
                end)
            else
                slot.ItemIcon.Image = ""
            end
        end
    end
    
    for i = 1, utilsCount do
        local itemName = inventory[toolbarCount + i]
        local slot = slots.utils[i]
        if slot then
            if itemName and itemName ~= "" then
                task.spawn(function()
                    local itemModule = RequestModule:InvokeServer(itemName)
                    if itemModule then
                        slot.ItemIcon.Image = itemModule.imageIconId
                    end
                end)
            else
                slot.ItemIcon.Image = ""
            end
        end
    end
    
    local gearTypes = {"Armor", "TShirt", "Pants"}
    for i, gearType in ipairs(gearTypes) do
        local gearSlot = slots.gear[gearType]
        if gearSlot then
            local gearIndex = #inventory - gearCount + i
            local itemName = inventory[gearIndex]
            
            if itemName and itemName ~= "" then
                task.spawn(function()
                    local gearModule = RequestModule:InvokeServer(itemName)
                    if gearModule then
                        gearSlot.ItemIcon.Image = gearModule.imageIconId
                    end
                end)
            else
                gearSlot.ItemIcon.Image = ""
            end
        end
    end
    
    for i, slot in pairs(slots.inventory) do
        local itemName = inventory[toolbarCount + utilsCount + gearCount + i]
        if itemName and itemName ~= "" then
            task.spawn(function()
                local itemModule = RequestModule:InvokeServer(itemName)
                if itemModule then
                    slot.ItemIcon.Image = itemModule.imageIconId
                end
            end)
        else
            slot.ItemIcon.Image = ""
        end
    end
end)