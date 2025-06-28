task.wait(1)

local tool = script.Parent
local config = require(tool:WaitForChild('Config'))

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

while character.Parent == nil do
	character.AncestryChanged:Wait()
end

local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local function createAnimation(id)
	local animObject = Instance.new("Animation")
	animObject.AnimationId = 'rbxassetid://'..id
	local animator = humanoid:FindFirstChildOfClass("Animator") or humanoid
	return animator:LoadAnimation(animObject)
end

local function createSound(id, volume)
	local sound = Instance.new("Sound")
	sound.Parent = tool:FindFirstChild("Handle") or tool
	sound.SoundId = 'rbxassetid://'..id
	sound.RollOffMaxDistance = 300
	sound.RollOffMinDistance = 10
	sound.Volume = volume
	sound.RollOffMode = Enum.RollOffMode.Linear
	
	return sound
end

local runService = game:GetService("RunService")
local tags = game:GetService("CollectionService")
local userInputService = game:GetService("UserInputService")
local contextActionService = game:GetService("ContextActionService")

local spring = require(game.ReplicatedStorage.Modules.spring)
local fastCast = require(game.ReplicatedStorage.Modules.FastCastRedux)
local caster = fastCast.new()
local cameraRecoil = spring.create()

local teammates = {}
local enemies = {}

local bulletParams = RaycastParams.new()
bulletParams.FilterDescendantsInstances = {character, config.TracerContainer}
bulletParams.FilterType = Enum.RaycastFilterType.Blacklist

if config.IgnoreTeammates == true then
	bulletParams.FilterDescendantsInstances = {character, config.TracerContainer, teammates}
end

local bulletSpeed = config.ProjectileSpeed

local behavior = fastCast.newBehavior()
behavior.RaycastParams = bulletParams
behavior.CosmeticBulletTemplate = config.TracerTemplate
behavior.CosmeticBulletContainer = config.TracerContainer
behavior.Acceleration = config.ProjectileAcceleration or Vector3.new()
behavior.MaxDistance = 3000

local firingPoint = nil

if not tool:FindFirstChild("FiringPoint", true) then
	-- cannot find a firing point so let's make one
	firingPoint = Instance.new("Attachment")
	firingPoint.Parent = tool:FindFirstChildOfClass("BasePart")
	firingPoint.Name = "FiringPoint"
else
	firingPoint = tool:FindFirstChild("FiringPoint", true)
end

local RNG = Random.new()
local TAU = math.pi * 2

local idleAnimation = createAnimation(config.IdleAnimation)
local fireAnimation = createAnimation(config.FireAnimation)
local reloadFinishAnimation = createAnimation(config.ReloadFinishAnimation)
local reloadAnimation = createAnimation(config.ReloadAnimation)

local fireSound = createSound(config.FireSound, config.FireSoundVolume)
local reloadSound = createSound(config.ReloadSound, config.ReloadSoundVolume)
local reloadFinishSound = createSound(config.ReloadFinishSound, config.ReloadFinishSoundVolume)

local gui = nil
local toolEquipped = false

local lastFired = 0
local mouseDown = false

local reloading = false

local ammo = config.MagSize
local magSize = config.MagSize

local function refreshGui()
	if gui then
		gui.ChargesLeft.Text = ammo
		if ammo <= 0 then
			gui.ChargesLeft.BackgroundColor3 = Color3.fromRGB(255,0,0)
		else
			gui.ChargesLeft.BackgroundColor3 = Color3.fromRGB(0,0,0)
		end
	end
end

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

local function isInFirstPerson()
	local dist = (camera.CFrame.Position - character:WaitForChild("Head").Position).Magnitude
	if dist < 1 then
		return true
	else
		return false
	end
end

local function scopeIn()
	if gui and isInFirstPerson() and toolEquipped then
		if config.ZoomEnabled then
			userInputService.MouseDeltaSensitivity = 0.3
			camera.FieldOfView = 30
		end
		
		if config.AimDownSights then
			tool.FirstPersonArms:SetAttribute("Aiming", true)
		end
	end
end

local function scopeOut()
	if gui then
		if config.ZoomEnabled then
			userInputService.MouseDeltaSensitivity = 1
			camera.FieldOfView = 70
		end
		
		if config.AimDownSights then
			tool.FirstPersonArms:SetAttribute("Aiming", false)
		end
	end
end

local function performChecksForFiring()
	if humanoid.Health <= 0 then
		return
	end

	if raycast(root.Position, tool.Handle.FiringPoint.WorldPosition, {character, tool}) ~= nil then
		return
	end
	
	if ammo <= 0 then
		return
	end
	
	if reloading then
		return
	end
	
	return true
end

