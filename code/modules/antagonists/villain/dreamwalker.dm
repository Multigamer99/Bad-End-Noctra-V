/datum/antagonist/dreamwalker
	name = "Dreamwalker"
	roundend_category = "dreamwalker"
	antagpanel_category = "Dreamwalker"
	job_rank = ROLE_DREAMWALKER
	confess_lines = list(
		"MY VISION ABOVE ALL!",
		"I'LL TAKE YOU TO MY REALM!",
		"HIS FORM IS MAGNIFICENT!",
	)
	show_in_roundend = TRUE

	var/traits_dreamwalker = list(
		TRAIT_NOHUNGER,
		TRAIT_NOBREATH,
		TRAIT_NOPAIN,
		TRAIT_TOXIMMUNE,
		TRAIT_STEELHEARTED,
		TRAIT_NOSLEEP,
		TRAIT_NOMOOD,
		TRAIT_NOLIMBDISABLE,
		TRAIT_SHOCKIMMUNE,
		TRAIT_CRITICAL_RESISTANCE,
		TRAIT_HEAVYARMOR,
		TRAIT_RITUALIST,
		TRAIT_DREAMWALKER,
	)

/datum/antagonist/dreamwalker/on_gain()
	SSmapping.retainer.dreamwalkers |= owner
	owner.special_role = ROLE_DREAMWALKER
	. = ..()
	reset_dreamwalker_stats()
	greet()
	return ..()

/datum/antagonist/dreamwalker/greet()
	to_chat(owner.current, span_notice("I feel a rare ability awaken within me. I am someone coveted as a champion by most gods. A dreamwalker. Not merely touched by Abyssor's dream, but able to pull materia and power from his realm effortlessly. I shall bring glory to my patron. My mind frays under the influence of dream entities, but surely my resolve is stronger than theirs."))
	to_chat(owner.current, span_notice("I manifest a piece of ritual chalk... It seems potent. I shall forge a great weapon, one with such power it shall dwarf all others. I must find a target to begin... It should be easy enough if I focus."))
	owner.announce_objectives()
	..()

/datum/antagonist/dreamwalker/proc/reset_dreamwalker_stats()
	var/mob/living/carbon/human/body = owner.current
	if(!body)
		return
	for(var/trait in traits_dreamwalker)
		ADD_TRAIT(body, trait, "[type]")

	body.faction |= "dream"
	body.ambushable = FALSE
	body.AddComponent(/datum/component/dreamwalker_repair)
	body.AddComponent(/datum/component/dreamwalker_mark)

	var/obj/item/ritechalk/chalk = new()
	body.put_in_hands(chalk)

	if(body.mind)
		body.add_spell(/datum/action/cooldown/spell/blink)
		body.add_spell(/datum/action/cooldown/spell/undirected/mark_target)
		body.add_spell(/datum/action/cooldown/spell/undirected/dream_jaunt)
		body.add_spell(/datum/action/cooldown/spell/dream_bind)
		body.add_spell(/datum/action/cooldown/spell/undirected/dream_trance)

	body.change_stat(STATKEY_STR, 5)
	body.change_stat(STATKEY_INT, 2)
	body.change_stat(STATKEY_CON, 2)
	body.change_stat(STATKEY_PER, 2)
	body.change_stat(STATKEY_SPD, 2)
	body.change_stat(STATKEY_END, 2)

/datum/outfit/job/roguetown/dreamwalker_armorrite
	name = "Dreamwalker Armor Rite"
	armor = /obj/item/clothing/armor/plate/full/dreamwalker
	pants = /obj/item/clothing/pants/platelegs/dreamwalker
	shoes = /obj/item/clothing/shoes/boots/armor/dreamwalker
	gloves = /obj/item/clothing/gloves/plate/dreamwalker
	head = /obj/item/clothing/head/helmet/bascinet/dreamwalker

/datum/outfit/job/roguetown/dreamwalker_armorrite/pre_equip(mob/living/carbon/human/H)
	..()
	var/list/items = list()
	items |= H.get_equipped_items(TRUE)
	for(var/I in items)
		H.dropItemToGround(I, TRUE)
	H.drop_all_held_items()
	armor = /obj/item/clothing/armor/plate/full/dreamwalker
	pants = /obj/item/clothing/pants/platelegs/dreamwalker
	shoes = /obj/item/clothing/shoes/boots/armor/dreamwalker
	gloves = /obj/item/clothing/gloves/plate/dreamwalker
	head = /obj/item/clothing/head/helmet/bascinet/dreamwalker
	neck = /obj/item/clothing/neck/bevor

