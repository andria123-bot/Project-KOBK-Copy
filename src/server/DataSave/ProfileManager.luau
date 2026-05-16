-- ProfileManager.luau
-- Handles data persistence using ProfileService

local ProfileService = require(game:GetService("ServerScriptService").ServerPackages.Profileservice)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerWeaponSystemData = require(script.Parent.Parent.Main.PlayerWeaponSystemData)
local SlotMappings = require(script.Parent.Parent.Inventory.Data.SlotMappings)
local HashManager = require(script.Parent.Parent.Inventory.Core.HashManager)
local Helpers = require(script.Parent.Parent.Inventory.Utils.Helpers)

local ProfileManager = {}

-- Set to true to force starter kit on EVERY join (ignores saved data)
local isForcedKit = false

-- ProfileStore setup
local PROFILE_VERSION = 1
local PROFILE_SCOPE = "PlayerData"

local ProfileStore = ProfileService.GetProfileStore(PROFILE_SCOPE, {
    Version = PROFILE_VERSION,
    Inventory = {
        Clothing = {},
        ClothingContents = {},
        Hotbar = {},
        WeaponStorage = {},
        Equipment = {},
    },
    Stats = {
        Kills = 0,
        Deaths = 0,
        TimePlayed = 0,
    },
})

local activeProfiles = {} -- [player] = profile

-- ============================================================
-- STARTER KIT
-- ============================================================

-- ProfileManager.luau
-- Add this require at the top with other requires

-- Then replace the ApplyStarterKit function with this:

local function ApplyStarterKit(manager)
    print("[ProfileManager]: Applying starter kit")
    
    -- Get starter data from PlayerWeaponSystemData
    local starterData = PlayerWeaponSystemData.weaponSystem.Inventory.Equipment
    
    -- Apply starter clothing
    for clothingType, clothingData in pairs(starterData.Clothing) do
        if clothingData.equipped and clothingData.name ~= "" then
            -- clothingType is like "Armor", "TShirt", "Pants", etc.
            -- clothingData.name is like "6B45", "WorkingTShirt", "WorkingPants"
            Helpers.equipClothing(manager.player, clothingData.name, clothingType)
        end
    end
    
    -- Apply starter weapons in hotbar
    for weaponSlot, weaponData in pairs(starterData.Weapons) do
        if weaponData.equipped and weaponData.item ~= "" then
            -- weaponSlot is like "ItemHip1", "ItemHip2", "ItemHip3"
            Helpers.equipWeapon(manager.player, weaponSlot, weaponData.item)
        end
    end
    
    -- Apply starter tools
    for toolSlot, toolData in pairs(starterData.Utils) do
        if toolData.equipped and toolData.name ~= "" then
            -- toolSlot is like "Melee", "GPS", "Map", "Compass"
            Helpers.equipTool(manager.player, toolSlot, toolData.name)
        end
    end
    
    manager:refresh()
end

-- ============================================================
-- LOAD DATA FROM PROFILE
-- ============================================================

local function LoadClothingFromProfile(profile, manager)
    for slotName, itemName in pairs(profile.Data.Inventory.Clothing) do
        if itemName and itemName ~= "" then
            Helpers.equipClothing(manager.player, slotName, itemName)
        end
    end
end

local function LoadClothingContentsFromProfile(profile, manager)
    local clothingFolder = manager.sessionProfile:FindFirstChild("Clothing")
    if not clothingFolder then
        return
    end
    
    for clothingSlot, contents in pairs(profile.Data.Inventory.ClothingContents or {}) do
        local clothingItem = clothingFolder:FindFirstChild(clothingSlot)
        if clothingItem then
            -- Get or create Inventory folder
            local invFolder = clothingItem:FindFirstChild("Inventory")
            if not invFolder then
                invFolder = Instance.new("Folder")
                invFolder.Name = "Inventory"
                invFolder.Parent = clothingItem
                -- Set slots attribute if needed
                local slotCount = Helpers.getContainerSlotCount(clothingSlot, clothingItem.Value)
                invFolder:SetAttribute("Slots", slotCount)
            end
            
            -- Load each item
            for _, content in pairs(contents) do
                local subItem = Instance.new("StringValue")
                subItem.Name = content.Slot
                subItem.Value = content.Name
                subItem.Parent = invFolder
                
                -- Create item properties
                Helpers.createItemProperties(subItem, content.Name)
            end
        end
    end
end