local function refreshEnemiesAndTeammates()
	teammates = {}
	enemies = {}

	for _,v in pairs(workspace:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChild("Humanoid") then
			local team = v.Humanoid:GetAttribute("Team")
			if team == humanoid:GetAttribute("Team") then
				table.insert(teammates, v)
			else
				table.insert(enemies, v)
			end
		end
	end
end

local function ricochet(hitPosition, hitNormal, originalNormal)
	local reflectedNormal = originalNormal - (2 * originalNormal:Dot(hitNormal) * hitNormal)

	local direction = ((hitPosition + reflectedNormal) - hitPosition)

	local attachment = Instance.new("Attachment")
	attachment.Parent = workspace.Terrain
	attachment.WorldPosition = hitPosition
	attachment.Name = "FXattach"

	local sparks = game.ReplicatedStorage.FX.Sparks:Clone()
	sparks.Parent = attachment
	sparks.Enabled = false
	sparks:Emit(20)

	local sound = game.ReplicatedStorage.FX.Ricochet:Clone()
	sound.Parent = attachment
	sound.PlaybackSpeed = math.random(90, 110)/100
	sound:Play()

	game.Debris:AddItem(attachment, 2)
	delay(2, function()
		if attachment and attachment.Parent ~= nil then
			attachment:Destroy()
		end
	end)
	
	if config.FiringMethod == "Projectile" then
		caster:Fire(hitPosition, direction, bulletSpeed/2, behavior)
		game.ReplicatedStorage.Remotes.Replication.ReplicateBullet:FireServer(hitPosition, direction, bulletSpeed, behavior, config.TracerTemplate, "Projectile")
	elseif config.FiringMethod == "Hitscan" then
		hitscanFire(hitPosition, direction)
		game.ReplicatedStorage.Remotes.Replication.ReplicateBullet:FireServer(hitPosition, direction, bulletSpeed, behavior, config.TracerTemplate, "Hitscan")
	end
end

local function hit(hitPart, hitPosition, hitNormal)
	local enemyHumanoid = hitPart.Parent:FindFirstChild("Humanoid")

	if enemyHumanoid and 
		(
			enemyHumanoid:GetAttribute("Team") ~= humanoid:GetAttribute("Team") 
				or config.TeamKillingEnabled == true
				or enemyHumanoid:GetAttribute("Team") == nil
		) 

			and enemyHumanoid.Health > 0 then	
		
		local multipliers = config.DamageMultipliers
		local displayDamage = config.Damage
		
		if multipliers[hitPart.Name] ~= nil then
			displayDamage = displayDamage * multipliers[hitPart.Name]
		end
		
		tool.VerifyHit:FireServer(enemyHumanoid, hitPart)
		_G.IndicateDamage(displayDamage, false, config.HitSound, config.KillSound, config.DamageIndicationNumber, config.DamageIndicationHitmarker)
	end
end

function hitscanFire(origin, direction)
	local ray = workspace:Raycast(origin, direction.Unit * 1000, bulletParams)
	local endPos = origin + (direction.Unit * 300)
	
	local ricochetTags = config.RichochetTags
	if ray then
		local isDeflectionSurface = false

		for _,v in pairs(ricochetTags) do
			if tags:HasTag(ray.Instance, v) or tags:HasTag(ray.Instance.Parent, v) then
				isDeflectionSurface = true
			end
		end

		if isDeflectionSurface then
			ricochet(ray.Position, ray.Normal, direction)
		else
			hit(ray.Instance, ray.Position, ray.Normal)
		end
		
		endPos = ray.Position
	end
	
	if config.DynamicTracerScaling then
		local distance = (origin - endPos).Magnitude
		local half = (origin - endPos)/2
		
		local tracer = config.TracerTemplate:Clone()
		tracer.Parent = config.TracerContainer
		tracer.CanCollide = false
		tracer.CanQuery = false
		tracer.Size = Vector3.new(config.DynamicTracerScalingSize, config.DynamicTracerScalingSize, distance)
		tracer.CFrame = CFrame.lookAt(origin, endPos) * CFrame.new(0, 0, -distance/2)
		
		local ti = TweenInfo.new(distance / config.ProjectileSpeed, Enum.EasingStyle.Linear)
		local tween = game:GetService("TweenService"):Create(tracer, ti, {Size = Vector3.new(config.DynamicTracerScalingSize, config.DynamicTracerScalingSize, 0), Position = endPos})
		tween:Play(); tween:Destroy()
		
		game.Debris:AddItem(tracer, ti.Time)
	end
end

local function activated()
	mouseDown = true
end
local function deactivated()
	mouseDown = false
end

local function reload()
	if not reloading and ammo < magSize and toolEquipped then
		reloading = true
		if config.ReloadMethod == "EntireClip" then
			reloadSound:Play()
			game.ReplicatedStorage.Remotes.Replication.ReplicateSound:FireServer(reloadSound.SoundId)

			reloadAnimation:Play()
			wait(config.ReloadSpeed or 3)
			reloading = false

			ammo = magSize
		elseif config.ReloadMethod == "Individually" then
			local toReload = magSize - ammo
			local done = 0

			repeat
				reloadAnimation:Play()

				local clone = reloadSound:Clone()
				clone.Parent = firingPoint or tool:FindFirstChildOfClass("BasePart")
				clone.Name = "SoundClone"
				clone:Play()

				game.Debris:AddItem(clone, clone.TimeLength)

				wait(config.ReloadSpeed or 0.5)
				done = done + 1
			until done >= toReload

			if config.ReloadFinishAnimation ~= "" then
				reloadFinishAnimation:Play()
				reloadFinishSound:Play()

				wait(0.5)
			end

			reloading = false
			ammo = magSize
		end

		refreshGui()
	end
end

local function fire()
	if performChecksForFiring() == nil then return end
	
	cameraRecoil:shove(Vector3.new(config.VerticalRecoil, config.HorizontalRecoil, 0))
	
	local origin = firingPoint.WorldPosition
	local direction = (mouse.Hit.p - origin)

	if userInputService.TouchEnabled then
		local viewportPos = camera.ViewportSize/2
		local unitRay = camera:ViewportPointToRay(viewportPos.x, viewportPos.y, 0)
		direction = unitRay.Direction
	end
	for i = 1, config.Pellets, 1 do
		local spread = config.BulletSpread

		local directionalCF = CFrame.new(Vector3.new(), direction)			
		local direction = (directionalCF * CFrame.fromOrientation(0, 0, RNG:NextNumber(0, TAU)) * CFrame.fromOrientation(math.rad(RNG:NextNumber(-spread, spread)), math.rad(RNG:NextNumber(-spread, spread)), math.rad(RNG:NextNumber(-spread, spread)))).LookVector

		if config.FiringMethod == "Projectile" then
			caster:Fire(origin, direction, bulletSpeed, behavior)
			game.ReplicatedStorage.Remotes.Replication.ReplicateBullet:FireServer(origin, direction, bulletSpeed, behavior, config.TracerTemplate, "Projectile")
		elseif config.FiringMethod == "Hitscan" then
			hitscanFire(origin, direction)

			if config.DynamicTracerScaling then
				game.ReplicatedStorage.Remotes.Replication.ReplicateBullet:FireServer(origin, direction, bulletSpeed, behavior, config.TracerTemplate, "Hitscan")
			end
		end
	end
	local randomized = 1

	if config.FireSoundAdjustPitch then
		local base = config.FireSoundPitch * 100
		randomized = math.random(base-10,base+10)/100
	end

	local soundClone = fireSound:Clone()
	soundClone.Parent = firingPoint
	soundClone.Name = "SoundClone"
	soundClone.PlaybackSpeed = randomized
	soundClone:Play()

	game.ReplicatedStorage.Remotes.Replication.ReplicateSound:FireServer(soundClone.SoundId, randomized)
	game.Debris:AddItem(soundClone, soundClone.TimeLength)

	fireAnimation:Play()

	ammo = ammo - 1
	refreshGui()
end

local function rayHit(cast, result, segmentVelocity, bullet)
	local hitPart = result.Instance
	local hitPosition = result.Position
	local hitNormal = result.Normal
	
	local isDeflectionSurface = false
	local ricochetTags = config.RichochetTags
	
	for _,v in pairs(ricochetTags) do
		if tags:HasTag(hitPart, v) or tags:HasTag(hitPart.Parent, v) then
			isDeflectionSurface = true
		end
	end

	if isDeflectionSurface then
		ricochet(hitPosition, hitNormal, segmentVelocity.Unit)
	else
		hit(hitPart, hitPosition, hitNormal)
	end
end

local function lengthChanged(cast, lastPoint, rayDir, displacement, segmentVelocity, bullet)
	if bullet then
		local currentPoint = lastPoint + (rayDir * displacement)
		
		local start = lastPoint + (rayDir * displacement/2)
		local endPos = currentPoint
		
		bullet.CFrame = CFrame.lookAt(start, endPos)
		
		if config.DynamicTracerScaling then
			local distance = (currentPoint - lastPoint).Magnitude
			bullet.Size = Vector3.new(config.DynamicTracerScalingSize, config.DynamicTracerScalingSize, distance)
		end
	end
end

local function castTerminating(cast)
	if cast.RayInfo.CosmeticBulletObject then
		cast.RayInfo.CosmeticBulletObject:Destroy()
	end
end

local function keyPress(input)
	if input.KeyCode == Enum.KeyCode.R then
		reload()
	end
end

local function heartbeat()
	if mouseDown and not reloading and ammo > 0 then
		local now = tick()
		
		if now - lastFired > 60/config.Firerate then
			fire()
			lastFired = now
		end
	elseif ammo <= 0 then
		reload()
	end
end

local function renderStepped(dt)
	if gui and not userInputService.TouchEnabled then
		if gui:FindFirstChild("Mouse") then
			gui.Mouse.Position = UDim2.new(0, mouse.X, 0, mouse.Y)
		end
	end
	
	if toolEquipped then
		if config.PlayerFacesMouse3rdPerson and not userInputService.TouchEnabled then
			local pos = mouse.Hit.p
			local lookToPosVector = Vector3.new(pos.X, root.Position.Y, pos.Z)

			root.CFrame = CFrame.lookAt(root.Position, lookToPosVector)
		end
		
		if config.VerticalRecoil > 0 or config.HorizontalRecoil > 0 then
			local recoilUpdated = cameraRecoil:update(dt)
			local x,y,z = recoilUpdated.X, recoilUpdated.Y, recoilUpdated.Z

			camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))
		end
	end
