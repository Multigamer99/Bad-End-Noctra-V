/datum/action/cooldown/spell/blink
	name = "Blink"
	desc = "Teleport to a targeted location within your field of view. Limited to a range of 5 tiles."
	button_icon_state = "rune6"
	invocation = "Nictare Teleporto!"
	invocation_type = INVOCATION_SHOUT
	charge_time = 3 SECONDS
	charge_drain = 1
	charge_slowdown = 2
	cooldown_time = 10 SECONDS
	spell_cost = 30
	cast_range = 5
	self_cast_possible = TRUE
	var/phase = /obj/effect/temp_visual/blink

/obj/effect/temp_visual/blink
	icon = 'icons/effects/effects.dmi'
	icon_state = "hierophant_blast"
	name = "teleportation magic"
	desc = "Get out of the way!"
	randomdir = FALSE
	duration = 4 SECONDS
	layer = ABOVE_MOB_LAYER
	light_outer_range = 2
	light_color = COLOR_PALE_PURPLE_GRAY

/obj/effect/temp_visual/blink/Initialize(mapload, new_caster)
	. = ..()
	var/turf/src_turf = get_turf(src)
	playsound(src_turf, 'sound/magic/blink.ogg', 65, TRUE, -5)

/datum/action/cooldown/spell/blink/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	var/mob/living/user = owner
	var/turf/T = get_turf(cast_on)
	var/turf/start = get_turf(user)
	if(!T || !start)
		to_chat(user, span_warning("Invalid target location!"))
		return . | SPELL_CANCEL_CAST
	var/area/target_area = get_area(T)
	if(target_area && (target_area.area_flags & NO_TELEPORT))
		to_chat(user, span_warning("I can't teleport here!"))
		return . | SPELL_CANCEL_CAST
	if(T.z != start.z)
		to_chat(user, span_warning("I can only teleport on the same plane!"))
		return . | SPELL_CANCEL_CAST
	if(istransparentturf(T))
		to_chat(user, span_warning("I cannot teleport to the open air!"))
		return . | SPELL_CANCEL_CAST
	if(T.density)
		to_chat(user, span_warning("I cannot teleport into a wall!"))
		return . | SPELL_CANCEL_CAST
	var/list/turf_list = getline(start, T)
	if(length(turf_list) > 0)
		turf_list.len--
	for(var/turf/turf in turf_list)
		if(turf.density)
			to_chat(user, span_warning("I cannot blink through walls!"))
			return . | SPELL_CANCEL_CAST
	return .

/datum/action/cooldown/spell/blink/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	var/turf/T = get_turf(cast_on)
	var/turf/start = get_turf(user)
	if(!T || !start)
		return

	user.visible_message(
		span_warning("<b>[user]'s body begins to shimmer with arcane energy as [user.p_they()] prepare[user.p_s()] to blink!</b>"),
		span_notice("<b>I focus my arcane energy, preparing to blink across space!</b>")
	)

	var/obj/spot_one = new phase(start, user.dir)
	var/obj/spot_two = new phase(T, user.dir)

	spot_one.Beam(spot_two, "purple_lightning", time = 1.5 SECONDS)
	playsound(T, 'sound/magic/blink.ogg', 25, TRUE)

	if(user.buckled)
		user.buckled.unbuckle_mob(user, TRUE)

	if(!do_teleport(user, T, channel = TELEPORT_CHANNEL_MAGIC))
		reset_spell_cooldown()
		return

	user.visible_message(
		span_danger("<b>[user] vanishes in a mysterious purple flash!</b>"),
		span_notice("<b>I blink through space in an instant!</b>")
	)

/datum/action/cooldown/spell/undirected/mark_target
	name = "Mark Target"
	desc = "Marks a random target for pursuit. Track them, extract metal from their mind with the -TRACK- spell you'll gain to complete your vision. Hit them with a dream weapon to summon them to you later."
	button_icon_state = "dream_mark"
	invocation = "Dream... manifest my vision, bend to my will."
	invocation_type = INVOCATION_WHISPER
	charge_time = 1.5 SECONDS
	charge_drain = 1
	charge_slowdown = 1
	cooldown_time = 25 MINUTES
	spell_cost = 75

	var/static/list/valid_target_roles = list(
		"Orthodoxist",
		"Absolver",
		"Templar",
		"Dungeoneer",
		"Sergeant",
		"Men-at-arms",
		"Knight",
		"Squire",
		"Mercenary",
		"Warden"
	)

/datum/action/cooldown/spell/undirected/mark_target/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	var/mob/living/user = owner
	var/datum/component/dreamwalker_mark/mark_component = user?.GetComponent(/datum/component/dreamwalker_mark)
	var/mob/living/current_mark = mark_component?.marked_target
	if(!length(get_valid_targets(user, current_mark)))
		to_chat(user, span_warning("No valid targets found."))
		return . | SPELL_CANCEL_CAST
	return .

