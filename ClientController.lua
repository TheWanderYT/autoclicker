-- // Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService('StarterGui')
local RunService = game:GetService('RunService')

-- // Player and Character
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Root = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local CharacterData = ReplicatedStorage.AliveData:WaitForChild(Character.Name)

-- // Get the CharacterHandler script (Parent of this script)
local CharacterHandler = script.Parent

-- // Get the Requests folder from CharacterHandler
local CharacterRequests = CharacterHandler:WaitForChild("Requests")

-- // Get the Requests folder from ReplicatedStorage
local ReplicatedRequests = ReplicatedStorage:WaitForChild("Requests")

-- // Modules
local AnimationHandler = require(ReplicatedStorage.Modules.AnimationHandler)
local MovementHandler = require(ReplicatedStorage.Modules.MovementHandler)
local CombatHandler = require(ReplicatedStorage.Modules.CombatHandler)
local Utility = require(ReplicatedStorage.Modules.Utility)

-- // Assets
local Assets = ReplicatedStorage.Assets
local Animations = Assets.Animations

-- // UI
local RhythmUI = Assets.RhythmUI:Clone()

-- // Variables
local ClientController = {}
ClientController.Variables = {
	SprintTick = 0,
	HitKeys = {},
	Dodges = 3,
	RecentDodges = {},
	SprintStart = 0,
	LastStep = 0,
	InAir = false,
	Jog = false,
	Sprint = false,
	LastSprint = 0
}

ClientController.AnimsFolder = {} -- Add AnimsFolder variable
ClientController.LoadedAnimations = {}

-- // Initialize
function ClientController:Initialize()
	-- // Setup UI
	RhythmUI.Parent = Root
	self:SetupRhythmUI(RhythmUI)

	-- // Load Animations
	self.LoadedAnimations = {
		Sprint = Humanoid:LoadAnimation(Animations.Movement.Sprint),
		Jog = Humanoid:LoadAnimation(Animations.Movement.Jog)
	}

	-- // Initialize Modules
	AnimationHandler:Initialize(Humanoid, Animations)
	MovementHandler:Initialize(CharacterData, Root, Humanoid, self.Variables, self.LoadedAnimations) -- Pass LoadedAnimations
	CombatHandler:Initialize(CharacterData, Root, Humanoid, self.Variables, CharacterRequests, ReplicatedRequests)

	-- // Set Humanoid States
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

	-- // Setup Input
	self:SetupInput()

	-- // Loading Screen
	if not Player:GetAttribute("LDS") then
		self:LoadingScreen()
		Player:SetAttribute("LDS", true)
	end

	-- // Set up remote functions
	self:SetupRemotes()

	-- // Setup BodyMover event
	self:SetupBodyMover()

	-- // Jump Cooldown
	self:SetupJumpCooldown()

	-- // Core Call
	self:CoreCall('SetCore', 'ResetButtonCallback', false)

	-- // Get initial animsFolder
	self:GetAnimsFolder()

	-- // Main Loop
	coroutine.wrap(function()
		while true do
			task.wait()
			MovementHandler:Update(self.Variables) -- Pass Variables to Update
			CombatHandler:Update(self.AnimsFolder) -- Pass animsFolder to Update
			self:Update(self.LoadedAnimations) -- Pass LoadedAnimations to Update
		end
	end)()

	-- // Stamina Regeneration
	--self:SetupStaminaRegen() -- Commented out for now, see note below
	-- // FakeH Head Transparency
	self:SetupFakeHTransparency()
end

-- // Setup Rhythm UI
function ClientController:SetupRhythmUI(rhythmUI)
	for i, v in pairs(rhythmUI:GetDescendants()) do
		if v.Name ~= "F" and v:IsA("ImageLabel") then
			v.ImageTransparency = 1
		end
		if v.Name == "Bar" and v:IsA("ImageLabel") then
			v.BackgroundTransparency = 1
		end
	end
end

-- // Loading Screen Function
function ClientController:LoadingScreen()
	local Gui = Assets:WaitForChild("LoadMenu", 1):Clone()
	Gui.Parent = Player.PlayerGui
	Gui.LocalScript.Disabled = false
end

-- // Function to update animations and humanoid
function ClientController:Update(loadedAnimations)
	MovementHandler:UpdateAnimations(loadedAnimations) -- Pass LoadedAnimations
	MovementHandler:UpdateHumanoid(self.Variables) -- Pass Variables
	CombatHandler:UpdateRhythm(CharacterData) -- Pass CharacterData here
	CombatHandler:UpdateIdle(self.AnimsFolder) -- Pass animsFolder

	self.Variables.InAir = Utility.InAir(Humanoid)
end

-- // Input Setup Function
function ClientController:SetupInput()
	UserInputService.InputBegan:Connect(function(Key, Processed)
		if Processed then
			return
		end

		MovementHandler:HandleMovementInputBegan(Key, self.Variables) -- Pass Variables
		CombatHandler:HandleCombatInputBegan(Key)

		if Key.KeyCode == Enum.KeyCode.W or Key.KeyCode == Enum.KeyCode.A or Key.KeyCode == Enum.KeyCode.S or Key.KeyCode == Enum.KeyCode.D then
			table.insert(self.Variables.HitKeys, Key.KeyCode)
		end
	end)

	UserInputService.InputEnded:Connect(function(Key)
		MovementHandler:HandleMovementInputEnded(Key, self.Variables)  -- Pass Variables
		CombatHandler:HandleCombatInputEnded(Key)

		if Key.KeyCode == Enum.KeyCode.W or Key.KeyCode == Enum.KeyCode.A or Key.KeyCode == Enum.KeyCode.S or Key.KeyCode == Enum.KeyCode.D then
			table.remove(self.Variables.HitKeys, table.find(self.Variables.HitKeys, Key.KeyCode))
		end
	end)
