// None of these are really complex enough to merit their own file

/**
 * # Pet Command: Idle
 * Tells a pet to resume its idle behaviour, usually staying put where you leave it
 */
/datum/pet_command/idle
	command_name = "Stay"
	command_desc = "Command your pet to stay idle in this location."
	radial_icon = 'icons/obj/objects.dmi'
	radial_icon_state = "dogbed"
	speech_commands = list("sit", "stay", "stop")
	command_feedback = "sits"

/datum/pet_command/idle/execute_action(datum/ai_controller/controller)
	return SUBTREE_RETURN_FINISH_PLANNING // This cancels further AI planning

/**
 * # Pet Command: Stop
 * Tells a pet to exit command mode and resume its normal behaviour, which includes regular target-seeking and what have you
 */
/datum/pet_command/free
	command_name = "Loose"
	command_desc = "Allow your pet to resume its natural behaviours."
	radial_icon = 'icons/mob/actions/actions_spells.dmi'
	radial_icon_state = "repulse"
	speech_commands = list("free", "loose")
	command_feedback = "relaxes"

/datum/pet_command/free/execute_action(datum/ai_controller/controller)
	controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	return // Just move on to the next planning subtree.

/**
 * # Pet Command: Follow
 * Tells a pet to follow you until you tell it to do something else
 */
/datum/pet_command/follow
	command_name = "Follow"
	command_desc = "Command your pet to accompany you."
	radial_icon = 'icons/testing/turf_analysis.dmi'
	radial_icon_state = "red_arrow"
	speech_commands = list("heel", "follow")
	command_feedback = "follows"

/datum/pet_command/follow/set_command_active(mob/living/parent, mob/living/commander)
	. = ..()
	set_command_target(parent, commander)

