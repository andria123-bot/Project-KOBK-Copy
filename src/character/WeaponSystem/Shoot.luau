local Shoot = {}

local ApplyGunVisualFeedbacks = require(script.Parent.ApplyGunVisualFeedbacks)

local viewmodelKickOffset = CFrame.new()
local kickReturnTime = 0

function Shoot:Fire(
	camera,
	fireMode: string,
	recoilData,
	fireRate: number,
    viewmodel
)
	if fireMode == "Semi Auto" then
		ApplyGunVisualFeedbacks:Fire(
			camera,
			recoilData.rx,
			recoilData.ry,
			recoilData.rz
		)

		viewmodelKickOffset = ApplyGunVisualFeedbacks:Kickback()
		kickReturnTime = tick() + 0.08

		task.delay(0.08, function()
			viewmodelKickOffset = CFrame.new()
		end)

	elseif fireMode == "Full Auto" then
		ApplyGunVisualFeedbacks:Fire(
			camera,
			recoilData.rx,
			recoilData.ry,
			recoilData.rz
		)

		viewmodelKickOffset = ApplyGunVisualFeedbacks:Kickback()
		kickReturnTime = tick() + fireRate

		task.delay(fireRate, function()
			viewmodelKickOffset = CFrame.new()
		end)
	end
end

return Shoot