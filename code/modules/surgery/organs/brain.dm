/obj/item/organ/brain
	name = "brain"
	desc = ""
	icon_state = "brain"
	throw_speed = 1
	throw_range = 5
	layer = ABOVE_MOB_LAYER
	zone = BODY_ZONE_PRECISE_SKULL
	slot = ORGAN_SLOT_BRAIN
	organ_flags = ORGAN_VITAL
	attack_verb = list("attacked", "slapped", "whacked")

	///The brain's organ variables are significantly more different than the other organs, with half the decay rate for balance reasons, and twice the maxHealth
	decay_factor = STANDARD_ORGAN_DECAY	/ 2		//30 minutes of decaying to result in a fully damaged brain, since a fast decay rate would be unfun gameplay-wise

	maxHealth	= BRAIN_DAMAGE_DEATH
	low_threshold = 45
	high_threshold = 120

	var/suicided = FALSE
	var/mob/living/brain/brainmob = null
	var/brain_death = FALSE //if the brainmob was intentionally killed by attacking the brain after removal, or by severe braindamage
	var/decoy_override = FALSE	//if it's a fake brain with no brainmob assigned. Feedback messages will be faked as if it does have a brainmob. See changelings & dullahans.
	//two variables necessary for calculating whether we get a brain trauma or not
	var/damage_delta = 0


	var/list/datum/brain_trauma/traumas = list()

/obj/item/organ/brain/Insert(mob/living/carbon/C, special = FALSE, drop_if_replaced = FALSE, no_id_transfer = FALSE)
	. = ..()

	name = "brain"

	if(brainmob)
		if(brainmob.mind)
			brainmob.mind.transfer_to(C)
		else
			C.key = brainmob.key

		QDEL_NULL(brainmob)

	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		BT.owner = owner
		BT.on_gain()

	//Update the body's icon so it doesnt appear debrained anymore
	C.update_body()

/obj/item/organ/brain/Remove(mob/living/carbon/C, special = 0, no_id_transfer = FALSE)
	. = ..()
	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		BT.on_lose(TRUE)
		BT.owner = null

	if((!gc_destroyed || (owner && !owner.gc_destroyed)) && !no_id_transfer)
		transfer_identity(C)
	C.update_body()

/obj/item/organ/brain/prepare_eat(mob/living/carbon/human/H)
	if( HAS_TRAIT(H, TRAIT_ROTMAN))//braaaaaains... otherwise, too important to eat.
		return ..()
	return FALSE

/obj/item/organ/brain/proc/transfer_identity(mob/living/L)
	if(brainmob || decoy_override)
		return
	if(!L.mind)
		return
	brainmob = new(src)
	brainmob.name = L.real_name
	brainmob.real_name = L.real_name
	brainmob.timeofhostdeath = L.timeofdeath
	brainmob.suiciding = suicided
	if(L.has_dna())
		var/mob/living/carbon/C = L
		if(!brainmob.stored_dna)
			brainmob.stored_dna = new /datum/dna/stored(brainmob)
		C.dna.copy_dna(brainmob.stored_dna)
	if(L.mind?.current)
		L.mind.transfer_to(brainmob)
//	to_chat(brainmob, "<span class='notice'>I feel slightly disoriented. That's normal when you're just a brain.</span>")

/obj/item/organ/brain/attackby(obj/item/O, mob/user, params)
	user.changeNext_move(CLICK_CD_MELEE)

	if((organ_flags & ORGAN_FAILING) && O.is_drainable()) //attempt to heal the brain
		. = TRUE //don't do attack animation.
		if(brain_death || brainmob?.health <= HEALTH_THRESHOLD_DEAD) //if the brain is fucked anyway, do nothing
			to_chat(user, "<span class='warning'>[src] is far too damaged, there's nothing else we can do for it!</span>")
			return

		user.visible_message("<span class='notice'>[user] starts to pour the contents of [O] onto [src].</span>", "<span class='notice'>I start to slowly pour the contents of [O] onto [src].</span>")
		if(!do_after(user, 6 SECONDS, src, (IGNORE_HELD_ITEM)))
			to_chat(user, "<span class='warning'>I failed to pour [O] onto [src]!</span>")
			return

		user.visible_message("<span class='notice'>[user] pours the contents of [O] onto [src], causing it to reform its original shape and turn a slightly brighter shade of pink.</span>", "<span class='notice'>I pour the contents of [O] onto [src], causing it to reform its original shape and turn a slightly brighter shade of pink.</span>")
		setOrganDamage(damage - (0.05 * maxHealth))	//heals a small amount, and by using "setorgandamage", we clear the failing variable if that was up
		O.reagents.clear_reagents()
		return

	if(brainmob) //if we aren't trying to heal the brain, pass the attack onto the brainmob.
		O.attack(brainmob, user) //Oh noooeeeee

	if(O.force != 0 && !(O.item_flags & NOBLUDGEON))
		setOrganDamage(maxHealth) //fails the brain as the brain was attacked, they're pretty fragile.

