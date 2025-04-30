local ComponentService = require(script.Parent.Parent.Parent.Services.ComponentService)
local Layout = require(script.Parent.Layout)
local Panel = require(script.Parent.Panel)

type LayoutContainerParams = {
	-- Padding
	Padding: {
		Top: number|UDim?,
		Left: number|UDim?,
		Bottom: number|UDim?,
		Right: number|UDim?,
		List: number|UDim?,
	}?,

	Name: string,

	-- UIListLayout
	FillDirection: Enum.FillDirection?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,

	-- Panel
	AnchorPoint: Vector2?,
	AutomaticSize: Enum.AutomaticSize?,
	ClipsDescendants: boolean?,
	LayoutOrder: number?,
	Position: UDim2?,
	Size: UDim2?,
	SizeConstraint: Enum.SizeConstraint?,
	Visible: boolean?
}

return ComponentService.Component("LayoutContainer", function(_, COM)
	COM.Items = {}

	function COM:Render(params: LayoutContainerParams)
		local paddingInfo = params.Padding or {}

		return Panel {
			Name = params.Name,
			BackgroundTransparency = 1,

			AnchorPoint = params.AnchorPoint,
			AutomaticSize = params.AutomaticSize,
			ClipsDescendants = params.ClipsDescendants,
			LayoutOrder = params.LayoutOrder,
			Position = params.Position,
			Size = params.Size,
			SizeConstraint = params.SizeConstraint,
			Visible = params.Visible,

			Layout.Padding(paddingInfo.Top, paddingInfo.Left, paddingInfo.Bottom, paddingInfo.Right),
			Layout.List {
				Padding = paddingInfo.List,
				FillDirection = params.FillDirection,
				HorizontalAlignment = params.HorizontalAlignment,
				VerticalAlignment = params.VerticalAlignment
			}
		}
	end
end) :: (LayoutContainerParams) -> ComponentService.Component