return function()
	local CalicoM = script.Parent
	if not CalicoM:IsA("ModuleScript") then error("Please place the Collection loader directly underneath Calico") end
	local Calico = require(CalicoM)

	local RunService = game:GetService("RunService")
	local CollectionService = game:GetService("CollectionService")
	local SERVER_TAG = script:GetAttribute("ServerTarget") or "CalicoServerBehaviour"
	local CLIENT_TAG = script:GetAttribute("ClientTarget") or "CalicoClientBehaviour"
	local USE_TAG = if RunService:IsClient() then CLIENT_TAG else SERVER_TAG

	local function COM_SET(tag)
		for _, v in CollectionService:GetTagged(tag) do
			Calico.COMRuntime.TagCOMInstance(v, tag)
		end

		CollectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			Calico.COMRuntime.TagCOMInstance(v, tag)
		end)
	end

	local function loadModule(m: ModuleScript)
		if not m:IsA("ModuleScript") then return end

		local ok, desc = pcall(require, m)
		if not ok then
			warn(desc)
			return
		end -- < technically this doesn't capture any warnings but whatever

		if type(desc) ~= "table" or not desc.CollectionTag then
			warn(`Module {m} probably didnt return a Description`)
			return
		end

		COM_SET(desc.CollectionTag)
	end

	for _, v in CollectionService:GetTagged(USE_TAG) do
		loadModule(v)
	end

	CollectionService:GetInstanceAddedSignal(USE_TAG):Connect(function(v)
		loadModule(v)
	end)
end