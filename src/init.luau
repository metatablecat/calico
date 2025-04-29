-- CALICO: Behaviour library
-- currently, only legacy syntax is supported
-- TODO: Descriptor syntax

local Behaviour = require(script.lib.Behaviour)
local Event = require(script.lib.Event)
local Types = require(script.lib.Types)
local DescriptorRuntime = require(script.rt)

local Calico = {}

function Calico.new(cid: string, inst: Instance?, istate: {[string]: any}?): Types.Behaviour
	return Behaviour(cid, inst, istate or {})
end

function Calico.Event<O, A...>(sender: O): Types.Event<O, A...>
	-- roblox will do anything but make generics not stupid
	return Event(sender)
end

Calico.Describe = DescriptorRuntime.newDescriptionInfo
Calico.AddBehaviour = DescriptorRuntime.addBehaviour
Calico.RemoveBehaviour = DescriptorRuntime.removeBehaviour
Calico.FindBehaviour = DescriptorRuntime.findBehaviour
Calico.GetInstanceBehaviours = DescriptorRuntime.getBehaviours

-- COMRuntime is intended for low-level internal usage if you're building a runtime
-- Its best to leave these functions unless you wish to work with COM instances
-- directly
Calico.COMRuntime = {}
Calico.COMRuntime.TagCOMInstance = DescriptorRuntime.tagBehaviourCOM
Calico.COMRuntime.UnloadCOMInstance = DescriptorRuntime.removeBehaviourCOM
Calico.COMRuntime.UntagCOMInstance = DescriptorRuntime.untagCOM

table.freeze(Calico.COMRuntime)
table.freeze(Calico)
return Calico
