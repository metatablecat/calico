# Calico

A Component implementation for Roblox that uses CollectionServce tagged instances under other instances to create small
reusable code fragments known as behaviours.

# Features

## Easy-to-use declarative syntax

Each Behaviour is described using a declarative syntax where you tell it how it should react to events, and return
the state you want it to handle.

```luau
return Calico.describe("KillBrick", function(describe)
	describe.InstanceAssertion = function(p) return p:IsA("BasePart") end

	describe:OnInstance("Touched", nil, function(self, SenderParams, otherPart)
		local human = otherPart.Parent and otherPart.Parent:FindFirstChildOfClass("Humanoid")
		if human then
			local damage = self:GetState("Damage")
			human:TakeDamage(if type(damage) ~= "number" or damage < 0 then human.MaxHealth else damage)
		end
	end)

	return {
		Damage = -1
	}
end)
```

## Behaviours as Instances

Each behaviour gets given its own instance that you can drag around your workspace, and it will recreate itself (if it can)
under the new instance you drag it under.

## Behaviours can talk to each other

TODO: Messaging API is not available in initial release, you may see it in the API but it currently calls a "NOT_IMPLEMENTED_EXCEPTION"
thrower.

