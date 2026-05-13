local Player = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HashManager = {}
local playerManagers = {} -- [player] = Manager Object

local Manager = {}
Manager.__index = Manager

function Manager.new(player)
	local self = setmetatable({
		player = player,
		sessionProfile = nil, -- ReplicatedStorage.Players[player]
		equipment = {
			Clothing = {},
			Weapons = {},
			Tools = {},
		},
		
		Inventory = {
			HashItem = {},      -- player's own items
			HashItemTemp = {},  -- container/loot items
			Inventories = {},   -- container references
			Vault = {},
		},
		
		Status = {
			Hotbar = {},
			EquippedItem = { Item = nil, Model = nil },
			LastEquippedItem = nil,
			Dead = false,
		},
		
		Signals = {},
		
		InFolderPlayer = nil,
		IsProcessing = false,
		InContainer = false,
	}, Manager)
	
	self:setupReplicatedFolder()
	self:refresh()

	return self
end

local idCounter = 0
local function generateID()
	idCounter = idCounter + 1
	return tostring(os.time()) .. tostring(idCounter) .. tostring(math.random(1000, 9999))
end

function Manager:setupReplicatedFolder()
	local playersFolder = ReplicatedStorage:FindFirstChild("Players")

	local playerFolder = playersFolder:FindFirstChild(self.player.Name)
	if playerFolder then
		playerFolder:Destroy()
	end

	playerFolder = Instance.new("Folder")
	playerFolder.Name = self.player.Name
	playerFolder.Parent = playersFolder

	-- required sub-folders
	local folders = {"Clothing", "Equipment", "Inventory", "Settings", "StartUp", "Status", "Vault"}
	for _, name in pairs(folders) do
		local folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = playerFolder
	end

	self.sessionProfile = playerFolder
	self.InFolderPlayer = playerFolder
end

function Manager:refresh()
	if not self.sessionProfile then return end

	self.Inventory.HashItem = {}
	self.Inventory.HashItemTemp = {}
	self.Inventory.Inventories = {} 
	self.equipment.Clothing = {}
	self.equipment.Weapons = {}
	self.equipment.Tools = {}

	local clothingFolder = self.sessionProfile:FindFirstChild("Clothing")
	if clothingFolder then
		for _, item in pairs(clothingFolder:GetChildren()) do
			if item:IsA("StringValue") then
				local frameName = item.Name

				self.Inventory.HashItem[frameName] = {
					Item = item,
					Ubiety = clothingFolder,
					ID = generateID(),
					CurrentFrame = frameName,
				}

				self.equipment.Clothing[frameName] = {
					Item = item,
					Parent = clothingFolder,
					CurrentFrameName = frameName,
				}

				local invFolder = item:FindFirstChild("Inventory")
				if invFolder then
					for _, subItem in pairs(invFolder:GetChildren()) do
						if subItem:IsA("StringValue") then
							local subFrameName = subItem.Name

							self.Inventory.HashItem[subFrameName] = {
								Item = subItem,
								Ubiety = invFolder,
								ID = generateID(),
								CurrentFrameName = subFrameName,
								ParentItem = item,
							}
						end
					end

					self.Inventory.Inventories[frameName] = {
						Item = invFolder,
						ID = generateID(),
						Slots = invFolder:GetAttribute("Slots") or 0,
						ParentItem = item,
					}
				end
			end
		end
	end

	local equipmentFolder = self.sessionProfile:FindFirstChild("Equipment")
	if equipmentFolder then
		for _, item in pairs(equipmentFolder:GetChildren()) do
			if item:IsA("StringValue") then
				local frameName = item.Name
				
				self.Inventory.HashItem[frameName] = {
					Item = item,
					Ubiety = equipmentFolder,
					ID = generateID(),
					CurrentFrameName = frameName,
				}

				if frameName:find("Gun") then
					self.equipment.Weapons[frameName] = {
						Item = item,
						Parent = equipmentFolder,
						CurrentFrameName = frameName,
					}
				else
					self.equipment.Tools[frameName] = {
						Item = item,
						Parent = equipmentFolder,
						CurrentFrameName = frameName,
					}
				end
			end
		end
	end

	local inventoryFolder = self.sessionProfile:FindFirstChild("Inventory")
	if inventoryFolder then
		for _, item in pairs(inventoryFolder:GetChildren()) do
			if item:IsA("StringValue") then
				local frameName = item.Name

				self.Inventory.HashItem[frameName] = {
					Item = item,
					Ubiety = inventoryFolder,
					ID = generateID(),
					CurrentFrameName = frameName,
				}
			end
		end
	end
end

function Manager:getItem(slotName)
	return self.Inventory.HashItem[slotName]
end

function Manager:getItemTemp(slotName)
	return self.Inventory.HashItemTemp[slotName]
end

function Manager:getInventory(inventoryType)
	return self.Inventory.Inventories[inventoryType]
end

function Manager:release()
	if self.sessionProfile then
		self.sessionProfile:Destroy()
	end
	
	playerManagers[self.player] = nil
end

function HashManager.getPlayer(player)
	if not playerManagers[player] then
		playerManagers[player] = Manager.new(player)
	end
	return playerManagers[player]
end

function HashManager.clearPlayer(player)
	if playerManagers[player] then
		playerManagers[player]:release()
	end
end

return HashManager