/obj/item/organ/brain/examine(mob/user)
	. = ..()

	if(suicided)
		. += "<span class='info'>It's started turning slightly grey. They must not have been able to handle the stress of it all.</span>"
	else if(brainmob)
		if(brainmob.get_ghost(FALSE, TRUE))
			if(brain_death || brainmob.health <= HEALTH_THRESHOLD_DEAD)
				. += "<span class='info'>It's lifeless and severely damaged.</span>"
			else if(organ_flags & ORGAN_FAILING)
				. += "<span class='info'>It seems to still have a bit of energy within it, but it's rather damaged... You may be able to restore it with some <b>mannitol</b>.</span>"
			else
				. += "<span class='info'>I can feel the small spark of life still left in this one.</span>"
		else if(organ_flags & ORGAN_FAILING)
			. += "<span class='info'>It seems particularly lifeless and is rather damaged... You may be able to restore it with some <b>mannitol</b> incase it becomes functional again later.</span>"
		else
			. += "<span class='info'>This one seems particularly lifeless. Perhaps it will regain some of its luster later.</span>"
	else
		if(decoy_override)
			if(organ_flags & ORGAN_FAILING)
				. += "<span class='info'>It seems particularly lifeless and is rather damaged... You may be able to restore it with some <b>mannitol</b> incase it becomes functional again later.</span>"
			else
				. += "<span class='info'>This one seems particularly lifeless. Perhaps it will regain some of its luster later.</span>"
		else
			. += "<span class='info'>This one is completely devoid of life.</span>"

/obj/item/organ/brain/attack(mob/living/carbon/C, mob/user)
	if(!istype(C))
		return ..()

	add_fingerprint(user)

	if(user.zone_selected != BODY_ZONE_HEAD)
		return ..()

	var/target_has_brain = C.getorgan(/obj/item/organ/brain)

	if(!target_has_brain && C.is_eyes_covered())
		to_chat(user, "<span class='warning'>You're going to need to remove [C.p_their()] head cover first!</span>")
		return

//since these people will be dead M != usr

	if(!target_has_brain)
		if(!C.get_bodypart(BODY_ZONE_HEAD) || !user.temporarilyRemoveItemFromInventory(src))
			return
		var/msg = "[C] has [src] inserted into [C.p_their()] head by [user]."
		if(C == user)
			msg = "[user] inserts [src] into [user.p_their()] head!"

		C.visible_message("<span class='danger'>[msg]</span>",
						"<span class='danger'>[msg]</span>")

		if(C != user)
			to_chat(C, "<span class='notice'>[user] inserts [src] into your head.</span>")
			to_chat(user, "<span class='notice'>I insert [src] into [C]'s head.</span>")
		else
			to_chat(user, "<span class='notice'>I insert [src] into your head.</span>"	)

		Insert(C)
	else
		..()

/obj/item/organ/brain/Destroy() //copypasted from MMIs.
	if(brainmob)
		QDEL_NULL(brainmob)
	QDEL_LIST(traumas)
	return ..()

/obj/item/organ/brain/on_life()
	if(damage >= BRAIN_DAMAGE_DEATH) //rip
		to_chat(owner, "<span class='danger'>The last spark of life in your brain fizzles out...</span>")
		owner.death()
		brain_death = TRUE

/obj/item/organ/brain/check_damage_thresholds(mob/M)
	. = ..()
	//if we're not more injured than before, return without gambling for a trauma
	if(damage <= prev_damage)
		return
	damage_delta = damage - prev_damage
	if(damage > BRAIN_DAMAGE_MILD)
		if(prob(damage_delta * (1 + max(0, (damage - BRAIN_DAMAGE_MILD)/100)))) //Base chance is the hit damage; for every point of damage past the threshold the chance is increased by 1% //learn how to do your bloody math properly goddamnit
			gain_trauma_type(BRAIN_TRAUMA_MILD)
	if(damage > BRAIN_DAMAGE_SEVERE)
		if(prob(damage_delta * (1 + max(0, (damage - BRAIN_DAMAGE_SEVERE)/100)))) //Base chance is the hit damage; for every point of damage past the threshold the chance is increased by 1%
			if(prob(20))
				gain_trauma_type(BRAIN_TRAUMA_SPECIAL)
			else
				gain_trauma_type(BRAIN_TRAUMA_SEVERE)

	if (owner)
		if(owner.stat < UNCONSCIOUS) //conscious or soft-crit
			var/brain_message
			if(prev_damage < BRAIN_DAMAGE_MILD && damage >= BRAIN_DAMAGE_MILD)
				brain_message = "<span class='warning'>I feel lightheaded.</span>"
			else if(prev_damage < BRAIN_DAMAGE_SEVERE && damage >= BRAIN_DAMAGE_SEVERE)
				brain_message = "<span class='warning'>I feel less in control of your thoughts.</span>"
			else if(prev_damage < (BRAIN_DAMAGE_DEATH - 20) && damage >= (BRAIN_DAMAGE_DEATH - 20))
				brain_message = "<span class='warning'>I can feel your mind flickering on and off...</span>"

			if(.)
				. += "\n[brain_message]"
			else
				return brain_message

