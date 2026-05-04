local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local Controllers = script.Parent.Controllers
for _, module in Controllers:GetChildren() do
	if module:IsA("ModuleScript") then
		local ok, err = pcall(require, module)
		if not ok then
			warn("[Client] Failed to load controller", module.Name, err)
		else
			print("[Client] Loaded controller", module.Name)
		end
	end
end

Knit.Start()
	:andThen(function()
		print("[Client] Knit started — all controllers running")
	end)
	:catch(function(err)
		warn("[Client] Knit failed to start:", err)
	end)
