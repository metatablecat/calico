-- A simple service for managing Instance-linked components, with a built-in
-- tree
local Catwork = require(script.Parent.Parent.Catwork)
local Event = require(script.Parent.Parent.Modules.Event)

local function fastMixedTableSplit(t)
	local l = #t
	if l == 0 then return {} end
	local out = table.move(t, 1, l, 1, {})
	table.move({}, 1, l, 1, t)
	return out
end

export type Component = Catwork.Object<{
	Instance: any?,
	RefComponent: Component,
	State: {[string]: any},
	Params: {[string]: any},
	ChildMount: Component,
	_eOnStateChanged: Event.Event<Component, string, any, any>,
	OnStateChanged: Event.Signal<Component, string, any, any>,
	
	-- Tree navigation
	Parent: (Component|Instance)?, -- instance directly ontop of this one, required for keep-alive impl
	Children: {[string]: Component}, -- child components, for tree navigation
	
	-- Callbacks
	StateChanged: (Component, stateKey: string, newValue: any, oldValue: any) -> (),
	Render: (Component, params: {[string]: any}) -> (),
	GetEventSignal: (Component, eName: string) -> RBXScriptSignal,
	
	-- Methods
	SetState: (Component, stateKey: string, newValue: any) -> (),
	SetParent: (Component, Component|Instance?) -> (),
	Connect: (Component, eName: string, eFn: (Component, ...any) -> ()) -> RBXScriptConnection,
	
	--loosen table (technically this indexes the Children table but ehh)
	[string]: Component,
}>

local instanceComponentLinks: {[Instance]: Component} = {}

local function isInstanceDestroyed(f: Component)
	if not f.Instance then return false end -- cannot be established
	return instanceComponentLinks[f.Instance] == nil
end

local function setParentContainer(parent: Component, child: Component)
	local p
	if child == parent.ChildMount then
		p = parent.Instance
	else
		p = if parent.ChildMount then parent.ChildMount.Instance else parent.Instance
	end
	
	if child.Instance then child.Instance.Parent = p end
end

local function destroyAll(f: Component)
	if f.RefComponent then
		f.RefComponent:Destroy()
	end
	
	for _, v in f.Children do
		v:Destroy()
	end
	
	if f.Instance and not isInstanceDestroyed(f) then
		f.Instance:Destroy()
	end
end

local service = Catwork.Service {
	EnableTemplates = true,
	Name = "ComponentService",
	
	CreateObject = function(self, params)
		params.State = params.State or {}
		params.Params = params.Params or {}
		params.Children = {}
		
		if not params.Name then
			error(`Components require a Name`)
		end
		
		if not params.Render then
			error(`Component {params.Name} does not have a Render method`)
		end
		
		function params:SetState(key, value)
			local oV = self.State[key]
			if oV == value then return end
			self.State[key] = value

			local f = self.StateChanged
			if f then f(self, key, value, oV) end
			local mV = self.State[key] -- f might change the state internally, so we need to capture it again

			self._eOnStateChanged:Fire(self, key, mV, oV)
		end
		
		function params:SetParent(parent)
			-- do not allow duplicate child names if the parent is a component
			-- for instances, roblox uses their own children system
			if not parent and self.Parent then
				-- no parent, remove from tree
				local p = self.Parent
				p.Children[self.Name] = nil
				self.Parent = nil

				if self.Instance and not isInstanceDestroyed(self) then self.Instance.Parent = nil end
			elseif typeof(parent) == "Instance" then
				-- RBX path
				self.Parent = parent
				if self.Instance then self.Instance.Parent = parent end
			elseif parent ~= self.Parent then
				-- Component path
				local p = parent.Children[self.Name]
				if p and p ~= self then
					error("Cannot use duplicate component names.")
				end
				
				parent.Children[self.Name] = self
				
				self.Parent = parent
				setParentContainer(parent, self)
			end
		end
		
		function params:Connect(name, fn)
			local e
			if self.GetEventSignal then
				e = self:GetEventSignal(name)
			elseif self.RefComponent and self.RefComponent.GetEventSignal then
				e = self.RefComponent:GetEventSignal(name)
			else
				error("Component cannot be connected to")
			end
			
			if typeof(e) ~= "RBXScriptSignal" then
				error(`Component {self.Name} does not have a valid event for {name}`)
			end
			
			return e:Connect(function(...)
				fn(self, ...)
			end)
		end
		
		params._eOnStateChanged = Event()
		params.OnStateChanged = params._eOnStateChanged.Signal
		return Catwork:CreateFragmentForService(params, self)
	end,
	
	ObjectAdded = function(self, f)
		getmetatable(f).__index = f.Children

		self:SpawnObject(f)
	end,
	
	Spawning = function(self, f: Component)
		-- execution order:
		-- Render initial instance
		-- Init (for extra child instances)
		-- Reconcile existing children
		
		local i = f:Render(f.Params)
		if type(i) == "table" then
			-- component instance, we should add this to the children table as "self"
			f.RefComponent = i
			f.Instance = i.Instance

			for _, v in f.RefComponent.Children do
				v:SetParent(f)
			end
		else
			f.Instance = i
		end
		
		instanceComponentLinks[i] = f

		f.Instance.Destroying:Connect(function()
			if f.Instance and not isInstanceDestroyed(f) then
				instanceComponentLinks[f.Instance] = nil
			end

			f:Destroy()
		end)
		
		if f.Init then f:Init() end
		
		for k, v in f.Children do
			if k == "self" then return end
			-- re-run MountChild if needed
			setParentContainer(f, v)
		end
	end,
	
	ObjectRemoved = function(self, f: Component)
		f:SetParent(nil)
		destroyAll(f)
	end
}

local API = {}

-- RBX_INTERNAL_CTOR
service:Class("RBX_INTERNAL_CTOR", function(COM)
	function COM:Render()
		local i = Instance.new(COM.ClassName)
		i.Name = COM.Name
		-- params is a map for properties to add
		for k, v in COM.Params do
			i[k]=v
		end
		
		return i
	end
	
	function COM:GetEventSignal(name)
		return self.Instance[name]
	end
end)

function API.Component(name: string, runFn: (Component) -> ()): ({[string|number]: any}) -> Component
	-- component name = Libray.ComponentName
	-- do not allow RBX as a library name as this is used for an internal constructor
	service:Class(name, runFn)

	return function(params)
		return API.CreateComponent(name, params)
	end
end

function API.CreateComponent(name: string, params: {[string|number]: any}): Component
	-- if starts with RBX, use the instance ctor
	-- the RHS will be a class name
	params = params or {}
	local lib, comName = string.match(name, "^(.+)%.(%w+)$")
	local c
	local children = fastMixedTableSplit(params)
	
	local objName = params.Name
	if not objName then error("Component requires Name key.") end
	
	if lib == "RBX" then
		-- RBX className path
		c = service:CreateObjectFromClass("RBX_INTERNAL_CTOR", {
			ClassName = comName,
			Name = objName,
			Params = params
		})
	else
		-- Component path
		local s
		if params.State then
			s = params.State
			params.State = nil
		end
		
		c = service:CreateObjectFromClass(name, {
			Name = objName,
			Params = params,
			State = s
		})
	end
	
	if children then
		for _, com in children do
			com:SetParent(c)
		end
	end
	
	return c
end

function API.RBX(className: string, params: {[string|number]: any}): Component
	-- same as above but always use RBX path
	return API.CreateComponent(`RBX.{className}`,  params)
end

-- This function is intended for debugging, do not use it in live production
function API:GetComponentFromInstance(instance: Instance): Component?
	return instanceComponentLinks[instance]
end

return API