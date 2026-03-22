local GrenadeFunc = {}

local camera = game.Workspace.CurrentCamera

GrenadeFunc.weaponSystem = nil

function GrenadeFunc:Init(weaponSystem)
    self.weaponSystem = weaponSystem
end

function GrenadeFunc:grenade(grenade)
	repeat task.wait() until self.weaponSystem.animations.FirstPerson[1].isPlaying == true

	local grenadeThrown = false

	self.weaponSystem.animations.FirstPerson[1]:GetMarkerReachedSignal("GrenadeThrow"):Connect(function()

		if not grenadeThrown then
            local viewModel = camera:FindFirstChildWhichIsA("Model")
			viewModel.Grenade.Transparency = 1

			game.ReplicatedStorage.Remotes.Main.Grenade:FireServer(grenade, viewModel.Grenade.Position, camera.CFrame.LookVector, self.weaponSystem.module.sounds[2], 1)
			
			grenadeThrown = true
		end
	end)

	self.weaponSystem.animations.FirstPerson[1].Ended:Connect(function()
		self.weaponSystem.inventory[self.weaponSystem.currentSlot] = ""
		self.weaponSystem.currentSlot = 1
		self.loadSlot(self.weaponSystem.inventory[self.weaponSystem.currentSlot])
	end)
end

return GrenadeFunc