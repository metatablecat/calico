-- CALICO: Behaviour library

local Behaviour = require(script.lib.Behaviour)
local Describe = require(script.descript)
local Event = require(script.lib.Event)
local Types = require(script.lib.Types)

local Calico = {}

function Calico.new(cid: string, inst: Instance?, iac: boolean?, istate: {[string]: any}?): Types.Behaviour
	return Behaviour(cid, inst, if iac ~= nil then iac else false, istate or {})
end

function Calico.Event<O, A...>(sender: O): Types.Event<O, A...>
	-- roblox will do anything but make generics not stupid
	return Event(sender)
end

Calico.Describe = Describe
table.freeze(Calico)
return Calico
