-- A TextBox from Dropper
local TweenService = game:GetService("TweenService")
local ComponentService = require(script.Parent.Parent.Parent.Parent.Services.ComponentService)
local ThemeManager = require(script.Parent.Parent.Parent.Parent.Modules.ThemeManager)
local Panel = require(script.Parent.Parent.Panel)
local Layout = require(script.Parent.Parent.Layout)

local tweenInfoCommon = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function Tween(name: string, c: ComponentService.Component, info: TweenInfo, goals: {[string]: any}): Tween
	local i = c.Instance
	local t = TweenService:Create(i, info, goals)
	t.Name = name
	t.Parent = i
	return t
end

type TextBoxParams = {
	-- this is prestyled so no modifier keys here
	Name: string,
	AnchorPoint: Vector2?,
	ClipsDescendants: boolean?,
	LayoutOrder: number?,
	Position: UDim2?,
	Size: UDim2?,
	SizeConstraint: Enum.SizeConstraint?,

	PlaceholderText: string?,
	Text: string?
}

return ComponentService.Component("Dropper.TextBox", function(_, COM)
	COM.State = {
		Text = "",
		Selected = false,
		ResetNextClick = false,
	}

	function COM:Init()
		local textBox = self.Background.InputBox
		self.InputBox = textBox

		local gradient = self["$gradient"]
		
		local tweens = {}
		self.Tweens = tweens
		tweens.SelectedTween = Tween("Selected", gradient, tweenInfoCommon, {Offset = Vector2.new(1, 0)})
		tweens.DeselectedTween = Tween("Deselected", gradient, tweenInfoCommon, {Offset = Vector2.new(-1, 0)})
		
		ThemeManager:SetInstance(
			textBox.Instance,
			"TextColor3",
			Enum.StudioStyleGuideColor.MainText
		)

		ThemeManager:SetInstance(
			textBox.Instance,
			"PlaceholderColor3",
			Enum.StudioStyleGuideColor.MainText
		)

		textBox:Connect("Focused", function(sender)
			self:SetState("Selected", true)

			if self.State.ResetNextClick then
				self:SetState("ResetNextClick", false)
			end
		end)

		textBox:Connect("FocusLost", function(sender)
			self:SetState("Selected", false)
		end)

		textBox.Instance:GetPropertyChangedSignal("Text"):Connect(function()
			self:SetState("Text", textBox.Instance.Text)
		end)
	end

	function COM:Render(params: TextBoxParams)
		self.State.Text = params.Text or ""

		return Panel {
			Name = params.Name,
			AnchorPoint = params.AnchorPoint,
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor = Color3.new(1,1,1),
			ClipsDescendants = params.ClipsDescendants,
			LayoutOrder = params.LayoutOrder,
			Position = params.Position,
			Size = params.Size,
			SizeConstraint = params.SizeConstraint,

			Layout.Gradient {
				Color = {
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 106, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 90, 90))
				},
				Offset = Vector2.new(-1, 0)
			},

			Layout.Padding(1),
			Layout.Corner(12),

			Panel {
				Name = "Background",
				AutomaticSize = Enum.AutomaticSize.Y,
				StudioThemeKey = Enum.StudioStyleGuideColor.MainBackground,
				Size = UDim2.fromScale(1, 0),

				Layout.Padding(10),
				Layout.Corner(12),

				ComponentService.RBX("TextBox", {
					Name = "InputBox",
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					ClearTextOnFocus = false,
					Size = UDim2.fromScale(1, 0),
					FontFace = Font.fromId(12187606934),
					PlaceholderText = params.PlaceholderText or "",
					Text = self.State.Text,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true
				})
			}
		}
	end

	function COM:StateChanged(key, val)
		if key == "Selected" then
			(if val then self.Tweens.SelectedTween else self.Tweens.DeselectedTween):Play()
		elseif key == "Text" then
			local box = self.InputBox.Instance
			if val == box.Text then return end
			box.Text = val
		elseif key == "ResetNextClick" then
			self.InputBox.Instance.ClearTextOnFocus = val
		end
	end

	function COM:GetEventSignal(eName)
		return self.InputBox.Instance[eName]
	end

	function COM:GetPropertyChangedSignal(name)
		return self.InputBox.Instance:GetPropertyChangedSignal(name)
	end
end) :: (TextBoxParams) -> ComponentService.Component