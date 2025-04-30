local ComponentService = require(script.Parent.Parent.Parent.Services.ComponentService)
local Layout = {}

local function toUdim(x: UDim | number): UDim
	if typeof(x) == "number" then
		return UDim.new(0, x)
	else
		return x
	end
end

-- Basic objects (dont need table ctors)
function Layout.AspectRatioConstraint(
	ratio: number,
	dominantAxis: Enum.DominantAxis?,
	aspectType: Enum.AspectType?
): ComponentService.Component
	return ComponentService.RBX("UIAspectRatioConstraint", {
		Name = "$aspectRatio",
		AspectRatio = ratio,
		AspectType = aspectType or Enum.AspectType.FitWithinMaxSize,
		DominantAxis = dominantAxis or Enum.DominantAxis.Width
	})
end

function Layout.SizeConstraint(
	min: Vector2?,
	max: Vector2?
): ComponentService.Component
	return ComponentService.RBX("UISizeConstraint", {
		Name = "$sizeConstraint",
		MinSize = min or Vector2.new(),
		MaxSize = max or Vector2.new(math.huge, math.huge)
	})
end

function Layout.TextSizeConstraint(
	min: number?,
	max: number?
): ComponentService.Component
	return ComponentService.RBX("UITextSizeConstraint", {
		Name = "$textSizeConstraint",
		MinTextSize = min or 1,
		MaxTextSize = max or 100
	})
end

function Layout.Corner(
	radius: number|UDim?
): ComponentService.Component
	return ComponentService.RBX("UICorner", {
		Name = "$corner",
		CornerRadius = toUdim(radius or UDim.new())
	})
end

function Layout.FlexItem(
	flexMode: Enum.UIFlexMode?,
	itemLineAlignment: Enum.ItemLineAlignment?,
	grow: number?,
	shrink: number?
): ComponentService.Component
	-- grow and shrink are only respected when flexMode is custom
	-- show a warning else, but just use the same constructor (roblox ignores it internally)
	
	if flexMode ~= Enum.UIFlexMode.Custom and (grow or shrink) then
		warn("GrowRatio and ShrinkRatio are only respected when FlexMode is Custom")
	end
	
	return ComponentService.RBX("UIFlexItem", {
		Name = "$flexItem",
		FlexMode = flexMode or Enum.UIFlexMode.None,
		GrowRatio = grow or 0,
		ItemLineAlignment = itemLineAlignment or Enum.ItemLineAlignment.Automatic,
		ShrinkRatio = shrink or 0
	})
end

function Layout.Padding(
	top: number|UDim?,
	left: number|UDim?,
	bottom: number|UDim?,
	right: number|UDim?
): ComponentService.Component
	local t = toUdim(top or UDim.new())
	local l = toUdim(left or t)
	local b = toUdim(bottom or t)
	local r = toUdim(right or l)
	
	return ComponentService.RBX("UIPadding", {
		Name = "$padding",
		PaddingTop = t,
		PaddingLeft = l,
		PaddingBottom = b,
		PaddingRight = r
	})
end

function Layout.Scale(
	scale: number?
): ComponentService.Component
	return ComponentService.RBX("UIScale", {
		Name = "$scale",
		Scale = scale or 1
	})
end

local function toSequence(
	x: number
	|Color3
	|{NumberSequenceKeypoint}
	|{ColorSequenceKeypoint}
	|NumberSequence
	|ColorSequence, 
	ctorlib: typeof(NumberSequence)|typeof(ColorSequence)
)
	local t = typeof(x)
	if t == "NumberSequence" or t == "ColorSequence" then return x end
	return ctorlib.new(x)
end

-- The other layout objects need to use tabular constructors because they have a lot of properties
function Layout.Gradient(params: {
	Color: Color3|{ColorSequenceKeypoint}|ColorSequence?,
	Offset: Vector2?,
	Rotation: number?,
	Transparency: number|{NumberSequenceKeypoint}|NumberSequence?
}): ComponentService.Component
	return ComponentService.RBX("UIGradient", {
		Name = "$gradient",
		Color = toSequence(params.Color or Color3.new(1,1,1), ColorSequence),
		Offset = params.Offset or Vector2.new(),
		Rotation = params.Rotation or 0,
		Transparency = toSequence(params.Transparency or 0, NumberSequence)
	})
end

type UILayoutCommon = {
	FillDirection: Enum.FillDirection?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	SortOrder: Enum.SortOrder?,
	VerticalAlignment: Enum.VerticalAlignment?
}

