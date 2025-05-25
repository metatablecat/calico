local RunService = game:GetService("RunService")
local Types = require(script.Parent.descript.Types)
local Descriptor = require(script.Parent.descript)
-- Unlike other objects, this just provides a starter point for descriptions
-- you need to pass Instances yourself

-- This is just for COM instances, use untracked descriptions to build your own systems

-- CALICO RT HOOKS
local Runtime = {}
local LoadedDescriptions: {[string]: Types.Description} = {}
local IState: {[Instance]: Types.Behaviour} = {}
local AncestryEvents: {[Instance]: RBXScriptConnection} = {}

local function I_DESTROY(i: Instance)
	if IState[i] then
		IState[i]:Destroy()
		IState[i] = nil
	end
end

local function I_SETUP(i: Instance, desc: Types.Description): (boolean, Types.Behaviour)
	local ok, bhv = pcall(desc.Build, desc, i, "COM"::"COM")
	if ok then
		IState[i] = bhv
		return true, bhv
	else
		warn(bhv)
		return false, bhv
	end
end

local function SETUP_WATCHER(COM, desc)
	if AncestryEvents[COM] then error(`{COM} is already being watched by another connection`) end

	AncestryEvents[COM] = COM.AncestryChanged:Connect(function(_, p)
		I_DESTROY(COM)
		if p then
			-- rebuild in a new location
			I_SETUP(COM, desc)
		elseif not RunService:IsStudio() and IState[COM] then
			-- IState is important here in case the object got untagged, it should disconnect this
			-- destroy the COM, unless in Studio (because we may need to recover it)
			AncestryEvents[COM] = nil
			COM:Destroy()
		end
	end)
end

function Runtime.newDescriptionInfo(
	classID: string,
	describe: (Types.Descriptor) -> {[string]: any}?
): Types.Description
	assert(not LoadedDescriptions[classID], `Description {classID} is already defined by another description`)
	local desc = Descriptor(classID, describe)
	LoadedDescriptions[desc.CollectionTag] = desc
	return desc
end

function Runtime.untrackedDescriptionInfo(
	classID: string,
	describe: (Types.Descriptor) -> {[string]: any}?
): Types.Description
	return Descriptor(classID, describe)
end

local function BuildObject(
	i: Instance,
	com: Instance,
	classID: string
): Types.Behaviour
	local desc = LoadedDescriptions[classID]
	if not desc.InstanceAssertion(i) then error(`Cant assign {i} to description {classID}`) end
	local ok, err = I_SETUP(com, desc)
	if not ok then error(`Failed to create {classID} because {err}`, -1) end
	return err
end

function Runtime.tagBehaviourCOM(
	com: Instance,
	classID: string
)
	local desc = LoadedDescriptions[classID]
	if not desc then error(`Description {classID} not defined in context.`) end
	if IState[com] then error(`COM Instance {com} already has an associated behaviour`) end
	local inst = com.Parent

	SETUP_WATCHER(com, desc)
	if inst then BuildObject(inst, com, classID) end
end

function Runtime.addBehaviour(
	i: Instance,
	classID: string
): Types.Behaviour
	local desc = LoadedDescriptions[classID]
	if not desc then error(`Description {classID} not defined in context.`) end
	if desc.InstanceAssertion and not desc.InstanceAssertion(i) then error(`Cant assign {i} to description {classID}`) end

	local comOverload = Instance.new("BindableEvent")
	comOverload.Parent = i
	comOverload.Name = `Behaviour<{classID}>`

	Runtime.tagBehaviourCOM(comOverload, classID)
	return BuildObject(i, comOverload, classID)
end

function Runtime.removeBehaviourCOM(
	com: Instance
)
	if IState[com] then
		com:Destroy()
		return
	end

	error(`Instance {com} has no associated behaviour.`)
end

function Runtime.untagCOM(
	com: Instance
)
	local is = IState[com]
	local ae = AncestryEvents[com]
	if not (is or ae) then error(`{com} has no associated Behaviour`) end

	if is then I_DESTROY(com) end

	if ae then
		ae:Disconnect()
		AncestryEvents[com] = nil
	end
end

function Runtime.removeBehaviour(
	i: Instance,
	classID: string
)
	for _, v in i:GetChildren() do
		local bhv = IState[v]
		if bhv then v:Destroy() end
	end
end

function Runtime.findBehaviour(
	i: Instance,
	classID: string
): Types.Behaviour?
	-- find behaviour can return any type of behaviour
	for _, v in i:GetChildren() do
		local bhv = IState[v]
		if bhv then return bhv end
	end

	return nil
end

function Runtime.getBehaviours(
	i: Instance
): {Types.Behaviour}
	-- note, this only returns managed behaviours
	-- which means if multiple systems are working with the system
	-- we reference that
	local t = {}
	for _, v in i:GetChildren() do
		local bhv = IState[v]
		if bhv then table.insert(t, bhv) end
	end

	return t
end

function Runtime.isInstanceCOM(
	com: Instance
): boolean
	return IState[com] ~= nil
end

return Runtime