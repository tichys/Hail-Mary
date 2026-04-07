// Mercenary Contract Board System
// Non-faction players can take temporary jobs from any faction

GLOBAL_LIST_EMPTY(mercenary_contracts)
GLOBAL_LIST_EMPTY(active_mercenaries)

// ============ MERCENARY CONTRACT ============

/datum/mercenary_contract
	var/contract_id
	var/name = "Contract"
	var/description = "Complete a task for payment."
	var/faction_employer = "neutral"
	var/reward_caps = 100
	var/reward_reputation = 10
	var/difficulty = 1
	var/time_limit = 0
	var/required_reputation = 0
	var/status = "available"
	var/assigned_to = null
	var/created_time = 0
	var/accepted_time = 0
	var/completed_time = 0
	var/location_hint = ""
	var/list/objectives = list()
	var/objectives_completed = 0
	var/blacklist_factions = list()

	var/static/next_id = 1

/datum/mercenary_contract/New()
	contract_id = "contract_[next_id++]"
	created_time = world.time

/datum/mercenary_contract/proc/get_ui_data()
	return list(
		"contract_id" = contract_id,
		"name" = name,
		"description" = description,
		"faction_employer" = faction_employer,
		"reward_caps" = reward_caps,
		"reward_reputation" = reward_reputation,
		"difficulty" = difficulty,
		"time_limit" = time_limit,
		"required_reputation" = required_reputation,
		"status" = status,
		"assigned_to" = assigned_to,
		"location_hint" = location_hint,
		"objectives_total" = objectives.len,
		"objectives_completed" = objectives_completed,
	)

/datum/mercenary_contract/proc/accept(mob/user)
	if(status != "available")
		return FALSE

	status = "active"
	assigned_to = user.ckey
	accepted_time = world.time
	GLOB.active_mercenaries[user.ckey] = contract_id

	to_chat(user, span_notice("Contract accepted: [name]"))
	return TRUE

/datum/mercenary_contract/proc/complete(mob/user)
	if(status != "active")
		return FALSE

	if(assigned_to != user.ckey)
		return FALSE

	status = "completed"
	completed_time = world.time
	GLOB.active_mercenaries -= user.ckey

	var/mob/living/carbon/human/H = user
	if(istype(H))
		var/obj/item/stack/f13Cash/caps = new /obj/item/stack/f13Cash/caps(get_turf(H), reward_caps)
		H.put_in_hands(caps)

		if(faction_employer != "neutral")
			adjust_faction_reputation(user.ckey, faction_employer, reward_reputation)

	to_chat(user, span_notice("Contract completed! You received [reward_caps] caps."))
	return TRUE

/datum/mercenary_contract/proc/fail()
	status = "failed"
	GLOB.active_mercenaries -= assigned_to

/datum/mercenary_contract/proc/check_timeout()
	if(time_limit > 0 && status == "active")
		if(world.time > accepted_time + time_limit)
			fail()
			return TRUE
	return FALSE

// ============ CONTRACT TYPES ============

/datum/mercenary_contract/escort
	name = "Escort Mission"
	description = "Escort a VIP safely to their destination."
	difficulty = 2
	reward_caps = 150
	reward_reputation = 15
	time_limit = 30 MINUTES
	location_hint = "VIP waiting at designated location"

/datum/mercenary_contract/retrieval
	name = "Item Retrieval"
	description = "Retrieve a specific item from a dangerous location."
	difficulty = 3
	reward_caps = 200
	reward_reputation = 20
	location_hint = "Item last seen at marked location"

/datum/mercenary_contract/elimination
	name = "Target Elimination"
	description = "Eliminate a specific hostile target."
	difficulty = 4
	reward_caps = 300
	reward_reputation = 25
	location_hint = "Target operating in designated area"

/datum/mercenary_contract/recon
	name = "Reconnaissance"
	description = "Scout a location and report findings."
	difficulty = 1
	reward_caps = 75
	reward_reputation = 10
	location_hint = "Investigate marked location"

/datum/mercenary_contract/guard
	name = "Guard Duty"
	description = "Protect a location for a set period."
	difficulty = 2
	reward_caps = 125
	reward_reputation = 12
	time_limit = 20 MINUTES
	location_hint = "Report to location and stand guard"

/datum/mercenary_contract/rescue
	name = "Rescue Operation"
	description = "Rescue a captured individual."
	difficulty = 4
	reward_caps = 350
	reward_reputation = 30
	location_hint = "Hostage held at marked location"

/datum/mercenary_contract/sabotage
	name = "Sabotage"
	description = "Destroy or disable enemy equipment."
	difficulty = 3
	reward_caps = 200
	reward_reputation = 20
	location_hint = "Target equipment at designated location"

// ============ MERCENARY BOARD ============

