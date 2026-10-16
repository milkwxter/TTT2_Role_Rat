if SERVER then
	AddCSLuaFile()
	resource.AddFile("materials/vgui/ttt/dynamic/roles/icon_rat.vmt")
  -- required for network messages
	util.AddNetworkString("ttt2_rat_sound_net")
end

function ROLE:PreInitialize()
  self.color = Color(80, 173, 59, 255)

  self.abbr = "rat" -- abbreviation
  self.surviveBonus = 0 -- bonus multiplier for every survive while another player was killed
  self.scoreKillsMultiplier = 2 -- multiplier for kill of player of another team
  self.scoreTeamKillsMultiplier = -8 -- multiplier for teamkill
  self.unknownTeam = true

  self.defaultTeam = TEAM_INNOCENT

  self.conVarData = {
    pct = 0.17, -- necessary: percentage of getting this role selected (per player)
    maximum = 1, -- maximum amount of roles in a round
    minPlayers = 6, -- minimum amount of players until this role is able to get selected
    credits = 0, -- the starting credits of a specific role
    togglable = true, -- option to toggle a role for a client if possible (F1 menu)
    random = 33,
    traitorButton = 0, -- can use traitor buttons
    shopFallback = SHOP_DISABLED
  }
end

-- now link this subrole with its baserole
function ROLE:Initialize()
  roles.SetBaseRole(self, ROLE_INNOCENT)
end



if SERVER then
	-- Give Loadout on respawn and rolechange
	function ROLE:GiveRoleLoadout(ply, isRoleChange)
	--Check if instant expose convar is on
	--If so, instantly expose traitor to rat 
	if GetConVar("ttt2_rat_instant_expose"):GetInt() == 1 then
		for _, ply in ipairs( player.GetAll() ) do
        -- check if player is valid
        if not IsValid(ply) then return end
        -- check if player is actually a rat
        if ply:GetRoleString() == "rat" then
          -- do rat marker
          local mvObject = ply:AddMarkerVision("player_rat")
          mvObject:SetOwner(TEAM_TRAITOR)
          mvObject:SetVisibleFor(VISIBLE_FOR_TEAM)
          mvObject:SyncToClients()
          --displaying the proper message
          EPOP:AddMessage(ply, {text = "You have been exposed!" , color = TRAITOR.color}, {text = "Survive until the timer to expose a traitor." , color = RAT.color}, 6, true)
          -- Tell the Rat client to hear the sound
          net.Start("ttt2_rat_sound_net")
          net.Send(ply)
        end
		  end
	end
    --Start the rat clock
    STATUS:AddTimedStatus(ply, "ttt2_rat_expose_timer", GetConVar("ttt2_rat_traitor_reveal_timer"):GetInt(), true)
    timer.Create("ttt2_rat_clock_timer", GetConVar("ttt2_rat_traitor_reveal_timer"):GetInt(), 1, function()
      -- call our custom function to out the traitors
      exposeTraitorToRat()
	  --displaying the proper message
	  EPOP:AddMessage(ply, {text =  ratTraitorString, color = TRAITOR.color}, {text = "The Traitors can see your location now. Get ready for a fight!", color = RAT.color}, 6, true)
	  -- Tell the Rat client to hear the sound
	  net.Start("ttt2_rat_sound_net")
      net.Send(ply)
	  --Execute this code when we didn't instantly expose rat
	  if GetConVar("ttt2_rat_instant_expose"):GetInt() == 0 then
      -- highlight the rat for all traitors
      for _, ply in ipairs( player.GetAll() ) do
        -- check if player is valid
        if not IsValid(ply) then return end
        -- check if player is actually a rat
        if ply:GetRoleString() == "rat" then
          -- do rat marker
          local mvObject = ply:AddMarkerVision("player_rat")
          mvObject:SetOwner(TEAM_TRAITOR)
          mvObject:SetVisibleFor(VISIBLE_FOR_TEAM)
          mvObject:SyncToClients()
		end
	  end
	 end
    end)
	end

	-- Remove Loadout on death and rolechange
	function ROLE:RemoveRoleLoadout(ply, isRoleChange)
    timer.Remove("ttt2_rat_clock_timer")
    ply:RemoveMarkerVision("player_rat")
    STATUS:RemoveStatus(ply, "ttt2_rat_expose_timer")
	end

  -- Remove wallhacks when the rat dies
	hook.Add("TTTOnCorpseCreated", "RatRoleDies", function(rag, ply)
		if not IsValid(rag) or not IsValid(ply) then return end
    if ply:GetRoleString() == "rat" then
      ply:RemoveMarkerVision("player_rat")
    end
	end)

  -- Remove wallhacks when the rat dies
	hook.Add("TTTEndRound", "RatRoundEnd", function()
    for _, v in ipairs(player.GetAll()) do
      if v:GetSubRole() == ROLE_RAT then
        v:RemoveMarkerVision("player_rat")
      end
    end
	end)
end

-- actual wallhacks part
if CLIENT then
	local TryT = LANG.TryTranslation
	local ParT = LANG.GetParamTranslation

	local materialRat = Material("vgui/ttt/dynamic/roles/icon_rat.vmt")

	hook.Add("TTT2RenderMarkerVisionInfo", "HUDDrawMarkerVisionRatPlayer", function(mvData)
		local ent = mvData:GetEntity()
		local mvObject = mvData:GetMarkerVisionObject()

    if not mvObject:IsObjectFor(ent, "player_rat") then return end

		local distance = math.Round(util.HammerUnitsToMeters(mvData:GetEntityDistance()), 1)

		mvData:EnableText()

		mvData:AddIcon(materialRat)
		mvData:SetTitle("The Rat! Kill him before he exposes your role!")

		mvData:AddDescriptionLine(ParT("marker_vision_distance", {distance = distance}))
		mvData:AddDescriptionLine(TryT(mvObject:GetVisibleForTranslationKey()), COLOR_SLATEGRAY)
	end)
end

-- adding convars to the TTT2 menu
if CLIENT then
  function ROLE:AddToSettingsMenu(parent)
    local form = vgui.CreateTTT2Form(parent, "header_roles_additional")
    
	form:MakeSlider({
      serverConvar = "ttt2_rat_traitor_reveal_timer",
      label = "label_rat_traitor_reveal_time",
      min = 60,
      max = 240,
      decimal = 0,
    })
	
	form:MakeCheckBox({
      serverConvar = "ttt2_rat_instant_expose",
      label = "label_rat_instant_expose"
    })

  end
end

if CLIENT then
  net.Receive("ttt2_rat_sound_net", function()
    --playing the squeak!
		surface.PlaySound("rat_squeak.mp3")
  end)
end