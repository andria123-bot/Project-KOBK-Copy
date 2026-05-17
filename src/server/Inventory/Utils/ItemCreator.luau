-- ItemCreator.luau
-- Handles creation of inventory items, clothing, weapons, and tools

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SlotMappings = require(script.Parent.Parent.Data.SlotMappings)
local Helpers = require(script.Parent.Helpers)

local ItemCreator = {}

-- Server-side module loader (doesn't use RemoteEvent)
local function GetModuleServer(itemName)
    local LoadModule = require(ServerScriptService.Server.ModuleHandler.LoadModule)
    local success, module = pcall(function()
        return LoadModule.GetModule(itemName)
    end)
    if success and module then
        return module
    end
    return nil
end

-- Get slot count from item module (Server version)
function ItemCreator.GetSlotCountFromItem(itemName)
    local module = require(GetModuleServer(itemName))
    print(module)
    if module and module.slotCount then
        return module.slotCount
    end
    
    -- Fallback slot counts
    local fallbacks = {
        ["6B45"] = 5,
        WorkingTShirt = 4,
        WorkingPants = 6,
    }
    return fallbacks[itemName] or 5
end

-- Create a clothing item with Inventory folder
function ItemCreator.CreateClothing(player, itemName, slotType)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then
        warn("[ItemCreator]: Player folder not found for", player.Name)
        return nil
    end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then
        clothingFolder = Instance.new("Folder")
        clothingFolder.Name = "Clothing"
        clothingFolder.Parent = playerFolder
    end
    
    -- Remove existing item with same name
    local existing = clothingFolder:FindFirstChild(itemName)
    if existing then
        existing:Destroy()
    end
    
    -- Create new clothing item
    local stringValue = Instance.new("StringValue")
    stringValue.Name = itemName
    stringValue.Value = slotType -- "Armor", "TShirt", "Pants"
    stringValue.Parent = clothingFolder
    
    -- Create ItemProperties
    Helpers.createItemProperties(stringValue, itemName)
    
    -- Create Inventory folder for containers
    local invFolder = Instance.new("Folder")
    invFolder.Name = "Inventory"
    invFolder.Parent = stringValue
    
    -- Get slot count from module
    local slotCount = ItemCreator.GetSlotCountFromItem(itemName)
    invFolder:SetAttribute("Slots", slotCount)
    
    print("[ItemCreator]: Created clothing", itemName, "with", slotCount, "slots")
    return stringValue
end

-- Create a weapon in hotbar
function ItemCreator.CreateWeapon(player, hotbarSlot, weaponName)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then
        warn("[ItemCreator]: Player folder not found for", player.Name)
        return nil
    end
    
    local hotbarFolder = playerFolder:FindFirstChild("Hotbar")
    if not hotbarFolder then
        hotbarFolder = Instance.new("Folder")
        hotbarFolder.Name = "Hotbar"
        hotbarFolder.Parent = playerFolder
        
        -- Create all hotbar slots if they don't exist
        for _, slotName in pairs(SlotMappings.HotbarSlots) do
            local slot = Instance.new("StringValue")
            slot.Name = slotName
            slot.Value = ""
            slot.Parent = hotbarFolder
        end
    end
    
    local slot = hotbarFolder:FindFirstChild(hotbarSlot)
    if slot then
        slot.Value = weaponName
        print("[ItemCreator]: Created weapon", weaponName, "in slot", hotbarSlot)
    else
        warn("[ItemCreator]: Hotbar slot not found:", hotbarSlot)
    end
    
    return slot
end

-- Create a tool (Melee, GPS, Map, Compass)
function ItemCreator.CreateTool(player, toolSlot, toolName)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then
        warn("[ItemCreator]: Player folder not found for", player.Name)
        return nil
    end
    
    local equipmentFolder = playerFolder:FindFirstChild("Equipment")
    if not equipmentFolder then
        equipmentFolder = Instance.new("Folder")
        equipmentFolder.Name = "Equipment"
        equipmentFolder.Parent = playerFolder
        
        -- Create all tool slots if they don't exist
        local toolSlots = { "Melee", "EquipmentGPS", "EquipmentMap", "EquipmentLighter", "EquipmentCompass" }
        for _, slotName in pairs(toolSlots) do
            local slot = Instance.new("StringValue")
            slot.Name = slotName
            slot.Value = ""
            slot.Parent = equipmentFolder
        end
    end
    
    local slot = equipmentFolder:FindFirstChild(toolSlot)
    if slot then
        slot.Value = toolName
        print("[ItemCreator]: Created tool", toolName, "in slot", toolSlot)
    else
        warn("[ItemCreator]: Tool slot not found:", toolSlot)
    end
    
    return slot
end

-- Add item to a clothing's inventory
function ItemCreator.AddItemToClothing(player, clothingName, slotNumber, itemName)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then
        warn("[ItemCreator]: Player folder not found for", player.Name)
        return nil
    end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then
        warn("[ItemCreator]: Clothing folder not found")
        return nil
    end
    
    local clothingItem = clothingFolder:FindFirstChild(clothingName)
    if not clothingItem then
        warn("[ItemCreator]: Clothing item not found:", clothingName)
        return nil
    end
    
    -- Get or create Inventory folder
    local invFolder = clothingItem:FindFirstChild("Inventory")
    if not invFolder then
        invFolder = Instance.new("Folder")
        invFolder.Name = "Inventory"
        invFolder.Parent = clothingItem
    end
    
    -- Get slot type from clothing value ("Armor", "TShirt", "Pants")
    local slotType = clothingItem.Value
    local slotPosition = slotType .. slotNumber
    
    -- Create the item
    local item = Instance.new("StringValue")
    item.Name = itemName
    item.Value = slotPosition
    item.Parent = invFolder
    
    -- Create ItemProperties
    Helpers.createItemProperties(item, itemName)
    
    print("[ItemCreator]: Added", itemName, "to", clothingName, "slot", slotNumber)
    return item
end

-- Clear all items from a clothing's inventory
function ItemCreator.ClearClothingInventory(player, clothingName)
    local playerFolder = ReplicatedStorage.Players:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then return end
    
    local clothingItem = clothingFolder:FindFirstChild(clothingName)
    if not clothingItem then return end
    
    local invFolder = clothingItem:FindFirstChild("Inventory")
    if invFolder then
        for _, child in pairs(invFolder:GetChildren()) do
            if child:IsA("StringValue") then
                child:Destroy()
            end
        end
    end
end

return ItemCreator