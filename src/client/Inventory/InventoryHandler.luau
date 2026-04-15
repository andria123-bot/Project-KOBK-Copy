local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestWeaponSystemData = ReplicatedStorage.Shared.Remotes.Requests:WaitForChild("RequestWeaponSystemData")

local InventoryHandler = {}

function InventoryHandler:GetEquipedClothes()
    print(RequestWeaponSystemData:InvokeServer())
end


InventoryHandler:GetEquipedClothes()
return InventoryHandler