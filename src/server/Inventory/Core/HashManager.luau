-- HashManager.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SlotMappings = require(script.Parent.Parent.Data.SlotMappings)

local HashManager = {}
local playerManagers = {}

local Manager = {}
Manager.__index = Manager

local function generateID()
    return os.time() .. "_" .. math.random(1000, 9999) .. "_" .. tick()
end

function Manager.new(player)
    local self = setmetatable({
        player = player,
        sessionProfile = nil,
        
        equipment = {
            Clothing = {},
            Weapons = {},
            Tools = {},
        },
        
        Inventory = {
            HashItem = {},
            HashItemTemp = {},
            Inventories = {},
            Vault = {},
        },
        
        Status = {
            Hotbar = {},
            EquippedItem = { Item = nil, Model = nil },
            LastEquippedItem = nil,
            Dead = false,
        },
        
        Signals = {},
        
        InFolderPlayer = nil,
        IsProcessing = false,
        InContainer = false,
    }, Manager)
    
    self:setupReplicatedFolder()
    self:refresh()
    
    return self
end

function Manager:setupReplicatedFolder()
    local playersFolder = ReplicatedStorage:FindFirstChild("Players")
    if not playersFolder then
        playersFolder = Instance.new("Folder")
        playersFolder.Name = "Players"
        playersFolder.Parent = ReplicatedStorage
    end
    
    local playerFolder = playersFolder:FindFirstChild(self.player.Name)
    if playerFolder then
        playerFolder:Destroy()
    end
    
    playerFolder = Instance.new("Folder")
    playerFolder.Name = self.player.Name
    playerFolder.Parent = playersFolder
    
    -- Create main folders
    local folders = {"Clothing", "Equipment", "Inventory", "Hotbar", "Settings", "StartUp", "Status", "Vault"}
    for _, name in pairs(folders) do
        local folder = Instance.new("Folder")
        folder.Name = name
        folder.Parent = playerFolder
    end
    
    -- Pre-create Hotbar slots
    local hotbarFolder = playerFolder:FindFirstChild("Hotbar")
    for _, slotName in pairs(SlotMappings.HotbarSlots) do
        local slot = Instance.new("StringValue")
        slot.Name = slotName
        slot.Value = ""
        slot.Parent = hotbarFolder
    end
    
    -- Pre-create Weapon Inventory slots (storage)
    local inventoryFolder = playerFolder:FindFirstChild("Inventory")
    for _, slotName in pairs(SlotMappings.WeaponInventorySlots) do
        local slot = Instance.new("StringValue")
        slot.Name = slotName
        slot.Value = ""
        slot.Parent = inventoryFolder
    end
    
    -- Pre-create Equipment slots (tools)
    local equipmentFolder = playerFolder:FindFirstChild("Equipment")
    for slotName, _ in pairs(SlotMappings.EquipmentSlots) do
        -- Only create tool slots (non-clothing, non-weapon)
        if not string.find(slotName, "Clothing") and 
           not SlotMappings.IsHotbarSlot(slotName) and
           not SlotMappings.IsWeaponInventorySlot(slotName) then
            local slot = Instance.new("StringValue")
            slot.Name = slotName
            slot.Value = ""
            slot.Parent = equipmentFolder
        end
    end
    
    self.sessionProfile = playerFolder
    self.InFolderPlayer = playerFolder
end

