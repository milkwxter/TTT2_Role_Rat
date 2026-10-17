local L = LANG.GetLanguageTableReference("en")

-- GENERAL ROLE LANGUAGE STRINGS
L[RAT.name] = "Rat"
L["info_popup_" .. RAT.name] = [[You are a Rat! Surive during the round to eventually learn the name of a living Traitor.]]
L["body_found_" .. RAT.abbr] = "They were a Rat."
L["search_role_" .. RAT.abbr] = "This person was a Rat!"
L["target_" .. RAT.name] = "Rat"
L["ttt2_desc_" .. RAT.name] = [[The Rat will learn the name of a living Traitor after a certain amount of time.]]

-- CUSTOM ROLE LANGUAGE STRINGS
L["ttt2_label_rat_expose_epop"] = "{name} is a Traitor. Kill them or die trying."
L["ttt2_label_rat_expose_epop_desc"] = "Your location is now exposed to the Traitors for the rest of the round. Good luck."

L["ttt2_label_rat_expose_notraitors_epop"] = "There are no living Traitors left."
L["ttt2_label_rat_expose_notraitors_epop_desc"] = "Your location has not been exposed."

L["ttt2_label_rat_instantexpose_epop"] = "Your location is exposed to all Traitors."
L["ttt2_label_rat_instantexpose_epop_desc"] = "Survive until your timer expires to learn the name of a living Traitor."

L["ttt2_label_rat_markervision_title"] = "{name} is a Rat."
L["ttt2_label_rat_markervision_desc"] = "If left alive, they will expose your role."

L["ttt2_label_rat_chat_start"] = "[RAT] "
L["ttt2_label_rat_chat_traitor"] = "{name} is a Traitor."
L["ttt2_label_rat_chat_end"] = " This message is visible to you only."

-- CONVAR LANGUAGE STRINGS
L["label_convar_rat_traitor_reveal_time"] = "Seconds to reveal traitors to the Rat"
L["label_convar_rat_instant_expose"] = "Should the Rat be exposed on spawn?"
L["label_convar_rat_chat_reminder"] = "Remind the Rat in chat when the Traitor is revealed?"

-- TIMER LANGUAGE STRINGS
L["label_status_rattimer_name"] = "Rat Expose Timer"
L["label_status_rattimer_desc"] = "When this timer finishes, exposes a Traitor to you."

-- CLIENTSIDE MENU LANGUAGE STRINGS
L["submenu_addons_rat_title"] = "Rat Subrole"
L["header_addons_rat_title"] = "Client Rat Subrole Settings"
