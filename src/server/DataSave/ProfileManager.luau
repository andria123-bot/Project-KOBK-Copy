-- ProfileManager.luau
-- Handles data persistence using ProfileService

local ProfileService = require(game:GetService("ServerScriptService").ServerPackages.Profileservice)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PlayerWeaponSystemData = require(script.Parent.Parent.Main.PlayerWeaponSystemData)
local SlotMappings = require(script.Parent.Parent.Inventory.Data.SlotMappings)
local HashManager = require(script.Parent.Parent.Inventory.Core.HashManager)
local Helpers = require(script.Parent.Parent.Inventory.Utils.Helpers)
local ItemCreator = require(script.Parent.Parent.Inventory.Utils.ItemCreator)

local ProfileManager = {}

-- Set to true to force starter kit on EVERY join (ignores saved data)
local isForcedKit = false
local isEnabled = true -- Master toggle for persistence system

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

local function ApplyStarterKit(manager)
    print("[ProfileManager]: ===== APPLYING STARTER KIT =====")
    local player = manager.player
    print("[ProfileManager]: Player:", player.Name)
    
    -- Create clothing using ItemCreator
    print("[ProfileManager]: Creating clothing...")
    ItemCreator.CreateClothing(player, "6B45", "Armor")
    ItemCreator.CreateClothing(player, "WorkingTShirt", "TShirt")
    ItemCreator.CreateClothing(player, "WorkingPants", "Pants")
    
    -- Create weapon in hotbar
    print("[ProfileManager]: Creating weapon...")
    ItemCreator.CreateWeapon(player, "ItemHip1", "HK416")
    
    -- Create tools
    print("[ProfileManager]: Creating tools...")
    ItemCreator.CreateTool(player, "Melee", "Tomahawk")
    
    -- Optional: Add test items to Armor slots
    print("[ProfileManager]: Adding test items...")
    ItemCreator.AddItemToClothing(player, "6B45", 1, "HK416")
    
    manager:refresh()
    print("[ProfileManager]: ===== STARTER KIT APPLIED =====")
end

-- ============================================================
-- LOAD DATA FROM PROFILE
-- ============================================================

local function LoadClothingFromProfile(profile, manager)
    print("[ProfileManager]: LoadClothingFromProfile START")
    print("[ProfileManager]: Clothing data:", profile.Data.Inventory.Clothing)
    
    for itemName, slotType in pairs(profile.Data.Inventory.Clothing) do
        print("[ProfileManager]: Loading clothing - Name:", itemName, "SlotType:", slotType)
        if itemName and itemName ~= "" and slotType and slotType ~= "" then
            Helpers.equipClothing(manager.player, itemName, slotType)
        end
    end
    print("[ProfileManager]: LoadClothingFromProfile END")
end

