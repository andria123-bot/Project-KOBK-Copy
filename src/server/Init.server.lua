local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Services = script.Parent.Services

for _, module in Services:GetChildren() do
	if module:IsA("ModuleScript") then
		print("[Server] Loading: ", module.Name)
		require(module)
	end
end

Knit.Start()
	:andThen(function()
		print("[Server] Knit started — all services running")
	end)
	:catch(function(err)
		warn("[Server] Knit failed to start:", err)
	end)
