local module = {
	["IdleAnimation"] = "", -- Self explanatory
	["FireAnimation"] = "", -- Self explanatory
	["ReloadAnimation"] = "", -- Self explanatory
	["ReloadFinishAnimation"] = "1", -- If the ReloadMethod is "Individually", this animation will play after finishing the reload. You can set it to nothing if you don't want to play this animation.
	["EquipAnimation"] = "", -- Self explanatory
	
	["FiringMethod"] = "Hitscan", -- Projectile or Hitscan. Hitscan is instant, projectile is a bullet that is simulated
	
	--[[
	PROJECTILE
		Pros:
			- More realistic
			- Cooler
			- More customizable
			
		Cons:
			- Laggier
			- Can't really stop gun exploits due to how projectiles can't be sanity checked
			
	HITSCAN
		Pros:
			- Less laggier
			- Can be sanity checked, preventing wall-bang exploits
			- Instant hits, no need to lead your shots
			
		Cons:
			- Less cooler
			- Not really realistic
			- Can't be customized very well
	
	Choose wisely!
	--]]
	
	["TracerTemplate"] = game.ReplicatedStorage.FX.Tracer, -- If you're using a projectile firing method, you can put a 'bullet' object here. Set it to nil if you don't want a projectile object
	["TracerContainer"] = Instance.new("Folder", workspace), -- Determines where the tracer objects will be placed when fired.
	-- ^^ WARNING: Setting this to the Workspace will make the gun ignore EVERYTHING, so please save yourself the hassle and make a folder
	["ProjectileSpeed"] = 3000, -- How fast the projectile will fire (if you're using it, of course). Calculates in studs per second.
	["ProjectileAcceleration"] = Vector3.new(0,0,0), -- Determines how the projectile accelerates, i.e gravity and wind.
	
	["MagSize"] = 5, -- How much ammo the gun carries before having to reload
	["Firerate"] = 600, -- RPM (rounds per minute)
	["Pellets"] = 9, -- How many 'bullets' will be in one shot
	["BulletSpread"] = 1, -- The gun will randomly choose a number that's within the specified range, then deviate it. Calculated with degrees (i.e, 3 is 3 degrees cone of bullet spread)
	["ReloadSpeed"] = 0.4, -- If the ReloadMethod is set on "Individually", this is how much seconds it will take for the gun to load 1 bullet. If it's on "EntireClip", this will determine how long the reload animation takes.
	["Damage"] = 10, -- Self explanatory
	["DamageMultipliers"] = {
		["Head"] = 2, -- If the part name is called "Head", it'll deal 2x damage
	},
	["VerticalRecoil"] = 1, -- In degrees
	["HorizontalRecoil"] = 0.2, -- In degrees
	-- Just a fair warning, this gun kit's recoil is really hard to control since it doesn't do any recoil recovery things
	
	["ZoomEnabled"] = true, -- Determines if the gun allows the player to zoom in while in first person.
	["PlayerFacesMouse3rdPerson"] = true, -- Determines if the player's character faces the mouse when in 3rd person.
	["DamageIndicationNumber"] = true, -- If enabled, the gun will display the damage you've delt on your HUD.
	["DamageIndicationHitmarker"] = true, -- If enabled, the gun will display a small hitmarker for when you hit a target.
	["DynamicTracerScaling"] = true, -- If enabled, the tracers fired will be stretched to match the last simulated position. Generally makes your tracers look better. Applies to both Projectile and Hitscan methods
	["DynamicTracerScalingSize"] = 2, -- How wide/tall the tracer appears IF the DynamicTracerScaling is enabled. This does NOT determine how stretched the tracer appears
	["TeamKillingEnabled"] = false, -- If enabled, the gun will allow you to shoot your own teammates.
	["IgnoreTeammates"] = true, -- If enabled, bullets will ignore the player's teammates.
	["FireSoundAdjustPitch"] = true, -- If enabled, the sound of firing will be randomly (and slightly) scaled up or down to prevent sounds sounding repetitive. Highly recommended.
	["FirstPersonArms"] = true, -- If enabled, the gun will attempt to replicate what the person might see in first person, with their arms.
	
	["ReloadMethod"] = "Individually", -- EntireClip and Individually. 
	--[[
		"EntireClip" mode will reload the entire magazine at once.
		"Individually" mode will reload the magazine one bullet at a time.
	--]]
	
	["FireSound"] = "5832364132", -- What sound the gun plays when you shoot it
	["ReloadSound"] = "6052570694", -- What sound the gun plays when you reload it
	["ReloadFinishSound"] = "7244962945", -- What sound the gun plays when you finish reloading it, if the gun is on the "Individually" ReloadMethod.
	
	["HitSound"] = "4817809188",
	["KillSound"] = "7293523910",
	
	["FireSoundPitch"] = 1, -- Determines how slow/fast the firing sound sounds
	["FireSoundVolume"] = 0.3, -- Determines how loud or quiet the firing sound is
	["ReloadSoundVolume"] = 0.5, -- Determines how loud or quiet the reload sound is
	["ReloadFinishSoundVolume"] = 0.5, -- Determines how loud the reload finishing sound is. Only plays if the ReloadMethod is set on "Individually".
	
	["RichochetTags"] = { -- Determines what parts with a tag (using CollectionService) will deflect/redirect the bullet
		"DeflectionSurface"
	},
	
	["Rigging"] = { -- What part the gun should rig to
		{
			Part0 = "RightHand",
			Part1 = "Handle",
			
			C0 = CFrame.new(),
			C1 = CFrame.new(),
		},
	}
	
	--[[
	RIGGING EXAMPLE;
	["Rigging"] = {
		{
			-- The tool will try to find a 'Right Arm', then rig it to the 'Handle'
			
			Part0 = "Right Arm",
			Part1 = "Handle",
			
			-- Here's the CFraming part of rigging
			C0 = CFrame.new(),
			C1 = CFrame.new(),
		},
		
		{
			-- You can make more if you want
			
			Part0 = ...
			Part1 = ...
			
			C0 = CFrame.new(),
			C1 = CFrame.new(),
		}
	}
	
	This is completely optional. If you set it to blank, the tool won't rig anything.
	If you're rigging the gun, MAKE SURE EACH PART HAS ITS OWN UNIQUE NAME! Or else the tool will confuse another part of the gun for it.
	--]]
}

return module
