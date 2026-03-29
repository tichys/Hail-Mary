// Bounty System for Big Iron: Hail Mary
// Places bounties on players with negative karma and manages bounty hunters

GLOBAL_LIST_INIT(bounties, list())
GLOBAL_LIST_INIT(active_bounty_hunters, list())

#define BOUNTY_THRESHOLD_VILLAIN -500
#define BOUNTY_THRESHOLD_INFAMOUS -750
#define BOUNTY_AMOUNT_VILLAIN 500
#define BOUNTY_AMOUNT_INFAMOUS 1000
#define BOUNTY_KILL_REWARD 5 // Karma reward for killing bounty target

// ============ HELPER PROCS ============

/proc/find_player_by_ckey(ckey)
	if(!ckey)
		return null
	for(var/mob/M in GLOB.player_list)
		if(M.ckey == ckey)
			return M
	return null

// ============ DATABASE FUNCTIONS ============

/proc/setup_bounty_db()
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery({"
		CREATE TABLE IF NOT EXISTS [format_table_name("player_bounties")] (
			ckey VARCHAR(32) PRIMARY KEY,
			bounty_amount INT DEFAULT 0,
			placed_by VARCHAR(32) DEFAULT 'system',
			reason TEXT,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
			updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
		)"}
	)
	
	var/success = query.Execute()
	qdel(query)
	return success

/proc/get_bounty(ckey)
	if(!ckey)
		return 0
	if(!SSdbcore.Connect())
		return 0
	
	// Check cache first
	if(GLOB.bounties[ckey])
		return GLOB.bounties[ckey]
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT bounty_amount FROM [format_table_name("player_bounties")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	
	var/bounty_amount = 0
	if(query.Execute() && query.NextRow())
		bounty_amount = text2num(query.item[1])
		GLOB.bounties[ckey] = bounty_amount
	
	qdel(query)
	return bounty_amount

/proc/set_bounty(ckey, amount, placed_by = "system", reason = "")
	if(!ckey)
		return FALSE
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"INSERT INTO [format_table_name("player_bounties")] (ckey, bounty_amount, placed_by, reason, updated_at) VALUES (:ckey, :amount, :placed_by, :reason, NOW()) ON DUPLICATE KEY UPDATE bounty_amount = :amount, placed_by = :placed_by, reason = :reason, updated_at = NOW()",
		list("ckey" = ckey, "amount" = amount, "placed_by" = placed_by, "reason" = reason)
	)
	
	var/success = query.Execute()
	qdel(query)
	
	// Update cache
	GLOB.bounties[ckey] = amount
	
	// Notify player
	notify_bounty_change(ckey, amount)
	
	return success

/proc/remove_bounty(ckey)
	if(!ckey)
		return FALSE
	if(!SSdbcore.Connect())
		return FALSE
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"DELETE FROM [format_table_name("player_bounties")] WHERE ckey = :ckey",
		list("ckey" = ckey)
	)
	
	query.Execute()
	qdel(query)
	
	// Clear cache
	GLOB.bounties -= ckey
	
	// Notify player
	notify_bounty_change(ckey, 0)
	
	return TRUE

// ============ BOUNTY TRIGGERING ============

/proc/check_bounty_trigger(ckey)
	var/karma = get_karma(ckey)
	var/current_bounty = get_bounty(ckey)
	
	// Remove bounty if karma improved
	if(karma >= KARMA_VILLAIN && current_bounty > 0)
		remove_bounty(ckey)
		return
	
	// Add bounty if karma dropped
	if(karma <= KARMA_INFAMOUS && current_bounty < BOUNTY_AMOUNT_INFAMOUS)
		set_bounty(ckey, BOUNTY_AMOUNT_INFAMOUS, "system", "Infamous crimes")
		announce_bounty(ckey, BOUNTY_AMOUNT_INFAMOUS, "Infamous crimes")
		spawn_bounty_hunters(ckey)
	else if(karma <= KARMA_VILLAIN && current_bounty < BOUNTY_AMOUNT_VILLAIN)
		set_bounty(ckey, BOUNTY_AMOUNT_VILLAIN, "system", "Villainous actions")
		announce_bounty(ckey, BOUNTY_AMOUNT_VILLAIN, "Villainous actions")

// ============ NOTIFICATIONS ============