function Layout.Grid(params: UILayoutCommon & {
	CellPadding: UDim2?,
	CellSize: UDim2?,
	FillDirectionMaxCells: number?,
	StartCorner: Enum.StartCorner?,
}): ComponentService.Component
	return ComponentService.RBX("UIGridLayout", {
		Name = "$grid",
		CellPadding = params.CellPadding or UDim2.new(),
		CellSize = params.CellSize or UDim2.new(),
		FillDirectionMaxCells = params.FillDirectionMaxCells or 0,
		StartCorner = params.StartCorner or Enum.StartCorner.TopLeft,
		
		FillDirection = params.FillDirection or Enum.FillDirection.Horizontal,
		HorizontalAlignment = params.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		SortOrder = params.SortOrder or Enum.SortOrder.LayoutOrder,
		VerticalAlignment = params.VerticalAlignment or Enum.VerticalAlignment.Top
	})
end

function Layout.List(params: UILayoutCommon & {
	HorizontalFlex: Enum.UIFlexAlignment?,
	ItemLineAlignment: Enum.ItemLineAlignment?,
	Padding: UDim?,
	VerticalFlex: Enum.UIFlexAlignment?,
	Wraps: boolean?
}): ComponentService.Component
	return ComponentService.RBX("UIListLayout", {
		Name = "$list",
		HorizontalFlex = params.HorizontalFlex or Enum.UIFlexAlignment.None,
		ItemLineAlignment = params.ItemLineAlignment or Enum.ItemLineAlignment.Automatic,
		Padding = toUdim(params.Padding or UDim.new()),
		VerticalFlex = params.VerticalFlex or Enum.UIFlexAlignment.None,
		Wraps = if params.Wraps ~= nil then params.Wraps else false,
		
		FillDirection = params.FillDirection or Enum.FillDirection.Vertical,
		HorizontalAlignment = params.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		SortOrder = params.SortOrder or Enum.SortOrder.LayoutOrder,
		VerticalAlignment = params.VerticalAlignment or Enum.VerticalAlignment.Top
	})
end

function Layout.Page(params: UILayoutCommon & {
	Animated: boolean?,
	Circular: boolean?,
	GamepadInputEnabled: boolean?,
	Padding: UDim?,
	ScrollWheelInputEnabled: boolean,
	TouchInputEnabled: boolean,
	TweenInfo: TweenInfo?
}): ComponentService.Component
	local ti = params.TweenInfo or TweenInfo.new()
	
	return ComponentService.RBX("UIPageLayout", {
		Name = "$page",
		Animated = if params.Animated ~= nil then params.Animated else true,
		Circular = if params.Circular ~= nil then params.Circular else false,
		EasingDirection = ti.EasingDirection,
		Easingstyle = ti.EasingStyle,
		GamepadInputEnabled = if params.GamepadInputEnabled ~= nil then params.GamepadInputEnabled else true,
		Padding = toUdim(params.Padding or UDim.new()),
		ScrollWheelInputEnabled = if params.ScrollWheelInputEnabled ~= nil then params.ScrollWheelInputEnabled else true,
		TouchInputEnabled = if params.TouchInputEnabled ~= nil then params.TouchInputEnabled else true,
		TweenTime = ti.Time,
		
		FillDirection = params.FillDirection or Enum.FillDirection.Horizontal,
		HorizontalAlignment = params.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		SortOrder = params.SortOrder or Enum.SortOrder.LayoutOrder,
		VerticalAlignment = params.VerticalAlignment or Enum.VerticalAlignment.Top
	})
end

function Layout.Table(params: UILayoutCommon & {
	FillEmptySpaceColumns: boolean?,
	FillEmptySpaceRows: boolean?,
	MajorAxis: Enum.TableMajorAxis?,
	Padding: UDim2?,
}): ComponentService.Component
	return ComponentService.RBX("UITableLayout", {
		Name = "$table",
		FillEmptySpaceColumns = if params.FillEmptySpaceColumns ~= nil then params.FillEmptySpaceColumns else false,
		FillEmptySpaceRows = if params.FillEmptySpaceRows ~= nil then params.FillEmptySpaceRows else false,
		MajorAxis = params.MajorAxis or Enum.TableMajorAxis.RowMajor,
		Padding = params.Padding or UDim2.new(),
		
		FillDirection = params.FillDirection or Enum.FillDirection.Horizontal,
		HorizontalAlignment = params.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		SortOrder = params.SortOrder or Enum.SortOrder.LayoutOrder,
		VerticalAlignment = params.VerticalAlignment or Enum.VerticalAlignment.Top
	})
end
	
function Layout.Stroke(params: {
	ApplyStrokeMode: Enum.ApplyStrokeMode?,
	Color: Color3?,
	LineJoinMode: Enum.LineJoinMode?,
	Thickness: number?,
	Transparency: number?
}): ComponentService.Component
	return ComponentService.RBX("UIStroke", {
		Name = "$stroke",
		ApplyStrokeMode = params.ApplyStrokeMode or Enum.ApplyStrokeMode.Contextual,
		Color = params.Color or Color3.new(),
		LineJoinMode = params.LineJoinMode or Enum.LineJoinMode.Round,
		Thickness = params.Thickness or 1,
		Transparency = params.Transparency or 0
	})
end

return Layout