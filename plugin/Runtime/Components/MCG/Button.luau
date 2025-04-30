-- ported from DropperButton

local TweenService = game:GetService("TweenService")
local ComponentService = require(script.Parent.Parent.Parent.Parent.Services.ComponentService)
local Panel = require(script.Parent.Parent.Panel)
local Layout = require(script.Parent.Parent.Layout)
local Text = require(script.Parent.Parent.Text)
local tweenInfoCommon = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local MAIN = Color3.fromRGB(255, 106, 0)
--local SECONDARY =Color3.fromRGB(90, 90, 90)

local function darker(c3: Color3, strength: number?): Color3
	local h,s,v = c3:ToHSV()
	return Color3.fromHSV(h, s, v * (strength or 0.5))
end

local function lighter(c3: Color3, strength: number?): Color3
	local h,s,v = c3:ToHSV()
	return Color3.fromHSV(h, s * (strength or 0.5), v)
end

local function Tween(name: string, c: ComponentService.Component, info: TweenInfo, goals: {[string]: any}): Tween
	local i = c.Instance
	local t = TweenService:Create(i, info, goals)
	t.Name = name
	t.Parent = i
	return t
end

type ButtonParams = {
	-- this is prestyled so no modifier keys here
	Name: string,
	AnchorPoint: Vector2?,
	ClipsDescendants: boolean?,
	LayoutOrder: number?,
	Position: UDim2?,

	Enabled: boolean?,
	Mode: "Image"|"Text",
	Content: string,
}

local function btnText(params: ButtonParams)
	return Text {
		Name = "Content",
		AutomaticSize = Enum.AutomaticSize.XY,
		Font = Font.fromId(12187606934, Enum.FontWeight.Bold),
		Text = params.Content,
		TextColor3 = Color3.new(),
		TextSize = 16
	}
end

local function btnImage(params: ButtonParams)
	return ComponentService.RBX("ImageLabel", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(24, 24),
		Image = params.Content,
		ImageColor3 = Color3.new()
	})
end

local function toTargetColor(COM, guiState: Enum.GuiState)
	local tweens: {[string]: Tween} = COM.Tweens
	if guiState == Enum.GuiState.Press then return end
	
	if  COM.State.Enabled and guiState == Enum.GuiState.Hover then
		tweens.Hover:Play()
		tweens.BackgroundHover:Play()
	else
		tweens.Enabled:Play()
		tweens.BackgroundEnabled:Play()
	end
end

return ComponentService.Component("Dropper.Button", function(_, COM)
	COM.State = {
		Enabled = true,
		Pressed = false
	}

	function COM:Init()
		local tweens = {}
		self.Tweens = tweens
		local main = self.Border
		local padding1 = self["$padding"]
		local padding2 = main["$padding"]

		tweens.Enabled = Tween("Enabled", main, tweenInfoCommon, {BackgroundColor3 = darker(MAIN)})
		tweens.BackgroundEnabled = Tween("Enabled", main.Background, tweenInfoCommon, {BackgroundColor3 = MAIN})
		tweens.Hover = Tween("Hover", main, tweenInfoCommon, {BackgroundColor3 = lighter(darker(MAIN))})
		tweens.BackgroundHover = Tween("BackgroundHovern", main.Background, tweenInfoCommon, {BackgroundColor3 = lighter(MAIN)})

		tweens.PaddingPopOut = Tween("PaddingPopOut", padding2, tweenInfoCommon, {PaddingBottom = UDim.new(0,5)})
		tweens.ACPaddingPopOut = Tween("ACPaddingPopOut", padding1, tweenInfoCommon, {PaddingTop = UDim.new(0,0)})
		tweens.PaddingPushIn = Tween("PaddingPushIn", padding2, tweenInfoCommon, {PaddingBottom = UDim.new(0,1)})
		tweens.ACPaddingPushIn = Tween("ACPaddingPushIn", padding1, tweenInfoCommon, {PaddingTop = UDim.new(0,4)})

		main.Trigger.Instance:GetPropertyChangedSignal("GuiState"):Connect(function()
			toTargetColor(self, main.Trigger.Instance.GuiState)
		end)
	end

	function COM:Render(params: ButtonParams)
		local enabled = if params.Enabled ~= nil then params.Enabled else true
		self.State.Enabled = enabled

		return Panel {
			Name = params.Name,
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			ClipsDescendants = params.ClipsDescendants,
			LayoutOrder = params.LayoutOrder,
			
			Layout.Padding(),

			Panel {
				Name = "Border",
				AutomaticSize = Enum.AutomaticSize.XY,
				BackgroundColor = darker(MAIN),

				Layout.Padding(1,1,5,1),
				Layout.Corner(12),

				Panel {
					Name = "Background",
					AutomaticSize = "XY",
					BackgroundColor = MAIN,
					Size = UDim2.fromScale(1, 0),
					
					Layout.Padding(if params.Mode == "Text" then 11 else 7),
					Layout.Corner(10),
					if params.Mode == "Text" then btnText(params) else btnImage(params)
				},

				ComponentService.RBX("ImageButton", {
					Name = "Trigger",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.new(1,1,1,1),
					Image = ""
				})
			}
		}
	end

	function COM:StateChanged(key, val)
		if key == "Enabled" then
			toTargetColor(self, self.Border.Trigger.Instance.GuiState)
		elseif key == "Pressed" then
			if val then
				self.Tweens.PaddingPushIn:Play()
				self.Tweens.ACPaddingPushIn:Play()
			else
				self.Tweens.PaddingPopOut:Play()
				self.Tweens.ACPaddingPopOut:Play()
			end
		end
	end

	function COM:GetEventSignal(eName)
		return self.Border.Trigger.Instance[eName]
	end
end) :: (ButtonParams) -> ComponentService.Component