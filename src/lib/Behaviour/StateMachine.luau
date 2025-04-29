local Types = require("../Types")
local Event = require("../Event")

return function(bhv: Types.Behaviour, initState: {[string]: any}): Types.StateMachine
	local sm = {} :: Types.StateMachine
	sm.State = initState

	function sm:GetState(key)
		return self.State[key]
	end

	function sm:GetStates()
		return table.clone(sm.State)
	end

	function sm:SetState(key, val)
		local ov = sm[key]
		if type(val) == "table" or ov ~= val then
			sm[key] = val
			self.StateChanged:Fire(key, val, ov)
		end
	end

	sm.StateChanged = Event(bhv)

	function sm:Destroy()
		sm.StateChanged:DisconnectAll()
	end
	
	return sm
end