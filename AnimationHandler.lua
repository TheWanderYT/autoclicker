-- // AnimationHandler Module
local AnimationHandler = {}

-- // Variables
AnimationHandler.Humanoid = nil
AnimationHandler.Animations = nil
AnimationHandler.LoadedAnimations = {}

-- // Initialize Function
function AnimationHandler:Initialize(humanoid, animations)
	self.Humanoid = humanoid
	self.Animations = animations
	self:LoadAnimations()
end

-- // Load Animations Function
function AnimationHandler:LoadAnimations()
	self.LoadedAnimations = {
		Sprint = self.Humanoid:LoadAnimation(self.Animations.Movement.Sprint),
		Jog = self.Humanoid:LoadAnimation(self.Animations.Movement.Jog)
	}

	self.LoadedAnimations.Sprint:GetMarkerReachedSignal("Footstep"):Connect(function()
		if require(game.ReplicatedStorage.Modules.Utility).InAir(self.Humanoid) then return end
		require(game.ReplicatedStorage.Modules.Utility).Footstep(self.Humanoid)
	end)

	self.LoadedAnimations.Jog:GetMarkerReachedSignal("Footstep"):Connect(function()
		if require(game.ReplicatedStorage.Modules.Utility).InAir(self.Humanoid) then return end
		require(game.ReplicatedStorage.Modules.Utility).Footstep(self.Humanoid)
	end)
end

-- // Stop Sprint Animations Function
function AnimationHandler:StopSprintAnimations()
	self.LoadedAnimations.Sprint:Stop()
	self.LoadedAnimations.Jog:Stop()
end

-- // Return the module
return AnimationHandler
