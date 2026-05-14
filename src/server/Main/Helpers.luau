local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playersFolder = ReplicatedStorage.Players

local RequestModule = require(script.Parent.Parent.ModuleHandler.LoadModule)
local ItemList = require(ReplicatedStorage.Shared.Modules.ItemList)

local Helpers = {}
local extraInventories = {
	Backpack = true,
	TShirt = true, 
	Armor = true,
	Pants = true, 
}

function Helpers.createFolder(parent, name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function Helpers.createStringValue(parent, itemType, itemName)
	local stringValue = Instance.new("StringValue")
	stringValue.Name = itemName
	stringValue.Value = itemType
	stringValue.Parent = parent
	return stringValue
end

function Helpers.returnEquippedClothes(inventory)
	local equippedClothes = {}
	for itemName, itemData in pairs(inventory.Equipment.Clothing) do
		if itemData.equipped and itemData.name ~= "" then
			equippedClothes[itemName] = itemData
		end
	end
	return equippedClothes
end

function Helpers.equipItem(player, slotType, itemName)
	local playerFolder = playersFolder:FindFirstChild(player.Name)
	if not playerFolder then return end

	local clothingFolder = playerFolder:FindFirstChild("Clothing")
	if not clothingFolder then
		clothingFolder = Helpers.createFolder(playerFolder, "Clothing")
	end

	local existing = clothingFolder:FindFirstChild(slotType)
	if existing then
		existing:Destroy()
	end

	local stringValue = Helpers.createStringValue(clothingFolder, slotType, itemName)

	Helpers.createItemProperties(stringValue, itemName)

	--if extraInventories[slotType] then
	--	local invFolder = Helpers.createFolder(stringValue, "Inventory")
	--	local slotCount = slotType == "Backpack" and 10 or (slotType == "Armor" and 4 or 2)
	--	invFolder:SetAttribute("Slots", slotCount)
	--end
end

function Helpers.deequipItem(player, slotName)
	local playerFolder = playersFolder:FindFirstChild(player.Name)
	if not playerFolder then 
		return 
	end
	local clothingFolder = playerFolder:FindFirstChild("Clothing")

	local stringValue = clothingFolder:FindFirstChild(slotName)
	if stringValue then
		stringValue:Destroy()
	end
end

-- In your Helpers.equipItem - add test items when player joins
function Helpers.addItemToClothingInventory(player, clothingType, slotName, itemName)
    local playerFolder = playersFolder:FindFirstChild(player.Name)
    if not playerFolder then return end
    
    local clothingFolder = playerFolder:FindFirstChild("Clothing")
    if not clothingFolder then return end
    
    local clothingItem = clothingFolder:FindFirstChild(clothingType) -- "Armor", "Backpack", etc.
    if not clothingItem then return end
    
    -- Get or create Inventory folder inside clothing item
    local invFolder = clothingItem:FindFirstChild("Inventory")
    if not invFolder then
        invFolder = Helpers.createFolder(clothingItem, "Inventory")
    end
    
    -- Create the item
    local stringValue = Helpers.createStringValue(invFolder, slotName, itemName)
    Helpers.createItemProperties(stringValue, itemName)
    
    return stringValue
end

function Helpers.setupInventoryFolder(player, value, inventory)
	local playerFolder = playersFolder:FindFirstChild(player.Name)
	if not playerFolder then return end

	local equipped = Helpers.returnEquippedClothes(inventory)
	if not equipped then return end

	for itemName, itemData in pairs(equipped) do
		if extraInventories[itemName] then
			local clothingFolder = playerFolder:FindFirstChild("Clothing")
			if clothingFolder then
				local strValInstance = clothingFolder:FindFirstChild(tostring(value))
				print(strValInstance)
				if strValInstance then
					-- Only create Inventory folder, NOT ItemProperties again
					local invFolder = strValInstance:FindFirstChild("Inventory")
					if not invFolder then
						Helpers.createFolder(strValInstance, "Inventory")
					end
				end
			end
		end
	end
end

function Helpers.GetItemModule(itemName)
	local module = require(RequestModule.FindModuleScript(itemName))
	local imageId = module.imageIconId
	
	return imageId
end

function Helpers.createItemProperties(parent, itemName)
	local props = Instance.new("Folder")
	props.Name = "ItemProperties"  -- ✅ Fixed name
	props.Parent = parent

	local durability = Instance.new("NumberValue")
	durability.Name = "Durability"
	durability.Value = 100
	durability.Parent = props

	local maxDurability = Instance.new("NumberValue")
	maxDurability.Name = "MaxDurability"
	maxDurability.Value = 100
	maxDurability.Parent = props
	
	local itemIcon = Instance.new("StringValue")
	itemIcon.Name = "IconImage"
	itemIcon.Value = Helpers.GetItemModule(itemName)
	itemIcon.Parent = props

	-- Only create Amount/StackSize if the function exists
	if ItemList.isStackable(itemName) then --add stacksize
		local amount = Instance.new("NumberValue")
		amount.Name = "Amount"
		amount.Value = Helpers.GetItemModule(itemName)
		amount.Parent = props

		local stackSize = Instance.new("NumberValue")
		stackSize.Name = "StackSize"
		stackSize.Value = Helpers.GetItemModule(itemName)
		stackSize.Parent = props
	end

	return props
end

function Helpers.cleanUpPlayerFolder(player)
	local folder = playersFolder:FindFirstChild(player.Name)
	if folder then folder:Destroy() end
end

return Helpers