/proc/announce_bounty(ckey, amount, reason)
	var/mob/player = find_player_by_ckey(ckey)
	var/player_name = player ? player.real_name : ckey
	
	priority_announce("A bounty of [amount] caps has been placed on [player_name]! [reason]", "Bounty Alert", "bounty")

	// Also notify in OOC
	for(var/mob/M in GLOB.player_list)
		if(M.client)
			to_chat(M, span_notice("[span_bold("BREAKING:")] A bounty of [amount] caps has been placed on [player_name]!"))

/proc/notify_bounty_change(ckey, new_amount)
	var/mob/player = find_player_by_ckey(ckey)
	if(!player)
		return
	
	if(new_amount > 0)
		to_chat(player, span_userdanger("A bounty of [new_amount] caps has been placed on your head!"))
		to_chat(player, span_warning("Improve your karma to reduce the bounty."))
		to_chat(player, span_notice("Type /view_bounties to see all active bounties."))
	else
		to_chat(player, span_notice("Your bounty has been removed."))

// ============ BOUNTY COLLECTION ============

/proc/collect_bounty(killer_ckey, victim_ckey)
	var/bounty = get_bounty(victim_ckey)
	if(bounty <= 0)
		return 0
	
	var/mob/killer = find_player_by_ckey(killer_ckey)
	var/mob/victim = find_player_by_ckey(victim_ckey)
	
	// Give reward to killer
	if(killer && ishuman(killer))
		// Create cash stack
		var/obj/item/stack/f13Cash/caps/cap_stack = new(get_turf(killer))
		cap_stack.amount = min(bounty, BOUNTY_CAPS_STACK_MAX) // Cap at 50 per stack
		killer.put_in_hands(cap_stack)
		
		to_chat(killer, span_notice("You collected a [bounty] cap bounty on [victim ? victim.real_name : victim_ckey]!"))
		
		// Karma reward
		adjust_karma(killer_ckey, BOUNTY_KILL_REWARD)
	
	// Announce
	if(victim)
		priority_announce("[killer ? killer.real_name : killer_ckey] has collected the [bounty] cap bounty on [victim.real_name]!", "Bounty Collected", "bounty")
	
	// Remove bounty
	remove_bounty(victim_ckey)
	
	// Clear any bounty hunters targeting this player
	clear_bounty_hunters(victim_ckey)
	
	return bounty

// ============ BOUNTY HUNTERS ============

/proc/spawn_bounty_hunters(ckey)
	var/mob/target = find_player_by_ckey(ckey)
	if(!target)
		return
	
	// Only spawn for high bounties
	var/bounty = get_bounty(ckey)
	if(bounty < BOUNTY_AMOUNT_INFAMOUS)
		return
	
	// Spawn 2-3 bounty hunters
	var/num_hunters = rand(2, 3)
	var/turf/spawn_turf = find_safe_turf()
	
	for(var/i = 1 to num_hunters)
		var/mob/living/carbon/human/hunter = new(spawn_turf)
		hunter.set_species(/datum/species/human)
		hunter.real_name = "Bounty Hunter"
		hunter.name = hunter.real_name
		hunter.faction = "bounty_hunter"
		
		// Equip well
		hunter.equip_to_slot_or_del(new /obj/item/clothing/under/suit/black_really(hunter), SLOT_W_UNIFORM)
		hunter.equip_to_slot_or_del(new /obj/item/clothing/shoes/combat(hunter), SLOT_SHOES)
		
		// Good weapon
		var/obj/item/gun/ballistic/automatic/assault_rifle/assault_rifle = new(hunter)
		hunter.equip_to_slot_or_del(assault_rifle, SLOT_BACK)
		
		// Track this hunter
		GLOB.active_bounty_hunters += hunter
		
		// Make them hunt the target
		// Note: Full AI implementation would require proper AI controller
		// For now they just spawn and exist
		
		addtimer(CALLBACK(GLOBAL_PROC, /proc/qdel, hunter), 600) // Despawn after 10 min

/proc/clear_bounty_hunters(ckey)
	for(var/mob/living/carbon/human/H in GLOB.active_bounty_hunters)
		if(H && !QDELETED(H))
			H.visible_message(span_notice("[H] receives word that the bounty has been collected and leaves."))
			qdel(H)

// ============ QUERY FUNCTIONS ============

/proc/get_all_bounties()
	if(!SSdbcore.Connect())
		return list()
	
	var/datum/db_query/query = SSdbcore.NewQuery(
		"SELECT ckey, bounty_amount, reason, placed_by, created_at FROM [format_table_name("player_bounties")] WHERE bounty_amount > 0 ORDER BY bounty_amount DESC"
	)
	
	var/list/bounties = list()
	if(query.Execute())
		while(query.NextRow())
			bounties += list(list(
				"ckey" = query.item[1],
				"amount" = text2num(query.item[2]),
				"reason" = query.item[3],
				"placed_by" = query.item[4],
				"created_at" = query.item[5]
			))
	
	qdel(query)
	return bounties

