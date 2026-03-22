local DragAndDropSys = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MoveItem = ReplicatedStorage.Shared.Remotes.InventoryEvents:WaitForChild("MoveItem")

MoveItem.OnServerEvent:Connect(function(player, fromSlot, toSlot)
	
end)


return DragAndDropSys