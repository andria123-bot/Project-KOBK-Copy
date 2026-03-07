local playerWeaponSystemData = {
    weaponSystem = {
        inventory = {
            "HK416";
            "Khrissy10R";
            "MG42";
            "Knife";
            "Grenade";
            "M4A1";
            "";
            "";
            "";
        };
        
        gear = {
            ChestRig = nil,
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

        module = nil,
        viewmodel = nil,
        currentSlot = 0,
    }
}

playerWeaponSystemData.weaponSystem.state = playerWeaponSystemData.weaponSystem.states[1]
print(playerWeaponSystemData.weaponSystem.state)
function playerWeaponSystemData:setState(newState)
    print(newState) 
    playerWeaponSystemData.weaponSystem.state = newState
end

return playerWeaponSystemData