/obj/structure/pillory
	name = "pillory"
	desc = "To keep the criminals locked!"
	icon_state = "pillory_single"
	icon = 'modular_nova/modules/primitive_structures/icons/pillory.dmi'
	can_buckle = TRUE
	max_buckled_mobs = 1
	buckle_lying = 0
	buckle_prevents_pull = TRUE
	anchored = TRUE
	density = TRUE
	layer = ABOVE_MOB_LAYER
	var/base_icon = "pillory_single"
	var/latched = FALSE
	var/mutable_appearance/pillory_hand_overlay = null

/obj/structure/pillory/examine(mob/user)
	. = ..()
	. += span_info("Right clicking the pillory will latch it onto the head and hands of anyone on the same turf.")
	. += "It is [latched ? "latched" : "unlatched"]."

/obj/structure/pillory/double
/obj/structure/pillory/double
	icon_state = "pillory_double"

/obj/structure/pillory/reinforced
	icon_state = "pillory_reinforced"

/obj/structure/pillory/crafted

/obj/structure/pillory/Initialize()
	LAZYINITLIST(buckled_mobs)
	. = ..()

/obj/structure/pillory/attack_hand(mob/living/user, list/modifiers)
	if(!LAZYACCESS(modifiers, RIGHT_CLICK))
		return ..()
	. = ..()
	if(!buckled_mobs.len)
		to_chat(user, span_warning("What's the point of latching it with nobody inside?"))
		return
	if(user in buckled_mobs)
		to_chat(user, span_warning("I can't reach the latch!"))
		return
	togglelatch(user)

/obj/structure/pillory/proc/togglelatch(mob/living/user, silent)
	user.changeNext_move(CLICK_CD_MELEE)
	if(latched)
		user.visible_message(span_warning("[user] unlatches [src]."), \
			span_notice("I unlatch [src]."))
		playsound(src, 'sound/items/tools/crowbar.ogg', 100)
		latched = FALSE
		icon_state = base_icon
		remove_hand_overlay()
		update_icon()
	else
		user.visible_message(span_warning("[user] latches [src]."), \
			span_notice("I latch [src]."))
		playsound(src, 'sound/items/tools/crowbar.ogg', 100)
		latched = TRUE
		icon_state = base_icon
		if(buckled_mobs.len)
			var/mob/living/carbon/human/H = pick(buckled_mobs)
			if(istype(H))
				apply_hand_overlay(H)
		update_icon()

/obj/structure/pillory/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	if (!anchored)
		return FALSE

	if (!istype(M, /mob/living/carbon/human))
		to_chat(usr, span_warning("It doesn't look like [M.p_they()] can fit into this properly!"))
		return FALSE // Can't hold non-humanoids

	return ..(M, force, FALSE)

/obj/structure/pillory/post_buckle_mob(mob/living/M)
	if (!istype(M, /mob/living/carbon/human))
		return

	var/mob/living/carbon/human/H = M

	if (H.dna)
		if (H.dna.species)
			var/datum/species/S = H.dna.species

			if (istype(S))
				// Simplified: no species-specific offsets
				icon_state = base_icon
				latched = TRUE
				H.layer = BELOW_MOB_LAYER
				RegisterSignal(H, COMSIG_USER_PRE_ITEM_ATTACK, TYPE_PROC_REF(/mob/living, _pillory_block_item_attack))
				RegisterSignal(H, COMSIG_USER_PRE_ITEM_ATTACK_SECONDARY, TYPE_PROC_REF(/mob/living, _pillory_block_item_attack_secondary))
				apply_hand_overlay(H)
				update_icon()
			else
				unbuckle_all_mobs()
		else
			unbuckle_all_mobs()
	else
		unbuckle_all_mobs()

	..()

/obj/structure/pillory/post_unbuckle_mob(mob/living/M)
	M.layer = MOB_LAYER
	icon_state = base_icon
	remove_hand_overlay()
	UnregisterSignal(M, list(COMSIG_USER_PRE_ITEM_ATTACK, COMSIG_USER_PRE_ITEM_ATTACK_SECONDARY))
	update_icon()
	..()

/obj/structure/pillory/proc/apply_hand_overlay(mob/living/carbon/human/H)
	remove_hand_overlay()
	pillory_hand_overlay = mutable_appearance(icon, "[base_icon]-pillory_hand_overlay", layer = layer)
	if(H.skin_tone)
		pillory_hand_overlay.color = skintone2hex(H.skin_tone)
	H.add_overlay(pillory_hand_overlay)
	update_icon()

/obj/structure/pillory/proc/remove_hand_overlay()
	if(!pillory_hand_overlay)
		return
	// Need to find the buckled human to remove overlay from them
	for(var/mob/living/carbon/human/H in buckled_mobs)
		H.cut_overlay(pillory_hand_overlay)
		break
	pillory_hand_overlay = null
	update_icon()

/obj/structure/pillory/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(!latched)
		return ..()
	if(buckled_mob == user)
		buckled_mob.visible_message(span_warning("[buckled_mob] struggles in [src], trying to get the latch off!"))
		if(do_after(buckled_mob, 60 SECONDS))
			buckled_mob.visible_message(span_warning("[buckled_mob] forces [src]'s latch open!"))
			latched = FALSE
			return ..()
		else
			return null
	latched = FALSE //we pull them free, which implies unlatching
	return ..()

/obj/structure/pillory/hitby(atom/movable/AM, skipcatch, hitpush, blocked, datum/thrownthing/throwingdatum, damage_flag)
	if(!has_buckled_mobs())
		return ..()

	var/mob/living/victim = pick(buckled_mobs)
	return AM.throw_impact(victim, throwingdatum)

/mob/living/proc/_pillory_block_item_attack(obj/item/src, atom/target, list/modifiers, list/attack_modifiers)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/mob/living/proc/_pillory_block_item_attack_secondary(obj/item/src, atom/target, list/modifiers, list/attack_modifiers)
	return COMPONENT_SECONDARY_CANCEL_ATTACK_CHAIN