end

local function killEvent(damage)
	_G.IndicateDamage(damage, true, config.HitSound, config.KillSound, config.DamageIndicationNumber, config.DamageIndicationHitmarker)
end

local function mobileContextButtons(actionName, inputState, inputObject)
	if actionName == "Fire" then
		if inputState == Enum.UserInputState.Begin then
			activated()
		elseif inputState == Enum.UserInputState.End then
			deactivated()
		end
	elseif actionName == "Zoom" then
		if inputState == Enum.UserInputState.Begin then
			scopeIn()
		elseif inputState == Enum.UserInputState.End then
			scopeOut()
		end
	elseif actionName == "Reload" then
		reload()
	end
end

local function setUpMobileButtons()
	if userInputService.TouchEnabled then
		contextActionService:BindAction("Fire", mobileContextButtons, true)
		contextActionService:BindAction("Reload", mobileContextButtons, true)
		if config.ZoomEnabled then
			contextActionService:BindAction("Zoom", mobileContextButtons, true)
		end
		
		contextActionService:SetImage("Fire", 'rbxassetid://8961981049')
		contextActionService:SetPosition("Fire", UDim2.new(1,-70, 0, 10))
		contextActionService:GetButton("Fire").Size = UDim2.new(0,70,0,70)
		
		contextActionService:SetImage("Reload", 'rbxassetid://8908047394')
		contextActionService:SetPosition("Reload", UDim2.new(1,-110,0,-40))
		
		if config.ZoomEnabled then
			contextActionService:SetImage("Zoom", 'rbxassetid://8908047094')
			contextActionService:SetPosition("Zoom", UDim2.new(1,-70,0,-90))
		end
	end