local function LoadHotbarFromProfile(profile, manager)
    for slotName, itemName in pairs(profile.Data.Inventory.Hotbar) do
        if itemName and itemName ~= "" then
            if SlotMappings.IsEquippedWeaponSlot(slotName) then
                Helpers.equipWeapon(manager.player, slotName, itemName)
            else
                -- For Hotbar4-8 (consumables, etc.)
                local hotbarFolder = manager.sessionProfile:FindFirstChild("Hotbar")
                local slot = hotbarFolder and hotbarFolder:FindFirstChild(slotName)
                if slot then
                    slot.Value = itemName
                end
            end
        end
    end
end

local function LoadWeaponStorageFromProfile(profile, manager)
    for slotName, itemName in pairs(profile.Data.Inventory.WeaponStorage) do
        if itemName and itemName ~= "" then
            Helpers.storeWeapon(manager.player, slotName, itemName)
        end
    end
end

local function LoadEquipmentFromProfile(profile, manager)
    for slotName, itemName in pairs(profile.Data.Inventory.Equipment) do
        if itemName and itemName ~= "" then
            Helpers.equipTool(manager.player, slotName, itemName)
        end
    end
end

-- ============================================================
-- SAVE DATA TO PROFILE
-- ============================================================

local function SaveClothingToProfile(profile, manager)
    local clothingFolder = manager.sessionProfile:FindFirstChild("Clothing")
    if not clothingFolder then
        return
    end
    
    for slotName in pairs(profile.Data.Inventory.Clothing) do
        local item = clothingFolder:FindFirstChild(slotName)
        if item then
            profile.Data.Inventory.Clothing[slotName] = item.Value or ""
        else
            profile.Data.Inventory.Clothing[slotName] = ""
        end
    end
end

local function SaveClothingContentsToProfile(profile, manager)
    local clothingFolder = manager.sessionProfile:FindFirstChild("Clothing")
    if not clothingFolder then
        return
    end
    
    profile.Data.Inventory.ClothingContents = {}
    
    for _, clothingItem in pairs(clothingFolder:GetChildren()) do
        if clothingItem:IsA("StringValue") then
            local invFolder = clothingItem:FindFirstChild("Inventory")
            if invFolder then
                local contents = {}
                for _, subItem in pairs(invFolder:GetChildren()) do
                    if subItem:IsA("StringValue") and subItem.Value ~= "" then
                        table.insert(contents, {
                            Slot = subItem.Name,
                            Name = subItem.Value,
                        })
                    end
                end
                if #contents > 0 then
                    profile.Data.Inventory.ClothingContents[clothingItem.Name] = contents
                end
            end
        end
    end
end

local function SaveHotbarToProfile(profile, manager)
    local hotbarFolder = manager.sessionProfile:FindFirstChild("Hotbar")
    if not hotbarFolder then
        return
    end
    
    for slotName in pairs(profile.Data.Inventory.Hotbar) do
        local slot = hotbarFolder:FindFirstChild(slotName)
        if slot then
            profile.Data.Inventory.Hotbar[slotName] = slot.Value or ""
        end
    end
end

local function SaveWeaponStorageToProfile(profile, manager)
    local inventoryFolder = manager.sessionProfile:FindFirstChild("Inventory")
    if not inventoryFolder then
        return
    end
    
    for slotName in pairs(profile.Data.Inventory.WeaponStorage) do
        local slot = inventoryFolder:FindFirstChild(slotName)
        if slot then
            profile.Data.Inventory.WeaponStorage[slotName] = slot.Value or ""
        end
    end
end

local function SaveEquipmentToProfile(profile, manager)
    local equipmentFolder = manager.sessionProfile:FindFirstChild("Equipment")
    if not equipmentFolder then
        return
    end
    
    for slotName in pairs(profile.Data.Inventory.Equipment) do
        local slot = equipmentFolder:FindFirstChild(slotName)
        if slot then
            profile.Data.Inventory.Equipment[slotName] = slot.Value or ""
        end
    end
end

-- ============================================================
-- DATA TEMPLATES
-- ============================================================

local function GetClothingTemplate()
    local template = {}
    for slotName in pairs(SlotMappings.EquipmentSlots) do
        if string.find(slotName, "Clothing") then
            template[slotName] = ""
        end
    end
    return template
end

local function GetHotbarTemplate()
    local template = {}
    for _, slotName in pairs(SlotMappings.HotbarSlots) do
        template[slotName] = ""
    end
    return template
end

local function GetWeaponStorageTemplate()
    local template = {}
    for _, slotName in pairs(SlotMappings.WeaponInventorySlots) do
        template[slotName] = ""
    end
    return template
end