/datum/pet_command/follow/execute_action(datum/ai_controller/controller)
	controller.queue_behavior(/datum/ai_behavior/pet_follow_friend, BB_CURRENT_PET_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/**
 * # Pet Command: Play Dead
 * Pretend to be dead for a random period of time
 */
/datum/pet_command/play_dead
	command_name = "Play Dead"
	command_desc = "Play a macabre trick."
	radial_icon = 'icons/roguetown/mob/cabbit.dmi'
	radial_icon_state = "cabbit_dead"
	speech_commands = list("play dead") // Don't get too creative here, people talk about dying pretty often

/datum/pet_command/play_dead/execute_action(datum/ai_controller/controller)
	controller.queue_behavior(/datum/ai_behavior/play_dead)
	return SUBTREE_RETURN_FINISH_PLANNING

/**
 * # Pet Command: Good Boy
 * React if complimented
 */
/datum/pet_command/good_boy
	command_name = "Good Boy"
	command_desc = "Give your pet a compliment."
	hidden = TRUE

/datum/pet_command/good_boy/New(mob/living/parent)
	. = ..()
	speech_commands += "good [parent.name]"
	switch (parent.gender)
		if (MALE)
			speech_commands += "good boy"
			speech_commands += "dobro boy"
			return
		if (FEMALE)
			speech_commands += "good girl"
			speech_commands += "dobro girl"
			return
	// If we get past this point someone has finally added a non-binary dog

/datum/pet_command/good_boy/execute_action(datum/ai_controller/controller)
	controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	var/mob/living/parent = weak_parent.resolve()
	if (!parent)
		return SUBTREE_RETURN_FINISH_PLANNING

	new /obj/effect/temp_visual/heart(parent.loc)
	parent.emote("spin")
	return SUBTREE_RETURN_FINISH_PLANNING

/**
 * # Pet Command: Attack
 * Tells a pet to chase and bite the next thing you point at
 */
/datum/pet_command/point_targeting/attack
	command_name = "Attack"
	command_desc = "Command your pet to attack things that you point out to it."
	radial_icon = 'icons/effects/effects.dmi'
	radial_icon_state = "bite"

	speech_commands = list("attack", "sic", "kill")
	command_feedback = "growl"
	pointed_reaction = "and growls"
	/// Balloon alert to display if providing an invalid target
	var/refuse_reaction = "shakes head"
	/// Attack behaviour to use
	var/attack_behaviour = /datum/ai_behavior/basic_melee_attack

// Refuse to target things we can't target, chiefly other friends
/datum/pet_command/point_targeting/attack/set_command_target(mob/living/parent, atom/target)
	if (!target)
		return
	var/mob/living/living_parent = parent
	if (!living_parent.ai_controller)
		return
	var/datum/targetting_datum/targeter = living_parent.ai_controller.blackboard[targeting_strategy_key]
	if (!targeter)
		return
	if (!targeter.can_attack(living_parent, target))
		refuse_target(parent, target)
		return
	return ..()

/// Display feedback about not targeting something
/datum/pet_command/point_targeting/attack/proc/refuse_target(mob/living/parent, atom/target)
	var/mob/living/living_parent = parent
	living_parent.say(refuse_reaction)
	living_parent.visible_message(span_notice("[living_parent] refuses to attack [target]."))

/datum/pet_command/point_targeting/attack/execute_action(datum/ai_controller/controller)
	controller.queue_behavior(attack_behaviour, BB_CURRENT_PET_TARGET, targeting_strategy_key)
	return SUBTREE_RETURN_FINISH_PLANNING

/**
 * # Breed command. breed with a partner!
 */
/datum/pet_command/point_targeting/breed
	command_name = "Breed"
	command_desc = "Command your pet to attempt to breed with a partner."
	radial_icon = 'icons/effects/effects.dmi'
	radial_icon_state = "heart"
	speech_commands = list("breed", "consummate")
	var/datum/ai_behavior/reproduce_behavior = /datum/ai_behavior/make_babies

/datum/pet_command/point_targeting/breed/set_command_target(mob/living/parent, atom/target)
	if(isnull(target) || !isliving(target))
		return
	if(!HAS_TRAIT(parent, TRAIT_MOB_BREEDER) || !HAS_TRAIT(target, TRAIT_MOB_BREEDER))
		return
	if(isnull(parent.ai_controller))
		return
	if(!parent.ai_controller.blackboard[BB_BREED_READY] || isnull(parent.ai_controller.blackboard[BB_BABIES_PARTNER_TYPES]))
		return
	var/mob/living/living_target = target
	if(!living_target.ai_controller?.blackboard[BB_BREED_READY])
		return
	return ..()

/datum/pet_command/point_targeting/breed/execute_action(datum/ai_controller/controller)
	if(is_type_in_list(controller.blackboard[BB_CURRENT_PET_TARGET], controller.blackboard[BB_BABIES_PARTNER_TYPES]))
		controller.queue_behavior(reproduce_behavior, BB_CURRENT_PET_TARGET)
		controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	return SUBTREE_RETURN_FINISH_PLANNING

/**
 * # Pet Command: Targetted Ability
 * Tells a pet to use some kind of ability on the next thing you point at
 */
/datum/pet_command/point_targeting/use_ability
	command_name = "Use ability"
	command_desc = "Command your pet to use one of its special skills on something that you point out to it."
	radial_icon = 'icons/mob/actions/actions_spells.dmi'
	radial_icon_state = "projectile"
	speech_commands = list("shoot", "blast", "cast")
	command_feedback = "growl"
	pointed_reaction = "and growls"
	/// Blackboard key where a reference to some kind of mob ability is stored
	var/pet_ability_key

/datum/pet_command/point_targeting/use_ability/execute_action(datum/ai_controller/controller)
	if (!pet_ability_key)
		return
	var/datum/action/cooldown/using_action = controller.blackboard[pet_ability_key]
	if (QDELETED(using_action))
		return
	// We don't check if the target exists because we want to 'sit attentively' if we've been instructed to attack but not given one yet
	// We also don't check if the cooldown is over because there's no way a pet owner can know that, the behaviour will handle it
	controller.queue_behavior(/datum/ai_behavior/pet_use_ability, pet_ability_key, BB_CURRENT_PET_TARGET)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/pet_command/protect_owner
	command_name = "Protect owner"
	command_desc = "Your pet will run to your aid."
	hidden = TRUE
	///the range our owner needs to be in for us to protect him
	var/protect_range = 9
	///the behavior we will use when he is attacked
	var/protect_behavior = /datum/ai_behavior/basic_melee_attack
	///message cooldown to prevent too many people from telling you not to commit suicide
	COOLDOWN_DECLARE(self_harm_message_cooldown)

/datum/pet_command/protect_owner/add_new_friend(mob/living/tamer)
	RegisterSignal(tamer, COMSIG_ATOM_WAS_ATTACKED, PROC_REF(set_attacking_target))
	if(!HAS_TRAIT(tamer, TRAIT_RELAYING_ATTACKER))
		tamer.AddElement(/datum/element/relay_attackers)

/datum/pet_command/protect_owner/remove_friend(mob/living/unfriended)
	UnregisterSignal(unfriended, COMSIG_ATOM_WAS_ATTACKED)

/datum/pet_command/protect_owner/execute_action(datum/ai_controller/controller)
	var/mob/living/victim = controller.blackboard[BB_CURRENT_PET_TARGET]
	if(QDELETED(victim))
		return
	// cancel the action if they're below our given crit stat, OR if we're trying to attack ourselves (this can happen on tamed mobs w/ protect subtree rarely)
	if(victim.stat > controller.blackboard[BB_TARGET_MINIMUM_STAT] || victim == controller.pawn)
		controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
		return
	controller.queue_behavior(protect_behavior, BB_CURRENT_PET_TARGET, BB_PET_TARGETING_DATUM)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/pet_command/protect_owner/set_command_active(mob/living/parent, mob/living/victim)
	. = ..()
	set_command_target(parent, victim)

/datum/pet_command/protect_owner/proc/set_attacking_target(atom/source, mob/living/attacker)
	var/mob/living/owner = weak_parent.resolve()
	if(isnull(owner))
		return
	if(source == attacker)
		var/list/interventions = owner.ai_controller?.blackboard[BB_OWNER_SELF_HARM_RESPONSES] || list()
		if (length(interventions) && COOLDOWN_FINISHED(src, self_harm_message_cooldown) && prob(30))
			COOLDOWN_START(src, self_harm_message_cooldown, 5 SECONDS)
			var/chosen_statement = pick(interventions)
			INVOKE_ASYNC(owner, TYPE_PROC_REF(/atom/movable, say), chosen_statement)
		return
	var/mob/living/current_target = owner.ai_controller?.blackboard[BB_CURRENT_PET_TARGET]
	if(attacker == current_target) //we are already dealing with this target
		return
	if(isliving(attacker) && can_see(owner, attacker, protect_range))
		set_command_active(owner, attacker)

// Some flavor additions for wolf-related pet commands
/datum/pet_command/good_boy/wolf
	speech_commands = list("good wolf")

/datum/pet_command/follow/wolf
	// Nordic-themed for a bit of extra flavor
	speech_commands = list("heel", "follow", "fylgja", "fyl")

/datum/pet_command/calm
	command_name = "Calm"
	command_desc = "Makes the pet calm"

	speech_commands = list("calm")

/datum/pet_command/calm/execute_action(datum/ai_controller/controller)
	controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	var/mob/living/parent = weak_parent.resolve()
	if (!parent)
		return SUBTREE_RETURN_FINISH_PLANNING

	parent.pet_passive = TRUE
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/pet_command/aggressive
	command_name = "Aggressive"
	command_desc = "Makes the pet calm"

	speech_commands = list("aggressive")

/datum/pet_command/aggressive/execute_action(datum/ai_controller/controller)
	controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	var/mob/living/parent = weak_parent.resolve()
	if (!parent)
		return SUBTREE_RETURN_FINISH_PLANNING

	parent.pet_passive = FALSE
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/pet_command/point_targeting/home
	command_name = "Set Home"
	command_desc = "Command your pet to make the targetted area its home."
	radial_icon = 'icons/mob/actions/actions_spells.dmi'
	radial_icon_state = "projectile"
	speech_commands = list("new home")
	command_feedback = "nods"
	pointed_reaction = "and nods"

/datum/pet_command/point_targeting/home/execute_action(datum/ai_controller/controller)
	controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	var/obj/structure/target = controller.blackboard[BB_CURRENT_PET_TARGET]
	if(!target)
		return
	if(!istype(target, controller.blackboard[BB_HOME_PATH]))
		return

	// We don't check if the target exists because we want to 'sit attentively' if we've been instructed to attack but not given one yet
	// We also don't check if the cooldown is over because there's no way a pet owner can know that, the behaviour will handle it
	controller.set_blackboard_key(BB_CURRENT_HOME, target)
	return SUBTREE_RETURN_FINISH_PLANNING

/datum/pet_command/go_home
	command_name = "Go Home"
	command_desc = "Sends your pet home."
	radial_icon = 'icons/roguetown/mob/cabbit.dmi'
	radial_icon_state = "cabbit_dead"
	speech_commands = list("go home") // Don't get too creative here, people talk about dying pretty often

/datum/pet_command/go_home/execute_action(datum/ai_controller/controller)
	controller.clear_blackboard_key(BB_ACTIVE_PET_COMMAND)
	controller.queue_behavior(/datum/ai_behavior/enter_exit_home/no_cooldown)
	return SUBTREE_RETURN_FINISH_PLANNING
