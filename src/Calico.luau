-- CALICO: Behaviour library
-- currently, only legacy syntax is supported
-- TODO: Descriptor syntax

local Behaviour = require("./lib/Behaviour/Behaviour")
local Event = require("./lib/Event")
local Types = require("./lib/Types")
local Descriptor = require("./descript/Descriptor")
local DescriptorRuntime = require("./descript/DescriptorRuntime")
local DescriptorTypes = require("./descript/Types")

local Calico = {}

function Calico.new(cid: string, inst: Instance?, istate: {[string]: any}?): Types.Behaviour
	return Behaviour(cid, inst, istate or {})
end

function Calico.Event<O, A...>(sender: O): Types.Event<O, A...>
	-- roblox will do anything but make generics not stupid
	return Event(sender)
end

function Calico.Describe(classID: string, describe: (DescriptorTypes.Descriptor) -> {[string]:any}?): DescriptorTypes.Description
	local desc = Descriptor(classID, describe)
	DescriptorRuntime.newDescriptionInfo(desc)
	return desc
end

Calico.AddBehaviour = DescriptorRuntime.addBehaviour
Calico.RemoveBehaviour = DescriptorRuntime.removeBehaviour
Calico.FindBehaviour = DescriptorRuntime.findBehaviour
Calico.GetInstanceBehaviours = DescriptorRuntime.getBehaviours

table.freeze(Calico)
return Calico
