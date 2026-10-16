if SERVER then
	AddCSLuaFile()
	
	-- clients need these
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_rat.vmt")
	resource.AddFile("materials/vgui/ttt/status/icon_rat_timer.vmt")
	resource.AddFile("sound/rat_squeak.mp3")

	util.AddNetworkString("TTT2_Rat_InstantExpose_Client")
	util.AddNetworkString("TTT2_Rat_NormalExpose_Client")
	util.AddNetworkString("TTT2_Rat_NormalExposeNoTraitors_Client")
end

-- shared convars
CreateConVar("ttt2_rat_instant_expose", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Should the rat be exposed on spawn?", 0, 1)
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
	-- helper for traitor names
	function getLivingTraitorNick()
		-- find all living traitors
		local livingTraitors = {}
		for _, ply in ipairs( player.GetAll() ) do
			if not IsValid(ply) or not ply:IsActive() then continue end
			if ply:GetRealTeam() ~= TEAM_TRAITOR then continue end
			
			-- yeah this guy is alive
			table.insert(livingTraitors, ply:Nick())
		end
		
		-- return a random guy from list
		if #livingTraitors == 0 then return nil end
		return livingTraitors[math.random(#livingTraitors)]
	end

	-- expose rat on spawn depending on convar
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
		-- early returns
		if not IsValid(ply) then return end
		if ply:GetSubRole() ~= ROLE_RAT then return end
		
		-- instant expose convar
		if GetConVar("ttt2_rat_instant_expose"):GetBool() then
			-- give traitors marker vision on him
			local mvObject = ply:AddMarkerVision("ttt2_rat_player")
			mvObject:SetOwner(TEAM_TRAITOR)
			mvObject:SetVisibleFor(VISIBLE_FOR_TEAM)
			mvObject:SyncToClients()
			
			-- network to the rat player he is insta exposed
			net.Start("TTT2_Rat_InstantExpose_Client")
			net.Send(ply)
		end
		
		-- give him a status so he knows the timer
		STATUS:AddTimedStatus(ply, "ttt2_rat_expose_timer", GetConVar("ttt2_rat_traitor_reveal_timer"):GetInt(), true)
		
		-- start a timer for the rat
		timer.Create("ttt2_rat_clock_timer_" .. ply:SteamID64(), GetConVar("ttt2_rat_traitor_reveal_timer"):GetInt(), 1, function()
			-- more checks
			if not IsValid(ply) then return end
			if not ply:IsActive() then return end
			if ply:GetSubRole() ~= ROLE_RAT then return end
			
			-- call our custom function to get a traitor name
			local traitorName = getLivingTraitorNick()
			if traitorName ~= nil then
				net.Start("TTT2_Rat_NormalExpose_Client")
					net.WriteString(traitorName)
				net.Send(ply)
			else
				net.Start("TTT2_Rat_NormalExposeNoTraitors_Client")
				net.Send(ply)
			end
			
			-- skip the end if rat was exposed on spawn
			if GetConVar("ttt2_rat_instant_expose"):GetBool() then return end
			
			-- highlight the rat for all traitors
			if not IsValid(ply) then return end
			if ply:GetSubRole() ~= ROLE_RAT then return end
			
			local mvObject = ply:AddMarkerVision("ttt2_rat_player")
			mvObject:SetOwner(TEAM_TRAITOR)
			mvObject:SetVisibleFor(VISIBLE_FOR_TEAM)
			mvObject:SyncToClients()
		end)
	end

	-- remove rats loadout on role change or death
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
		timer.Remove("ttt2_rat_clock_timer_" .. ply:SteamID64())
		ply:RemoveMarkerVision("ttt2_rat_player")
		STATUS:RemoveStatus(ply, "ttt2_rat_expose_timer")
	end
	
	hook.Add("TTTEndRound", "TTT2_RatRoundEnd", function()
		for _, ply in ipairs(player.GetAll()) do
			if ply:GetSubRole() ~= ROLE_RAT then continue end
			ply:RemoveMarkerVision("ttt2_rat_player")
			timer.Remove("ttt2_rat_clock_timer_" .. ply:SteamID64())
		end
	end)
end

if CLIENT then
	local TryT = LANG.TryTranslation
	local ParT = LANG.GetParamTranslation

	local materialRat = Material("vgui/ttt/dynamic/roles/icon_rat.vmt")
	local materialRatTimer = Material("vgui/ttt/status/icon_rat_timer.vmt")
	
	-- add status for client
	hook.Add("Initialize", "TTT2_Rat_StatusInit", function()
		STATUS:RegisterStatus("ttt2_rat_expose_timer", {
			hud = materialRatTimer,
			type = "good",
			name = "label_status_rattimer_name",
			sidebarDescription = "label_status_rattimer_desc"
		})
	end)

	-- marker vision
	hook.Add("TTT2RenderMarkerVisionInfo", "HUDDrawMarkerVisionRatPlayer", function(mvData)
		local ent = mvData:GetEntity()
		local mvObject = mvData:GetMarkerVisionObject()

		if not mvObject:IsObjectFor(ent, "ttt2_rat_player") then return end

		local distance = math.Round(util.HammerUnitsToMeters(mvData:GetEntityDistance()), 1)

		mvData:EnableText()

		mvData:AddIcon(materialRat)
		mvData:SetTitle(ParT("ttt2_label_rat_markervision_title", {name = ent:Nick()}), COLOR_RED)
		mvData:AddDescriptionLine(TryT("ttt2_label_rat_markervision_desc"))

		mvData:AddDescriptionLine(ParT("marker_vision_distance", {distance = distance}))
		mvData:AddDescriptionLine(TryT(mvObject:GetVisibleForTranslationKey()), COLOR_SLATEGRAY)
	end)
	
	-- f1 menu support
	function ROLE:AddToSettingsMenu(parent)
		local form = vgui.CreateTTT2Form(parent, "header_roles_additional")

		form:MakeSlider({
			serverConvar = "ttt2_rat_traitor_reveal_timer",
			label = "label_convar_rat_traitor_reveal_time",
			min = 10,
			max = 600,
			decimal = 0,
		})

		form:MakeCheckBox({
			serverConvar = "ttt2_rat_instant_expose",
			label = "label_convar_rat_instant_expose"
		})
	end
	
	-- networked message
	net.Receive("TTT2_Rat_InstantExpose_Client", function()
		-- event popup
		EPOP:AddMessage({text = "ttt2_label_rat_instantexpose_epop", color = TRAITOR.color}, "ttt2_label_rat_instantexpose_epop_desc", 3, nil, true)
		
		-- sfx
		surface.PlaySound("rat_squeak.mp3")
	end)
	
	net.Receive("TTT2_Rat_NormalExpose_Client", function()
		local traitor = net.ReadString()
		
		-- event popup
		local textString = LANG.GetParamTranslation("ttt2_label_rat_expose_epop", {name = traitor})
		EPOP:AddMessage({text = textString, color = TRAITOR.color}, "ttt2_label_rat_expose_epop_desc", 3, nil, true)
		
		-- sfx
		surface.PlaySound("rat_squeak.mp3")
	end)
	
	net.Receive("TTT2_Rat_NormalExposeNoTraitors_Client", function()
		-- event popup
		EPOP:AddMessage({text = "ttt2_label_rat_expose_notraitors_epop", color = RAT.color}, "ttt2_label_rat_expose_notraitors_epop_desc", 3, nil, true)
		
		-- sfx
		surface.PlaySound("rat_squeak.mp3")
	end)
end
