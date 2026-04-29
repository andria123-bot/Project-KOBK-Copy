local Shoot = {} --ts module should return CFrames for camera recoil and viewmodel kickback, and handle timing for returning to original position

function Shoot:ApplyRecoil(camera, rx: number, ry: number, rz: number)
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

	return kickRecoil, settleRecoil
end

Shoot.viewmodel = nil
Shoot.weaponModule = nil

Shoot.kickbackCurrent = CFrame.new()
Shoot.kickbackTarget = CFrame.new()

function Shoot:Init(viewmodel, weaponModule)
	self.viewmodel = viewmodel
	self.weaponModule = weaponModule
	self.kickbackCurrent = CFrame.new()
	self.kickbackTarget = CFrame.new()
end

function Shoot:ApplyKickback(shotStack: number)
	if not self.viewmodel or not self.weaponModule then
		return
	end

	if shotStack <= 0 then
		shotStack = 1
	end

	local kickbackAmount = self.weaponModule.kickbackAmount * shotStack

	self.kickbackTarget *= CFrame.new(0, 0, kickbackAmount)
end

function Shoot:Update(dt)
	self.kickbackCurrent = self.kickbackCurrent:Lerp(
		self.kickbackTarget,
		1 - 0.01 ^ dt
	)

	self.kickbackTarget = self.kickbackTarget:Lerp(
		CFrame.new(),
		1 - 0.001 ^ dt
	)

	return self.kickbackCurrent
end

function Shoot:ResetKickback()
	self.kickbackCurrent = CFrame.new()
	self.kickbackTarget = CFrame.new()
end

function Shoot:Fire(camera, fireMode: string, recoilData, fireRate: number, stack: number)
	if fireMode == "Semi Auto" then
		self:ApplyRecoil(
			camera,
			recoilData.rx,
			recoilData.ry,
			recoilData.rz
		)

	elseif fireMode == "Full Auto" then
		-- self:ApplyRecoil(
		-- 	camera,
		-- 	recoilData.rx,
		-- 	recoilData.ry,
		-- 	recoilData.rz
		-- )

		print("Applying kickback with stack:", stack)

		-- self.viewmodelKickOffset = self:ApplyKickback(stack)
		-- task.wait(fireRate)
	end
end

return Shoot