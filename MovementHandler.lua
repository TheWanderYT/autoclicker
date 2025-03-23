-- // MovementHandler Module
local MovementHandler = {}

-- // Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Variables
MovementHandler.CharacterData = nil
MovementHandler.Root = nil
MovementHandler.Humanoid = nil
MovementHandler.Variables = nil
MovementHandler.LoadedAnimations = nil

-- // Initialize Function
function MovementHandler:Initialize(characterData, root, humanoid, variables, loadedAnimations)
	self.CharacterData = characterData
	self.Root = root
	self.Humanoid = humanoid
	self.Variables = variables
	self.LoadedAnimations = loadedAnimations

	-- Initialize SprintTick and LastSprint in MovementHandler
	self.Variables.SprintTick = self.Variables.SprintTick or 0
	self.Variables.LastSprint = self.Variables.LastSprint or 0
end

-- // Update Function
function MovementHandler:Update(Variables) -- Pass Variables as argument
	--self:UpdateAnimations()
	self:UpdateHumanoid(Variables) -- Pass Variables
end

-- // Is Sprinting Function
function MovementHandler:IsSprinting(Variables) -- Pass Variables as argument
	return Variables.Sprint
end

-- // Get Combat Tool Function
function MovementHandler:GetCombatTool()
	for i,v in pairs(game.Players.LocalPlayer.Character:children()) do
		if v:IsA("Tool") and v:FindFirstChild("Style") then
			return v
		end
	end

	for i,v in pairs(game.Players.LocalPlayer.Backpack:children()) do
		if v:IsA("Tool") and v:FindFirstChild("Style") then
			return v
		end
	end

	return nil
end

-- // Sprint Check Function
function MovementHandler:SprintCheck(Variables) -- Pass Variables as argument
	return require(ReplicatedStorage.Modules.ActionChecks).SprintCheck(self.CharacterData)
end

-- // Dodge Check Function
function MovementHandler:DodgeCheck()
	return require(ReplicatedStorage.Modules.ActionChecks).DodgeCheck(self.CharacterData)
end

-- // Sprint Function
function MovementHandler:Sprint(Value, Variables) -- Pass Variables as argument
	Variables.SprintStart = Value and tick() or 0
	Variables.Sprint = Value or false
end

-- // Update Animations Function
function MovementHandler:UpdateAnimations(loadedAnimations)
	if not loadedAnimations then return end

	if self.Variables.WalkAnimation then
		self.Variables.WalkAnimation:AdjustSpeed(self.Humanoid.WalkSpeed / 36)
	end

	if self:IsMoving() and not self.Variables.Sprint and not require(game.ReplicatedStorage.Modules.Utility).InAir(self.Humanoid) and self.Variables.Idle then
		local Animations = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("ClientController").AnimsFolder

		if not self.Variables.WalkAnimation and Animations and Animations.Walk then
			local Animation = self.Humanoid:LoadAnimation(Animations.Walk)
			Animation:Play(0.2)
			Animation:GetMarkerReachedSignal("Footstep"):Connect(function()
				if require(game.ReplicatedStorage.Modules.Utility).InAir(self.Humanoid) or self.Variables.InAir then return end
				self:Footstep()
			end)

			self.Variables.WalkAnimation = Animation
		end
	elseif self.Variables.WalkAnimation then
		self.Variables.WalkAnimation:Stop()
		self.Variables.WalkAnimation = nil
	end

	local SprintAnimation = not self.Variables.Jog and loadedAnimations.Sprint or loadedAnimations.Jog

	if self:IsMoving() and self.Variables.Sprint then
		if not SprintAnimation.IsPlaying then
			self:StopSprintAnimations()
			SprintAnimation:Play(0.2)
		end
	else
		self:StopSprintAnimations()
	end
end

-- // Stop Sprint Animations Function
function MovementHandler:StopSprintAnimations()
	if self.LoadedAnimations then
		self.LoadedAnimations.Sprint:Stop()
		self.LoadedAnimations.Jog:Stop()
	end
end

