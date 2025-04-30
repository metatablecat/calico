local FragmentFolder = script.Parent.Parent.Runtime

local function loadRecurse(objChildren: {Instance})
	for _, v in objChildren do
		if v:IsA("ModuleScript") then
			require(v)
		else
			loadRecurse(v:GetChildren())
		end
	end
end

loadRecurse(FragmentFolder:GetChildren())