/obj/item/organ/brain/alien
	name = "alien brain"
	desc = ""
	icon_state = "brain-x"


////////////////////////////////////TRAUMAS////////////////////////////////////////

/obj/item/organ/brain/proc/has_trauma_type(brain_trauma_type = /datum/brain_trauma, resilience = TRAUMA_RESILIENCE_ABSOLUTE)
	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		if(istype(BT, brain_trauma_type) && (BT.resilience <= resilience))
			return BT

/obj/item/organ/brain/proc/get_traumas_type(brain_trauma_type = /datum/brain_trauma, resilience = TRAUMA_RESILIENCE_ABSOLUTE)
	. = list()
	for(var/X in traumas)
		var/datum/brain_trauma/BT = X
		if(istype(BT, brain_trauma_type) && (BT.resilience <= resilience))
			. += BT

/obj/item/organ/brain/proc/can_gain_trauma(datum/brain_trauma/trauma, resilience)
	if(!ispath(trauma))
		trauma = trauma.type
	if(!initial(trauma.can_gain))
		return FALSE
	if(!resilience)
		resilience = initial(trauma.resilience)

	var/resilience_tier_count = 0
	for(var/X in traumas)
		if(istype(X, trauma))
			return FALSE
		var/datum/brain_trauma/T = X
		if(resilience == T.resilience)
			resilience_tier_count++

	var/max_traumas
	switch(resilience)
		if(TRAUMA_RESILIENCE_BASIC)
			max_traumas = TRAUMA_LIMIT_BASIC
		if(TRAUMA_RESILIENCE_SURGERY)
			max_traumas = TRAUMA_LIMIT_SURGERY
		if(TRAUMA_RESILIENCE_LOBOTOMY)
			max_traumas = TRAUMA_LIMIT_LOBOTOMY
		if(TRAUMA_RESILIENCE_MAGIC)
			max_traumas = TRAUMA_LIMIT_MAGIC
		if(TRAUMA_RESILIENCE_ABSOLUTE)
			max_traumas = TRAUMA_LIMIT_ABSOLUTE

	if(resilience_tier_count >= max_traumas)
		return FALSE
	return TRUE

//Proc to use when directly adding a trauma to the brain, so extra args can be given
/obj/item/organ/brain/proc/gain_trauma(datum/brain_trauma/trauma, resilience, ...)
	var/list/arguments = list()
	if(args.len > 2)
		arguments = args.Copy(3)
	. = brain_gain_trauma(trauma, resilience, arguments)

//Direct trauma gaining proc. Necessary to assign a trauma to its brain. Avoid using directly.
/obj/item/organ/brain/proc/brain_gain_trauma(datum/brain_trauma/trauma, resilience, list/arguments)
	if(!can_gain_trauma(trauma, resilience))
		return

	var/datum/brain_trauma/actual_trauma
	if(ispath(trauma))
		if(!LAZYLEN(arguments))
			actual_trauma = new trauma() //arglist with an empty list runtimes for some reason
		else
			actual_trauma = new trauma(arglist(arguments))
	else
		actual_trauma = trauma

	if(actual_trauma.brain) //we don't accept used traumas here
		WARNING("gain_trauma was given an already active trauma.")
		return

	traumas += actual_trauma
	actual_trauma.brain = src
	if(owner)
		actual_trauma.owner = owner
		actual_trauma.on_gain()
	if(resilience)
		actual_trauma.resilience = resilience
	. = actual_trauma
	SSblackbox.record_feedback("tally", "traumas", 1, actual_trauma.type)

//Add a random trauma of a certain subtype
/obj/item/organ/brain/proc/gain_trauma_type(brain_trauma_type = /datum/brain_trauma, resilience)
	var/list/datum/brain_trauma/possible_traumas = list()
	for(var/T in subtypesof(brain_trauma_type))
		var/datum/brain_trauma/BT = T
		if(can_gain_trauma(BT, resilience) && initial(BT.random_gain))
			possible_traumas += BT

	if(!LAZYLEN(possible_traumas))
		return

	var/trauma_type = pick(possible_traumas)
	gain_trauma(trauma_type, resilience)

//Cure a random trauma of a certain resilience level
/obj/item/organ/brain/proc/cure_trauma_type(brain_trauma_type = /datum/brain_trauma, resilience = TRAUMA_RESILIENCE_BASIC)
	var/list/traumas = get_traumas_type(brain_trauma_type, resilience)
	if(LAZYLEN(traumas))
		qdel(pick(traumas))

/obj/item/organ/brain/proc/cure_all_traumas(resilience = TRAUMA_RESILIENCE_BASIC)
	var/list/traumas = get_traumas_type(resilience = resilience)
	for(var/X in traumas)
		qdel(X)

/obj/item/organ/brain/smooth
	icon_state = "brain-smooth"
