local Catwork = require(script.Parent.Parent.Catwork)
local ComponentService = require(script.Parent.ComponentService)
local DebugView = require(script.FormDebugView)

local DockWidgetTemplate = ComponentService.Component("TabbyForms.DockWidget", function(_, com)
	function com:Init()
		-- renders an input sink frame
		local inputSink = ComponentService.RBX("Frame", {
			Name = "InputSink",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1)
		})
		
		inputSink:SetParent(self)
		self.ChildMount = inputSink
	end

	function com:Render(params)
		local guiInfo = params.GuiInfo
		local ID = params.ID
		params.GuiInfo, params.ID = nil, nil

		local widget = Catwork.Plugin:CreateDockWidgetPluginGui(ID, guiInfo)

		-- sensible defaults
		widget.ZIndexBehavior = "Sibling"
		widget.Name = ID

--[[
		for k, v in ipairs(params) do
			widget[k]=v
		end
]]--

		return widget
	end
end)

type FormInternal<OpenA..., OpenR..., CloseA..., CloseR...> = Catwork.Fragment<{
	Design: {[string|number]: any},
	Widget: ComponentService.Component,
	Open: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>, OpenA...) -> OpenR...,
	Close: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>, CloseA...) -> CloseR...,
	Toggle: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>) -> (),
	Opening: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>, OpenA...) -> OpenR...,
	Closing: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>, CloseA...) -> CloseR...,
	Enabled: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>) -> (),
	Disabled: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>) -> (),
	Focused: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>) -> (),
	FocusLost: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>) -> (),
	InputBegan: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>, io: InputObject) -> (),
	InputChanged: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>, io: InputObject) -> (),
	InputEnded: (FormInternal<OpenA..., OpenR..., CloseA..., CloseR...>, io: InputObject) -> (),
	DebugView: DebugView.DebugViewController?
}>

type FormConstructorParams<B..., C..., D..., E...> = {
	Design: {[string|number]: any},
	Opening: ((FormInternal<B..., C..., D..., E...>, B...) -> C...)?,
	Closing: ((FormInternal<B..., C..., D..., E...>, D...) -> E...)?,
	Enabled: (FormInternal<B..., C..., D..., E...>) -> ()?,
	Disabled: (FormInternal<B..., C..., D..., E...>) -> ()?,
	Focused: (FormInternal<B..., C..., D..., E...>) -> ()?,
	FocusLost: (FormInternal<B..., C..., D..., E...>) -> ()?,
	InputBegan: (FormInternal<B..., C..., D..., E...>, io: InputObject) -> ()?,
	InputChanged: (FormInternal<B..., C..., D..., E...>, io: InputObject) -> ()?,
	InputEnded: (FormInternal<B..., C..., D..., E...>, io: InputObject) -> ()?,
}

export type Form = FormInternal<(...any), (...any), (...any), (...any)>

local function tryFire(o, name, ...)
	local f = o[name]
	if f then return f(o, ...) end
end

local function lifecycles(form, dockwidget: DockWidgetPluginGui, sink: Frame)
	dockwidget:GetPropertyChangedSignal("Enabled"):Connect(function()
		local e = dockwidget.Enabled
		tryFire(form, if e then "Enabled" else "Disabled")
	end)
	
	dockwidget.WindowFocused:Connect(function()
		tryFire(form, "Focused")
	end)
	
	dockwidget.WindowFocusReleased:Connect(function()
		tryFire(form, "FocusLost")
	end)
	
	sink.InputBegan:Connect(function(io)
		tryFire(form, "InputBegan", io)
	end)
	
	sink.InputChanged:Connect(function(io)
		tryFire(form, "InputChanged", io)
	end)
	
	sink.InputEnded:Connect(function(io)
		-- F9 -> Toggle Debug view if defined
		-- Ctrl + R -> Refresh Debug view if defined
		local keycode = io.KeyCode
		local dbgView: DebugView.DebugViewController = form.DebugView
		if dbgView then
			if not dbgView:ProcessIO(io) then return end
		end
		
		tryFire(form, "InputEnded", io)
	end)
end

local TabbyForms = Catwork.Service {
	-- requires static fragments
	Name = "TabbyForms",
	
	Fragment = function(self, params)
		if not params.ID then
			error("Fragment must use static IDs")
		end
		
		local d = params.Design
		if not d or type(d) ~= "table" then
			error("Don't know what to render, provide Design as a table.")
		end
		
		d.ID = params.ID
		d.Name = d.Name or params.ID
		d.Title = d.Title or d.Name or params.ID
		
		function params:Open(...)
			self:Await()
			local o = self.Opening
			if o then return o(self, ...) end
			self.Widget.Instance.Enabled = true
		end
		
		function params:Close(...)
			self:Await()
			local c = self.Closing
			if c then return c(self, ...) end
			self.Widget.Instance.Enabled = false
		end
		
		function params:Toggle()
			self:Await()
			-- does not fire Open or Close
			local i = self.Widget.Instance
			i.Enabled = not i.Enabled
		end

		return Catwork:CreateFragmentForService(params, self)
	end,
	
	FragmentAdded = function(self, form: Form)
		local widget = DockWidgetTemplate(form.Design)
		widget:Await()
		local dbgView = DebugView(form)
		local widgetInstance: DockWidgetPluginGui = widget.Instance
		form.Widget = widget
		
		if dbgView then
			form.DebugView = dbgView
			dbgView:SetParent(widgetInstance)
		end
		
		lifecycles(form, widgetInstance, widget.InputSink.Instance)
		
		form:Spawn()
	end,
}

return function<A..., B..., C..., D...>(formParams: FormConstructorParams<A..., B..., C..., D...>): FormInternal<A..., B..., C..., D...>
	return TabbyForms:Fragment(formParams)
end