-- clientside menu
CLGAMEMODESUBMENU.base = "base_gamemodesubmenu"

CLGAMEMODESUBMENU.priority = 0
CLGAMEMODESUBMENU.title = "submenu_addons_rat_title"

function CLGAMEMODESUBMENU:Populate(parent)
	local form = vgui.CreateTTT2Form(parent, "header_addons_rat_title")

	enabled = form:MakeCheckBox({
		label = "label_convar_rat_chat_reminder",
		convar = "ttt2_rat_chat_reminder"
	})
end
