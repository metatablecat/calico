-- Renders a debug view of the Form tree
-- The tree itself does not appear as a Component since it does not render
-- in the tree
local StudioService = game:GetService("StudioService")
local Catwork = require(script.Parent.Parent.Parent.Catwork)
local Plugin = Catwork.Plugin
local pluginIsLocal = string.sub(Plugin.Name, 1, 5) == "user_"
local ENABLE_DEBUGGER = pluginIsLocal

local builderMono = Font.fromId(16658246179)

export type DebugViewController = {
	Instance: Frame,
	Form: any,
	Open: boolean,
	Toggle: (DebugViewController) -> (),
	Refresh: (DebugViewController) -> (),
	SetParent: (DebugViewController, Instance) -> (),
	ProcessIO: (DebugViewController, InputObject) -> boolean
}

local function drawImage(component)
	-- fetches a StudioService icon from the component's rendered instance
	-- if available, else return the Instance icon
	
	if component.Instance then
		return StudioService:GetClassIcon(component.Instance.ClassName)
	end
	
	return StudioService:GetClassIcon("Instance")
end

local function getComponentTemplateName(component)
	local templateName = component.Template.Name
	if templateName == "RBX_INTERNAL_CTOR" then
		return if component.Instance then component.Instance.ClassName else "Instance"
	end
	
	return templateName
end

local function getComponentName(component)
	return `[{getComponentTemplateName(component)}] {component.Name}`
end

local function debugWindowBackground(formName)
	local debugWindow = Instance.new("Frame")
	debugWindow.Active = true
	debugWindow.BackgroundColor3 = Color3.new()
	debugWindow.BackgroundTransparency = 0.5
	debugWindow.BorderSizePixel = 0
	debugWindow.Name = "FormDebugWindow"
	debugWindow.Size = UDim2.fromScale(1, 1)
	debugWindow.Visible = false
	debugWindow.ZIndex = 2
	
	local topText = Instance.new("TextLabel")
	topText.BackgroundTransparency = 0
	topText.BackgroundColor3 = Color3.new(1,1,1)
	topText.BorderSizePixel = 0
	topText.Name = "DebugText"
	topText.Size = UDim2.new(1,0,0,14)
	topText.FontFace = builderMono
	topText.Text = `Form Debug Window - {formName} [F9 Close] [F10 Print Tree] [^R Refresh]`
	topText.TextColor3 = Color3.new()
	topText.TextSize = 14
	topText.TextXAlignment = "Left"
	
	local canvas = Instance.new("ScrollingFrame")
	canvas.BackgroundTransparency = 1
	canvas.BorderSizePixel = 0
	canvas.Name = "Canvas"
	canvas.Position = UDim2.fromOffset(0, 14)
	canvas.Size = UDim2.new(1,0,1,-14)
	canvas.AutomaticCanvasSize = "XY"
	canvas.ScrollBarThickness = 10
	canvas.BottomImage = "rbxasset://textures/AnimationEditor/image_scrollbar_vertical_bot.png"
	canvas.MidImage = "rbxasset://textures/AnimationEditor/image_scrollbar_vertical_mid.png"
	canvas.TopImage = "rbxasset://textures/AnimationEditor/image_scrollbar_vertical_top.png"
	canvas.CanvasSize = UDim2.new()
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = "LayoutOrder"
	listLayout.Name = "$layout"

	listLayout.Parent = canvas
	canvas.Parent = debugWindow
	topText.Parent = debugWindow
	return debugWindow
end

