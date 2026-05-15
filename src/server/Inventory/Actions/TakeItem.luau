-- TakeItem.luau
-- Handles picking up items from the world

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HashManager = require(script.Parent.Parent.Core.HashManager)
local SlotManager = require(script.Parent.Parent.Core.SlotManager)
local SlotMappings = require(script.Parent.Parent.Data.SlotMappings)

local TakeItem = {}

-- Cooldown tracking
local takeCooldowns = {} -- [playerUserId_itemId] = lastTakeTime
local TAKE_COOLDOWN = 0.5

-- ============================================================
-- MAIN TAKE FUNCTION
-- ============================================================

function TakeItem.TakeLoot(player, worldModel)
    if not player or not worldModel then
        return false, "Invalid parameters"
    end
    
    -- Cooldown check
    local now = os.time()
    local cooldownKey = player.UserId .. "_" .. worldModel.Name
    local lastTake = takeCooldowns[cooldownKey] or 0
    if now - lastTake < TAKE_COOLDOWN then
        return false, "Take on cooldown"
    end
    takeCooldowns[cooldownKey] = now
    
    local manager = HashManager.getPlayer(player)
    if not manager then
        return false, "No manager found"
    end
    
    -- Get item name and properties from world model
    local itemName = worldModel.Name
    local itemType = TakeItem.GetItemTypeFromModel(worldModel)
    local slotType = TakeItem.GetSlotTypeFromModel(worldModel)
    
    -- Find available slot for this item
    local targetSlot = SlotManager.FindAvailableSlot(manager, itemName, itemType, slotType)
    
    if not targetSlot then
        return false, "No available slots"
    end
    
    -- Package the world model into a StringValue
    local newItem = TakeItem.PackageItem(worldModel, targetSlot)
    if not newItem then
        return false, "Failed to package item"
    end
    
    -- Add to player's inventory
    local success = TakeItem.AddToInventory(manager, newItem, targetSlot)
    if not success then
        newItem:Destroy()
        return false, "Failed to add to inventory"
    end
    
    -- Destroy the world model
    worldModel:Destroy()
    
    -- Refresh manager
    manager:refresh()
    
    return true, "Success"
end

-- Get item type from world model
function TakeItem.GetItemTypeFromModel(worldModel)
    local props = worldModel:FindFirstChild("ItemProperties")
    if props then
        local itemType = props:FindFirstChild("ItemType")
        if itemType then
            return itemType.Value
        end
    end
    return "Unknown"
end

-- Get slot type from world model
function TakeItem.GetSlotTypeFromModel(worldModel)
    local props = worldModel:FindFirstChild("ItemProperties")
    if props then
        local slotType = props:FindFirstChild("SlotType")
        if slotType then
            return slotType.Value
        end
    end
    return nil
end