/datum/component/dreamwalker_repair
	/// List of dream items being repaired
	var/list/repairing_items = list()
	/// List of timers for broken items being fully repaired
	var/list/repair_timers = list()
	/// Processing interval
	var/process_interval = 5 SECONDS
	/// Time of last processing
	var/last_process = 0
	var/next_armor_peel_process = 0
	var/next_armor_peel_interval = 1 MINUTES

/datum/component/dreamwalker_repair/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	to_chat(parent, span_userdanger("Your body pulses with strange dream energies."))
	RegisterSignal(parent, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_item_equipped))
	RegisterSignal(parent, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_item_unequipped))
	START_PROCESSING(SSprocessing, src)

/datum/component/dreamwalker_repair/Destroy()
	STOP_PROCESSING(SSprocessing, src)
	UnregisterSignal(parent, list(COMSIG_MOB_EQUIPPED_ITEM, COMSIG_MOB_UNEQUIPPED_ITEM))
	for(var/obj/item/I in repair_timers)
		deltimer(repair_timers[I])
	repair_timers = null
	repairing_items = null
	return ..()

/datum/component/dreamwalker_repair/process(delta_time)
	if(world.time < last_process + process_interval)
		return

	last_process = world.time

	for(var/obj/item/I in repairing_items)
		if(!I)
			continue
		if(I.obj_broken)
			if(!(I in repair_timers))
				start_full_repair(I)
			continue
		if(I.uses_integrity && I.max_integrity && I.get_integrity() < I.max_integrity)
			I.repair_damage(I.max_integrity * 0.01)
			I.update_icon()
		if(I.max_blade_int && I.blade_int < I.max_blade_int)
			I.add_bintegrity(I.max_blade_int * 0.01)

	if(world.time >= next_armor_peel_process)
		next_armor_peel_process = world.time + next_armor_peel_interval
		for(var/obj/item/I in repairing_items)
			if(istype(I, /obj/item/clothing))
				var/peel_count = I.vars["peel_count"]
				if(isnum(peel_count) && peel_count > 0)
					I.vars["peel_count"] = peel_count - 1
					I.visible_message(span_notice("The dream energies snap a peeled layer of [I] back in place."))
					break

/datum/component/dreamwalker_repair/proc/on_item_equipped(mob/user, obj/item/source, slot)
	SIGNAL_HANDLER
	if(source.item_flags & DREAM_ITEM)
		to_chat(parent, span_notice("The [source] pulses in your hands, dream energies passively repairing it."))
		add_item(source)

/datum/component/dreamwalker_repair/proc/on_item_unequipped(mob/user, obj/item/source, force, newloc, no_move, invdrop, silent)
	SIGNAL_HANDLER
	if(source.item_flags & DREAM_ITEM)
		to_chat(parent, span_notice("The [source] stops pulsing as it leaves your person."))
		remove_item(source)

/datum/component/dreamwalker_repair/proc/add_item(obj/item/I)
	if(I in repairing_items)
		return
	repairing_items += I
	if(I.obj_broken)
		start_full_repair(I)

/datum/component/dreamwalker_repair/proc/remove_item(obj/item/I)
	if(I in repairing_items)
		repairing_items -= I
		if(I in repair_timers)
			deltimer(repair_timers[I])
			repair_timers -= I

/datum/component/dreamwalker_repair/proc/start_full_repair(obj/item/I)
	if(I in repair_timers)
		deltimer(repair_timers[I])
	repair_timers[I] = addtimer(CALLBACK(src, PROC_REF(finish_full_repair), I), 1 MINUTES, TIMER_STOPPABLE)

/datum/component/dreamwalker_repair/proc/finish_full_repair(obj/item/I)
	if(I && (I in repairing_items) && I.obj_broken)
		I.visible_message(span_danger("The [I] melds back into a useable shape."))
		I.atom_fix()
		if(I.uses_integrity && I.max_integrity)
			I.update_integrity(max(1, round(I.max_integrity * 0.25)))
			I.update_icon()
	repair_timers -= I