/datum/action/cooldown/spell/undirected/mark_target/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	if(!user)
		return

	var/datum/component/dreamwalker_mark/mark_component = user.GetComponent(/datum/component/dreamwalker_mark)
	if(!mark_component)
		mark_component = user.AddComponent(/datum/component/dreamwalker_mark)

	var/list/valid_targets = get_valid_targets(user, mark_component.marked_target)
	if(!length(valid_targets))
		to_chat(user, span_warning("No valid targets found."))
		return

	to_chat(user, span_notice("The spell seeks out a worthy target..."))

	var/mob/living/target = pick(valid_targets)
	mark_component.set_marked_target(target)

	user.add_spell(/datum/action/cooldown/spell/undirected/track_mark, override = TRUE)

	if(target && target != user)
		user.visible_message(
			span_warning("[user] traces a glowing symbol in the air marking [target]."),
			span_notice("You mark [target] for pursuit.")
		)

/datum/action/cooldown/spell/undirected/mark_target/proc/get_valid_targets(mob/living/user, mob/living/current_mark)
	var/list/valid_targets = list()
	if(!user)
		return valid_targets

	for(var/mob/living/carbon/human/player in GLOB.player_list)
		if(player == user || player.stat == DEAD || !player.mind || !player.client || player == current_mark)
			continue
		if(player.mind.assigned_role in valid_target_roles)
			valid_targets += player

	return valid_targets

/datum/action/cooldown/spell/undirected/track_mark
	name = "Track Marked Target"
	desc = "Track your mark. They must be downed for you to extract metal. Cast this spell whilst adjacent to do so."
	button_icon_state = "dream_track"
	invocation = "Dream... Find them."
	invocation_type = INVOCATION_WHISPER
	charge_required = FALSE
	cooldown_time = 2 SECONDS
	spell_cost = 75

/datum/action/cooldown/spell/undirected/track_mark/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	if(!user)
		return

	var/datum/component/dreamwalker_mark/mark_component = user.GetComponent(/datum/component/dreamwalker_mark)
	if(!mark_component || !mark_component.marked_target)
		to_chat(user, span_warning("The mark has faded!"))
		user.remove_spell(src)
		return

	var/mob/living/marked_target = mark_component.marked_target
	var/turf/user_turf = get_turf(user)
	var/turf/target_turf = get_turf(marked_target)

	if(user_turf.z != target_turf.z)
		var/z_direction = "unknown"
		if(user_turf.z > target_turf.z)
			z_direction = "below"
		else
			z_direction = "above"
		to_chat(user, span_notice("The target is on a level [z_direction] you."))
	else
		var/distance = get_dist(user, marked_target)
		var/direction = get_dir(user, marked_target)

		if(distance == 0)
			to_chat(user, span_notice("The target is here!"))
		else
			var/direction_text = dir2text(direction)
			to_chat(user, span_notice("The target is [distance] tiles away to the [direction_text]."))

	if(user.Adjacent(marked_target) && !(marked_target.mobility_flags & MOBILITY_STAND) && !marked_target.buckled)
		to_chat(user, span_notice("The target is vulnerable. You begin to pull metal from their mind..."))

		if(do_after(user, 1 SECONDS, target = marked_target))
			marked_target.Stun(10)
			new /obj/item/ingot/sylveric(get_turf(user))
			marked_target.apply_status_effect(/datum/status_effect/debuff/dreamfiend_curse)
			to_chat(user, span_notice("You successfully manifest an ingot of strange metal using your target's psyche."))

			mark_component.set_marked_target(null)
			user.remove_spell(src)
		else
			to_chat(user, span_warning("You were interrupted."))

/datum/action/cooldown/spell/undirected/dream_jaunt
	name = "Dream Jaunt"
	desc = "Teleports you to a random coastal area after a short channel, leaving a temporary portal behind. You may be followed."
	button_icon_state = "dream_jaunt"
	invocation = "Whisper of the dream..."
	invocation_type = INVOCATION_WHISPER
	charge_time = 2 SECONDS
	charge_slowdown = 1
	cooldown_time = 15 MINUTES

/datum/action/cooldown/spell/undirected/dream_jaunt/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	if(!user)
		return

	var/turf/original_turf = get_turf(user)
	if(!original_turf)
		return

	var/static/list/possible_areas = list(
		/area/outdoors/beach,
		/area/outdoors/coast
	)
	var/area/destination_area = GLOB.areas_by_type[pick(possible_areas)]
	if(!destination_area)
		return

	var/list/safe_turfs = list()
	for(var/turf/T in get_area_turfs(destination_area))
		if(istype(T, /turf/open/water/ocean/deep))
			continue
		if(T.density)
			continue
		var/valid = TRUE
		for(var/atom/movable/AM in T)
			if(AM.density && AM.anchored)
				valid = FALSE
				break
		if(valid)
			safe_turfs += T

	if(!safe_turfs.len)
		return

	var/turf/destination = pick(safe_turfs)

	var/obj/structure/portal_jaunt/portal = new(original_turf)
	portal.linked_turf = destination

	if(do_teleport(user, destination))
		return

	qdel(portal)
	reset_spell_cooldown()

