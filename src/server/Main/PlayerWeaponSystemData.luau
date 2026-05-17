-- PlayerWeaponSystemData.lua
-- This module defines all slot types, weapon types, attachment compatibility,
-- and inventory constants for the Tarkov-style inventory system

local playerWeaponSystemData = {
    -- ============================================================
    -- SLOT DEFINITIONS
    -- ============================================================
    
    -- Maps UI slot names to internal slot types
    SlotMapping = {
        -- Clothing/Equipment Slots
        ClothingShirt = "Shirt",
        ClothingPants = "Pants",
        ClothingChestRig = "ChestRig",
        ClothingBackpack = "Backpack",
        ClothingHeadware = "Headware",
        ClothingMask = "Mask",
        ClothingGloves = "Gloves",
        ClothingLegArmor = "LegArmor",
        
        -- Weapon Slots (only hip slots)
        ItemHip1 = "WeaponHip1",
        ItemHip2 = "WeaponHip2",
        ItemHip3 = "WeaponHip3",
        
        -- Tool Slots
        Melee = "Melee",
        EquipmentGPS = "GPS",
        EquipmentMap = "Map",
        EquipmentLighter = "Lighter",
        EquipmentCompass = "Compass",
    },
    
    -- Reverse mapping for UI display
    ReverseSlotMapping = {
        Shirt = "ClothingShirt",
        Pants = "ClothingPants",
        ChestRig = "ClothingChestRig",
        Backpack = "ClothingBackpack",
        Headware = "ClothingHeadware",
        Mask = "ClothingMask",
        Gloves = "ClothingGloves",
        LegArmor = "ClothingLegArmor",
        WeaponHip1 = "ItemHip1",
        WeaponHip2 = "ItemHip2",
        WeaponHip3 = "ItemHip3",
        Melee = "Melee",
        GPS = "EquipmentGPS",
        Map = "EquipmentMap",
        Lighter = "EquipmentLighter",
        Compass = "EquipmentCompass",
    },
    
    -- Container slot prefixes (for loot/container view)
    ContainerPrefix = "Container",
    
    -- ============================================================
    -- WEAPON TYPES
    -- ============================================================
    
    WeaponTypes = {
        Pistol = "Pistol",
        SMG = "SMG",
        AssaultRifle = "AssaultRifle",
        DMR = "DMR",
        Shotgun = "Shotgun",
        Sniper = "Sniper",
        LMG = "LMG",
        Launcher = "Launcher",
    },
    
    -- Which weapon types can go in which slots
    WeaponSlotCompatibility = {
        WeaponHip1 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
        WeaponHip2 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
        WeaponHip3 = { "Pistol", "SMG", "AssaultRifle", "DMR", "Shotgun" },
    },
    
    -- ============================================================
    -- ATTACHMENT SYSTEM
    -- ============================================================
    
    AttachmentTypes = {
        Sight = "Sight",
        Muzzle = "Muzzle",
        Extra = "Extra", -- Lasers, grips, flashlights
        Magazine = "Magazine",
    },
    
    -- Attachment compatibility (what attaches to what)
    AttachmentCompatibility = {
        -- Sight types that work on weapon classes
        Sight = {
            Pistol = { "RedDot", "MicroRedDot" },
            SMG = { "RedDot", "Holographic", "MicroRedDot" },
            AssaultRifle = { "RedDot", "Holographic", "ACOG", "Reflex" },
            DMR = { "ACOG", "Scope4x", "Scope8x" },
            Sniper = { "Scope8x", "Scope16x" },
        },
        Muzzle = {
            Pistol = { "SuppressorPistol", "CompensatorPistol" },
            SMG = { "SuppressorSMG", "CompensatorSMG" },
            AssaultRifle = { "SuppressorAR", "CompensatorAR", "FlashHider" },
            DMR = { "SuppressorDMR", "CompensatorDMR" },
        },
        Extra = {
            Pistol = { "Laser", "Flashlight" },
            SMG = { "Laser", "Flashlight", "VerticalGrip", "AngledGrip" },
            AssaultRifle = { "Laser", "Flashlight", "VerticalGrip", "AngledGrip", "Bipod" },
            DMR = { "Bipod", "VerticalGrip" },
        },
    },
    
    -- ============================================================
    -- ITEM TYPES
    -- ============================================================
    
    ItemTypes = {
        RangedWeapon = "RangedWeapon",
        Clothing = "Clothing",
        Consumable = "Consumable",
        Magazine = "Magazine",
        Melee = "Melee",
        Visor = "Visor",
        Filter = "Filter",
        Sight = "Sight",
        Muzzle = "Muzzle",
        Extra = "Extra",
        Ammo = "Ammo",
        Container = "Container",
        Medical = "Medical",
        Food = "Food",
        Drink = "Drink",
    },
    
    -- SlotType definitions (what type of item can go where)
    SlotTypes = {
        Shirt = "Shirt",
        Pants = "Pants",
        ChestRig = "ChestRig",
        Backpack = "Backpack",
        Headware = "Headware",
        Consumable = "Consumable",
        Mask = "Mask",
        Gloves = "Gloves",
        LegArmor = "LegArmor",
        Melee = "Melee",
        GPS = "GPS",
        Map = "Map",
        Compass = "Compass",
    },
    
    -- ============================================================
    -- CONTAINER SLOT COUNTS
    -- ============================================================
    
    DefaultContainerSlots = {
        Backpack = {
            ["Fieldpack45"] = 45,
            ["Daypack"] = 15,
            ["TacticalBackpack"] = 35,
            ["RaidBackpack"] = 50,
        },
        ChestRig = {
            ["6B45"] = 5,
            ["TacticalRig"] = 10,
            ["LightRig"] = 5,
        },
        Shirt = {
            ["WorkingTShirt"] = 5,
            ["TacticalShirt"] = 5,
        },
        Pants = {
            ["WorkingPants"] = 5,
            ["TacticalPants"] = 5,
        },
    },
    
    -- ============================================================
    -- STACKING SYSTEM
    -- ============================================================
    
    DefaultStackSizes = {
        Ammo = {
            ["9x19mm"] = 50,
            ["5.56x45mm"] = 60,
            ["7.62x39mm"] = 40,
            ["12Gauge"] = 25,
        },
        Consumable = {
            ["Bandage"] = 5,
            ["Medkit"] = 3,
            ["Splint"] = 4,
            ["MRE"] = 2,
            ["Water"] = 2,
        },
        Currency = {
            ["Roubles"] = 999999,
            ["Dollars"] = 999999,
            ["Euros"] = 999999,
        },
    },
    
    -- ============================================================
    -- DURABILITY SYSTEM
    -- ============================================================
    
    DurabilityItems = {
        RangedWeapon = true,
        Visor = true,
        HelmetMask = true,
        Armor = true,
    },
    
    ZeroDurabilityDestroy = {
        FlareGun = true,
    },
    
    -- ============================================================
    -- AMMO SYSTEM
    -- ============================================================
    
    MagazineMaxAmmo = {
        ["PistolMag"] = 15,
        ["SMGMag"] = 30,
        ["ARMag"] = 30,
        ["DMRMag"] = 20,
        ["ShotgunShell"] = 8,
    },
    
    AmmoCompatibility = {
        ["9x19mm"] = { "Pistol", "SMG" },
        ["5.56x45mm"] = { "AssaultRifle", "DMR" },
        ["7.62x39mm"] = { "AssaultRifle" },
        ["7.62x51mm"] = { "DMR", "Sniper" },
        ["12Gauge"] = { "Shotgun" },
        [".45ACP"] = { "Pistol", "SMG" },
    },
    
    -- ============================================================
    -- EXISTING FIELDS (preserved for compatibility)
    -- ============================================================
    
    weaponSystem = {
        Inventory = {
            PlayerInventory = {},
            StorageInventory = {},
            
            Equipment = {
                Clothing = {
                    Mask     = { equipped = false, name = "" },
                    Gloves   = { equipped = false, name = "" },
                    Armor    = { equipped = true, name = "6B45" },
                    TShirt   = { equipped = true,  name = "WorkingTShirt" },
                    Pants    = { equipped = true,  name = "WorkingPants" },
                    Backpack = { equipped = false, name = "Fieldpack45" },
                    Leggings = { equipped = false, name = "" },
                    Helmet   = { equipped = false, name = "" },
                },
                Utils = {
                    Melee   = { equipped = true, name = "Tomahawk" },
                    GPS     = { equipped = false, name = "" },
                    Map     = { equipped = false, name = "" },
                    Compass = { equipped = false, name = "" },
                    Radio   = { equipped = false, name = "" },
                },
                Weapons = {
                    ItemHip1 = { equipped = true, item = "HK416" },
                    ItemHip2 = { equipped = false, item = "" },
                    ItemHip3 = { equipped = false, item = "" },
                },
            },
            
            SlotCount = 0,
        },
        
        animations = {
            FirstPerson = {
                nil, -- Shoot/use
                nil, -- Equip/draw
                nil, -- Deequip/holster
                nil, -- Empty Shoot
                nil, -- Reload 
                nil, -- Empty Reload
                nil, -- Inspect
                nil, -- Idle
            },
            ThirdPerson = {
                nil, -- Shoot/use
                nil, -- Equip/draw
                nil, -- Deequip/holster
                nil, -- Reload 
                nil, -- Empty Reload
                nil, -- Inspect
                nil, -- Idle
            },
        },
        
        sounds = {
            nil, -- equip/draw
            nil, -- shoot/use
            nil, -- reload
            nil, -- empty reload
            nil, -- inspect
            nil, -- deequip/holster
        },
        
        lastShotTime = 0,
        bulletId = 0,
        
        state = "",
        
        states = {
            "Idle",
            "Shooting",
            "Reloading",
            "Inspecting",
            "Aiming",
            "Sprinting",
            "Changing",
            "Dead",
        },
        
        modifiers = {
            IsAiming = false;
            IsInspecting = false;
            IsShooting = false;
            IsReloading = false;
        },
        
        viewmodel = nil,
        currentSlot = 0,
    },
}

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

