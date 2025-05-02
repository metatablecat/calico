local Types = require(script.Parent.Parent.lib.Types)

export type ApplyMode = Types.ApplyMode
export type Signal<A, O...> = Types.Signal<A, O...>

export type SignalSymbol = ({
	SignalType: "Behavioural",
	Tag: string?,
	SignalObject: string,
} | {
	SignalType: "RBX",
	Tag: string?,
	SignalObject: string|"RBXScriptSignal",
	Instance: Instance?,
} | {
	SignalType: "BehaviouralLinked",
	Tag: string,
	SignalObject: Signal<any>
})

export type Description = {
	CollectionTag: string,
	InstanceAssertion: ((Instance) -> boolean)?,
	Signals: {[SignalSymbol]: (Types.Behaviour, Types.SenderParams<any>, ...any) -> ()},
	EventTags: {[string]: true},
	State: {[string]: any},
	Build: (Description, Instance?, ApplyMode?) -> Types.Behaviour
}

export type Descriptor = {
	_description: Description,
	InstanceAssertion: ((Instance) -> boolean)?,
	On: <O, A...>(Descriptor, SignalPtr<O, A...>|Signal<O, A...>, signalTag: string?, handler: (Types.Behaviour, Types.SenderParams<O>, A...) -> ()) -> (),
	OnInstance: (Descriptor, signalName: string, signalTag: string?, handler: (Types.Behaviour, Types.SenderParams<Instance>, ...any) -> ()) -> (),
	OnRBXSignal: (Descriptor, owner: Instance, signalName: string, signalTag: string?, handler: (Types.Behaviour, Types.SenderParams<Instance>, ...any) -> ()) -> (),

	Init: SignalPtr<Types.Behaviour>,
	Destroying: SignalPtr<Types.Behaviour>,
	StateChanged: SignalPtr<Types.Behaviour, string, any, any>,
	Broadcasting: SignalPtr<Types.Behaviour, string, any>
}

export type SignalPtr<O, A...> = {
	Name: string
}

export type Behaviour = Types.Behaviour
return nil