// ============ PLAYER VERBS ============

/client/verb/check_bounties()
	set name = "View Bounties"
	set category = "Character"
	set desc = "View active bounties in the wasteland"
	
	show_bounty_list(usr)

/proc/show_bounty_list(mob/user)
	var/datum/browser/popup = new(user, "bounty_list", "Active Bounties", 600, 500)
	
	var/list/bounties = get_all_bounties()
	var/user_bounty = get_bounty(user.ckey)
	
	var/html = {"
	<!DOCTYPE html>
	<html>
	<head>
		<style>
			body { background: #1a1a1a; color: #d4a574; font-family: "Courier New", monospace; padding: 20px; }
			h1 { color: #ff6666; border-bottom: 1px solid #662222; padding-bottom: 10px; }
			.bounty-item { padding: 15px; margin: 10px 0; background: #2a1515; border: 1px solid #663333; }
			.bounty-name { font-size: 1.2em; color: #ff6666; font-weight: bold; }
			.bounty-amount { color: #ffcc00; font-size: 1.1em; }
			.bounty-reason { color: #996633; font-style: italic; }
			.bounty-placed { color: #664422; font-size: 0.9em; }
			.your-bounty { border: 2px solid #ff0000; background: #330000; }
			.no-bounty { color: #33ff33; }
		</style>
	</head>
	<body>
		<h1>Active Bounties</h1>
"}
	
	// Show user's own bounty status
	if(user_bounty > 0)
		html += "<div class='bounty-item your-bounty'>"
		html += "<div class='bounty-name'>YOUR BOUNTY</div>"
		html += "<div class='bounty-amount'>[user_bounty] caps</div>"
		html += "<div class='bounty-reason'>Bounty hunters may be after you!</div>"
		html += "</div>"
		html += "<hr>"
	
	if(!bounties.len)
		html += "<p class='no-bounty'>No active bounties in the wasteland. Good news!</p>"
	else
		html += "<p>Total active bounties: [bounties.len]</p>"
		for(var/list/b in bounties)
			var/is_self = (b["ckey"] == user.ckey)
			var/cls = is_self ? "bounty-item your-bounty" : "bounty-item"
			
			html += "<div class='[cls]'>"
			html += "<div class='bounty-name'>[b["ckey"]]</div>"
			html += "<div class='bounty-amount'>[b["amount"]] caps</div>"
			html += "<div class='bounty-reason'>[b["reason"]]</div>"
			html += "<div class='bounty-placed'>Placed: [b["created_at"]]</div>"
			html += "</div>"
	
	html += "</body></html>"
	
	popup.set_content(html)
	popup.open()

// ============ ADMIN VERBS ============

/client/proc/place_bounty()
	set category = "Admin"
	set name = "Place Bounty"
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	var/amount = input(src, "Enter bounty amount:", "Amount") as num|null
	if(isnull(amount) || amount <= 0)
		return
	
	var/reason = input(src, "Enter reason:", "Reason") as text|null
	if(!reason)
		reason = "Manual bounty"
	
	set_bounty(target_ckey, amount, ckey, reason)
	
	log_admin("[key_name(src)] placed a [amount] cap bounty on [target_ckey]: [reason]")
	message_admins("[key_name(src)] placed a [amount] cap bounty on [target_ckey]: [reason]")

/client/proc/remove_bounty_verb()
	set category = "Admin"
	set name = "Remove Bounty"
	
	var/target_ckey = input(src, "Enter player ckey:", "Player Ckey") as text|null
	if(!target_ckey)
		return
	
	remove_bounty(target_ckey)
	
	log_admin("[key_name(src)] removed bounty from [target_ckey]")
	message_admins("[key_name(src)] removed bounty from [target_ckey]")

// ============ INITIALIZATION ============

/world/proc/init_bounty_system()
	setup_bounty_db()
	// Process bounties periodically
	addtimer(CALLBACK(GLOBAL_PROC, .proc/process_bounties), 6000) // Every 10 minutes

/proc/process_bounties()
	// Spawn bounty hunters for infamous players
	for(var/mob/living/carbon/human/H in GLOB.alive_mob_list)
		if(H.client && H.ckey)
			var/karma = get_karma(H.ckey)
			if(karma <= KARMA_INFAMOUS && prob(5))
				spawn_bounty_hunters(H.ckey)