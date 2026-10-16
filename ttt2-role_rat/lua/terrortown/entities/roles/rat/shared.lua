if SERVER then
	AddCSLuaFile()

	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_rat.vmt")

	util.AddNetworkString("TTT2_Rat_InstantExpose")
	
	-- server only convars
	CreateConVar("ttt2_rat_instant_expose", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Should the rat be exposed on spawn?", 0, 1)
end

-- shared convars
CreateConVar("ttt2_rat_traitor_reveal_timer", 120, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds to reveal traitors to the rat", 10, 600)

function ROLE:PreInitialize()
	self.color = Color(80, 173, 59, 255)

	self.abbr = "rat"

	self.defaultTeam = TEAM_INNOCENT

	self.scoreKillsMultiplier = 2
	self.scoreTeamKillsMultiplier = -8
	self.surviveBonus = 0
	self.unknownTeam = true

	self.conVarData = {
		pct = 0.1,
		maximum = 1,
		minPlayers = 6,
		credits = 0,
		togglable = true,
		random = 25,
		traitorButton = 0,
		shopFallback = SHOP_DISABLED
	}
end

function ROLE:Initialize()
	roles.SetBaseRole(self, ROLE_INNOCENT)
end

if SERVER then
	-- expose rat on spawn depending on convar
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		-- skip if convar is disabled
		if not GetConVar("ttt2_rat_instant_expose"):GetBool() then return end
		
		-- early returns
		if not IsValid(ply) then return end
		if ply:GetSubRole() ~= ROLE_RAT then return end
		
		-- give traitors marker vision on him
		local mvObject = ply:AddMarkerVision("ttt2_rat_player")
		mvObject:SetOwner(ROLE_TRAITOR)
		mvObject:SetVisibleFor(VISIBLE_FOR_ROLE)
		mvObject:SyncToClients()
		
		-- network to the rat player he is insta exposed
		net.Start("TTT2_Rat_InstantExpose")
		net.Send(ply)
		
		-- start a timer for the rat
		STATUS:AddTimedStatus(ply, "ttt2_rat_expose_timer", GetConVar("ttt2_rat_traitor_reveal_timer"):GetInt(), true)
		timer.Create("ttt2_rat_clock_timer", GetConVar("ttt2_rat_traitor_reveal_timer"):GetInt(), 1, function()
			-- call our custom function to out the traitors
			exposeTraitorToRat()
			--displaying the proper message
			EPOP:AddMessage(ply, {text =  ratTraitorString, color = TRAITOR.color}, {text = "The Traitors can see your location now. Get ready for a fight!", color = RAT.color}, 6, true)
			-- Tell the Rat client to hear the sound
			net.Start("ttt2_rat_sound_net")
			net.Send(ply)
			
			-- skip the end if rat was exposed on spawn
			if GetConVar("ttt2_rat_instant_expose"):GetBool() then return end
			
			-- highlight the rat for all traitors
			for _, ply in ipairs(player.GetAll()) do
				-- simple checks
				if not IsValid(ply) then return end
				if ply:GetSubRole() ~= ROLE_RAT then return end
				
				-- add the rat marker vision
				local mvObject = ply:AddMarkerVision("ttt2_rat_player")
				mvObject:SetOwner(TEAM_TRAITOR)
				mvObject:SetVisibleFor(VISIBLE_FOR_TEAM)
				mvObject:SyncToClients()
			end
		end)
	end

	-- Remove Loadout on death and rolechange
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
		timer.Remove("ttt2_rat_clock_timer")
		ply:RemoveMarkerVision("ttt2_rat_player")
		STATUS:RemoveStatus(ply, "ttt2_rat_expose_timer")
	end

	-- remove marker vision
	hook.Add("TTTOnCorpseCreated", "TTT2_RatDeath", function(rag, ply)
		if not IsValid(rag) or not IsValid(ply) then return end
		if ply:GetSubRole() ~= ROLE_RAT then return end
		ply:RemoveMarkerVision("ttt2_rat_player")
	end)

	-- Remove wallhacks when the rat dies
	hook.Add("TTTEndRound", "RatRoundEnd", function()
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetSubRole() ~= ROLE_RAT then return end
			ply:RemoveMarkerVision("ttt2_rat_player")
		end
	end)
end

if CLIENT then
	local TryT = LANG.TryTranslation
	local ParT = LANG.GetParamTranslation

	local materialRat = Material("vgui/ttt/dynamic/roles/icon_rat.vmt")

	-- marker vision
	hook.Add("TTT2RenderMarkerVisionInfo", "HUDDrawMarkerVisionRatPlayer", function(mvData)
		local ent = mvData:GetEntity()
		local mvObject = mvData:GetMarkerVisionObject()

		if not mvObject:IsObjectFor(ent, "ttt2_rat_player") then return end

		local distance = math.Round(util.HammerUnitsToMeters(mvData:GetEntityDistance()), 1)

		mvData:EnableText()

		mvData:AddIcon(materialRat)
		mvData:SetTitle("The Rat! Kill him before he exposes your role!")

		mvData:AddDescriptionLine(ParT("marker_vision_distance", {distance = distance}))
		mvData:AddDescriptionLine(TryT(mvObject:GetVisibleForTranslationKey()), COLOR_SLATEGRAY)
	end)
	
	-- f1 menu support
	function ROLE:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

		form:MakeSlider({
			serverConvar = "ttt2_rat_traitor_reveal_timer",
			label = "label_rat_traitor_reveal_time",
			min = 10,
			max = 600,
			decimal = 0,
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_rat_instant_expose",
			label = "label_rat_instant_expose"
		})
	end
	
	-- networked message
	net.Receive("TTT2_Rat_InstantExpose", function()
		-- event popup
		EPOP:AddMessage({text = "You have been exposed!" , color = TRAITOR.color}, {text = "Survive until the timer to expose a traitor." , color = RAT.color}, 3, nil, true)
		
		-- sfx
		surface.PlaySound("rat_squeak.mp3")
	end)
end