-- // Update Humanoid Function
function MovementHandler:UpdateHumanoid(Variables) -- Pass Variables as argument
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	self.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

	local BaseSpeed = (1 / (1 + (self.CharacterData.Stats.Fat.Value / 150)))
	local Speed, Jump = 14, 50

	self.Humanoid.PlatformStand = self.CharacterData:FindFirstChild("Ragdoll")
	self.Humanoid.AutoRotate = not self.CharacterData:FindFirstChild("No Rotate") and not self.CharacterData:FindFirstChild("Ragdoll") and not self.CharacterData:FindFirstChild("Mount") and not self.CharacterData:FindFirstChild("Mounted")

	if Variables.Sprint then
		local SpeedBoost = 14 * math.max(1.1, (1 + (self.CharacterData.Stats.RunningSpeed.Value / 1000) - (self.CharacterData.Stats.LowerMuscle.Value / 1250) - (self.CharacterData.Stats.UpperMuscle.Value / 1250)))

		if Variables.Jog then
			SpeedBoost /= 1.5
		end

		Speed += SpeedBoost * math.clamp(((self.CharacterData.Stats.UpperMuscle.Value + self.CharacterData.Stats.LowerMuscle.Value > 300) and tick() or tick() + 0.5) , 0, 1)
		if self.Humanoid.Health / self.Humanoid.MaxHealth <= 0.4 then
			Speed = Speed / 1.4
		end

		if Variables.Jog then
			self:StaminaDrain(1.5)
		else
			self:StaminaDrain(1)
		end
	end

	if self.CharacterData:FindFirstChild("Blocking") then
		Speed = math.max(0, Speed - 6)
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("Slow") then
		Speed = math.max(0, Speed - 6)
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("Heavy Slow") then
		Speed = math.max(0, Speed - 12)
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("Stun") then
		Speed = math.max(0, Speed - 14)
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("No Jump") then
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("Full Stun") then
		Speed = 0
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("Ragdoll") then
		Speed = 0
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("Mount") then
		Speed = 0
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("Mounted") then
		Speed = 0
		Jump = 0
	end

	if self.CharacterData:FindFirstChild("Raging Blow") then
		Speed = 100
		Jump = 0
	end

	self.Humanoid.WalkSpeed = Speed
	self.Humanoid.JumpPower = Jump
end

-- // Handle Movement Input Began Function
function MovementHandler:HandleMovementInputBegan(Key, Variables) -- Pass Variables as argument
	local SprintTick = Variables.SprintTick
	local LastSprint = Variables.LastSprint

	if Key.KeyCode == Enum.KeyCode.W then
		if tick() - SprintTick < 0.2 and tick() - LastSprint >= 0.25 then
			self:Sprint(true, Variables) -- Pass Variables
			Variables.SprintTick = 0
		else
			Variables.SprintTick = tick()
		end
	end

	if Key.KeyCode == Enum.KeyCode.Up then
		if Variables.Sprint then
			Variables.LastSprint = tick()
			Variables.SprintTick = 0
		end
		self:Sprint(false, Variables) -- Pass Variables
	end

	if Key.KeyCode == Enum.KeyCode.Down then
		if Variables.Sprint then
			Variables.LastSprint = tick()
			Variables.SprintTick = 0
		end
		self:Sprint(false, Variables) -- Pass Variables
	end

	if Key.KeyCode == Enum.KeyCode.R and Variables.Sprint then
		Variables.Jog = not Variables.Jog
	end
end

-- // Handle Movement Input Ended Function
function MovementHandler:HandleMovementInputEnded(Key, Variables) -- Pass Variables as argument
	if Key.KeyCode == Enum.KeyCode.W then
		if Variables.Sprint then
			Variables.LastSprint = tick()
			Variables.SprintTick = 0
		end
		self:Sprint(false, Variables) -- Pass Variables
	end
end

-- // Stamina Drain Function
function MovementHandler:StaminaDrain(i)
	if self.cd == true then return end

	if i == nil then
		i = 1
	end

	game.ReplicatedStorage.Requests.DrainRemote:FireServer(i)

	self.cd = true

	task.wait()

	self.cd = false
end

-- // Footstep Function
function MovementHandler:Footstep()
	if not require(game.ReplicatedStorage.Modules.Utility).InAir(self.Humanoid) and not self.Variables.InAir then
		local Material = "Concrete"

		if self.Humanoid.FloorMaterial == Enum.Material.Grass then
			Material = "Grass"
		end

		if self.Humanoid.FloorMaterial == Enum.Material.Sand then
			Material = "Sand"
		end

		if self.Humanoid.FloorMaterial == Enum.Material.Wood or self.Humanoid.FloorMaterial == Enum.Material.WoodPlanks then
			Material = "Wood"
		end

		local Sound = game.ReplicatedStorage.Footstep_Sounds:FindFirstChild(Material)

		if Material == "Sand" then
			Sound.Volume = 0.3
		end

		if Sound then
			local Clone = Sound:Clone()
			Clone.Parent = self.Humanoid.Parent:FindFirstChild("RightFoot")
			Clone.Volume = 0.25
			Clone.PlaybackSpeed = Clone.PlaybackSpeed + math.random(-8, 10) / 100

			if self.Variables.Sprint then
				Clone.PlaybackSpeed = Clone.PlaybackSpeed * 1.6
			end

			Clone:Play()

			Clone.Ended:connect(function()
				Clone:Destroy()
			end)
		end
	end
end

-- // Is Moving Function
function MovementHandler:IsMoving()
	return (self.Root.Velocity * Vector3.new(1, 0, 1)).Magnitude > 1
end

-- // Return the module
return MovementHandler