local function GetEquipmentTemplate()
    local template = {}
    local toolSlots = { "Melee", "EquipmentGPS", "EquipmentMap", "EquipmentLighter", "EquipmentCompass" }
    for _, slotName in pairs(toolSlots) do
        template[slotName] = ""
    end
    return template
end

-- ============================================================
-- MAIN FUNCTIONS
-- ============================================================

function ProfileManager.LoadProfile(player)
    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    
    if not profile then
        player:Kick("Failed to load profile. Please rejoin.")
        return nil
    end
    
    -- Handle version migration if needed
    if profile.Data.Version ~= PROFILE_VERSION then
        profile.Data.Version = PROFILE_VERSION
    end
    
    -- Ensure all data sections exist
    if not profile.Data.Inventory then
        profile.Data.Inventory = {}
    end
    
    if not profile.Data.Inventory.Clothing then
        profile.Data.Inventory.Clothing = GetClothingTemplate()
    end
    
    if not profile.Data.Inventory.ClothingContents then
        profile.Data.Inventory.ClothingContents = {}
    end
    
    if not profile.Data.Inventory.Hotbar then
        profile.Data.Inventory.Hotbar = GetHotbarTemplate()
    end
    
    if not profile.Data.Inventory.WeaponStorage then
        profile.Data.Inventory.WeaponStorage = GetWeaponStorageTemplate()
    end
    
    if not profile.Data.Inventory.Equipment then
        profile.Data.Inventory.Equipment = GetEquipmentTemplate()
    end
    
    if not profile.Data.Stats then
        profile.Data.Stats = {
            Kills = 0,
            Deaths = 0,
            TimePlayed = 0,
        }
    end
    
    -- Release previous profile if exists
    if activeProfiles[player] then
        activeProfiles[player]:Release()
    end
    
    activeProfiles[player] = profile
    
    -- Set up auto-save
    profile:AddUserId(player.UserId)
    profile:Reconcile()
    
    -- Get or create manager (this creates ReplicatedStorage folders)
    local manager = HashManager.getPlayer(player)
    
    -- Load data OR apply starter kit
    if isForcedKit then
        print("[ProfileManager]: Forced kit enabled - applying starter kit")
        ApplyStarterKit(manager)
    else
        -- Check if player has any saved items
        local hasSavedItems = false
        for _, itemName in pairs(profile.Data.Inventory.Clothing) do
            if itemName ~= "" then
                hasSavedItems = true
                break
            end
        end
        for _, itemName in pairs(profile.Data.Inventory.Hotbar) do
            if itemName ~= "" then
                hasSavedItems = true
                break
            end
        end
        
        if hasSavedItems then
            -- Load saved data
            print("[ProfileManager]: Loading saved data for", player.Name)
            LoadClothingFromProfile(profile, manager)
            LoadClothingContentsFromProfile(profile, manager)
            LoadHotbarFromProfile(profile, manager)
            LoadWeaponStorageFromProfile(profile, manager)
            LoadEquipmentFromProfile(profile, manager)
        else
            -- New player, give starter kit
            print("[ProfileManager]: New player - applying starter kit")
            ApplyStarterKit(manager)
        end
    end
    
    -- Refresh manager to update hash tables
    manager:refresh()
    
    -- Listen for profile release (player leaves)
    profile:ListenToRelease(function()
        activeProfiles[player] = nil
    end)
    
    -- Auto-save every 60 seconds
    task.spawn(function()
        while activeProfiles[player] == profile do
            task.wait(60)
            ProfileManager.SaveProfile(player)
        end
    end)
    
    print("[ProfileManager]: Loaded profile for", player.Name)
    return profile
end

function ProfileManager.SaveProfile(player)
    local profile = activeProfiles[player]
    if not profile then
        return false
    end
    
    local manager = HashManager.getPlayer(player)
    if not manager then
        return false
    end
    
    -- Save current inventory state to profile
    SaveClothingToProfile(profile, manager)
    SaveClothingContentsToProfile(profile, manager)
    SaveHotbarToProfile(profile, manager)
    SaveWeaponStorageToProfile(profile, manager)
    SaveEquipmentToProfile(profile, manager)
    
    -- Trigger save
    profile:Save()
    
    return true
end

function ProfileManager.ReleaseProfile(player)
    local profile = activeProfiles[player]
    if profile then
        ProfileManager.SaveProfile(player)
        profile:Release()
        activeProfiles[player] = nil
        print("[ProfileManager]: Released profile for", player.Name)
    end
end

function ProfileManager.GetProfile(player)
    return activeProfiles[player]
end

function ProfileManager.SetForcedKit(enabled)
    isForcedKit = enabled
    print("[ProfileManager]: Forced kit set to", enabled)
end

return ProfileManager