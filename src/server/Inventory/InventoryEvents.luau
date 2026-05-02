local InventoryFunctions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DropItem = ReplicatedStorage.Shared.Remotes.InventoryFunctionEvents:WaitForChild("DropItem")
local PickupItem = ReplicatedStorage.Shared.Remotes.InventoryFunctionEvents:WaitForChild("PickupItem")

local function createSound(parent)
    local sound = Instance.new("Sound")
    sound.Parent = parent
    sound.SoundId = "rbxassetid://9125747060"
    sound.Volume = 1
    sound.TimePosition = .7567
    sound:Play()
    
    return sound
end

DropItem.OnServerEvent:Connect(function(player, itemName)
    local itemClone = ReplicatedStorage.Weapons:FindFirstChild(itemName):Clone()
    
    if itemClone then
        for _, v in pairs(itemClone:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
                v.Anchored = false
            end
        end

        itemClone:SetAttribute("IsDroppedItem", true)
        
        itemClone.Name = itemName
        
        local id = tostring(tick())
        itemClone:SetAttribute("DropID", id)
        
        itemClone.Parent = workspace
        
        local character = player.Character
        if character and character.HumanoidRootPart then
            itemClone:SetPrimaryPartCFrame(character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3))
        end
        
        createSound(itemClone)
    end
end)

PickupItem.OnServerEvent:Connect(function(player, item)
    print(player.Name .. " picked up " .. item)
end)

return InventoryFunctions