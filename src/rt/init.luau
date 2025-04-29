return function()
	local RunService = game:GetService("RunService")
	local CollectionService = game:GetService("CollectionService")

	local SERVER_TAG = script:GetAttribute("ServerTarget") or "CalicoServerBehaviour"
	local CLIENT_TAG = script:GetAttribute("ClientTarget") or "CalicoClientBehaviour"

	local USE_TAG = if RunService:IsClient() then CLIENT_TAG else SERVER_TAG

	local function loadModule(m: ModuleScript)
		if not m:IsA("ModuleScript") then return end

		local ok, err = pcall(require, m)
		if not ok then
			warn(err)
			return
		end -- < technically this doesn't capture any warnings but whatever

		if type(err) ~= "function" then
			warn(`Behaviour module {m} does not return a callable function`)
			return
		end
		err()
	end

	for _, v in CollectionService:GetTagged(USE_TAG) do
		loadModule(v)
	end

	CollectionService.TagAdded:Connect(function(v)
		loadModule(v)
	end)
end