/datum/action/cooldown/spell/undirected/summon_marked
	name = "Summon Marked"
	desc = "Summons your marked target to your location, leaving a temporary portal behind. Requires the target to be marked for at least 10 minutes."
	button_icon_state = "dream_summon"
	invocation = "I invoke the dream connection, come to me!"
	invocation_type = INVOCATION_WHISPER
	charge_time = 1.5 SECONDS
	charge_slowdown = 1
	cooldown_time = 30 SECONDS

/datum/action/cooldown/spell/undirected/summon_marked/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	var/mob/living/user = owner
	var/datum/component/dreamwalker_mark/mark_component = user?.GetComponent(/datum/component/dreamwalker_mark)
	if(!mark_component || !mark_component.marked_target)
		to_chat(user, span_warning("You have no target marked for summoning!"))
		return . | SPELL_CANCEL_CAST
	if(!mark_component.can_summon())
		return . | SPELL_CANCEL_CAST
	var/mob/living/target = mark_component.marked_target
	if(!target.has_status_effect(/datum/status_effect/dream_mark))
		to_chat(user, span_warning("Your connection with [target] has faded!"))
		return . | SPELL_CANCEL_CAST
	if(target.stat == DEAD)
		to_chat(user, span_warning("[target] is dead and cannot be summoned!"))
		return . | SPELL_CANCEL_CAST
	return .

/datum/action/cooldown/spell/undirected/summon_marked/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	if(!user)
		return

	var/datum/component/dreamwalker_mark/mark_component = user.GetComponent(/datum/component/dreamwalker_mark)
	if(!mark_component || !mark_component.marked_target)
		return

	var/mob/living/target = mark_component.marked_target
	if(!target)
		return

	to_chat(target, span_userdanger("YOU CAN FEEL THE DREAMWALKER BEGIN TO SUMMON YOU BY FORCE."))
	if(!do_after(user, 20 SECONDS, target = user))
		to_chat(user, span_warning("You must stand still to summon your target!"))
		return

	var/turf/original_turf = get_turf(target)
	var/turf/destination = get_turf(user)
	if(!original_turf || !destination)
		return

	var/obj/structure/portal_jaunt/portal = new(original_turf)
	portal.linked_turf = destination

	if(do_teleport(target, destination))
		to_chat(user, span_warning("You summon [target] to your location!"))
		to_chat(target, span_userdanger("You're violently pulled through the dream realm to [user]'s location!"))
		target.remove_status_effect(/datum/status_effect/dream_mark)
		mark_component.set_marked_target(null)
		return

	qdel(portal)
	reset_spell_cooldown()

/datum/action/cooldown/spell/dream_bind
	name = "Dream Bind"
	desc = "Bind a dream item to your soul, allowing you to summon it at will. Cast on a dream item to bind it, or cast on anything else to summon your bound item."
	button_icon_state = "dream_bind"
	invocation = "From dream to hand..."
	invocation_type = INVOCATION_WHISPER
	charge_time = 0.5 SECONDS
	cooldown_time = 10 SECONDS
	var/obj/item/bound_item = null

/datum/action/cooldown/spell/dream_bind/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return .
	if(!istype(cast_on, /obj/item) && !bound_item)
		owner.balloon_alert(owner, "No bound item!")
		return . | SPELL_CANCEL_CAST
	if(istype(cast_on, /obj/item))
		var/obj/item/target_item = cast_on
		if(!(target_item.item_flags & DREAM_ITEM) && !bound_item)
			owner.balloon_alert(owner, "No dream item to bind!")
			return . | SPELL_CANCEL_CAST
	return .

/datum/action/cooldown/spell/dream_bind/cast(atom/cast_on)
	. = ..()
	var/mob/living/user = owner
	if(!user)
		return
	var/atom/target = cast_on

	if(istype(target, /obj/item))
		var/obj/item/dream_item = target
		if(dream_item.item_flags & DREAM_ITEM)
			bound_item = dream_item
			to_chat(user, span_notice("You bind [bound_item] to your soul. You can now summon it at will."))
			return

	if(!bound_item)
		to_chat(user, span_warning("You don't have any dream item bound!"))
		return

	if(bound_item.loc == user)
		to_chat(user, span_notice("[bound_item] is already in your possession."))
		return

	if(QDELETED(bound_item))
		to_chat(user, span_warning("Your bound item has been destroyed!"))
		bound_item = null
		return

	bound_item.forceMove(get_turf(user))
	user.put_in_hands(bound_item)
	to_chat(user, span_notice("You summon [bound_item] to your hand."))

/datum/action/cooldown/spell/undirected/dream_trance
	name = "Dream Trance"
	desc = "Draw dream energy into your being to banish any fatigue."
	button_icon_state = "dream_lotus"
	invocation = "Humm..."
	invocation_type = INVOCATION_WHISPER
	charge_required = FALSE
	cooldown_time = 10 SECONDS

/datum/action/cooldown/spell/undirected/dream_trance/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!H)
		return

	to_chat(H, span_info("I begin meditating."))
	while(TRUE)
		if(do_after(H, 15 SECONDS, target = H))
			H.adjust_energy(0.2 * H.max_energy)
			H.apply_status_effect(/datum/status_effect/buff/healing, 5)
		else
			to_chat(H, span_info("I must remain still to focus energies and recover."))
			break
