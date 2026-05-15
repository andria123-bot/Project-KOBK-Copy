local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playersFolder = ReplicatedStorage.Players

local RequestModule = require(script.Parent.Parent.Parent.ModuleHandler.LoadModule)
local ItemList = require(ReplicatedStorage.Shared.Modules.ItemList)
local SlotMappings = require(script.Parent.Parent.Parent.Inventory.Data.SlotMappings)

local Helpers = {}

-- Container types that can have inventories (backpacks, armor, pants, shirt)
local containerTypes = {
    Backpack = true,
    Armor = true,
    Pants = true,
    TShirt = true,
}

-- ============================================================
-- FOLDER UTILITIES
-- ============================================================

function Helpers.createFolder(parent, name)
    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

function Helpers.createStringValue(parent, slotName, itemName)
    local stringValue = Instance.new("StringValue")
    stringValue.Name = slotName  -- Slot identifier (e.g., "ItemHip1", "Backpack")
    stringValue.Value = itemName -- Item name (e.g., "HK416", "Medkit")
    stringValue.Parent = parent
    return stringValue
end

-- ============================================================
-- CLOTHING EQUIPMENT
-- ============================================================

function Helpers.returnEquippedClothes(inventory)
    local equippedClothes = {}
    for itemName, itemData in pairs(inventory.Clothing) do
        if itemData.equipped and itemData.name ~= "" then
            equippedClothes[itemName] = itemData
        end
    end
    return equippedClothes
end

-- Equip clothing item (Armor, Backpack, TShirt, Pants, etc.)
function Helpers.equipClothing(player, clothingType, itemName)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end

    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then
        clothingFolder = Helpers.createFolder(playerFolder, "Clothing")
    end

    -- Remove existing item in this slot
    local existing = clothingFolder:FindFirstChild(clothingType)
    if existing then
        existing:Destroy()
    end

    -- Create new clothing item
    local stringValue = Helpers.createStringValue(clothingFolder, clothingType, itemName)
    Helpers.createItemProperties(stringValue, itemName)

    -- Create inventory folder for containers (backpack, armor, pants, shirt)
    if containerTypes[clothingType] then
        local invFolder = Helpers.createFolder(stringValue, "Inventory")
        local slotCount = Helpers.getContainerSlotCount(clothingType, itemName)
        invFolder:SetAttribute("Slots", slotCount)
    end
end

-- Unequip clothing item
function Helpers.deequipClothing(player, clothingType)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then return end

    local stringValue = clothingFolder:FindFirstChild(clothingType)
    if stringValue then
        stringValue:Destroy()
    end
end

-- Get slot count for a container type
function Helpers.getContainerSlotCount(containerType, itemName)
    local slotCounts = {
        Backpack = 20,
        Armor = 10,
        Pants = 6,
        TShirt = 4,
    }
    return slotCounts[containerType] or 5
end

-- ============================================================
-- WEAPON EQUIPMENT (Hotbar)
-- ============================================================

-- Equip weapon to hotbar slot
function Helpers.equipWeapon(player, hotbarSlot, weaponName)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local hotbarFolder = playerFolder:FindFirstChild("Hotbar")
    if not hotbarFolder then return end
    
    local slot = hotbarFolder:FindFirstChild(hotbarSlot)
    if not slot then return end
    
    -- Clear the inventory storage slot if moving from there
    -- This will be handled by the move logic
    
    slot.Value = weaponName
end

-- Unequip weapon from hotbar slot
function Helpers.unequipWeapon(player, hotbarSlot)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local hotbarFolder = playerFolder:FindFirstChild("Hotbar")
    if not hotbarFolder then return end
    
    local slot = hotbarFolder:FindFirstChild(hotbarSlot)
    if slot then
        slot.Value = ""
    end
end

-- ============================================================
-- WEAPON STORAGE (Inventory folder)
-- ============================================================

