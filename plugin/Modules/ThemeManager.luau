local STUDIO = settings():GetService("Studio")
local tracked: {[Instance]: {[string]: {c: Enum.StudioStyleGuideColor, m: Enum.StudioStyleGuideModifier}}} = {}
local ACTIVE_THEME: StudioTheme = STUDIO.Theme

local Manager = {}

local function changePropColor(i, propName, state)
	i[propName] = ACTIVE_THEME:GetColor(state.c, state.m)
end

local function doChangeTheme(i: Instance, prop: string?)
	local state = tracked[i]
	if prop then
		-- fast path, just change the single prop
		changePropColor(i, prop, state[prop])
		return
	end

	for prop, colorKey in state do
		changePropColor(i, prop, colorKey)
	end
end

local function cleanup(i: Instance)
	i.Destroying:Connect(function()
		tracked[i] = nil
	end)
end

function Manager:SetInstance(i: Instance, prop: string, color: Enum.StudioStyleGuideColor, modifier: Enum.StudioStyleGuideModifier?)
	local state = tracked[i]
	if not state then
		state = {}
		tracked[i] = state
		cleanup(i)
	end

	local binding = state[prop]
	if not binding then
		binding = {}
		state[prop] = binding
	end

	binding.c = color
	binding.m = modifier or Enum.StudioStyleGuideModifier.Default
	doChangeTheme(i, prop)
end

STUDIO.ThemeChanged:Connect(function()
	ACTIVE_THEME = STUDIO.Theme
	for i in tracked do
		doChangeTheme(i)
	end
end)

return Manager
