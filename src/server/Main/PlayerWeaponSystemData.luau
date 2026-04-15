local playerWeaponSystemData = {
    weaponSystem = {
        inventory = {
            PlayerInventory = {};

            StorageInventory = {};

            equipment = {
                Clothing = {
                    Mask     = { equipped = false,  name = "" },
                    Gloves   = { equipped = false, name = ""},
                    TShirt   = { equipped = true,  name = "Default" },
                    Pants    = { equipped = true,  name = "Default" },
                    Backpack = { equipped = false, name = "Fieldpack45" },
                    Leggings = { equipped = false, name = "" },
                    Helmet   = { equipped = false, name = "" },
                    Armor    = { equipped = true, name = "6B45" },
                },
                Utils = {
                    Melee    = { equipped = true, name = {}}, -- name should be moduleScriptData of the item
                    GPS      = { equipped = false, name = {}},
                    Map      = { equipped = false, name = {}},
                    Compass  = { equipped = false, name = {}},
                },
                Weapons = {
                    Slot1    = { equipped = false, item = {}},
                    Slot2    = { equipped = false, item = {}},
                    Slot3    = { equipped = false, item = {}},
                },
            };

            SlotCount = 0;
        };
        
        gear = {
            Backpack = nil,
            Leggings = nil,
            TShirt = nil,
            Helmet = nil,
            Pants = nil,
            Armor = nil,
            Mask = nil,
        },

        animations = {
            FirstPerson = {
                nil; -- Shoot/use
                nil; -- Equip/draw
                nil; -- Deequip/holster
                nil; -- Empty Shoot
                nil; -- Reload 
                nil; -- Empty Reload
                nil; -- Inspect
                nil; -- Idle
            };

            ThirdPerson = {
                nil; -- Shoot/use
                nil; -- Equip/draw
                nil; -- Deequip/holster
                nil; -- Reload 
                nil; -- Empty Reload
                nil; -- Inspect
                nil; -- Idle
            };
        };

        sounds = {
            nil; -- equip/draw
            nil; -- shoot/use
            nil; -- reload
            nil; -- empty reload
            nil; -- inspect
            nil; -- deequip/holster
        };

        lastShotTime = 0;
        bulletId = 0;

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

        module = {},
        viewmodel = nil,
        currentSlot = 0,
    }
}


function playerWeaponSystemData:setState(newState)
    print(newState) 
    -- print(debug.traceback()) -- debug
    playerWeaponSystemData.weaponSystem.state = newState
end

playerWeaponSystemData:setState(playerWeaponSystemData.weaponSystem.states[1])

return playerWeaponSystemData