/obj/machinery/mercenary_board
	name = "Mercenary Contract Board"
	desc = "A terminal displaying available contracts for hire."
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer"
	density = TRUE
	anchored = TRUE

/obj/machinery/mercenary_board/Initialize()
	. = ..()
	generate_contracts()

/obj/machinery/mercenary_board/proc/generate_contracts()
	if(GLOB.mercenary_contracts.len > 0)
		return

	var/list/contract_types = list(
		/datum/mercenary_contract/escort,
		/datum/mercenary_contract/retrieval,
		/datum/mercenary_contract/elimination,
		/datum/mercenary_contract/recon,
		/datum/mercenary_contract/guard,
		/datum/mercenary_contract/rescue,
		/datum/mercenary_contract/sabotage,
	)

	for(var/i = 1 to 5)
		var/contract_type = pick(contract_types)
		var/datum/mercenary_contract/contract = new contract_type()
		contract.faction_employer = pick("ncr", "bos", "legion", "enclave", "neutral")
		GLOB.mercenary_contracts += contract

/obj/machinery/mercenary_board/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/mercenary_board/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MercenaryBoard")
		ui.open()

/obj/machinery/mercenary_board/ui_data(mob/user)
	var/list/available_contracts = list()
	var/list/active_contract = null

	for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
		if(contract.status == "available")
			available_contracts += list(contract.get_ui_data())
		if(contract.assigned_to == user.ckey && contract.status == "active")
			active_contract = contract.get_ui_data()

	return list(
		"available_contracts" = available_contracts,
		"active_contract" = active_contract,
		"player_reputation" = get_player_reputation(user.ckey),
		"can_take_contracts" = can_take_contracts(user),
	)

/obj/machinery/mercenary_board/proc/get_player_reputation(ckey)
	return 0

/obj/machinery/mercenary_board/proc/can_take_contracts(mob/user)
	if(GLOB.active_mercenaries[user.ckey])
		return FALSE
	return TRUE

/obj/machinery/mercenary_board/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	switch(action)
		if("accept_contract")
			var/contract_id = params["contract_id"]
			for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
				if(contract.contract_id == contract_id)
					return contract.accept(usr)
			return FALSE

		if("complete_contract")
			var/contract_id = params["contract_id"]
			for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
				if(contract.contract_id == contract_id)
					return contract.complete(usr)
			return FALSE

		if("abandon_contract")
			var/contract_id = params["contract_id"]
			for(var/datum/mercenary_contract/contract as anything in GLOB.mercenary_contracts)
				if(contract.contract_id == contract_id && contract.assigned_to == usr.ckey)
					contract.fail()
					to_chat(usr, span_warning("Contract abandoned. Your reputation may suffer."))
					return TRUE
			return FALSE

	return FALSE

// ============ FACTION-SPECIFIC CONTRACT BOARDS ============

/obj/machinery/mercenary_board/ncr
	name = "NCR Contract Terminal"
	desc = "NCR military contracts available here."

/obj/machinery/mercenary_board/ncr/generate_contracts()
	if(GLOB.mercenary_contracts.len > 0)
		return

	var/list/contract_types = list(
		/datum/mercenary_contract/escort,
		/datum/mercenary_contract/guard,
		/datum/mercenary_contract/recon,
	)

	for(var/i = 1 to 3)
		var/contract_type = pick(contract_types)
		var/datum/mercenary_contract/contract = new contract_type()
		contract.faction_employer = "ncr"
		GLOB.mercenary_contracts += contract

/obj/machinery/mercenary_board/bos
	name = "Brotherhood Contract Terminal"
	desc = "Brotherhood technology recovery contracts."

/obj/machinery/mercenary_board/bos/generate_contracts()
	if(GLOB.mercenary_contracts.len > 0)
		return

	var/list/contract_types = list(
		/datum/mercenary_contract/retrieval,
		/datum/mercenary_contract/recon,
		/datum/mercenary_contract/sabotage,
	)

	for(var/i = 1 to 3)
		var/contract_type = pick(contract_types)
		var/datum/mercenary_contract/contract = new contract_type()
		contract.faction_employer = "bos"
		GLOB.mercenary_contracts += contract

/obj/machinery/mercenary_board/legion
	name = "Legion Contract Terminal"
	desc = "Legion combat contracts."

/obj/machinery/mercenary_board/legion/generate_contracts()
	if(GLOB.mercenary_contracts.len > 0)
		return

	var/list/contract_types = list(
		/datum/mercenary_contract/elimination,
		/datum/mercenary_contract/rescue,
		/datum/mercenary_contract/sabotage,
	)

	for(var/i = 1 to 3)
		var/contract_type = pick(contract_types)
		var/datum/mercenary_contract/contract = new contract_type()
		contract.faction_employer = "legion"
		GLOB.mercenary_contracts += contract
