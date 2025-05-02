-- CALICO: Behaviour library

local Behaviour = require(script.lib.Behaviour)
local Event = require(script.lib.Event)
local Types = require(script.lib.Types)
local DescriptorRuntime = require(script.COMRuntime)

local Calico = {}

function Calico.new(cid: string, inst: Instance?, applyMode: Types.ApplyMode?, istate: {[string]: any}?): Types.Behaviour
	return Behaviour(cid, inst, applyMode or "Direct", istate or {})
end

function Calico.Event<O, A...>(sender: O): Types.Event<O, A...>
	-- roblox will do anything but make generics not stupid
	return Event(sender)
end

Calico.Describe = DescriptorRuntime.newDescriptionInfo
Calico.DescribeUntracked = DescriptorRuntime.untrackedDescriptionInfo
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