function playerWeaponSystemData.IsEquipmentSlot(slotName)
    return playerWeaponSystemData.SlotMapping[slotName] ~= nil
end

function playerWeaponSystemData.GetBaseSlotType(slotName)
    local base = slotName
    if slotName:sub(1, #playerWeaponSystemData.ContainerPrefix) == playerWeaponSystemData.ContainerPrefix then
        base = slotName:sub(#playerWeaponSystemData.ContainerPrefix + 1)
    end
    return base
end

function playerWeaponSystemData.IsContainerSlot(slotName)
    return slotName:sub(1, #playerWeaponSystemData.ContainerPrefix) == playerWeaponSystemData.ContainerPrefix
end

function playerWeaponSystemData.GetDisplaySlot(slotType, isContainer)
    if isContainer then
        return playerWeaponSystemData.ContainerPrefix .. slotType
    end
    return slotType
end

function playerWeaponSystemData.GetCompatibleWeaponTypes(slotName)
    return playerWeaponSystemData.WeaponSlotCompatibility[slotName] or {}
end

function playerWeaponSystemData.IsWeaponCompatible(slotName, weaponType)
    local compatible = playerWeaponSystemData.GetCompatibleWeaponTypes(slotName)
    for _, t in pairs(compatible) do
        if t == weaponType then
            return true
        end
    end
    return false
end

function playerWeaponSystemData.GetDefaultSlotCount(containerType, itemName)
    local slots = playerWeaponSystemData.DefaultContainerSlots[containerType]
    if slots and slots[itemName] then
        return slots[itemName]
    end
    local fallbacks = {
        Backpack = 20,
        ChestRig = 10,
        Shirt = 4,
        Pants = 6,
    }
    return fallbacks[containerType] or 5
end

return playerWeaponSystemData