function Manager:refresh()
    if not self.sessionProfile then 
        return 
    end
    
    -- Reset all tables
    self.Inventory.HashItem = {}
    self.Inventory.HashItemTemp = {}
    self.Inventory.Inventories = {}
    self.equipment.Clothing = {}
    self.equipment.Weapons = {}
    self.equipment.Tools = {}
    self.Status.Hotbar = {}
    
    -- 1. Process Clothing folder
    local clothingFolder = self.sessionProfile:FindFirstChild("Clothing")
    if clothingFolder then
        for _, item in pairs(clothingFolder:GetChildren()) do
            if item:IsA("StringValue") then
                local slotName = item.Name
                local itemName = item.Value
                
                if itemName ~= "" then
                    local internalType = SlotMappings.GetInternalType(slotName)
                    
                    self.Inventory.HashItem[slotName] = {
                        Item = item,
                        Ubiety = clothingFolder,
                        ID = generateID(),
                        CurrentFrameName = slotName,
                        CurrentSlot = slotName,
                        ItemName = itemName,
                    }
                    
                    self.equipment.Clothing[internalType] = {
                        Item = item,
                        Parent = clothingFolder,
                        CurrentFrameName = slotName,
                        CurrentSlot = slotName,
                    }
                end
                
                -- Handle container inventories (backpacks, rigs with slots)
                local invFolder = item:FindFirstChild("Inventory")
                if invFolder then
                    self.Inventory.Inventories[slotName] = {
                        Inventory = invFolder,
                        ID = generateID(),
                        Slots = invFolder:GetAttribute("Slots") or 0,
                        ParentItem = item,
                    }
                    
                    -- Index sub-items inside container
                    for _, subItem in pairs(invFolder:GetChildren()) do
                        if subItem:IsA("StringValue") then
                            local subSlotName = subItem.Name
                            local subItemName = subItem.Value
                            
                            if subItemName ~= "" then
                                self.Inventory.HashItem[subSlotName] = {
                                    Item = subItem,
                                    Ubiety = invFolder,
                                    ID = generateID(),
                                    CurrentFrameName = subSlotName,
                                    CurrentSlot = subSlotName,
                                    ItemName = subItemName,
                                    ParentItem = item,
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 2. Process Hotbar folder (equipped weapons and utility items)
    local hotbarFolder = self.sessionProfile:FindFirstChild("Hotbar")
    if hotbarFolder then
        for _, slotName in pairs(SlotMappings.HotbarSlots) do
            local slot = hotbarFolder:FindFirstChild(slotName)
            if slot and slot.Value ~= "" then
                local itemName = slot.Value
                
                self.Inventory.HashItem[slotName] = {
                    Item = slot,
                    Ubiety = hotbarFolder,
                    ID = generateID(),
                    CurrentFrameName = slotName,
                    CurrentSlot = slotName,
                    ItemName = itemName,
                }
                
                -- Store in Status.Hotbar for quick access
                self.Status.Hotbar[slotName] = {
                    Item = slot,
                    ItemName = itemName,
                }
                
                -- Also add to equipment.Weapons for weapon slots
                if SlotMappings.IsEquippedWeaponSlot(slotName) then
                    self.equipment.Weapons[slotName] = {
                        Item = slot,
                        Parent = hotbarFolder,
                        CurrentFrameName = slotName,
                        CurrentSlot = slotName,
                    }
                end
            end
        end
    end
    
    -- 3. Process Inventory folder (weapon storage)
    local inventoryFolder = self.sessionProfile:FindFirstChild("Inventory")
    if inventoryFolder then
        for _, slotName in pairs(SlotMappings.WeaponInventorySlots) do
            local slot = inventoryFolder:FindFirstChild(slotName)
            if slot and slot.Value ~= "" then
                local itemName = slot.Value
                
                self.Inventory.HashItem[slotName] = {
                    Item = slot,
                    Ubiety = inventoryFolder,
                    ID = generateID(),
                    CurrentFrameName = slotName,
                    CurrentSlot = slotName,
                    ItemName = itemName,
                }
                
                self.equipment.Weapons[slotName] = {
                    Item = slot,
                    Parent = inventoryFolder,
                    CurrentFrameName = slotName,
                    CurrentSlot = slotName,
                }
            end
        end
    end
    
    -- 4. Process Equipment folder (tools)
    local equipmentFolder = self.sessionProfile:FindFirstChild("Equipment")
    if equipmentFolder then
        for _, item in pairs(equipmentFolder:GetChildren()) do
            if item:IsA("StringValue") then
                local slotName = item.Name
                local itemName = item.Value
                
                if itemName ~= "" then
                    self.Inventory.HashItem[slotName] = {
                        Item = item,
                        Ubiety = equipmentFolder,
                        ID = generateID(),
                        CurrentFrameName = slotName,
                        CurrentSlot = slotName,
                        ItemName = itemName,
                    }
                    
                    self.equipment.Tools[slotName] = {
                        Item = item,
                        Parent = equipmentFolder,
                        CurrentFrameName = slotName,
                        CurrentSlot = slotName,
                    }
                end
            end
        end
    end
    
    -- 5. Process Vault folder
    local vaultFolder = self.sessionProfile:FindFirstChild("Vault")
    if vaultFolder then
        for _, item in pairs(vaultFolder:GetChildren()) do
            if item:IsA("StringValue") and item.Value ~= "" then
                table.insert(self.Inventory.Vault, {
                    Item = item,
                    Ubiety = vaultFolder,
                    ID = generateID(),
                    ItemName = item.Name,
                    Value = item.Value,
                })
            end
        end
    end
end

-- Get item by slot name
function Manager:getItem(slotName)
    return self.Inventory.HashItem[slotName]
end

-- Get item in temporary container view
function Manager:getItemTemp(slotName)
    return self.Inventory.HashItemTemp[slotName]
end

-- Get inventory by type
function Manager:getInventory(inventoryType)
    return self.Inventory.Inventories[inventoryType]
end

-- Move an item to a hotbar slot (equip)
function Manager:equipToHotbar(slotName, itemName)
    local hotbarFolder = self.sessionProfile:FindFirstChild("Hotbar")
    if not hotbarFolder then
        return false
    end
    
    local slot = hotbarFolder:FindFirstChild(slotName)
    if not slot then
        return false
    end
    
    slot.Value = itemName
    self:refresh()
    return true
end

-- Remove item from hotbar (unequip)
function Manager:unequipFromHotbar(slotName)
    local hotbarFolder = self.sessionProfile:FindFirstChild("Hotbar")
    if not hotbarFolder then
        return false
    end
    
    local slot = hotbarFolder:FindFirstChild(slotName)
    if not slot then
        return false
    end
    
    slot.Value = ""
    self:refresh()
    return true
end

-- Release player manager
function Manager:release()
    if self.sessionProfile then
        self.sessionProfile:Destroy()
    end
    playerManagers[self.player] = nil
end

-- ============================================================
-- PUBLIC API
-- ============================================================

function HashManager.getPlayer(player)
    if not playerManagers[player] then
        playerManagers[player] = Manager.new(player)
    end
    return playerManagers[player]
end

function HashManager.clearPlayer(player)
    if playerManagers[player] then
        playerManagers[player]:release()
    end
end

return HashManager