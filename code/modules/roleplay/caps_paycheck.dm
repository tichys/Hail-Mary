// CAPS PAYCHECK SYSTEM - Recurring caps income for employed players
// Uses a timer loop that fires every PAYCHECK_INTERVAL
// Defines are in __DEFINES/roleplay_constants.dm

/proc/start_caps_paychecks()
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(caps_paycheck_loop)), PAYCHECK_INTERVAL, TIMER_LOOP)
	addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(quest_progress_loop)), 100, TIMER_LOOP)

/proc/caps_paycheck_loop()
	deliver_all_paychecks()

/proc/quest_progress_loop()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.stat != DEAD && H.ckey)
			check_quest_progress_all(H)
			check_mercenary_contract_progress(H)
			if(H.client && !H.client.is_afk(300))
				check_perk_playtime(H.ckey, H.client.player_age, TRUE)

/proc/deliver_all_paychecks()
	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(H.stat == DEAD || !H.mind || !H.mind.assigned_role)
			continue
		if(H.client && H.client.is_afk(600))
			continue
		var/datum/job/J = SSjob.GetJob(H.mind.assigned_role)
		if(!J || J.caps_paycheck <= 0)
			continue
		var/pay_amount = J.caps_paycheck
		var/obj/item/stack/f13Cash/caps/C = new(get_turf(H), pay_amount)
		if(H.put_in_hands(C))
			to_chat(H, span_notice("<b>PAYDAY!</b> You receive [pay_amount] caps for your work as [J.title]."))
		else
			to_chat(H, span_notice("<b>PAYDAY!</b> [pay_amount] caps dropped at your feet for your work as [J.title]."))
		if(H.ckey)
			adjust_karma(H.ckey, 1)
		log_game("PAYCHECK: [H.ckey] received [pay_amount] caps as [J.title]")

/proc/check_mercenary_contract_progress(mob/living/carbon/human/H)
	if(!H || !H.ckey)
		return
	for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
		if(contract.assigned_to == H.ckey && contract.status == "active")
			contract.check_progress(H)
			contract.check_timeout()
