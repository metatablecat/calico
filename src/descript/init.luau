-- Descriptor syntax allows you to define CollectionService tags using a "Descriptor" object, which is very close to the underlying objects

local Types = require(script.Types)
local Behaviour = require(script.Parent.lib.Behaviour)
local PTR_ASSERTION = newproxy(false)

export type Description = Types.Description

local function SignalPtr<O, A...>(name): Types.SignalPtr<O, A...>
	local ptr = {} :: Types.SignalPtr<O, A...>
	ptr.Name = name
	ptr[PTR_ASSERTION] = true
	table.freeze(ptr)
	return ptr
end

local function descriptor(description): Types.Descriptor
	local descriptor = {}::Types.Descriptor
	descriptor._description = description
	descriptor.Init = SignalPtr("Init")
	descriptor.Destroying = SignalPtr("Destroying")
	descriptor.StateChanged = SignalPtr("StateChanged")
	descriptor.Broadcasting = SignalPtr("Broadcasting")
	descriptor.UseInstanceAsCOM = false
	
	function descriptor:On(sigPtr, tag, handler)
		if tag and self._description.EventTags[tag] then error(`Tag {tag} is already declared`) end
		local symbol: Types.SignalSymbol

		if sigPtr[PTR_ASSERTION] then
			symbol = {
				SignalType = "Behavioural",
				Tag = tag,
				SignalObject = sigPtr.Name,
			}
		else
			symbol = {
				SignalType = "BehaviouralLinked",
				Tag = tag,
				SignalObject = sigPtr
			}
		end

		self._description.Signals[symbol] = handler
		if tag then self._description.EventTags[tag] = true end
	end

	function descriptor:OnInstance(eName, tag, handler)
		if tag and self._description.EventTags[tag] then error(`Tag {tag} is already declared`) end

		local symbol: Types.SignalSymbol = {
			SignalType = "RBX",
			Tag = tag,
			SignalObject = eName,
		}

		self._description.Signals[symbol] = handler
		if tag then self._description.EventTags[tag] = true end
	end

	function descriptor:OnRBXSignal(sender, eName, tag, handler)
		if tag and self._description.EventTags[tag] then error(`Tag {tag} is already declared`) end

		local symbol: Types.SignalSymbol = {
			SignalType = "RBX",
			Tag = tag,
			Instance = sender,
			SignalObject = eName,
		}

		self._description.Signals[symbol] = handler
		if tag then self._description.EventTags[tag] = true end
	end

	return descriptor
end

local function instanceBuilder(description: Types.Description, inst: Instance?): Types.Behaviour
	local parent = if inst then if description.UseInstanceAsCOM then inst else inst.Parent else nil
	assert(parent, "no parent to attach component to")
	if description.InstanceAssertion then
		if not inst then error(`Description {description.CollectionTag} requires an Instance`) end
		assert(description.InstanceAssertion(parent::Instance), `Description {description.CollectionTag} received an invalid instance`)
	end
	-- we need to pcall this for safety
	-- anoyingly, event access errors can throw
	
	local obj = Behaviour(description.CollectionTag, inst, description.UseInstanceAsCOM, description.State)
	for signalInfo, handler in description.Signals do
		if signalInfo.SignalType == "Behavioural" then
			-- find signal from allocated pointer and bind
			obj:On(obj[signalInfo.SignalObject], signalInfo.Tag, handler)
		elseif signalInfo.SignalType == "RBX" then

			if not inst then
				warn(`OnInstance was used in the Description, but no Instance was assigned`)
				continue
			end

			local applyInst = signalInfo.Instance or (if description.UseInstanceAsCOM then inst.Parent else inst)
			if not applyInst then
				warn(`OnInstance was used in the Description, but no Instance to apply to.`)
				continue
			end

			obj:OnRBXSignal(applyInst, signalInfo.SignalObject, signalInfo.Tag, handler)
		elseif signalInfo.SignalType == "BehaviouralLinked" then
			obj:On(signalInfo.SignalObject, signalInfo.Tag, handler)
		end
	end

	return obj
end

return function(classID: string, describe: (Types.Descriptor) -> {[string]: any}?): Types.Description
	local description: Types.Description = {
		CollectionTag = classID,
		Signals = {},
		State = {},
		EventTags = {},
		Build = instanceBuilder,
		UseInstanceAsCOM = false
	}

	local descript = descriptor(description)
	local state = describe(descript) or {}
	description.State = state
	description.InstanceAssertion = descript.InstanceAssertion
	description.UseInstanceAsCOM = descript.UseInstanceAsCOM
	return description
end