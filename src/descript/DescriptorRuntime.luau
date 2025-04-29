-- This stays idle until a Description becomes available, then it activates.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Types = require("./Types")

local DescriptorRuntime = {}
local LoadedDescriptions = {}

local IState: {[Instance]: Types.Behaviour} = {}

local function I_DESTROY(i: Instance)
	if IState[i] then
		IState[i]:Destroy()
		IState[i] = nil
	end
end

local function I_SETUP(i: Instance, desc: Types.Description): (boolean, Types.Behaviour)
	local ok, bhv = pcall(desc.Build, desc, i)
	if ok then
		IState[i] = bhv
		return true, bhv
	else
		warn(bhv)
		return false, bhv
	end
end

local function SETUP_WATCHER(i, desc)
	i.AncestryChanged:Connect(function(_, p)
		I_DESTROY(i)
		if p then
			-- rebuild in a new location
			I_SETUP(i, desc)
		elseif not RunService:IsStudio() then
			-- destroy the COM, unless in Studio (because we may need to recover it)
			i:Destroy()
		end
	end)
end

function DescriptorRuntime.newDescriptionInfo(desc: Types.Description)
	LoadedDescriptions[desc.CollectionTag] = desc
	
	for _, i in CollectionService:GetTagged(desc.CollectionTag) do
		SETUP_WATCHER(i, desc)
		I_SETUP(i, desc)
	end

	CollectionService:GetInstanceAddedSignal(desc.CollectionTag):Connect(function(i)
		if not IState[i] then
			SETUP_WATCHER(i, desc)
			I_SETUP(i, desc)
			-- add behaviour does this so we need to surpress it
		end
	end)
end

function DescriptorRuntime.assertUndefinedClassID(classID: string)
	assert(not LoadedDescriptions[classID], `Description {classID} is already defined by another description`)
end

function DescriptorRuntime.addBehaviour(i: Instance, classID: string): Types.Behaviour
	local desc = LoadedDescriptions[classID]
	if not desc then error(`Description {classID} not defined in context.`) end
	if not desc.InstanceAssertion(i) then error(`Cant assign {i} to description {desc}`) end

	local descriptionBindable = Instance.new("BindableEvent")
	descriptionBindable.Parent = i
	descriptionBindable.Name = `Behaviour<{classID}>`
	descriptionBindable:AddTag(classID)

	SETUP_WATCHER(i, desc)
	local ok, err = I_SETUP(i, desc)
	if not ok then error(`Failed to create {desc} because {err}`, -1) end
	return err
end

function DescriptorRuntime.removeBehaviour(i: Instance, classID: string)
	for _, v in i:GetChildren() do
		if v:HasTag(classID) then
			-- destroying effectively removes it
			i:Destroy()
		end
	end
end

function DescriptorRuntime.findBehaviour(i: Instance, classID: string): Types.Behaviour?
	-- technically, Calico has a method to do this already but this is redundancy for the Bindable system
	for _, v in i:GetChildren() do
		if v:HasTag(classID) then return v end
	end

	return nil
end

function DescriptorRuntime.getBehaviours(i: Instance): {Types.Behaviour}
	local t = {}
	for _, v in i:GetChildren() do
		local bhv = IState[v]
		if bhv then table.insert(t, bhv) end
	end
	return t
end

return DescriptorRuntime