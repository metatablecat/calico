-- Typedefs
-- ./Behaviour
export type IBehaviour = {
	-- Internal linkers and event state
	Behaviour: Behaviour,

	EventManager: EventManager,
	MessageBus: never,
	StateMachine: StateMachine,

	Destroying: Event<Behaviour>,
	Init: Event<Behaviour>,

	COMInstance: Instance?,
	Destroyed: boolean,
	DestroyInternal: (IBehaviour) -> (),
}

export type Behaviour = {
	-- Main runtime object

	-- IBehaviour Interfacing
	ClassID: string,
	Instance: Instance?,
	IsDestroyed: (Behaviour) -> boolean,
	Destroy: (Behaviour) -> (),
	Destroying: Signal<Behaviour>,
	Init: Signal<Behaviour>,

	-- EventManager
	On: <O, A...>(Behaviour, Signal<O, A...>, eventName: string?, handler: (Behaviour, SenderParams<O>, A...) -> ()) -> Connection,
	OnInstance: (Behaviour, signal: string, eventName: string?, handler: (Behaviour, SenderParams<Instance>, ...any) -> ()) -> Connection,
	OnRBXSignal: (Behaviour, object: Instance, signal: string|RBXScriptSignal, eventName: string?, handler: (Behaviour, SenderParams<Instance>, ...any) -> ()) -> Connection,
	GetConnectionByTag: (Behaviour, tag: string) -> Connection?,
	GetConnections: (Behaviour) -> {[Connection]: string|boolean},

	-- MessageBus
	Subscribe: (Behaviour, topic: string, handler: (any) -> ()) -> Connection,
	SendMessage: (Behaviour, topic: string, message: any) -> (),
	Broadcast: (Behaviour, topic: string, message: any) -> (),
	SetOnInvoke: (Behaviour, topic: string, onInvoke: (any) -> any) -> Connection,
	Invoke: (Behaviour, topic: string, message: any) -> any,

	GetTopic: (Behaviour, topic: string) -> Connection?,
	GetTopicType: (Behaviour, topic: string) -> MessageTopicState,
	Broadcasting: Signal<Behaviour, string, any>,

	-- StateMachine
	GetState: (Behaviour, state: string) -> any,
	GetAllState: (Behaviour) -> {[string]: any},
	SetState: (Behaviour, state: string, value: any) -> (),
	StateChanged: Signal<Behaviour, string, any, any>
}

-- ./EventManager
export type EventManager = {
	-- handles event subscriptions to the Broadcaster
	__GC_LAST_SWEEP_TIME: number, -- we sweep the ConnectionData table for disconnected objects every second. invoked when a new connection is created, or GetConnections is called
	__GC_SWEEP: (EventManager) -> boolean,

	Behaviour: Behaviour,

	ConnectionData: {
		Connections: {[Connection]: string|boolean},
		Tagged: {[string]: Connection}
	},

	On: <O, A...>(EventManager, Signal<O, A...>, eventName: string?, handler: (Behaviour, SenderParams<O>, A...) -> ()) -> Connection,
	OnRBX: (EventManager, object: Instance, signal: string|RBXScriptSignal, eventName: string?, handler: (Behaviour, SenderParams<Instance>, ...any) -> ()) -> Connection,
	GetConnectionByTag: (EventManager, tag: string) -> Connection?,
	GetConnections: (EventManager) -> {[Connection]: string|boolean},
	Destroy: (EventManager) -> (),
}

export type Connection = {
	-- tagged object connection
	Tag: string?,
	IsConnected: (Connection) -> boolean,
	Disconnect: (Connection) -> ()
}

export type Signal<O, A...> = {
	Connect: (Signal<O, A...>, tag: string?, handler: (SenderParams<O>, A...) -> ()) -> Connection
}

export type SenderParams<O> = {
	Sender: O,
	Connection: Connection
}

export type Event<O, A...> = {
	Owner: O,
	Connections: {[Connection]: 
		{
			f: (SenderParams<O>, A...) -> (),
			sp: SenderParams<O>
		}
	},
	Signal: Signal<O, A...>,
	Fire: (Event<O, A...>, A...) -> (),
	DisconnectAll: (Event<O, A...>) -> ()
}

-- ./MessageBus
export type MessageTopicState =
| "Undefined"
| "Subscription"
| "Invokation"

-- ./StateMachine
export type StateMachine = {
	State: {[string]: any},
	GetState: (StateMachine, key: string) -> any,
	GetStates: (StateMachine) -> {[string]: any},
	SetState: (StateMachine, key: string, val: any) -> (),
	StateChanged: Event<Behaviour, string, any, any>,
	Destroy: (StateMachine) -> ()
}

return nil