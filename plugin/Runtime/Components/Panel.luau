local ComponentService = require(script.Parent.Parent.Parent.Services.ComponentService)
local ThemeManager = require(script.Parent.Parent.Parent.Modules.ThemeManager)

type PanelParams = {
	Name: string,
	StudioThemeKey: Enum.StudioStyleGuideColor?,
	StudioThemeModifier: Enum.StudioStyleGuideModifier?,

	AnchorPoint: Vector2?,
	AutomaticSize: Enum.AutomaticSize?,
	BackgroundColor: Color3?,
	BackgroundTransparency: number?,
	ClipsDescendants: boolean?,
	LayoutOrder: number?,
	Position: UDim2?,
	Size: UDim2?,
	SizeConstraint: Enum.SizeConstraint?,
	Visible: boolean?
}

return ComponentService.Component("StudioPanel", function(_, COM)
	function COM:Init()
		if self.ColorInfo then
			ThemeManager:SetInstance(
				self.RefComponent.Instance,
				"BackgroundColor3",
				self.ColorInfo.Color,
				self.ColorInfo.Modifier
			)
		end
	end

	function COM:Render(params: PanelParams)
		if params.StudioThemeKey or params.StudioThemeModifier then
			self.ColorInfo = {
				Color = params.StudioThemeKey or Enum.StudioStyleGuideColor.MainBackground,
				Modifier = params.StudioThemeModifier or Enum.StudioStyleGuideModifier.Default
			}
		end

		return ComponentService.RBX("Frame", {
			Name = params.Name,
			AnchorPoint = params.AnchorPoint or Vector2.new(),
			AutomaticSize = params.AutomaticSize or Enum.AutomaticSize.None,
			BackgroundColor3 = params.BackgroundColor or Color3.new(),
			BackgroundTransparency = params.BackgroundTransparency or 0,
			BorderSizePixel = 0,
			ClipsDescendants = if params.ClipsDescendants ~= nil then params.ClipsDescendants else true,
			LayoutOrder = params.LayoutOrder or 0,
			Position = params.Position or UDim2.new(),
			Size = params.Size or UDim2.new(),
			SizeConstraint = params.SizeConstraint or Enum.SizeConstraint.RelativeXY,
			Visible = if params.Visible ~= nil then params.Visible else true
		})
	end
end) :: (PanelParams) -> ComponentService.Component