/obj/structure/portal_jaunt
	name = "dream rift"
	desc = "A shimmering portal to another place. You hear countless whispers when you get close, seems dangerous."
	icon_state = "shitportal"
	icon = 'icons/roguetown/misc/structure.dmi'
	max_integrity = 250
	var/cooldown = 0
	var/uses = 0
	var/max_uses = 3
	var/turf/linked_turf

/obj/structure/portal_jaunt/Initialize()
	. = ..()
	cooldown = world.time + 4 SECONDS
	visible_message(span_warning("[src] shimmers into existence!"))
	playsound(src, 'sound/magic/charging_lightning.ogg', 50, TRUE)

/obj/structure/portal_jaunt/attack_hand(mob/user)
	if(!do_after(user, 1 SECONDS, target = src))
		to_chat(user, span_warning("I must stand still to use the portal."))
		return

	if(world.time < cooldown)
		var/time_left = (cooldown - world.time) * 0.1
		to_chat(user, span_warning("The portal is not stable yet. [time_left] seconds remaining."))
		return

	if(uses >= max_uses)
		to_chat(user, span_warning("The portal collapses as you touch it!"))
		qdel(src)
		return

	if(!linked_turf || !do_teleport(user, linked_turf))
		to_chat(user, span_warning("The portal flickers but nothing happens."))
		return

	uses++
	cooldown = world.time + 15 SECONDS
	visible_message(span_warning("[user] steps through [src]!"))
	playsound(src, 'sound/magic/lightning.ogg', 50, TRUE)

	if(uses >= max_uses)
		visible_message(span_danger("[src] collapses in on itself!"))
		QDEL_IN(src, 1)

/datum/component/dreamwalker_mark
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/mob/living/marked_target = null
	var/hit_count = 0
	var/max_hits = 5
	var/mark_duration = 30 MINUTES
	var/mark_start_time = 0
	var/mark_minimum_duration = 10 MINUTES
	var/datum/action/cooldown/spell/undirected/summon_marked/summon_spell = null