local function listItem(component, layoutOrder, depth, parent)
	local debugWindow = Instance.new("Frame")
	debugWindow.AutomaticSize = "X"
	debugWindow.BackgroundTransparency = 1
	debugWindow.Name = "Component"
	debugWindow.LayoutOrder = layoutOrder
	debugWindow.Size = UDim2.fromOffset(0,16)
	
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = "LayoutOrder"
	listLayout.Padding = UDim.new(0, 4)
	listLayout.FillDirection = "Horizontal"
	listLayout.VerticalAlignment = "Center"
	listLayout.Name = "$layout"
	
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Name = "ItemImage"
	image.Size = UDim2.fromOffset(16,16)
	
	local imageInfo = drawImage(component)
	image.Image = imageInfo.Image
	image.ImageRectSize = imageInfo.ImageRectSize
	image.ImageRectOffset = imageInfo.ImageRectOffset
	
	local itemText = Instance.new("TextLabel")
	itemText.AutomaticSize = "X"
	itemText.BackgroundTransparency = 1
	itemText.Name = "ItemText"
	itemText.Size = UDim2.new(0,0,0,16)
	itemText.FontFace = builderMono
	itemText.LayoutOrder = 1
	itemText.Text = getComponentName(component)
	itemText.TextColor3 = Color3.new(1,1,1)
	itemText.TextSize = 14
	
	listLayout.Parent = debugWindow
	image.Parent = debugWindow
	itemText.Parent = debugWindow

	if depth > 0 then
		local dividerFrame = Instance.new("Frame")
		-- rendered divider lines before the window
		dividerFrame.AutomaticSize = "X"
		dividerFrame.BackgroundTransparency = 1
		dividerFrame.Name = "DividerPanel"
		dividerFrame.LayoutOrder = layoutOrder
		dividerFrame.Size = UDim2.fromOffset(0,16)
		
		local listLayout = Instance.new("UIListLayout")
		listLayout.SortOrder = "LayoutOrder"
		listLayout.Padding = UDim.new(0,0)
		listLayout.FillDirection = "Horizontal"
		listLayout.VerticalAlignment = "Center"
		listLayout.Name = "$layout"
		
		-- draw lines depth number of times
		for i = 1, depth do
			local dividerBackPanel = Instance.new("Frame")
			dividerBackPanel.BackgroundTransparency = 1
			dividerBackPanel.Size = UDim2.fromOffset(16, 16)
			dividerBackPanel.LayoutOrder = i
			
			local dividerLine = Instance.new("Frame")
			dividerLine.AnchorPoint = Vector2.new(0.5, 0)
			dividerLine.BackgroundTransparency = 0.5
			dividerLine.BackgroundColor3 = Color3.new(1,1,1)
			dividerLine.BorderSizePixel = 0
			dividerLine.Position = UDim2.fromScale(0.5,0)
			dividerLine.Size = UDim2.new(0,1,1,0)
			
			dividerLine.Parent = dividerBackPanel
			dividerBackPanel.Parent = dividerFrame
		end
		debugWindow.LayoutOrder = depth + 1
		
		listLayout.Parent = dividerFrame
		debugWindow.Parent = dividerFrame
		dividerFrame.Parent = parent
	else
		debugWindow.Parent = parent
	end
end

local function generateTreeDigest(components: {any}, useComponentNames: boolean)
	-- generates a depth-first children tree from the component
	-- useComponentNames: use the name to store the nodes instead of the children
	-- stored as [Component]: {}
	local digest = {}
	for _, component in components do
		local childrenDigest = generateTreeDigest(component.Children, useComponentNames)
		digest[if useComponentNames then getComponentName(component) else component] = childrenDigest
	end
	return digest
end

local index = 0
local function drawTreeItem(digestSection, parent, depth)
	-- digest: {[Component]: {[Component]: ...}
		-- where the keys are the parent components and the values are a list of child components
	for component, children in digestSection do
		index += 1
		listItem(component, index, depth, parent)
		if next(children) then
			drawTreeItem(children, parent, depth + 1)
		end
	end
end

local function drawTree(digest, parent)
	for _, v in parent:GetChildren() do
		if v:IsA("Frame") then v:Destroy() end
	end
	
	task.wait()
	index = 0
	drawTreeItem(digest, parent, 0)
end

local function renderDebugger(form): DebugViewController?
	if not ENABLE_DEBUGGER then 	return end
	
	local controller = {}
	controller.Instance = debugWindowBackground(form.ID)
	controller.Form = form
	controller.Open = false
	
	function controller:Toggle()
		self.Open = not self.Open
		
		if self.Open then
			self:Refresh()
		end
		
		self.Instance.Visible = self.Open
	end
	
	function controller:Refresh()
		local treeDigest = generateTreeDigest({self.Form.Widget}, false)
		drawTree(treeDigest, self.Instance.Canvas)
	end
	
	function controller:SetParent(parent)
		self.Instance.Parent = parent
	end
	
	function controller:ProcessIO(io: InputObject): boolean
		-- F9 - toggle
		-- other actions should only trigger if open
		-- Ctrl-R - refresh
		-- F10 - print tree to console
		-- boolean indicates if input should be sunk (ignored by the controller)
		local key = io.KeyCode
		if key == Enum.KeyCode.F9 then
			self:Toggle()
			return false
		end
		
		if not self.Open then return true end
		
		if key == Enum.KeyCode.F10 then
			print(generateTreeDigest({self.Form.Widget}, true))
			return false
		end
		
		if key == Enum.KeyCode.R and io:IsModifierKeyDown(Enum.ModifierKey.Ctrl) then
			self:Refresh()
			return false
		end
		
		return true
	end
	
	return controller
end

return renderDebugger