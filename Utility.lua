-- // Utility Module
local Utility = {}

-- // In Air Function
function Utility.InAir(Humanoid)
	return Humanoid.FloorMaterial == Enum.Material.Air
end

-- // Footstep Function
function Utility.Footstep(Humanoid)
	if not Utility.InAir(Humanoid) then
		local Material = "Concrete"

		if Humanoid.FloorMaterial == Enum.Material.Grass then
			Material = "Grass"
		end

		if Humanoid.FloorMaterial == Enum.Material.Sand then
			Material = "Sand"
		end

		if Humanoid.FloorMaterial == Enum.Material.Wood or Humanoid.FloorMaterial == Enum.Material.WoodPlanks then
			Material = "Wood"
		end

		local Sound = game:GetService("ReplicatedStorage").Footstep_Sounds:FindFirstChild(Material)

		if Sound then
			local Clone = Sound:Clone()
			Clone.Parent = Humanoid.Parent:FindFirstChild("RightFoot")
			Clone.Volume = 0.25
			Clone.PlaybackSpeed = Clone.PlaybackSpeed + math.random(-8, 10) / 100

			Clone:Play()

			Clone.Ended:Connect(function()
				Clone:Destroy()
			end)
		end
	end
end

-- // Return the module
return Utility