/datum/component/dreamwalker_mark/Initialize()
	if(!ishuman(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_MOB_ITEM_ATTACK, PROC_REF(on_attack))

/datum/component/dreamwalker_mark/Destroy()
	if(marked_target)
		UnregisterSignal(marked_target, COMSIG_LIVING_DEATH)
		marked_target = null

	if(summon_spell && ishuman(parent))
		var/mob/living/carbon/human/H = parent
		H.remove_spell(summon_spell)
		QDEL_NULL(summon_spell)
	return ..()

/datum/component/dreamwalker_mark/proc/set_marked_target(mob/living/target)
	if(marked_target)
		UnregisterSignal(marked_target, COMSIG_LIVING_DEATH)
		if(marked_target.has_status_effect(/datum/status_effect/dream_mark))
			marked_target.remove_status_effect(/datum/status_effect/dream_mark)

	marked_target = target
	hit_count = 0
	mark_start_time = 0

	if(marked_target)
		RegisterSignal(marked_target, COMSIG_LIVING_DEATH, PROC_REF(on_target_death))
		to_chat(parent, span_notice("You begin focusing your dream energy on [marked_target]."))

		if(summon_spell && ishuman(parent))
			var/mob/living/carbon/human/H = parent
			H.remove_spell(summon_spell)
			QDEL_NULL(summon_spell)

/datum/component/dreamwalker_mark/proc/on_attack(mob/user, mob/living/target, obj/item/I)
	SIGNAL_HANDLER

	if(!marked_target || target != marked_target)
		return

	if(!(I.item_flags & DREAM_ITEM))
		return

	if(marked_target.has_status_effect(/datum/status_effect/dream_mark))
		return

	hit_count++
	to_chat(user, span_notice("Your dream weapon strikes true. [hit_count]/[max_hits] hits to establish a connection."))

	if(hit_count >= max_hits)
		marked_target.apply_status_effect(/datum/status_effect/dream_mark, mark_duration)
		mark_start_time = world.time
		to_chat(user, span_warning("You've established a strong dream connection with [marked_target]! You'll be able to summon them in 10 minutes."))
		to_chat(marked_target, span_userdanger("You feel an unnatural connection forming with [user]. Your very essence feels tethered to them."))

		create_summon_spell()

/datum/component/dreamwalker_mark/proc/create_summon_spell()
	if(!marked_target || !ishuman(parent))
		return

	if(!marked_target.has_status_effect(/datum/status_effect/dream_mark))
		to_chat(parent, span_warning("Your connection with [marked_target] has faded before you could summon them!"))
		return

	summon_spell = new /datum/action/cooldown/spell/undirected/summon_marked
	var/mob/living/carbon/human/H = parent
	if(H)
		H.add_spell(summon_spell, override = TRUE)
		to_chat(H, span_warning("Your connection with [marked_target] is now strong enough to summon them!"))

/datum/component/dreamwalker_mark/proc/on_target_death()
	SIGNAL_HANDLER
	to_chat(parent, span_warning("Your connection with [marked_target] has been severed by death."))
	set_marked_target(null)

/datum/component/dreamwalker_mark/proc/can_summon()
	if(!marked_target)
		return FALSE

	if(!marked_target.has_status_effect(/datum/status_effect/dream_mark))
		return FALSE

	if(world.time < mark_start_time + mark_minimum_duration)
		var/time_left = ((mark_start_time + mark_minimum_duration) - world.time) * 0.1
		to_chat(parent, span_warning("The mark is not stable yet. [time_left] seconds remaining."))
		return FALSE

	return TRUE

/datum/status_effect/dream_mark
	id = "dream_mark"
	duration = 30 MINUTES
	alert_type = /atom/movable/screen/alert/status_effect/dream_mark

/datum/status_effect/dream_mark/on_apply()
	. = ..()
	to_chat(owner, span_userdanger("You feel your essence being pulled toward another realm. You've been marked by a dreamwalker!"))
	return TRUE

/datum/status_effect/dream_mark/on_remove()
	. = ..()
	to_chat(owner, span_notice("The connection to the dream realm fades."))

/atom/movable/screen/alert/status_effect/dream_mark
	name = "Dream Marked"
	desc = "A dreamwalker has established a connection to your essence. They may attempt to summon you once the connection stabilizes."
	icon_state = "dream_mark"

/datum/component/dream_weapon
	dupe_mode = COMPONENT_DUPE_UNIQUE
	var/effect_type = null
	var/cooldown_time
	var/next_use = 0

/datum/component/dream_weapon/Initialize(effect_type, cooldown_time)
	. = ..()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE

	src.effect_type = effect_type
	src.cooldown_time = cooldown_time

	RegisterSignal(parent, COMSIG_ITEM_ATTACK, PROC_REF(on_attack))
	RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equipped))

/datum/component/dream_weapon/proc/on_attack(obj/item/source, mob/living/target, mob/living/user, params)
	SIGNAL_HANDLER
	if(!effect_type)
		return

	if(world.time < next_use)
		return

	if(!ishuman(target))
		return

	var/mob/living/carbon/human/H = target

	switch(effect_type)
		if("fire")
			H.adjust_fire_stacks(4)
			spawn(0)
				H.IgniteMob()
			target.visible_message(span_warning("[source] ignites [target] with strange flame!"))
		if("frost")
			H.apply_status_effect(/datum/status_effect/debuff/frostbite)
			target.visible_message(span_warning("[source] freezes [target] with scalding ice!"))
		if("poison")
			if(H.reagents)
				H.reagents.add_reagent(/datum/reagent/berrypoison, 2)
				target.visible_message(span_warning("[source] injects [target] with vile ooze!"))

	next_use = world.time + cooldown_time

/datum/component/dream_weapon/proc/on_equipped(obj/item/source, mob/user, slot)
	SIGNAL_HANDLER
	if(HAS_TRAIT(user, TRAIT_DREAMWALKER))
		return

	to_chat(user, span_userdanger("The weapon rejects your touch, burning with dream energy!"))
	user.dropItemToGround(source, TRUE)

	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		spawn(0)
			H.apply_damage(10, BURN, pick(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM))
			H.adjust_fire_stacks(2)
			H.IgniteMob()