-- Package world model into StringValue for inventory
function TakeItem.PackageItem(worldModel, targetSlot)
    local itemsList = ReplicatedStorage:FindFirstChild("ItemsList")
    if not itemsList then
        warn("ItemsList not found")
        return nil
    end
    
    local template = itemsList:FindFirstChild(worldModel.Name)
    if not template then
        warn("No template for:", worldModel.Name)
        return nil
    end
    
    local newItem = template:Clone()
    newItem.Value = targetSlot
    
    -- Copy properties from world model
    local worldProps = worldModel:FindFirstChild("ItemProperties")
    if worldProps then
        local itemProps = newItem:FindFirstChild("ItemProperties")
        if itemProps then
            -- Copy durability
            local durability = worldProps:FindFirstChild("Durability")
            if durability and itemProps:FindFirstChild("Durability") then
                itemProps.Durability.Value = durability.Value
            end
            
            -- Copy max durability
            local maxDurability = worldProps:FindFirstChild("MaxDurability")
            if maxDurability and itemProps:FindFirstChild("MaxDurability") then
                itemProps.MaxDurability.Value = maxDurability.Value
            end
            
            -- Copy amount (for stackable items)
            local amount = worldProps:FindFirstChild("Amount")
            if amount and itemProps:FindFirstChild("Amount") then
                itemProps.Amount.Value = amount.Value
            end
            
            -- Copy skin
            local skin = worldProps:FindFirstChild("Skin")
            if skin and skin.Value ~= "" and itemProps:FindFirstChild("Skin") then
                itemProps.Skin.Value = skin.Value
            end
        end
    end
    
    -- Copy container items (items inside backpack, etc.)
    local worldInventory = worldModel:FindFirstChild("Inventory")
    if worldInventory then
        local newInventory = Instance.new("Folder")
        newInventory.Name = "Inventory"
        newInventory.Parent = newItem
        
        for _, subItem in pairs(worldInventory:GetChildren()) do
            if subItem:IsA("StringValue") then
                local subClone = subItem:Clone()
                -- Remove "Container" prefix if present
                local slotName = subClone.Name
                if string.sub(slotName, 1, 9) == "Container" then
                    subClone.Name = string.sub(slotName, 10)
                end
                subClone.Parent = newInventory
            end
        end
        
        -- Copy Slots attribute
        local slots = worldInventory:GetAttribute("Slots")
        if slots then
            newInventory:SetAttribute("Slots", slots)
        end
    end
    
    -- Copy attachments (for weapons)
    local worldAttachments = worldModel:FindFirstChild("Attachments")
    if worldAttachments then
        local newAttachments = Instance.new("Folder")
        newAttachments.Name = "Attachments"
        newAttachments.Parent = newItem
        
        for _, attachFolder in pairs(worldAttachments:GetChildren()) do
            local folderClone = attachFolder:Clone()
            folderClone.Parent = newAttachments
        end
    end
    
    return newItem
end

-- Add packaged item to player's inventory
function TakeItem.AddToInventory(manager, item, targetSlot)
    local targetFolder = TakeItem.GetTargetFolder(manager, targetSlot)
    if not targetFolder then
        return false
    end
    
    item.Parent = targetFolder
    return true
end

-- Get the correct folder for a slot
function TakeItem.GetTargetFolder(manager, slotName)
    local sessionProfile = manager.sessionProfile
    if not sessionProfile then
        return nil
    end
    
    local baseSlot = SlotMappings.GetBaseSlot(slotName)
    
    -- Check if it's a numbered container slot (Backpack1, Pants3, etc.)
    local containerType, slotNumber = SlotMappings.ParseNumberedSlot(slotName)
    if containerType and slotNumber then
        -- Find the clothing item that has this container
        local clothingFolder = sessionProfile:FindFirstChild("Clothing")
        if clothingFolder then
            local clothingSlotMap = {
                Backpack = "ClothingBackpack",
                Pants = "ClothingPants",
                Shirt = "ClothingShirt",
                ChestRig = "ClothingChestRig",
            }
            local clothingSlot = clothingSlotMap[containerType]
            if clothingSlot then
                local clothingItem = clothingFolder:FindFirstChild(clothingSlot)
                if clothingItem then
                    local invFolder = clothingItem:FindFirstChild("Inventory")
                    if invFolder then
                        return invFolder
                    end
                end
            end
        end
        return nil
    end
    
    -- Hotbar slots (equipped weapons and utilities)
    if SlotMappings.IsHotbarSlot(slotName) then
        return sessionProfile:FindFirstChild("Hotbar")
    end
    
    -- Weapon inventory slots (storage)
    if SlotMappings.IsWeaponInventorySlot(slotName) then
        return sessionProfile:FindFirstChild("Inventory")
    end
    
    -- Clothing slots
    if string.find(slotName, "Clothing") then
        return sessionProfile:FindFirstChild("Clothing")
    end
    
    -- Tool slots (GPS, Map, Compass, Melee)
    return sessionProfile:FindFirstChild("Equipment")
end

-- Clear cooldown for testing
function TakeItem.ClearCooldown(player, itemId)
    local cooldownKey = player.UserId .. "_" .. itemId
    takeCooldowns[cooldownKey] = nil
end

return TakeItem