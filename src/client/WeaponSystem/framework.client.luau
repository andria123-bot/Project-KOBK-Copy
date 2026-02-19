local StarterPlayer = game:GetService("StarterPlayer")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local viewmodelFinder = require(script.Parent.LoadViewmodel)
local moduleFinder = require(script.Parent.LoadModule)
local playerWeaponSystem = require(script.Parent.playerWeaponSystemData)

function loadSlot(Item)
	local newViewmodel = viewmodelFinder.GetViewmodel(Item)
	local newModule = moduleFinder.GetModule(Item)

	if newViewmodel and newModule and character then
		playerWeaponSystem.weaponSystem.viewmodel = newViewmodel
		playerWeaponSystem.weaponSystem.module = newModule
        

	end
end

loadSlot(playerWeaponSystem.weaponSystem.inventory[2])