local ComponentService = require(script.Parent.Parent.Parent.Services.ComponentService)
local ThemeManager = require(script.Parent.Parent.Parent.Modules.ThemeManager)

type TextParams = {
	Name: string,
	StudioThemeKey: Enum.StudioStyleGuideColor?,
	StudioThemeModifier: Enum.StudioStyleGuideModifier?,

	Interactable: boolean?, -- converts instance to a TextButton instead.

	AnchorPoint: Vector2?,
	AutomaticSize: Enum.AutomaticSize?,
	ClipsDescendants: boolean?,
	LayoutOrder: number?,
	Position: UDim2?,
	Size: UDim2?,
	SizeConstraint: Enum.SizeConstraint?,

	Text: string?,
	TextColor3: string?,
	Font: Font?,
	RichText: boolean?,
	TextSize: number?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	TextWrapped: boolean?
}

return ComponentService.Component("StudioText", function(_, COM)
	function COM:Init()
		if self.ColorInfo then
			ThemeManager:SetInstance(
				self.RefComponent.Instance,
				"TextColor3",
				self.ColorInfo.Color,
				self.ColorInfo.Modifier
			)
		end
	end

	function COM:Render(params: TextParams)
		if params.StudioThemeKey or params.StudioThemeModifier then
			self.ColorInfo = {
				Color = params.StudioThemeKey or Enum.StudioStyleGuideColor.MainText,
				Modifier = params.StudioThemeModifier or Enum.StudioStyleGuideModifier.Default
			}
		end

		local toMake = if params.Interactable then "TextButton" else "TextLabel"

		return ComponentService.RBX(toMake, {
			Name = params.Name,
			AnchorPoint = params.AnchorPoint or Vector2.new(),
			AutomaticSize = params.AutomaticSize or Enum.AutomaticSize.None,
			BackgroundTransparency = 1,
			ClipsDescendants = if params.ClipsDescendants ~= nil then params.ClipsDescendants else true,
			LayoutOrder = params.LayoutOrder or 0,
			Position = params.Position or UDim2.new(),
			Size = params.Size or UDim2.new(),
			SizeConstraint = params.SizeConstraint or Enum.SizeConstraint.RelativeXY,

			Text = params.Text or "",
			TextColor3 = params.TextColor3 or Color3.new(),
			FontFace = params.Font or Font.fromEnum(Enum.Font.SourceSans),
			RichText = if params.RichText ~= nil then params.RichText else false,
			TextSize = params.TextSize or 14,
			TextXAlignment = params.TextXAlignment or Enum.TextXAlignment.Center,
			TextYAlignment = params.TextYAlignment or Enum.TextYAlignment.Center,
			TextWrapped = if params.TextWrapped ~= nil then params.TextWrapped else false
		})
	end
end) :: (TextParams) -> ComponentService.Component