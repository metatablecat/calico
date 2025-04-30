local TweenService = game:GetService("TweenService")
local ComponentService = require(script.Parent.Parent.Parent.Services.ComponentService)

type CheckboxParams = {
	Name: string,
	AnchorPoint: Vector2?,
	Selected: boolean?,
	LayoutOrder: number?,
	Position: UDim2?,
	Size: UDim2?,
	SizeConstraint: Enum.SizeConstraint?,
}

local tweenInfoCommon = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function Tween(name: string, c: ComponentService.Component, info: TweenInfo, goals: {[string]: any}): Tween
	local i = c.Instance
	local t = TweenService:Create(i, info, goals)
	t.Name = name
	t.Parent = i
	return t
end

local IMG_CHECKBOX_OFF = "rbxasset://textures/DeveloperFramework/checkbox_unchecked_dark.png"
local IMG_CHECKBOX_ON = "rbxasset://textures/DeveloperFramework/checkbox_checked_light.png"

return ComponentService.Component("Checkbox", function(_, COM)
	COM.State = {
		Selected = false
	}

	function COM:Init()
		local tweens = {}
		self.Tweens = tweens
		
		local on = self.On
		tweens.ShowCheckbox = Tween("ShowCheckbox", on, tweenInfoCommon, {ImageTransparency = 0})
		tweens.HideCheckbox = Tween("HideCheckbox", on, tweenInfoCommon, {ImageTransparency = 1})

		self:Connect("Activated", function()
			self:SetState("Selected", not self.State.Selected)
		end)
	end

	function COM:Render(params: CheckboxParams)
		self.State.Selected = if params.Selected ~= nil then params.Selected else false
		
		return ComponentService.RBX("ImageButton", {
			Name = params.Name,
			AnchorPoint = params.AnchorPoint or Vector2.new(),
			BackgroundTransparency = 1,
			LayoutOrder = params.LayoutOrder or 0,
			Position = params.Position or UDim2.new(),
			Size = params.Size or UDim2.new(),
			SizeConstraint = params.SizeConstraint or Enum.SizeConstraint.RelativeXY,

			Image = IMG_CHECKBOX_OFF,

			ComponentService.RBX("ImageLabel", {
				Name = "On",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Image = IMG_CHECKBOX_ON,
				ImageTransparency = if self.State.Selected then 0 else 1
			})
		})
	end

	function COM:StateChanged(_, value)
		local t = if value then self.Tweens.ShowCheckbox else self.Tweens.HideCheckbox
		t:Play()
	end
end) :: (CheckboxParams) -> ComponentService.Component
