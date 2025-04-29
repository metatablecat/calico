local Types = require(script.Parent.Types)
local StateMachine = require(script.StateMachine)
local Event = require(script.Parent.Event)
local EventManager = require(script.EventManager)
local bhvAlloc: {[Types.Behaviour]: Types.IBehaviour} = {}

local function IBehaviour(inst: Instance?, bhv: Types.Behaviour, iState: {[string]: any}): Types.IBehaviour
	local ibhv = {} :: Types.IBehaviour
	ibhv.Behaviour = bhv
	ibhv.EventManager = EventManager(bhv)
	-- ibhv.MessageBus =
	ibhv.StateMachine = StateMachine(bhv, iState)

	ibhv.Destroying = Event(bhv)
	ibhv.Init = Event(bhv)
	ibhv.COMInstance = inst
	if inst then
		assert(inst.Parent, "cannot assign a component instance without a parent to attach to")
		bhv.Instance = inst.Parent
	end

	ibhv.Destroyed = false

	function ibhv.DestroyInternal(self: Types.IBehaviour)
		if self.Destroyed then return end
		self.Destroyed = true
		self.StateMachine:Destroy()
		-- self.MachineBus:Destroy()

		self.Init:DisconnectAll()
		bhvAlloc[self.Behaviour] = nil

		self.Destroying:Fire()
		self.Destroying:DisconnectAll()
		self.EventManager:Destroy()
	end

	return ibhv
end

local function NOT_IMPLEMENTED_EXCEPTION(...)
	error("NotImplementedException")
end

local function assertGetPrivate(self: Types.Behaviour): Types.IBehaviour
	return assert(bhvAlloc[self], `Behaviour {self.ClassID} is destroyed`)
end

local BHVImpl = {}
-- this is the only time im ever going to use a metamethod because it'll make this VROOM
local PROXY_MT = {
	__index = BHVImpl,
	__tostring = function(self)
		return `Behaviour<{self.ClassID}>`
	end
}

-- IBehaviour Interfacing
-- Destruction methods should bypass the assertion
function BHVImpl.GetInstance(self: Types.Behaviour): Instance?
	local private = assertGetPrivate(self)
	return private.Instance
end

function BHVImpl.IsDestroyed(self: Types.Behaviour): boolean
	local private = bhvAlloc[self]
	if not private then return true end
	return private.Destroyed
end

function BHVImpl.Destroy(self: Types.Behaviour)
	local private = bhvAlloc[self]
	if not private then return end
	private:DestroyInternal()
end

-- EventManager
function BHVImpl.On<O, A...>(
	self: Types.Behaviour,
	signal: Types.Signal<O, A...>,
	eventName: string?,
	handler:(Types.Behaviour, Types.SenderParams<O>, A...) -> ()
): Types.Connection
	local private = assertGetPrivate(self)
	return private.EventManager:On(signal, eventName, handler)
end

function BHVImpl.OnInstance(
	self: Types.Behaviour,
	signal: string,
	eventName: string?,
	handler: (Types.Behaviour, Types.SenderParams<Instance>, ...any) -> ()
): Types.Connection
	assertGetPrivate(self)
	if not self.Instance then error("Cant use OnInstance on a behaviour without an allocated Instance") end
	return self:OnRBXSignal(self.Instance, signal, eventName, handler)
end

function BHVImpl.OnRBXSignal(
	self: Types.Behaviour,
	object: Instance,
	signal:RBXScriptSignal | string,
	eventName: string?,
	handler: (Types.Behaviour, Types.SenderParams<Instance>, ...any) -> ()
): Types.Connection
	local private = assertGetPrivate(self)
	return private.EventManager:OnRBX(object, signal, eventName, handler)
end

function BHVImpl.GetConnectionByTag(
	self: Types.Behaviour,
	tag: string
): Types.Connection
	local private = assertGetPrivate(self)
	return private.EventManager:GetConnectionByTag(tag)
end

function BHVImpl.GetConnections(self: Types.Behaviour): {[Types.Connection]: string|boolean}
	local private = assertGetPrivate(self)
	return private.EventManager:GetConnections()
end

-- MessageBus
BHVImpl.Subscribe = NOT_IMPLEMENTED_EXCEPTION
BHVImpl.SendMessage = NOT_IMPLEMENTED_EXCEPTION
BHVImpl.Broadcast = NOT_IMPLEMENTED_EXCEPTION
BHVImpl.SetOnInvoke = NOT_IMPLEMENTED_EXCEPTION
BHVImpl.Invoke = NOT_IMPLEMENTED_EXCEPTION
BHVImpl.GetTopic = NOT_IMPLEMENTED_EXCEPTION
BHVImpl.GetTopicType = NOT_IMPLEMENTED_EXCEPTION

-- StateMachine
function BHVImpl.GetState(
	self: Types.Behaviour,
	key: string
)
	local private = assertGetPrivate(self)
	return private.StateMachine:GetState(key)
end

function BHVImpl.GetAllState(
	self: Types.Behaviour
)
	local private = assertGetPrivate(self)
	return private.StateMachine:GetStates()
end

function BHVImpl.SetState(
	self: Types.Behaviour,
	key: string,
	val: any
)
	local private = assertGetPrivate(self)
	private.StateMachine:SetState(key, val)
end

return function(classID: string, i: Instance?, stateInit: {[string]: any})
	local bhv = {} :: Types.Behaviour
	local ibhv = IBehaviour(i, bhv, stateInit)

	bhv.ClassID = classID
	bhv.Destroying = ibhv.Destroying.Signal
	bhv.Init = ibhv.Init.Signal
	bhv.StateChanged = ibhv.StateMachine.StateChanged.Signal

	setmetatable(bhv, PROXY_MT)
	table.freeze(bhv)

	bhvAlloc[bhv] = ibhv

	-- we need to delay this one extra cycle to ensure it gets connected
	task.defer(function()
		if ibhv.Destroyed then return end
		ibhv.Init:Fire()
	end)
	return bhv
end