end

-- // Setup Remotes
function ClientController:SetupRemotes()
	CharacterRequests.returnAnims.OnClientInvoke = function(properties)
		ClientController.AnimsFolder = properties
		return properties
	end
end

-- // Setup BodyMover
function ClientController:SetupBodyMover()
	ReplicatedRequests.BodyMover.OnClientEvent:Connect(function(Type, Properties)
		if Properties.Delay then
			task.wait(Properties.Delay)
		end

		if Properties.ClearMovers then
			for i,v in pairs(Root:children()) do
				if v:IsA("BodyMover") then
					v:Destroy()
				end
			end
		end

		if Type == "BodyVelocity" then
			local BodyVelocity = Instance.new("BodyVelocity")
			BodyVelocity.MaxForce = Properties.MaxForce
			BodyVelocity.Velocity = Properties.Velocity
			BodyVelocity.Parent = Properties.Parent
			game.Debris:AddItem(BodyVelocity, Properties.Duration)
		end

		if Type == "BodyPosition" then
			local BodyVelocity = Instance.new("BodyPosition")
			BodyVelocity.MaxForce = Properties.MaxForce
			BodyVelocity.Velocity = Properties.Velocity

			BodyVelocity.P = Properties.P or BodyVelocity.P
			BodyVelocity.D = Properties.D or BodyVelocity.D

			BodyVelocity.Parent = Properties.Parent
			game.Debris:AddItem(BodyVelocity, Properties.Duration)
		end

		if Type == "BodyGyro" then
			local BodyVelocity = Instance.new("BodyGyro")
			BodyVelocity.MaxTorque = Properties.MaxTorque
			BodyVelocity.CFrame = Properties.CFrame

			BodyVelocity.P = Properties.P or BodyVelocity.P
			BodyVelocity.D = Properties.D or BodyVelocity.D

			BodyVelocity.Parent = Properties.Parent
			game.Debris:AddItem(BodyVelocity, Properties.Duration)
		end
	end)

	ReplicatedRequests.GetMouse.OnClientInvoke = function()
		local Mouse = Player:GetMouse()

		return {
			Hit = Mouse.Hit
		}
	end
end

-- // Setup Jump Cooldown
function ClientController:SetupJumpCooldown()
	local Cooldown = 2
	local LastJump = time()

	Humanoid.Changed:Connect(function(Prop)
		if Prop == "Jump" and Humanoid.Jump then
			local CurrentTime = time()
			if LastJump + Cooldown > CurrentTime then
				Humanoid.Jump = false
			else
				LastJump = CurrentTime
			end
		end
	end)
end

-- // Core Call Function
local coreCall do
	local MAX_RETRIES = 8

	local StarterGui = game:GetService('StarterGui')
	local RunService = game:GetService('RunService')

	function ClientController:CoreCall(method, ...)
		local result = {}
		for retries = 1, MAX_RETRIES do
			result = {pcall(StarterGui[method], StarterGui, ...)}
			if result[1] then
				break
			end
			RunService.Stepped:Wait()
		end
		return unpack(result)
	end
end

-- // Get Anims Folder Function
function ClientController:GetAnimsFolder()
	local properties = CharacterRequests.returnAnims:InvokeServer()
	ClientController.AnimsFolder = properties
	return properties
end

-- // Setup Stamina Regen
--function ClientController:SetupStaminaRegen()
--	coroutine.wrap(function()
--		local stmGui = Player.PlayerGui.MainGui.Utility.StamBar
--		local function CreateNoStamEffect()
--			stmGui.BGC.Visible = true
--			local Tween = TweenService:Create(stmGui.BGC,TweenInfo.new(1),{BackgroundTransparency = 0.5})
--			Tween:Play()
--
--[[Tween.Completed:Wait()

local Tween = game:GetService("TweenService"):Create(stmGui.BGC,TweenInfo.new(1),{BackgroundTransparency = 1})
Tween:Play()

Tween.Completed:Wait()


stmGui.BGC.Visible = false

end--]]

--coroutine.wrap(function()

--while true do

--while CharacterData.Stamina.Value <= 1 do

--CreateNoStamEffect()

--end

--wait()

--end

--end)()

ClientController:CoreCall('SetCore', 'ResetButtonCallback', false)

-- // Setup FakeH Transparency
function ClientController:SetupFakeHTransparency()
	coroutine.wrap(function()
		while true do
			task.wait(0.1)
			pcall(function()
				if Character:FindFirstChild('FakeH') and Character:FindFirstChild('FakeH'):FindFirstChild("granks") then
					Character.FakeH.granks.Head.Transparency = 1
					if Character:FindFirstChild("granks") and Character:FindFirstChild("granks").fnoid.DisplayDistanceType ~= Enum.HumanoidDisplayDistanceType.None then
						Character:FindFirstChild("granks").fnoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					end
				end
			end)
		end
	end)()
end

-- // Initialize the ClientController
ClientController:Initialize()
