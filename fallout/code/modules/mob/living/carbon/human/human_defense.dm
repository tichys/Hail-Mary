/mob/living/carbon/human/alt_attack_hand(mob/user)
	if(..())
		return
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		if(!dna.species.alt_spec_attack_hand(H, src))
			dna.species.spec_attack_hand(H, src)
		return TRUE

/mob/living/carbon/human/on_attack_hand(mob/living/carbon/human/user, act_intent, unarmed_attack_flags)
	. = ..()
	if(.)
		return
	
	// Auto-trigger dialogue on HELP intent for NPCs (not player characters)
	if(act_intent == INTENT_HELP && user != src)
		// Only trigger for NPCs (has ckey but no player key = NPC)
		if(!client && ckey)
			var/dialogue_id = null
			
			if(dialogue_type)
				dialogue_id = dialogue_type
			else
				// Detect by name
				var/name_lower = lowertext(name)
				if(findtext(name_lower, "ncr") || findtext(name_lower, "soldier") || findtext(name_lower, "ranger") || findtext(name_lower, "sergeant"))
					dialogue_id = "ncr"
				else if(findtext(name_lower, "legion") || findtext(name_lower, "centurion") || findtext(name_lower, "decanus"))
					dialogue_id = "legion"
				else if(findtext(name_lower, "brotherhood") || findtext(name_lower, "paladin") || findtext(name_lower, "elder"))
					dialogue_id = "brotherhood"
				else if(findtext(name_lower, "trader") || findtext(name_lower, "merchant"))
					dialogue_id = "trader"
				else if(findtext(name_lower, "mayor") || findtext(name_lower, "sheriff"))
					dialogue_id = "bighorn"
			
			if(dialogue_id)
				start_dialogue(user, dialogue_id)
				return TRUE
	
	return FALSE