// Dream-crafted metal, used for the ritual weapon shaping.
/obj/item/ingot/sylveric
	name = "sylveric ingot"
	icon = 'icons/roguetown/items/ore.dmi'
	icon_state = "ingotsylveric"
	desc = "An impossibly light metal that seems to grow harder and heavier when pressured. Nothing seems to be able to shape this metal."

/obj/item/ingot/sylveric/examine(mob/user)
	. = ..()
	if(HAS_TRAIT(user, TRAIT_DREAMWALKER))
		. += span_notice("You can feel the metal resonate with your dream energy. If you strike another sylveric ingot with this one, you can shape it into a weapon.")

/obj/item/ingot/sylveric/attackby(obj/item/I, mob/living/user, params)
	if(istype(I, /obj/item/ingot/sylveric))
		if(!HAS_TRAIT(user, TRAIT_DREAMWALKER))
			return ..()

		if(I != user.get_active_held_item())
			return ..()

		if(!(src in user.contents) && !(isturf(src.loc) && in_range(src, user)))
			return ..()

		var/list/weapon_options = list(
			"Dreamreaver Greataxe" = image(icon = 'icons/roguetown/weapons/64.dmi', icon_state = "dreamaxeactive"),
			"Harmonious Spear" = image(icon = 'icons/roguetown/weapons/64.dmi', icon_state = "dreamspearactive"),
			"Oozing Sword" = image(icon = 'icons/roguetown/weapons/64.dmi', icon_state = "dreamswordactive"),
			"Thunderous Trident" = image(icon = 'icons/roguetown/weapons/64.dmi', icon_state = "dreamtriactive")
		)

		var/choice = show_radial_menu(user, src, weapon_options, require_near = TRUE, tooltips = TRUE)
		if(!choice)
			return

		to_chat(user, span_notice("You begin focusing your dream energy to shape the sylveric ingots into a [choice]..."))
		if(do_after(user, 10 SECONDS, target = src))
			var/obj/item/new_weapon
			switch(choice)
				if("Dreamreaver Greataxe")
					new_weapon = new /obj/item/weapon/axe/dreamscape/active(user.loc)
				if("Harmonious Spear")
					new_weapon = new /obj/item/weapon/polearm/spear/dreamscape/active(user.loc)
				if("Oozing Sword")
					new_weapon = new /obj/item/weapon/sword/long/greatsword/dreamscape/active(user.loc)
				if("Thunderous Trident")
					new_weapon = new /obj/item/weapon/polearm/spear/dreamscape_trident/active(user.loc)

			if(new_weapon)
				to_chat(user, span_notice("You shape the sylveric ingots into a [choice]."))
				user.put_in_hands(new_weapon)
				qdel(I)
				qdel(src)
		return
	return ..()

// Armor set
/obj/item/clothing/armor/plate/full/dreamwalker
	name = "otherworldly fullplate"
	desc = "Strange iridescent full plate. It reflects light as if covered in oily sheen."
	icon_state = "dreamplate"
	max_integrity = ARMOR_INT_CHEST_PLATE_ANTAG
	item_flags = DREAM_ITEM
	armor = ARMOR_PLATE

/obj/item/clothing/armor/plate/full/dreamwalker/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, null, 20 SECONDS)

/obj/item/clothing/pants/platelegs/dreamwalker
	max_integrity = ARMOR_INT_LEG_ANTAG
	name = "otherworldly legplate"
	desc = "Strange iridescent leg plate. It reflects light as if covered in shiny oil."
	icon_state = "dreamlegs"
	armor = ARMOR_PLATE
	item_flags = DREAM_ITEM
	prevent_crits = ALL_EXCEPT_BLUNT

/obj/item/clothing/pants/platelegs/dreamwalker/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, null, 20 SECONDS)

/obj/item/clothing/shoes/boots/armor/dreamwalker
	max_integrity = ARMOR_INT_SIDE_ANTAG
	name = "otherworldly boots"
	desc = "Strange iridescent plated boots. They shimmer with liquid color."
	icon_state = "dreamboots"
	armor = ARMOR_PLATE
	item_flags = DREAM_ITEM

/obj/item/clothing/shoes/boots/armor/dreamwalker/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, null, 20 SECONDS)

/obj/item/clothing/gloves/plate/dreamwalker
	name = "otherworldly gauntlets"
	desc = "Strange iridescent plated gauntlets. They flash with dreamlight."
	icon_state = "dreamgauntlets"
	max_integrity = ARMOR_INT_SIDE_ANTAG
	item_flags = DREAM_ITEM