end

local function destroyMobileButtons()
	contextActionService:UnbindAction("Fire")
	contextActionService:UnbindAction("Reload")
	contextActionService:UnbindAction("Zoom")
end

local function equipped()
	toolEquipped = true
	
	setUpMobileButtons()
	
	idleAnimation:Play(0)

	userInputService.MouseIconEnabled = false

	gui = script.GUI:Clone()
	gui.Parent = player:WaitForChild("PlayerGui")
	
	if userInputService.TouchEnabled then
		gui.IgnoreGuiInset = true
	else
		gui.IgnoreGuiInset = false
	end

	refreshGui()
end

local function unequipped()
	mouseDown = false
	toolEquipped = false
	
	destroyMobileButtons()
	
	idleAnimation:Stop()

	userInputService.MouseIconEnabled = true
	
	scopeOut()

	if gui then
		gui:Destroy()
		gui = nil
	end
end

unequipped()
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

mouse.Button2Down:Connect(scopeIn)
mouse.Button2Up:Connect(scopeOut)

tool.VerifyHit.OnClientEvent:Connect(killEvent)

caster.LengthChanged:Connect(lengthChanged)
caster.CastTerminating:Connect(castTerminating)
caster.RayHit:Connect(rayHit)

userInputService.InputBegan:Connect(keyPress)

runService.RenderStepped:Connect(renderStepped)
runService.Heartbeat:Connect(heartbeat)
humanoid.Died:Connect(unequipped)
tool.Equipped:Connect(equipped)
tool.Unequipped:Connect(unequipped)

tool.Activated:Connect(activated)
tool.Deactivated:Connect(deactivated)

if userInputService.TouchEnabled then
	script.GUI.IgnoreGuiInset = true
else
	script.GUI.IgnoreGuiInset = false
end
