/datum/job/butler
	title = "Butler"
	f_title = "Head Housekeeper"
	tutorial = "You are elevated to near nobility, as you hold the distinguished position of master of the royal household staff. \
	Your blade is a charcuterie of artisanal cheeses and meat, your armor wit and classical training. \
	By your word the meals are served, the chambers kept, and the floors polished clean. \
	You wear the royal colors and hold their semblance of dignity, \
	for without you and the servants under your command, the court would have all starved to death."
	department_flag = SERFS
	display_order = JDO_BUTLER
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1
	bypass_lastclass = TRUE

	allowed_ages = list(AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = RACES_BUTLER

	outfit = /datum/outfit/butler
	give_bank_account = 30
	cmode_music = 'sound/music/cmode/towner/CombatInn.ogg'

	exp_type = list(EXP_TYPE_LIVING)
	exp_requirements = list(
		EXP_TYPE_LIVING = 600
	)

	jobstats = list(
		STATKEY_STR = 2,
		STATKEY_INT = 2,
		STATKEY_CON = 2,
		STATKEY_END = 2
	)

	skills = list(
		/datum/skill/combat/knives = 2,
		/datum/skill/craft/cooking = 4,
		/datum/skill/craft/crafting = 2,
		/datum/skill/labor/butchering = 2,
		/datum/skill/labor/farming = 2,
		/datum/skill/labor/mathematics = 3,
		/datum/skill/misc/athletics = 2,
		/datum/skill/misc/medicine = 2,
		/datum/skill/misc/music = 1,
		/datum/skill/misc/reading = 3,
		/datum/skill/misc/riding = 1,
		/datum/skill/misc/sewing = 3,
		/datum/skill/misc/sneaking = 3,
		/datum/skill/misc/stealing = 3
	)

	traits = list(
		TRAIT_KNOWKEEPPLANS,
		TRAIT_ROYALSERVANT,
		TRAIT_CRITICAL_RESISTANCE,
		TRAIT_NOPAINSTUN,
		TRAIT_HARDDISMEMBER,
		TRAIT_EMPATH,
		TRAIT_INDENTURED,
	)

/datum/job/butler/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	var/mob/living/carbon/human/H = spawned
	var/client/chooser = player_client || H?.client
	if(!H || QDELETED(H) || !chooser)
		return

	if(length(GLOB.keep_doors) > 0)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(know_keep_door_password), H), 5 SECONDS)

	H.adjust_skillrank(/datum/skill/misc/music, pick(0, 0, 2, 3), TRUE)

	var/list/weapons = list("Pikeman", "Fencer", "Longsword", "Sabre", "Knife")
	var/weapon_choice = input(chooser, "Choose your weapon.", "TAKE UP ARMS") as null|anything in weapons
	if(!weapon_choice)
		return

	switch(weapon_choice)
		if("Pikeman")
			give_or_drop(H, /obj/item/weapon/polearm/spear/billhook)
			give_or_drop(H, /obj/item/weapon/sword/arming)
			H.adjust_skillrank(/datum/skill/combat/polearms, 4, TRUE)
			H.adjust_skillrank(/datum/skill/combat/swords, 3, TRUE)

		if("Fencer")
			give_or_drop(H, /obj/item/weapon/sword/rapier)
			H.adjust_skillrank(/datum/skill/combat/swords, 4, TRUE)

		if("Longsword")
			give_or_drop(H, /obj/item/weapon/sword/long)
			H.adjust_skillrank(/datum/skill/combat/swords, 4, TRUE)

		if("Sabre")
			give_or_drop(H, /obj/item/weapon/sword/sabre)
			H.adjust_skillrank(/datum/skill/combat/swords, 4, TRUE)

		if("Knife")
			give_or_drop(H, /obj/item/weapon/knife/dagger/steel)
			H.adjust_skillrank(/datum/skill/combat/knives, 2, TRUE)

/datum/job/butler/proc/give_or_drop(mob/living/carbon/human/H, path)
	if(!H || QDELETED(H) || !path)
		return

	var/obj/item/I = new path(H.drop_location())
	if(!H.put_in_hands(I))
		to_chat(H, span_warning("My hands are full. [I] drops to the floor."))

/datum/outfit/butler
	name = "Butler"
	shoes = /obj/item/clothing/shoes/nobleboot
	beltr = /obj/item/storage/keyring/captain
	beltl = /obj/item/storage/belt/pouch/coins/mid
	backr = /obj/item/storage/backpack/satchel

	backpack_contents = list(
		/obj/item/weapon/knife/villager = 1,
		/obj/item/servant_bell/lord = 1
	)

/datum/outfit/butler/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()

	if(equipped_human.gender == MALE)
		armor = /obj/item/clothing/armor/leather/jacket/tailcoat/lord
		shirt = /obj/item/clothing/shirt/undershirt/formal
		belt = /obj/item/storage/belt/leather/suspenders
		pants = /obj/item/clothing/pants/trou/formal
	else
		armor = /obj/item/clothing/shirt/dress/maid/lord
		cloak = /obj/item/clothing/cloak/apron/maid
		belt = /obj/item/storage/belt/leather/cloth_belt
		pants = /obj/item/clothing/pants/tights/colored/white