/obj/item/clothing/gloves/plate/dreamwalker/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, null, 20 SECONDS)

/obj/item/clothing/head/helmet/bascinet/dreamwalker
	name = "otherworldly squid helm"
	desc = "An alien-looking helm that ripples like oil."
	adjustable = CAN_CADJUST
	icon_state = "dreamsquidhelm"
	max_integrity = ARMOR_INT_HELMET_ANTAG
	item_flags = DREAM_ITEM
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/32x48/head.dmi'
	block2add = null
	worn_x_dimension = 32
	worn_y_dimension = 48
	body_parts_covered = FULL_HEAD
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH

/obj/item/clothing/head/helmet/bascinet/dreamwalker/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, null, 20 SECONDS)

// Dream weapons
/obj/item/weapon/axe/dreamscape
	name = "otherworldly greataxe"
	desc = "A strange greataxe made of otherworldly metal."
	icon_state = "dreamaxe"
	item_flags = DREAM_ITEM
	max_integrity = 275
	force = 20
	force_wielded = 35
	wdefense = 6
	gripped_intents = list(/datum/intent/axe/cut,/datum/intent/axe/chop)

/obj/item/weapon/axe/dreamscape/active
	icon_state = "dreamaxeactive"
	max_integrity = 500
	force = 25
	force_wielded = 40

/obj/item/weapon/axe/dreamscape/active/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, "fire", 20 SECONDS)

/obj/item/weapon/polearm/spear/dreamscape
	name = "otherworldly spear"
	desc = "A strange spear of bone-like metal."
	icon_state = "dreamspear"
	item_flags = DREAM_ITEM
	max_integrity = 240
	force = 18
	force_wielded = 28
	wdefense = 8
	gripped_intents = list(POLEARM_THRUST, SPEAR_CUT, POLEARM_BASH)

/obj/item/weapon/polearm/spear/dreamscape/active
	icon_state = "dreamspearactive"
	max_integrity = 380
	force = 22
	force_wielded = 32
	wdefense = 9

/obj/item/weapon/polearm/spear/dreamscape/active/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, "frost", 40 SECONDS)

/obj/item/weapon/sword/long/greatsword/dreamscape
	name = "otherworldly sword"
	desc = "A strange reflective greatsword. It hums with dreamstuff."
	icon_state = "dreamsword"
	force = 22
	force_wielded = 30
	max_integrity = 275
	item_flags = DREAM_ITEM
	wdefense = 4
	possible_item_intents = list(/datum/intent/sword/cut,/datum/intent/sword/chop,/datum/intent/stab, /datum/intent/sword/strike)

/obj/item/weapon/sword/long/greatsword/dreamscape/active
	icon_state = "dreamswordactive"
	max_integrity = 480
	force = 28
	force_wielded = 34
	wdefense = 5

/obj/item/weapon/sword/long/greatsword/dreamscape/active/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, "poison", 20 SECONDS)

/obj/item/weapon/polearm/spear/dreamscape_trident
	name = "otherworldly trident"
	desc = "A strange trident. It feels like it shouldn't be effective, yet whispers promise power."
	icon_state = "dreamtri"
	item_flags = DREAM_ITEM
	max_integrity = 260
	throwforce = 40
	force = 28
	force_wielded = 22
	wdefense = 4
	minstr = 8
	var/shockwave_cooldown = 0
	var/shockwave_cooldown_interval = 1 MINUTES
	var/shockwave_divisor = 3
	var/shockwave_damage = FALSE

/obj/item/weapon/polearm/spear/dreamscape_trident/active
	name = "iridescent trident"
	desc = "A strange trident glimmering with oily hues."
	icon_state = "dreamtriactive"
	max_integrity = 480
	throwforce = 50
	force = 32
	force_wielded = 24
	wdefense = 5
	shockwave_cooldown_interval = 30 SECONDS
	shockwave_divisor = 2
	shockwave_damage = TRUE

/obj/item/weapon/polearm/spear/dreamscape_trident/active/Initialize()
	. = ..()
	AddComponent(/datum/component/dream_weapon, null, 20 SECONDS)
