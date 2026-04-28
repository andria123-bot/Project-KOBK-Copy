local ApplyGunVisualFeedbacks = {}

function ApplyGunVisualFeedbacks:Fire(camera, rx: number, ry: number, rz: number)
	local kickRecoil = CFrame.Angles(
		math.rad(rx * 0.8),
		math.rad(ry * 0.5),
		math.rad(rz * 0.3)
	)

	local settleRecoil = CFrame.Angles(
		math.rad(rx * 0.2),
		math.rad(ry * 0.1),
		math.rad(rz * 0.05)
	)

	camera.CFrame = camera.CFrame * kickRecoil

	task.delay(0.05, function()
		camera.CFrame = camera.CFrame * settleRecoil
	end)
end

function ApplyGunVisualFeedbacks:Kickback()
	return CFrame.new(0, 0, .02)
end

return ApplyGunVisualFeedbacks