task.wait(1)

local tool = script.Parent
local player = script:FindFirstAncestorWhichIsA("Player") or game.Players:GetPlayerFromCharacter(script.Parent.Parent)
local myCharacter = player.Character
local myHumanoid = myCharacter:WaitForChild("Humanoid")
local myRoot = myCharacter:WaitForChild("HumanoidRootPart")

local config = require(tool:WaitForChild('Config'))

local tags = game:GetService("CollectionService")

local teammates = {}
local enemies = {}

local function raycast(origin, endPos, ignoreList)
	for _,v in pairs(teammates) do
		table.insert(ignoreList, v)
	end
	for _,v in pairs(enemies) do
		table.insert(ignoreList, v)
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = ignoreList
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist

	local direction = (endPos - origin)
	
	local result = workspace:Raycast(origin, direction, rayParams)
	return result
end

local function refreshEnemiesAndTeammates()
	teammates = {}
	enemies = {}

	for _,v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChild("Humanoid") then
			local team = v.Humanoid:GetAttribute("Team")
			if team == myHumanoid:GetAttribute("Team") then
				table.insert(teammates, v)
			else
				table.insert(enemies, v)
			end
		end
	end
end

local function createMotor6d(p0, p1, c0, c1)
	local motor6d = Instance.new("Motor6D")
	motor6d.Parent = p0
	
	motor6d.C0 = c0
	motor6d.C1 = c1
	
	motor6d.Part0 = p0
	motor6d.Part1 = p1
	motor6d.Name = p1.Name
	
	tags:AddTag(motor6d, "ToolRigJoint")
end

local function onEquip()
	wait(0.05)
	local rigging = config.Rigging
	
	if #rigging > 0 then
		local rightGrip = myCharacter:FindFirstChild("RightGrip", true)

		if rightGrip then
			rightGrip:Destroy()
		end
	end
	
	--[[
	local motor6d = Instance.new('Motor6D')
	motor6d.Parent = myCharacter:FindFirstChild("RightHand")
	motor6d.Part0 = myCharacter:FindFirstChild("RightHand")
	motor6d.Part1 = tool.Handle
	--]]
	
	local whitelistedRigObjects = {}
	
	for _,v in pairs(myCharacter:GetDescendants()) do
		if v:IsA("BasePart") and not v:FindFirstAncestorWhichIsA("Accessory") then
			table.insert(whitelistedRigObjects, v)
		end
	end
	
	for _,v in pairs(rigging) do
		local p0Name = v.Part0
		local p1Name = v.Part1
		
		local p0 = nil
		local p1 = nil
		
		for _,obj in pairs(whitelistedRigObjects) do
			if obj.Name == p0Name then
				p0 = obj
			end
			if obj.Name == p1Name then
				p1 = obj
			end
		end
		
		if p0 and p1 then
			createMotor6d(p0, p1, v.C0, v.C1)
		end
		
		if not p0 then
			warn("Could not find "..p0Name)
		end
		
		if not p1 then
			warn("Could not find "..p1Name)
		end
	end
end

local function onUnequip()
	for _,v in pairs(myCharacter:GetDescendants()) do
		if tags:HasTag(v, "ToolRigJoint") then
			v:Destroy()
		end
	end
end

local function verifyProjectile()
	-- none. sadly.
	
end

local function verifyHitscan(hitPart, humanoid)
	local result = raycast(tool.Handle.FiringPoint.WorldPosition, hitPart.Position, {myCharacter, humanoid.Parent})
	if result == nil then
		return true
	end
	
	return false
end

local function onHit(player, humanoid, hitPart)
	local distanceFromRoot = (hitPart.Position - humanoid.Parent.PrimaryPart.Position).Magnitude
	
	local ricochetTags = config.RichochetTags
	local isDeflectionSurface = false

	for _,v in pairs(ricochetTags) do
		if tags:HasTag(hitPart, v) or tags:HasTag(hitPart.Parent, v) then
			isDeflectionSurface = true
		end
	end
	
	if tool.Parent == myCharacter and isDeflectionSurface == false then
		if distanceFromRoot < 6 then
			if humanoid and 
				(
				humanoid:GetAttribute("Team") ~= myHumanoid:GetAttribute("Team") 
				or config.TeamKillingEnabled == true
				or humanoid:GetAttribute("Team") == nil
				) 

				and humanoid.Health > 0 then
				
				local result = true
				if config.FiringMethod == "Hitscan" then
					result = verifyHitscan(hitPart, humanoid)
				end
				
				if result == true then
					local multipliers = config.DamageMultipliers
					local damage = config.Damage

					if multipliers[hitPart.Name] ~= nil then
						damage = damage * multipliers[hitPart.Name]
					end
					
					humanoid:TakeDamage(damage)
					
					if humanoid.Health <= 0 then
						tool.VerifyHit:FireClient(player, damage)
					end
				end
			end
		end
	end
end

refreshEnemiesAndTeammates()

local childAddedConnection = workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child:FindFirstChild("Humanoid") then
		refreshEnemiesAndTeammates()
	end
end)
local childRemovedConnection = workspace.ChildRemoved:Connect(function(child)
	if child:IsA("Model") and child:FindFirstChild("Humanoid") then
		refreshEnemiesAndTeammates()
	end
end)

tool.VerifyHit.OnServerEvent:Connect(onHit)
tool.Equipped:Connect(onEquip)
tool.Unequipped:Connect(onUnequip)
