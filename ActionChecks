-- // ActionChecks Module
local ActionChecks = {}

-- // Central Check Function
local function CanPerformAction(CharacterData, specificChecks)
	if CharacterData:FindFirstChild("Stun") then
		return false
	end

	if CharacterData:FindFirstChild("Ragdoll") then
		return false
	end

	if CharacterData:FindFirstChild("Unconscious") then
		return false
	end

	for _, check in ipairs(specificChecks or {}) do
		if CharacterData:FindFirstChild(check) then
			return false
		end
	end

	return true
end

-- // Attack Check Function
ActionChecks.AttackCheck = function(CharacterData)
	local specificChecks = {"Action", "Blocking", "Mount", "Mounted"}
	return CanPerformAction(CharacterData, specificChecks)
end

-- // Mode Check Function
ActionChecks.ModeCheck = function(CharacterData)
	local specificChecks = {"Action", "Blocking", "Mount", "Mounted"}
	if CharacterData:FindFirstChild("Stun") and not CharacterData:FindFirstChild('DuraTraining') then
		return false
	end
	return CanPerformAction(CharacterData, specificChecks)
end

-- // Mount Check Function
ActionChecks.MountCheck = function(CharacterData)
	local specificChecks = {"Action", "Blocking", "Mount", "Mounted"}
	return CanPerformAction(CharacterData, specificChecks)
end

-- // Rob Check Function
ActionChecks.RobCheck = function(CharacterData)
	local specificChecks = {"Action", "Blocking", "Mount", "Mounted"}
	return CanPerformAction(CharacterData, specificChecks)
end

-- // Block Check Function
ActionChecks.BlockCheck = function(CharacterData, Tool)
	local specificChecks = {}
	if not CanPerformAction(CharacterData, specificChecks) then
		return false
	end

	if not Tool or (not Tool:FindFirstChild("Style") and not Tool:FindFirstChild("Skill")) then
		return false
	end

	return true
end

-- // Idle Check Function
ActionChecks.IdleCheck = function(CharacterData)
	local specificChecks = {"Mount", "Mounted"}
	return CanPerformAction(CharacterData, specificChecks)
end

-- // Sprint Check Function
ActionChecks.SprintCheck = function(CharacterData)
	local specificChecks = {"Blocking", "Action", "No Sprint", "Mount", "Mounted"}
	return CanPerformAction(CharacterData, specificChecks)
end

-- // Dodge Check Function
ActionChecks.DodgeCheck = function(CharacterData)
	local specificChecks = {"Action", "Mount", "Mounted"}
	return CanPerformAction(CharacterData, specificChecks)
end

-- // Rhythm Check Function
ActionChecks.RhythmCheck = function(CharacterData)
	local specificChecks = {"Blocking", "Mount", "Mounted"}
	return CanPerformAction(CharacterData, specificChecks)
end

-- // Return the module
return ActionChecks
