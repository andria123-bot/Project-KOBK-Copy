local InventoryFunctions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function InventoryFunctions.CreateItemClone(player, itemName)
    local itemClone = ReplicatedStorage.Weapons:FindFirstChild(itemName):Clone()

    if itemClone then
        for _, v in pairs(itemClone:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = true
                v.Anchored = false
            end
        end

        itemClone:SetAttribute("IsDroppedItem", true)
        itemClone:SetAttribute("ItemName", itemName)
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

        local primaryPart = itemClone.PrimaryPart
        if primaryPart then
            local connection
            connection = primaryPart.Touched:Connect(function(hit)
                local isCharacter = hit.Parent and hit.Parent:FindFirstChild("Humanoid")
                if isCharacter then return end

                local velocity = primaryPart.AssemblyLinearVelocity
                if velocity.Magnitude < 1 then
                    for _, v in pairs(itemClone:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.Anchored = true
                        end
                    end
                    connection:Disconnect()
                end
            end)

            task.delay(1.7, function()
                if itemClone and itemClone.Parent then
                    for _, v in pairs(itemClone:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.Anchored = true
                        end
                    end
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end
end

function InventoryFunctions.FindEmptySlot(inventory)
    for i, v in pairs(inventory) do
        if v == nil or v == "" then
            return i
        end
    end

    return nil
end

function InventoryFunctions.TakeItem(player, playerInventory, item)
    if not player or not player.Parent then
        return false
    end
    
    local emptySlot = InventoryFunctions.FindEmptySlot(playerInventory.PlayerInventory)
    
    if emptySlot then
        playerInventory.PlayerInventory[emptySlot] = item.Name
        item:Destroy()
        
        SendInventory:FireClient(player, { PlayerInventory = playerInventory.PlayerInventory })

        return true
    end
    return false
end

function InventoryFunctions.ReturnAvailableSlot(inventory)
    for slot = 1, #inventory do
        if inventory[slot] == "" then
            return slot
        end
    end
    return nil
end

return InventoryFunctions