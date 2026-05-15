-- DropItem.luau
-- Handles dropping items from inventory to the world

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local HashManager = require(script.Parent.Parent.Core.HashManager)
local SlotMappings = require(script.Parent.Parent.Data.SlotMappings)

local DropItem = {}

-- Dropped items folder in workspace
local DROPPED_ITEMS_FOLDER = "DroppedItems"

-- Cooldown tracking (prevent spam)
local dropCooldowns = {} -- [playerUserId] = lastDropTime
local DROP_COOLDOWN = 0.5 -- seconds

-- ============================================================
-- MAIN DROP FUNCTION
-- ============================================================

function DropItem.DropItem(player, slotName)
    -- Cooldown check
    local now = os.time()
    local lastDrop = dropCooldowns[player.UserId] or 0
    if now - lastDrop < DROP_COOLDOWN then
        return false, "Drop on cooldown"
    end
    dropCooldowns[player.UserId] = now
    
    local manager = HashManager.getPlayer(player)
    if not manager then
        return false, "No manager found"
    end
    
    -- Get the item from the slot
    local itemData = manager:getItem(slotName)
    if not itemData then
        return false, "Item not found in slot"
    end
    
    local item = itemData.Item
    local itemName = item.Value
    local slotType = slotName
    
    if itemName == "" then
        return false, "No item in slot"
    end
    
    -- Special item check (can't drop certain items)
    if itemName == "DV2" then
        return false, "Cannot drop this item"
    end
    
    -- Create world model
    local worldModel = DropItem.CreateWorldModel(player, item, itemName, slotType)
    if not worldModel then
        return false, "Failed to create world model"
    end
    
    -- Clear the inventory slot
    item.Value = ""
    
    -- If this was an equipped weapon, unequip from hotbar status
    if SlotMappings.IsEquippedWeaponSlot(slotName) then
        -- Update any equipped tracking here
        print(player.Name .. " dropped equipped weapon from slot:", slotName)
    end
    
    -- Refresh manager
    manager:refresh()
    
    -- Play drop sound
    DropItem.PlayDropSound(player, item)
    
    return true, "Success"
end

-- ============================================================
-- CREATE WORLD MODEL
-- ============================================================

function DropItem.CreateWorldModel(player, sourceItem, itemName, slotName)
    -- Get or create dropped items folder
    local droppedFolder = Workspace:FindFirstChild(DROPPED_ITEMS_FOLDER)
    if not droppedFolder then
        droppedFolder = Instance.new("Folder")
        droppedFolder.Name = DROPPED_ITEMS_FOLDER
        droppedFolder.Parent = Workspace
    end
    
    -- Get item model template from ReplicatedStorage
    local modelsFolder = ReplicatedStorage:FindFirstChild("ItemsListModels")
    if not modelsFolder then
        warn("ItemsListModels folder not found")
        return nil
    end
    
    local template = modelsFolder:FindFirstChild(itemName)
    if not template then
        warn("No model template for:", itemName)
        return nil
    end
    
    -- Clone the model
    local worldModel = template:Clone()
    
    -- Position at player's feet
    local character = player.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        worldModel:SetPrimaryPartCFrame(rootPart.CFrame * CFrame.new(0, -3, 2))
    else
        worldModel:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
    end
    
    -- Copy item properties to the world model
    DropItem.CopyPropertiesToModel(worldModel, sourceItem)
    
    -- Add metadata
    worldModel:SetAttribute("DroppedBy", player.Name)
    worldModel:SetAttribute("OriginalSlot", slotName)
    worldModel:SetAttribute("DroppedAt", os.time())
    
    -- Apply skin if exists
    local props = sourceItem:FindFirstChild("ItemProperties")
    if props then
        local skin = props:FindFirstChild("Skin")
        if skin and skin.Value ~= "" then
            DropItem.ApplySkin(worldModel, skin.Value)
        end
    end
    
    worldModel.Parent = droppedFolder
    
    return worldModel
end

-- Copy properties from StringValue item to world model
function DropItem.CopyPropertiesToModel(worldModel, sourceItem)
    local sourceProps = sourceItem:FindFirstChild("ItemProperties")
    if not sourceProps then
        return
    end
    
    local modelProps = worldModel:FindFirstChild("ItemProperties")
    if not modelProps then
        modelProps = Instance.new("Folder")
        modelProps.Name = "ItemProperties"
        modelProps.Parent = worldModel
    end
    
    -- Copy attributes
    for _, attr in pairs(sourceProps:GetChildren()) do
        local clone = attr:Clone()
        clone.Parent = modelProps
    end
    
    -- Copy container items (if this item had an inventory)
    local sourceInventory = sourceItem:FindFirstChild("Inventory")
    if sourceInventory then
        local modelInventory = Instance.new("Folder")
        modelInventory.Name = "Inventory"
        modelInventory.Parent = worldModel
        
        for _, subItem in pairs(sourceInventory:GetChildren()) do
            if subItem:IsA("StringValue") then
                local subClone = subItem:Clone()
                subClone.Parent = modelInventory
            end
        end
    end
    
    -- Copy attachments (if weapon)
    local sourceAttachments = sourceItem:FindFirstChild("Attachments")
    if sourceAttachments then
        local modelAttachments = Instance.new("Folder")
        modelAttachments.Name = "Attachments"
        modelAttachments.Parent = worldModel
        
        for _, attachFolder in pairs(sourceAttachments:GetChildren()) do
            local folderClone = attachFolder:Clone()
            folderClone.Parent = modelAttachments
        end
    end
end

-- Apply skin to world model
function DropItem.ApplySkin(worldModel, skinName)
    -- Find skin texture and apply to model parts
    local skinsFolder = ReplicatedStorage:FindFirstChild("Skins")
    if skinsFolder then
        local skin = skinsFolder:FindFirstChild(skinName)
        if skin then
            -- Apply skin to appropriate parts
            for _, part in pairs(worldModel:GetDescendants()) do
                if part:IsA("MeshPart") or part:IsA("Part") then
                    -- Apply texture if applicable
                end
            end
        end
    end
end

-- Play drop sound
function DropItem.PlayDropSound(player, item)
    local soundEvent = ReplicatedStorage:FindFirstChild("Remotes"):FindFirstChild("SoundServiceEvent")
    if soundEvent then
        soundEvent:FireAllClients("ItemDrop", player)
    end
end

-- ============================================================
-- CLEANUP
-- ============================================================

function DropItem.ClearCooldown(player)
    dropCooldowns[player.UserId] = nil
end

return DropItem