-- Store weapon in inventory storage slot
function Helpers.storeWeapon(player, storageSlot, weaponName)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local inventoryFolder = playerFolder:FindFirstChild("Inventory")
    if not inventoryFolder then return end
    
    local slot = inventoryFolder:FindFirstChild(storageSlot)
    if not slot then return end
    
    slot.Value = weaponName
end

-- Remove weapon from inventory storage
function Helpers.removeStoredWeapon(player, storageSlot)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local inventoryFolder = playerFolder:FindFirstChild("Inventory")
    if not inventoryFolder then return end
    
    local slot = inventoryFolder:FindFirstChild(storageSlot)
    if slot then
        slot.Value = ""
    end
end

-- ============================================================
-- CONTAINER ITEMS (inside backpack, armor, etc.)
-- ============================================================

-- Add item to a container (backpack, pants, etc.)
function Helpers.addItemToContainer(player, containerSlot, itemSlot, itemName)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then return end
    
    -- Find the container item (e.g., "Backpack" StringValue)
    local containerItem = clothingFolder:FindFirstChild(containerSlot)
    if not containerItem then return end
    
    -- Get or create Inventory folder
    local invFolder = containerItem:FindFirstChild("Inventory")
    if not invFolder then
        invFolder = Helpers.createFolder(containerItem, "Inventory")
    end
    
    -- Create the item
    local stringValue = Helpers.createStringValue(invFolder, itemSlot, itemName)
    Helpers.createItemProperties(stringValue, itemName)
    
    return stringValue
end

-- Remove item from container
function Helpers.removeItemFromContainer(player, containerSlot, itemSlot)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then return end
    
    local containerItem = clothingFolder:FindFirstChild(containerSlot)
    if not containerItem then return end
    
    local invFolder = containerItem:FindFirstChild("Inventory")
    if not invFolder then return end
    
    local item = invFolder:FindFirstChild(itemSlot)
    if item then
        item:Destroy()
    end
end

-- ============================================================
-- TOOL EQUIPMENT (GPS, Map, Compass, Melee)
-- ============================================================

function Helpers.equipTool(player, toolSlot, toolName)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local equipmentFolder = playerFolder:FindFirstChild("Equipment")
    if not equipmentFolder then return end
    
    local slot = equipmentFolder:FindFirstChild(toolSlot)
    if not slot then return end
    
    slot.Value = toolName
end

function Helpers.unequipTool(player, toolSlot)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local equipmentFolder = playerFolder:FindFirstChild("Equipment")
    if not equipmentFolder then return end
    
    local slot = equipmentFolder:FindFirstChild(toolSlot)
    if slot then
        slot.Value = ""
    end
end

-- ============================================================
-- ITEM PROPERTIES
-- ============================================================

function Helpers.GetItemModule(itemName)
    local module = require(RequestModule.FindModuleScript(itemName))
    return module.imageIconId
end

function Helpers.createItemProperties(parent, itemName)
    local props = Instance.new("Folder")
    props.Name = "ItemProperties"
    props.Parent = parent

    local durability = Instance.new("NumberValue")
    durability.Name = "Durability"
    durability.Value = 100
    durability.Parent = props

    local maxDurability = Instance.new("NumberValue")
    maxDurability.Name = "MaxDurability"
    maxDurability.Value = 100
    maxDurability.Parent = props
    
    local itemIcon = Instance.new("StringValue")
    itemIcon.Name = "IconImage"
    itemIcon.Value = Helpers.GetItemModule(itemName)
    itemIcon.Parent = props

    if ItemList.isStackable(itemName) then
        local amount = Instance.new("NumberValue")
        amount.Name = "Amount"
        amount.Value = 1
        amount.Parent = props

        local stackSize = Instance.new("NumberValue")
        stackSize.Name = "StackSize"
        stackSize.Value = Helpers.GetItemModule(itemName) or 10
        stackSize.Parent = props
    end

    return props
end

-- ============================================================
-- CLEANUP
-- ============================================================

function Helpers.cleanUpPlayerFolder(player)
    local folder = playersFolder:FindFirstChild(player.Name)
    if folder then 
        folder:Destroy() 
    end
end

return Helpers