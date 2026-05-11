local playerWeaponSystemData = {
    weaponSystem = {
        Inventory = {
            PlayerInventory = {};
            StorageInventory = {};

            Equipment = {
                Clothing = {
                    Mask     = { equipped = false, name = "" },
                    Gloves   = { equipped = false, name = "" },
                    Armor    = { equipped = false, name = "6B45" },
                    TShirt   = { equipped = false,  name = "Default" },
                    Pants    = { equipped = false,  name = "Default" },
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
                    Gun1 = { equipped = false, item = "" }, -- loadstartergear should fill these orr player could manually equip these, both are easy way. gn
                    Gun2 = { equipped = false, item = "" },
                    Gun3 = { equipped = false, item = "" },
                },
            };

            SlotCount = 0;
        };
        
        gear = {
            Backpack = "nil",
            Leggings = "nil",
            TShirt = "nil",
            Helmet = "nil",
            Pants = "nil",
            Armor = "nil",
            Mask = "nil",
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

        viewmodel = nil,
        currentSlot = 0,
    }
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RequestPlayerData = ReplicatedStorage.Shared.Remotes.Bindables:WaitForChild("RequestPlayerData")

RequestPlayerData.OnInvoke = function()
    return playerWeaponSystemData.weaponSystem
end

function playerWeaponSystemData:setState(newState)
    print(newState) 
    -- print(debug.traceback()) -- debug
    playerWeaponSystemData.weaponSystem.state = newState
end

playerWeaponSystemData:setState(playerWeaponSystemData.weaponSystem.states[1])

return playerWeaponSystemData