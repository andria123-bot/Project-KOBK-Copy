-- local Players = game:GetService("Players")
-- local RunService = game:GetService("RunService")
-- local workspace = game:GetService("Workspace")

-- local player = Players.LocalPlayer
-- local camera = workspace.CurrentCamera

-- -- Settings
-- local CAMERA_OFFSET = Vector3.new(0, 0.5, -0.7)  -- camera offset
-- local VIEWMODEL_OFFSET = Vector3.new(0, -0.2, -0.5) -- viewmodel offset
-- local VIEWMODEL_GAP = 0.1

-- local viewmodel = workspace:FindFirstChildWhichIsA("Model")
-- viewmodel.Parent = camera
-- local vpPrimary = viewmodel.PrimaryPart
-- if not vpPrimary then warn("Viewmodel needs a PrimaryPart!") end

-- local function setupCharacter(character)
--     local head = character:WaitForChild("Head")
--     local humanoid = character:WaitForChild("Humanoid")
--     local root = character:WaitForChild("HumanoidRootPart")

--     camera.CameraType = Enum.CameraType.Custom
--     camera.CameraSubject = humanoid
--     player.CameraMode = Enum.CameraMode.LockFirstPerson

--     humanoid.AutoRotate = false

--     -- Cache all body parts for visibility
--     local bodyParts = {}
--     for _, v in pairs(character:GetDescendants()) do
--         if v:IsA("BasePart") then
--             table.insert(bodyParts, v)
--         end
--     end

--     -- Determine hand parts
--     local handNames
--     if humanoid.RigType == Enum.HumanoidRigType.R6 then
--         handNames = {"Left Arm", "Right Arm"}
--     else
--         handNames = {"LeftHand","RightHand","LeftLowerArm","RightLowerArm","LeftUpperArm","RightUpperArm"}
--     end

--     local currentY = 0

--     RunService.RenderStepped:Connect(function(dt)
--         if not character or not root then return end

--         -- 🔹 Force full body visible
--         for _, part in pairs(bodyParts) do
--             part.LocalTransparencyModifier = 0
--         end

--         -- Hide head
--         head.LocalTransparencyModifier = 1

--         -- Make hands transparent
--         for _, name in pairs(handNames) do
--             local hand = character:FindFirstChild(name)
--             if hand and hand:IsA("BasePart") then
--                 hand.LocalTransparencyModifier = 1
--             end
--         end

--         -- Smooth body rotation (yaw only)
--         local _, targetY, _ = camera.CFrame:ToOrientation()
--         currentY = currentY + (targetY - currentY) * math.clamp(dt * 10, 0, 1)
--         root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, currentY, 0)

--         -- Camera offset
--         camera.CFrame = CFrame.new(head.Position + head.CFrame:VectorToWorldSpace(CAMERA_OFFSET))
--             * CFrame.fromMatrix(Vector3.zero, camera.CFrame.RightVector, camera.CFrame.UpVector)

--         -- Viewmodel position (with raycast to prevent clipping)
--         if vpPrimary then
--             local desiredPos = camera.CFrame.Position + camera.CFrame:VectorToWorldSpace(VIEWMODEL_OFFSET)
--             local ray = Ray.new(camera.CFrame.Position, (desiredPos - camera.CFrame.Position))
--             local hitPart, hitPos = workspace:FindPartOnRay(ray, character)

--             if hitPart then
--                 vpPrimary.CFrame = CFrame.new(hitPos - camera.CFrame.LookVector * VIEWMODEL_GAP)
--             else
--                 vpPrimary.CFrame = CFrame.new(desiredPos)
--             end

--             -- Keep viewmodel rotation aligned with camera
--             vpPrimary.CFrame = CFrame.new(vpPrimary.Position) * CFrame.fromMatrix(Vector3.zero, camera.CFrame.RightVector, camera.CFrame.UpVector)
--         end
--     end)
-- end

-- -- Run on spawn
-- if player.Character then
--     setupCharacter(player.Character)
-- end
-- player.CharacterAdded:Connect(setupCharacter)

-- local InventoryUIController = require(script.Parent.Inventory.InventoryUIController)

-- InventoryUIController:InitSys()
require(game.ReplicatedStorage.Shared.Modules.InventoryUIController)