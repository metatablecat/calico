-- Handles events owned to behaviours, and tagging RBXScriptSignals
-- note: disconnected script signals are assumed to be dangling references and
-- will be overwritten if given the chance

local Types = require(script.Parent.Parent.Types)
local GC_REST_TIME = 1
local GC_MAX_BUFFER = 32

local function RBXConnectionWrapper(tag: string?, conn: RBXScriptConnection): Types.Connection
	local iconn: Types.Connection = {
		Tag = tag,

		IsConnected = function(self)
			return conn.Connected
		end,

		Disconnect = function(self)
			conn:Disconnect()
		end
	}

	table.freeze(iconn)
	return iconn
end

return function(BHV: Types.Behaviour): Types.EventManager
	local evM = {} :: Types.EventManager
	evM.Behaviour = BHV
	evM.ConnectionData = {
		Connections = {},
		Tagged = {}
	}

	function evM.On<O, A...>(
		self: Types.EventManager,
		signal: Types.Signal<O, A...>,
		eventName: string?,
		handler:(Types.Behaviour, Types.SenderParams<O>, A...) -> ()
	): Types.Connection
		self:__GC_SWEEP()

		local oldConn = eventName and evM.ConnectionData.Tagged[eventName]
		if oldConn and oldConn:IsConnected() then error(`Tag {eventName} is already used`) end

		-- this creates the connection we want, we just need to callwrap it with self
		local conn = signal:Connect(eventName, function(sp, ...)
			handler(self.Behaviour, sp, ...)
		end)

		evM.ConnectionData.Connections[conn] = eventName or true
		if eventName then evM.ConnectionData.Tagged[eventName] = conn end
		return conn
	end

	function evM.OnRBX(
		self: Types.EventManager,
		object: Instance,
		signal: RBXScriptSignal | string,
		eventName: string?,
		handler:(Types.Behaviour, Types.SenderParams<Instance>, ...any) -> ()
	): Types.Connection
		self:__GC_SWEEP()

		local oldConn = eventName and evM.ConnectionData.Tagged[eventName]
		if oldConn and oldConn:IsConnected() then error(`Tag {eventName} is already used`) end

		if typeof(signal) == "string" then
			-- convert the signal to a RBXScriptSignal
			signal = object[signal]::RBXScriptSignal
			assert(typeof(signal) == "RBXScriptSignal", `{signal} is not a RBXScriptSignal`)
		end

		-- need to bake sender params
		local senderParams = {}::Types.SenderParams<Instance>
		senderParams.Sender = object

		local conn = RBXConnectionWrapper(
			eventName, 
			(signal::RBXScriptSignal):Connect(function(...)
				handler(self.Behaviour, senderParams, ...)
			end)
		)

		senderParams.Connection = conn
		evM.ConnectionData.Connections[conn] = eventName or true
		if eventName then evM.ConnectionData.Tagged[eventName] = conn end
		return conn
	end

	function evM.GetConnectionByTag(
		self: Types.EventManager,
		tag: string
	): Types.Connection?
		self:__GC_SWEEP()
		return self.ConnectionData.Tagged[tag]
	end

	function evM.GetConnections(
		self: Types.EventManager
	): {[Types.Connection]: string|boolean}
		self:__GC_SWEEP()
		return table.clone(self.ConnectionData.Connections)
	end

	function evM.Destroy(
		self: Types.EventManager
	)
		-- cleanup connections
		for conn in self.ConnectionData.Connections do
			if conn:IsConnected() then
				conn:Disconnect()
			end
		end

		table.clear(self.ConnectionData.Connections)
		table.clear(self.ConnectionData.Tagged)
	end

	evM.__GC_LAST_SWEEP_TIME = 0
	function evM.__GC_SWEEP(self: Types.EventManager)
		local now = os.clock()
		if now - self.__GC_LAST_SWEEP_TIME < GC_REST_TIME then return end
		self.__GC_LAST_SWEEP_TIME = now

		local toRemove: {Types.Connection} = table.create(GC_MAX_BUFFER)
		local removing = 0

		for connection in self.ConnectionData.Connections do
			if not connection:IsConnected() then
				removing += 1
				toRemove[removing] = connection
				if removing >= GC_MAX_BUFFER then break end
			end
		end

		for _, conn in toRemove do
			self.ConnectionData.Connections[conn] = nil
			if conn.Tag then
				self.ConnectionData.Tagged[conn.Tag] = nil
			end
		end
	end

	return evM
end