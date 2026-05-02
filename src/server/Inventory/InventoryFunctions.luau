local InventoryFunctions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientInventoryFunctions = require(ReplicatedStorage.Shared.Modules.Inventory:WaitForChild("InventoryFunctions"))
local SendInventory = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("SendInventory")

function InventoryFunctions.CreateSound(soundId, parent, volume, timePosition)
    local sound = Instance.new("Sound")
    sound.Parent = parent
    sound.SoundId = soundId
    sound.Volume = volume
    sound.TimePosition = timePosition
    sound:Play()

    return sound
end

function InventoryFunctions.CreateItemClone(itemName, player)
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
        
        itemClone.Parent = workspace:WaitForChild("DroppedItems")
        
        local character = player.Character
        if character and character.HumanoidRootPart then
            itemClone:SetPrimaryPartCFrame(character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2))
        end
        
        InventoryFunctions.CreateSound("rbxassetid://9125747060", itemClone, 1, 0.7567)
        game:GetService("Debris"):AddItem(itemClone, 600)
    end
end

function InventoryFunctions.TakeItem(player, playerInventory, item)
    if not player or not player.Parent then
        return false
    end
    
    local emptySlot = ClientInventoryFunctions.FindEmptySlot(playerInventory.PlayerInventory)
    
    if emptySlot then
        playerInventory.PlayerInventory[emptySlot] = item.Name
        item:Destroy()
        
        SendInventory:FireClient(player, { PlayerInventory = playerInventory.PlayerInventory })

        return true
    end
    return false
end

return InventoryFunctions