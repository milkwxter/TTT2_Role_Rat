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
L["ttt2_label_rat_instantexpose_epop"] = "Your location is exposed to all Traitors."
L["ttt2_label_rat_instantexpose_epop_desc"] = "Survive until your timer expires to learn the name of a living Traitor."
L["ttt2_label_rat_markervision_title"] = "{name} is a Rat."
L["ttt2_label_rat_markervision_desc"] = "If left alive, they will expose your role."

-- CONVAR LANGUAGE STRINGS
L["label_convar_rat_traitor_reveal_time"] = "Seconds to reveal traitors to the rat"
L["label_convar_rat_instant_expose"] = "Should the rat be exposed on spawn?"

-- TIMER LANGUAGE STRINGS
L["label_status_rattimer_name"] = "Rat Expose Timer"
L["label_status_rattimer_desc"] = "When this timer finishes, exposes a Traitor to you."