local function LoadClothingContentsFromProfile(profile, manager)
    print("[ProfileManager]: LoadClothingContentsFromProfile START")
    local clothingFolder = manager.sessionProfile:FindFirstChild("Clothing")
    if not clothingFolder then
        print("[ProfileManager]: No clothing folder found!")
        return
    end
    
    for clothingSlot, contents in pairs(profile.Data.Inventory.ClothingContents or {}) do
        print("[ProfileManager]: Loading contents for:", clothingSlot, "#items:", #contents)
        local clothingItem = clothingFolder:FindFirstChild(clothingSlot)
        if clothingItem then
            local invFolder = clothingItem:FindFirstChild("Inventory")
            if not invFolder then
                invFolder = Instance.new("Folder")
                invFolder.Name = "Inventory"
                invFolder.Parent = clothingItem
                local slotCount = Helpers.getContainerSlotCount(clothingSlot, clothingItem.Value)
                invFolder:SetAttribute("Slots", slotCount)
            end
            
            for _, content in pairs(contents) do
                print("[ProfileManager]: Loading item - Name:", content.Name, "Slot:", content.Slot)
                local subItem = Instance.new("StringValue")
                subItem.Name = content.Name  -- FIXED: Name is the item name
                subItem.Value = content.Slot -- FIXED: Value is the slot position
                subItem.Parent = invFolder
                Helpers.createItemProperties(subItem, content.Name)
            end
        end
    end
    print("[ProfileManager]: LoadClothingContentsFromProfile END")
end

local function LoadHotbarFromProfile(profile, manager)
    print("[ProfileManager]: LoadHotbarFromProfile START")
    print("[ProfileManager]: Hotbar data:", profile.Data.Inventory.Hotbar)
    
    for slotName, itemName in pairs(profile.Data.Inventory.Hotbar) do
        print("[ProfileManager]: Hotbar slot:", slotName, "Item:", itemName)
        if itemName and itemName ~= "" then
            if SlotMappings.IsEquippedWeaponSlot(slotName) then
                print("[ProfileManager]: Equipping weapon to:", slotName)
                Helpers.equipWeapon(manager.player, slotName, itemName)
            else
                print("[ProfileManager]: Setting hotbar slot:", slotName)
                local hotbarFolder = manager.sessionProfile:FindFirstChild("Hotbar")
                local slot = hotbarFolder and hotbarFolder:FindFirstChild(slotName)
                if slot then
                    slot.Value = itemName
                    print("[ProfileManager]: Set", slotName, "to", itemName)
                end
            end
        end
    end
    print("[ProfileManager]: LoadHotbarFromProfile END")
end

local function LoadWeaponStorageFromProfile(profile, manager)
    print("[ProfileManager]: LoadWeaponStorageFromProfile START")
    print("[ProfileManager]: WeaponStorage data:", profile.Data.Inventory.WeaponStorage)
    
    for slotName, itemName in pairs(profile.Data.Inventory.WeaponStorage) do
        print("[ProfileManager]: Weapon storage slot:", slotName, "Item:", itemName)
        if itemName and itemName ~= "" then
            Helpers.storeWeapon(manager.player, slotName, itemName)
            print("[ProfileManager]: Stored weapon:", itemName, "in", slotName)
        end
    end
    print("[ProfileManager]: LoadWeaponStorageFromProfile END")
end

local function LoadEquipmentFromProfile(profile, manager)
    print("[ProfileManager]: LoadEquipmentFromProfile START")
    print("[ProfileManager]: Equipment data:", profile.Data.Inventory.Equipment)
    
    for slotName, itemName in pairs(profile.Data.Inventory.Equipment) do
        print("[ProfileManager]: Equipment slot:", slotName, "Item:", itemName)
        if itemName and itemName ~= "" then
            Helpers.equipTool(manager.player, slotName, itemName)
            print("[ProfileManager]: Equipped tool:", itemName, "to", slotName)
        end
    end
    print("[ProfileManager]: LoadEquipmentFromProfile END")
end

-- ============================================================
-- SAVE DATA TO PROFILE
-- ============================================================

local function SaveClothingToProfile(profile, manager)
    print("[ProfileManager]: SaveClothingToProfile START")
    local clothingFolder = manager.sessionProfile:FindFirstChild("Clothing")
    print("[ProfileManager]: Clothing folder:", clothingFolder)
    
    if not clothingFolder then
        print("[ProfileManager]: No clothing folder - skipping save")
        return
    end
    
    -- IMPORTANT: Clear existing data FIRST
    profile.Data.Inventory.Clothing = {}
    
    for _, clothingItem in pairs(clothingFolder:GetChildren()) do
        if clothingItem:IsA("StringValue") then
            local slotType = clothingItem.Value  -- "Armor", "TShirt", "Pants"
            local itemName = clothingItem.Name   -- "6B45", "WorkingTShirt", "WorkingPants"
            print("[ProfileManager]: Saving clothing - Name:", itemName, "SlotType:", slotType)
            -- FIX: Store with itemName as key, slotType as value
            profile.Data.Inventory.Clothing[itemName] = slotType
        end
    end
    
    -- Count how many were saved
    local count = 0
    for _ in pairs(profile.Data.Inventory.Clothing) do count = count + 1 end
    print("[ProfileManager]: SaveClothingToProfile END, saved", count, "items")
end

local function SaveClothingContentsToProfile(profile, manager)
    print("[ProfileManager]: SaveClothingContentsToProfile START")
    local clothingFolder = manager.sessionProfile:FindFirstChild("Clothing")
    if not clothingFolder then
        print("[ProfileManager]: No clothing folder - skipping save")
        return
    end
    
    profile.Data.Inventory.ClothingContents = {}
    print("[ProfileManager]: Reset ClothingContents table")
    
    for _, clothingItem in pairs(clothingFolder:GetChildren()) do
        if clothingItem:IsA("StringValue") then
            print("[ProfileManager]: Processing clothing:", clothingItem.Name)
            local invFolder = clothingItem:FindFirstChild("Inventory")
            if invFolder then
                local contents = {}
                print("[ProfileManager]: Inventory folder found with", #invFolder:GetChildren(), "items")
                for _, subItem in pairs(invFolder:GetChildren()) do
                    if subItem:IsA("StringValue") and subItem.Value ~= "" then
                        local contentData = {
                            Name = subItem.Name,
                            Slot = subItem.Value,
                        }
                        table.insert(contents, contentData)
                        print("[ProfileManager]: Saved content - Name:", subItem.Name, "Slot:", subItem.Value)
                    end
                end
                if #contents > 0 then
                    profile.Data.Inventory.ClothingContents[clothingItem.Name] = contents
                    print("[ProfileManager]: Saved", #contents, "items for", clothingItem.Name)
                else
                    print("[ProfileManager]: No contents for", clothingItem.Name)
                end
            else
                print("[ProfileManager]: No Inventory folder for", clothingItem.Name)
            end
        end
    end
    print("[ProfileManager]: SaveClothingContentsToProfile END")
end

local function SaveHotbarToProfile(profile, manager)
    print("[ProfileManager]: SaveHotbarToProfile START")
    local hotbarFolder = manager.sessionProfile:FindFirstChild("Hotbar")
    if not hotbarFolder then
        print("[ProfileManager]: No hotbar folder - skipping save")
        return
    end
    
    for slotName in pairs(profile.Data.Inventory.Hotbar) do
        local slot = hotbarFolder:FindFirstChild(slotName)
        if slot then
            local value = slot.Value or ""
            profile.Data.Inventory.Hotbar[slotName] = value
            print("[ProfileManager]: Saved hotbar:", slotName, "=", value)
        else
            profile.Data.Inventory.Hotbar[slotName] = ""
            print("[ProfileManager]: Hotbar slot not found:", slotName)
        end
    end
    print("[ProfileManager]: SaveHotbarToProfile END")
end

local function SaveWeaponStorageToProfile(profile, manager)
    print("[ProfileManager]: SaveWeaponStorageToProfile START")
    local inventoryFolder = manager.sessionProfile:FindFirstChild("Inventory")
    if not inventoryFolder then
        print("[ProfileManager]: No inventory folder - skipping save")
        return
    end
    
    for slotName in pairs(profile.Data.Inventory.WeaponStorage) do
        local slot = inventoryFolder:FindFirstChild(slotName)
        if slot then
            local value = slot.Value or ""
            profile.Data.Inventory.WeaponStorage[slotName] = value
            print("[ProfileManager]: Saved weapon storage:", slotName, "=", value)
        else
            profile.Data.Inventory.WeaponStorage[slotName] = ""
            print("[ProfileManager]: Weapon storage slot not found:", slotName)
        end
    end
    print("[ProfileManager]: SaveWeaponStorageToProfile END")
end

local function SaveEquipmentToProfile(profile, manager)
    print("[ProfileManager]: SaveEquipmentToProfile START")
    local equipmentFolder = manager.sessionProfile:FindFirstChild("Equipment")
    if not equipmentFolder then
        print("[ProfileManager]: No equipment folder - skipping save")
        return
    end
    
    for slotName in pairs(profile.Data.Inventory.Equipment) do
        local slot = equipmentFolder:FindFirstChild(slotName)
        if slot then
            local value = slot.Value or ""
            profile.Data.Inventory.Equipment[slotName] = value
            print("[ProfileManager]: Saved equipment:", slotName, "=", value)
        else
            profile.Data.Inventory.Equipment[slotName] = ""
            print("[ProfileManager]: Equipment slot not found:", slotName)
        end
    end
    print("[ProfileManager]: SaveEquipmentToProfile END")
end

-- ============================================================
-- DATA TEMPLATES
-- ============================================================

local function GetClothingTemplate()
    print("[ProfileManager]: GetClothingTemplate called")
    local template = {}
    for slotName in pairs(SlotMappings.EquipmentSlots) do
        if string.find(slotName, "Clothing") then
            template[slotName] = ""
            print("[ProfileManager]: Added clothing template slot:", slotName)
        end
    end
    return template
end

local function GetHotbarTemplate()
    print("[ProfileManager]: GetHotbarTemplate called")
    local template = {}
    for _, slotName in pairs(SlotMappings.HotbarSlots) do
        template[slotName] = ""
        print("[ProfileManager]: Added hotbar template slot:", slotName)
    end
    return template
end

local function GetWeaponStorageTemplate()
    print("[ProfileManager]: GetWeaponStorageTemplate called")
    local template = {}
    for _, slotName in pairs(SlotMappings.WeaponInventorySlots) do
        template[slotName] = ""
        print("[ProfileManager]: Added weapon storage slot:", slotName)
    end
    return template
end

local function GetEquipmentTemplate()
    print("[ProfileManager]: GetEquipmentTemplate called")
    local template = {}
    local toolSlots = { "Melee", "EquipmentGPS", "EquipmentMap", "EquipmentLighter", "EquipmentCompass" }
    for _, slotName in pairs(toolSlots) do
        template[slotName] = ""
        print("[ProfileManager]: Added equipment slot:", slotName)
    end
    return template
end

-- ============================================================
-- MAIN FUNCTIONS
-- ============================================================

function ProfileManager.LoadProfile(player)
    print("[ProfileManager]: ===== LOAD PROFILE START =====")
    print("[ProfileManager]: Player:", player.Name)
    print("[ProfileManager]: isEnabled:", isEnabled)

    -- If persistence is disabled, just apply starter kit and return nil
    if not isEnabled then
        print("[ProfileManager]: Persistence disabled - applying starter kit only")
        local manager = HashManager.getPlayer(player)
        ApplyStarterKit(manager)
        manager:refresh()
        print("[ProfileManager]: ===== LOAD PROFILE END (disabled) =====")
        return nil
    end
    
    print("[ProfileManager]: Loading profile from ProfileStore...")
    local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
    
    if not profile then
        print("[ProfileManager]: Failed to load profile - kicking player")
        player:Kick("Failed to load profile. Please rejoin.")
        return nil
    end
    
    print("[ProfileManager]: Profile loaded successfully")
    
    -- Handle version migration if needed
    if profile.Data.Version ~= PROFILE_VERSION then
        print("[ProfileManager]: Migrating profile from version", profile.Data.Version, "to", PROFILE_VERSION)
        profile.Data.Version = PROFILE_VERSION
    end
    
    -- Ensure all data sections exist
    if not profile.Data.Inventory then
        print("[ProfileManager]: Creating Inventory section")
        profile.Data.Inventory = {}
    end
    
    if not profile.Data.Inventory.Clothing then
        print("[ProfileManager]: Creating Clothing section")
        profile.Data.Inventory.Clothing = GetClothingTemplate()
    end
    
    if not profile.Data.Inventory.ClothingContents then
        print("[ProfileManager]: Creating ClothingContents section")
        profile.Data.Inventory.ClothingContents = {}
    end
    
    if not profile.Data.Inventory.Hotbar then
        print("[ProfileManager]: Creating Hotbar section")
        profile.Data.Inventory.Hotbar = GetHotbarTemplate()
    end
    
    if not profile.Data.Inventory.WeaponStorage then
        print("[ProfileManager]: Creating WeaponStorage section")
        profile.Data.Inventory.WeaponStorage = GetWeaponStorageTemplate()
    end
    
    if not profile.Data.Inventory.Equipment then
        print("[ProfileManager]: Creating Equipment section")
        profile.Data.Inventory.Equipment = GetEquipmentTemplate()
    end
    
    if not profile.Data.Stats then
        print("[ProfileManager]: Creating Stats section")
        profile.Data.Stats = {
            Kills = 0,
            Deaths = 0,
            TimePlayed = 0,
        }
    end
    
    -- Release previous profile if exists
    if activeProfiles[player] then
        print("[ProfileManager]: Releasing previous profile")
        activeProfiles[player]:Release()
    end
    
    activeProfiles[player] = profile
    print("[ProfileManager]: Profile stored in activeProfiles")
    
    -- Set up auto-save
    profile:AddUserId(player.UserId)
    profile:Reconcile()
    print("[ProfileManager]: UserId added and profile reconciled")
    
    -- Get or create manager (this creates ReplicatedStorage folders)
    print("[ProfileManager]: Getting/Creating HashManager")
    local manager = HashManager.getPlayer(player)
    
    -- Load data OR apply starter kit
    if isForcedKit then
        print("[ProfileManager]: Forced kit enabled - applying starter kit")
        ApplyStarterKit(manager)
    else
        -- Check if player has any saved items
        local hasSavedItems = false
        print("[ProfileManager]: Checking for saved items...")
        for slotName, itemName in pairs(profile.Data.Inventory.Clothing) do
            if itemName ~= "" then
                hasSavedItems = true
                print("[ProfileManager]: Found saved clothing:", slotName, "=", itemName)
                break
            end
        end
        if not hasSavedItems then
            for slotName, itemName in pairs(profile.Data.Inventory.Hotbar) do
                if itemName ~= "" then
                    hasSavedItems = true
                    print("[ProfileManager]: Found saved hotbar:", slotName, "=", itemName)
                    break
                end
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
    print("[ProfileManager]: Refreshing manager")
    manager:refresh()
    
    -- Listen for profile release (player leaves)
    profile:ListenToRelease(function()
        print("[ProfileManager]: Profile released for", player.Name)
        activeProfiles[player] = nil
    end)
    
    -- Auto-save every 60 seconds
    task.spawn(function()
        while activeProfiles[player] == profile do
            task.wait(60)
            print("[ProfileManager]: Auto-saving profile for", player.Name)
            ProfileManager.SaveProfile(player)
        end
    end)
    
    print("[ProfileManager]: Loaded profile for", player.Name)
    print("[ProfileManager]: ===== LOAD PROFILE END =====")
    return profile
end

function ProfileManager.SaveProfile(player)
    print("[ProfileManager]: ===== SAVE PROFILE START =====")
    print("[ProfileManager]: Player:", player.Name)
    print("[ProfileManager]: isEnabled:", isEnabled)
    
    -- If persistence is disabled, do nothing
    if not isEnabled then
        print("[ProfileManager]: Persistence disabled - skipping save")
        return false
    end
    
    local profile = activeProfiles[player]
    if not profile then
        print("[ProfileManager]: No active profile found!")
        return false
    end
    
    local manager = HashManager.getPlayer(player)
    if not manager then
        print("[ProfileManager]: No manager found!")
        return false
    end
    
    print("[ProfileManager]: Saving inventory data...")
    
    -- Save current inventory state to profile
    SaveClothingToProfile(profile, manager)
    SaveClothingContentsToProfile(profile, manager)
    SaveHotbarToProfile(profile, manager)
    SaveWeaponStorageToProfile(profile, manager)
    SaveEquipmentToProfile(profile, manager)
    
    -- Trigger save
    print("[ProfileManager]: Triggering profile save...")
    profile:Save()
    
    print("[ProfileManager]: ===== SAVE PROFILE END =====")
    return true
end

function ProfileManager.ReleaseProfile(player)
    print("[ProfileManager]: ===== RELEASE PROFILE START =====")
    print("[ProfileManager]: Player:", player.Name)
    print("[ProfileManager]: isEnabled:", isEnabled)
    
    -- If persistence is disabled, just cleanup without saving
    if not isEnabled then
        local profile = activeProfiles[player]
        if profile then
            profile:Release()
            activeProfiles[player] = nil
            print("[ProfileManager]: Released profile (persistence disabled)")
        end
        return
    end
    
    local profile = activeProfiles[player]
    if profile then
        print("[ProfileManager]: Saving and releasing profile...")
        ProfileManager.SaveProfile(player)
        profile:Release()
        activeProfiles[player] = nil
        print("[ProfileManager]: Released profile for", player.Name)
    else
        print("[ProfileManager]: No active profile to release")
    end
    print("[ProfileManager]: ===== RELEASE PROFILE END =====")
end

function ProfileManager.GetProfile(player)
    if not isEnabled then
        return nil
    end
    return activeProfiles[player]
end

function ProfileManager.SetForcedKit(enabled)
    isForcedKit = enabled
    print("[ProfileManager]: Forced kit set to", enabled)
end

function ProfileManager.SetEnabled(enabled)
    isEnabled = enabled
    print("[ProfileManager]: Persistence system set to", enabled)
end

function ProfileManager.IsEnabled()
    return isEnabled
end

print("[ProfileManager]: Module loaded successfully!")

return ProfileManager